import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../../../core/numbers/flt.dart';
import '../../setup/data/refusal.dart';
import '../../stock/logic/stock_documents.dart';
import '../../stock/logic/stock_rules.dart';
import '../../stock/ui/stock_providers.dart';
import '../data/pos_closing_db.dart';
import '../data/pos_db.dart';
import '../logic/sale.dart';
import '../logic/totals.dart';

const posPath = '/pos';

final posSettingsProvider = Provider<PosSettings>(
  (ref) => PosSettings(
    ref.watch(singleProvider(PosSettings.doctype)).value ?? const {},
  ),
);

final sellingSettingsProvider = Provider<SellingSettings>(
  (ref) => SellingSettings(
    ref.watch(singleProvider(SellingSettings.doctype)).value ?? const {},
  ),
);

/// The Open POS Opening Entry, or null (POS-R1).
final openSessionProvider = StreamProvider<PosOpeningEntryData?>(
  (ref) => ref.watch(appDatabaseProvider).watchOpenSession(),
);

/// The closing entry that can still be cancelled (POS-R20).
final cancellableClosingProvider =
    FutureProvider.autoDispose<PosClosingEntryData?>((ref) {
      ref.watch(openSessionProvider);
      return ref.watch(appDatabaseProvider).cancellableClosing();
    });

final recentOrdersProvider = StreamProvider<List<SalesInvoiceData>>(
  (ref) => ref.watch(appDatabaseProvider).watchRecentOrders(),
);

/// The items the register sells, in the cart's warehouse and price list.
final registerItemsProvider = StreamProvider<List<RegisterItem>>((ref) {
  final (warehouse, list) = ref.watch(
    cartProvider.select((s) => (s.value?.warehouseId, s.value?.priceListId)),
  );
  if (warehouse == null || list == null) return const Stream.empty();
  return ref
      .watch(appDatabaseProvider)
      .watchRegisterItems(
        warehouse,
        list,
        toStorage(DateTime.now()).substring(0, 10),
      );
});

/// The cart's totals, recalculated on every change (POS-R9 to R14).
final cartTotalsProvider = Provider<Totals?>((ref) {
  final sale = ref.watch(cartProvider).value;
  if (sale == null) return null;
  return totalsOf(sale, saleSettingsOf(ref.watch(formatsProvider)));
});

final cartProvider = AsyncNotifierProvider<CartNotifier, Sale>(
  CartNotifier.new,
);

/// The sale being built. It lives in memory, so it survives rotation and
/// layout changes; only Save as Draft writes it (POS-R18).
class CartNotifier extends AsyncNotifier<Sale> {
  AppDatabase get _db => ref.read(appDatabaseProvider);
  Sale get sale => state.requireValue;
  int get _precision => ref.read(formatsProvider).system.currencyPrecision;

  @override
  Future<Sale> build() => ref.watch(appDatabaseProvider).newSale();

  /// Marks the sale changed and redraws it (the Serial / Batch editor calls
  /// it after changing a line's entries).
  void changed() {
    sale.dirty = true;
    ref.notifyListeners();
  }

  /// POS-R4: adds one of [item] in [uomId], or with serial or batch [entry];
  /// a line with the same item, unit, rate and batch takes it. A stock item
  /// short in the warehouse is refused, unless it may go negative.
  Future<void> add(RegisterItem item, {int? uomId, SbEntry? entry}) async {
    final s = sale;
    final line = await _db.newLine(s, item.id, uomId: uomId);
    final floats = ref.read(formatsProvider).system.floatPrecision;
    final inCart = s.lines
        .where((l) => l.itemId == item.id)
        .fold(0.0, (t, l) => t + stockQty(l.qty, l.factor, floats));
    final strict = item.hasBatch || item.hasSerial;
    final negative =
        !strict &&
        (item.allowNegative ||
            ref.read(stockSettingsProvider).allowNegativeStock);
    if (item.stockItem && !negative && item.qty < inCart + line.factor) {
      throw RefusedException(Refusal.itemUnavailable, null, [
        item.code,
        (ref.read(warehousesProvider).value ?? [])
            .where((w) => w.id == s.warehouseId)
            .map((w) => w.name)
            .join(),
        item.qty - inCart,
        inCart + line.factor,
      ]);
    }
    addToSale(s, line, entry);
    changed();
  }

  void remove(SaleLine line) {
    sale.lines.remove(line);
    changed();
  }

  void setQty(SaleLine line, double qty) {
    line.qty = qty;
    changed();
  }

  /// POS-R5: another unit looks the price up again.
  Future<void> setUnit(SaleLine line, int uomId) async {
    await _db.setUnit(sale, line, uomId);
    changed();
  }

  /// POS-R6, R7, R8: one of a typed rate, discount or Price List Rate; the
  /// others follow from it. A discount above the item's Max Discount (%) is
  /// refused: false, and the line is left as it was.
  bool setPrice(
    SaleLine line, {
    double? rate,
    double? percentage,
    double? amount,
    double? priceListRate,
  }) {
    final old = line.priceListRate;
    if (priceListRate != null) line.priceListRate = priceListRate;
    final p = linePrice(
      line.priceListRate,
      rate: rate,
      amount: amount,
      percentage:
          percentage ??
          (rate == null && amount == null ? line.discountPercentage : null),
      precision: _precision,
      method: ref.read(formatsProvider).rounding,
    );
    final max = maxDiscountOf(line);
    if (max > 0 && p.discountPercentage > max) {
      if (priceListRate != null) line.priceListRate = old;
      return false;
    }
    line
      ..rate = p.rate
      ..discountPercentage = p.discountPercentage
      ..discountAmount = p.discountAmount;
    changed();
    return true;
  }

  /// The item's Max Discount (%); 0 means none.
  double maxDiscountOf(SaleLine line) =>
      (ref.read(registerItemsProvider).value ?? [])
          .where((i) => i.id == line.itemId)
          .firstOrNull
          ?.maxDiscount ??
      0;

  /// POS-R13: a percentage, or an amount when the percentage is zero.
  void setAdditionalDiscount({double percentage = 0, double amount = 0}) {
    sale
      ..additionalDiscountPercentage = percentage
      ..discountAmount = amount;
    changed();
  }

  void setPayment(int modeId, double amount) {
    sale.payments[modeId] = flt(
      amount,
      _precision,
      ref.read(formatsProvider).rounding,
    );
    changed();
  }

  /// Starts a new sale with the settings in force now (POS-R2a).
  Future<void> reset() async {
    state = AsyncData(await _db.newSale());
  }

  /// POS-R18: held order [id] becomes the cart.
  Future<void> load(int id) async {
    state = AsyncData(await _db.loadSale(id));
  }

  /// Save as Draft; a new sale follows.
  Future<void> saveDraft() async {
    if (sale.lines.isEmpty) throw const RefusedException(Refusal.emptyCart);
    final problems = ref.read(posSettingsProvider).validateStockOnSave
        ? await _db.saleProblems(sale, stockOnly: true)
        : const <RefusedException>[];
    if (problems.isNotEmpty) throw RefusedAll(problems);
    await _db.saveSale(sale);
    await reset();
  }

  /// POS-R17: submits the cart; returns it, submitted, for the order
  /// summary, and starts a new sale.
  Future<Submitted> submit() async {
    final s = sale;
    final name = await _db.submitSale(s);
    await reset();
    return (sale: s, name: name);
  }
}

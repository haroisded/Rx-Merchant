import '../../../core/numbers/flt.dart';

// Pure stock rules of 02-stock.md: units, additional costs, price and item
// tax lookup, batch status and the order serials and batches are picked in.

/// STK-R9: `stock_qty = qty × conversion_factor`, at Float Precision.
double stockQty(double qty, double factor, int floatPrecision) =>
    flt(qty * factor, floatPrecision);

/// Max Discount (%) is a percentage: 0 to 100 (Item, 3.13).
bool maxDiscountOk(double d) => d >= 0 && d <= 100;

/// STK-R3: true when [qty] has no fractional part.
bool isWhole(double qty) => (qty - qty.roundToDouble()).abs() < 1e-9;

/// STK-R39: spreads [total] over rows in proportion to [basicAmounts],
/// rounded to [precision]; the last row takes the remainder so the shares
/// add up exactly. Rows of 600 and 400 with 50 receive 30 and 20.
List<double> spreadCosts(
  List<double> basicAmounts,
  double total,
  int precision,
) {
  if (basicAmounts.isEmpty) return const [];
  final base = basicAmounts.fold(0.0, (s, a) => s + a);
  final shares = <double>[];
  var given = 0.0;
  for (final (i, amount) in basicAmounts.indexed) {
    final share = i == basicAmounts.length - 1
        ? flt(total - given, precision)
        : flt(
            base == 0 ? total / basicAmounts.length : total * amount / base,
            precision,
          );
    shares.add(share);
    given += share;
  }
  return shares;
}

/// Empty bounds are open-ended. Dates are `YYYY-MM-DD`, so text order is
/// date order.
bool validityOverlaps(
  String? aFrom,
  String? aUpto,
  String? bFrom,
  String? bUpto,
) =>
    (aFrom == null || bUpto == null || aFrom.compareTo(bUpto) <= 0) &&
    (bFrom == null || aUpto == null || bFrom.compareTo(aUpto) <= 0);

/// One Item Price of an item on one price list. [uomId] null is the Stock UOM.
typedef PriceRow = ({
  int? uomId,
  double rate,
  String? validFrom,
  String? validUpto,
  int? batchId,
});

/// STK-R10 steps 1 and 2 on one price list: the price of [uomId] on [date]
/// (`YYYY-MM-DD`), and the unit it was stored for. Null when there is none;
/// the caller then tries the default price list (step 3).
({double rate, int storedUomId})? pickPrice(
  List<PriceRow> prices, {
  required int uomId,
  required int stockUomId,
  required double factor,
  required bool priceNotUomDependent,
  required String date,
  int? batchId,
}) {
  PriceRow? best(int unit) {
    final valid = [
      for (final p in prices)
        if ((p.uomId ?? stockUomId) == unit &&
            (p.batchId == null || p.batchId == batchId) &&
            (p.validFrom == null || p.validFrom!.compareTo(date) <= 0) &&
            (p.validUpto == null || p.validUpto!.compareTo(date) >= 0))
          p,
    ];
    // A row for the batch beats one without; then the latest Valid From.
    valid.sort((a, b) {
      if ((a.batchId == null) != (b.batchId == null)) {
        return a.batchId == null ? 1 : -1;
      }
      return (b.validFrom ?? '').compareTo(a.validFrom ?? '');
    });
    return valid.firstOrNull;
  }

  if (best(uomId) case final p?) return (rate: p.rate, storedUomId: uomId);
  if (uomId == stockUomId) return null;
  if (best(stockUomId) case final p?) {
    return (
      rate: priceNotUomDependent ? p.rate * factor : p.rate,
      storedUomId: stockUomId,
    );
  }
  return null;
}

/// STK-R13: the item's own row with the latest Valid From on or before
/// [date] (an empty Valid From always qualifies); otherwise the first
/// template up the item's group chain ([groupTemplates], the item's own
/// group first).
int? itemTaxTemplateFor(
  List<({int templateId, String? validFrom})> itemRows,
  List<int?> groupTemplates,
  String date,
) {
  final valid = [
    for (final r in itemRows)
      if (r.validFrom == null || r.validFrom!.compareTo(date) <= 0) r,
  ]..sort((a, b) => (b.validFrom ?? '').compareTo(a.validFrom ?? ''));
  return valid.firstOrNull?.templateId ??
      groupTemplates.whereType<int>().firstOrNull;
}

/// STK-R19 batch status on [today] (`YYYY-MM-DD`).
enum BatchStatus { notSet, notExpired, expired }

BatchStatus batchStatus(String? expiryDate, String today) =>
    switch (expiryDate) {
      null => BatchStatus.notSet,
      final e when today.compareTo(e) > 0 => BatchStatus.expired,
      _ => BatchStatus.notExpired,
    };

/// STK-R19: the expiry date a new batch defaults to.
String? defaultExpiry(String? fromDate, int? shelfLifeInDays) {
  if (fromDate == null || shelfLifeInDays == null) return null;
  return DateTime.parse(fromDate)
      .add(Duration(days: shelfLifeInDays))
      .toIso8601String()
      .substring(0, 10);
}

/// A serial number or batch that can be taken from a warehouse.
typedef Pickable<T> = ({T id, double qty, String received, String? expiry});

/// STK-R27 Auto Fetch: takes [need] from [available] in the order of Pick
/// Serial / Batch Based On ([basis]: 'FIFO' oldest receipt first, 'LIFO'
/// newest first, 'Expiry' earliest expiry first). Returns what it took,
/// which is less than [need] when there is not enough.
List<(T, double)> autoPick<T>(
  List<Pickable<T>> available,
  double need,
  String basis,
) {
  final sorted = [...available]
    ..sort(
      (a, b) => switch (basis) {
        'LIFO' => b.received.compareTo(a.received),
        'Expiry' when a.expiry != b.expiry =>
          a.expiry == null
              ? 1
              : b.expiry == null
              ? -1
              : a.expiry!.compareTo(b.expiry!),
        _ => a.received.compareTo(b.received),
      },
    );
  final picked = <(T, double)>[];
  var left = need;
  for (final a in sorted) {
    if (left <= 1e-9) break;
    if (a.qty <= 0) continue;
    final take = a.qty < left ? a.qty : left;
    picked.add((a.id, take));
    left -= take;
  }
  return picked;
}

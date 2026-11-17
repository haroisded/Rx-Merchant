import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/refusal.dart';
import '../../setup/data/setup_queries.dart';
import '../logic/stock_documents.dart';
import 'stock_entry_db.dart';
import 'stock_ledger.dart';

const stockReconciliationType = 'Stock Reconciliation';

/// Stock Reconciliation: Opening Stock and physical counts (STK-R42).
extension StockReconciliationDb on AppDatabase {
  /// Fills each line's current quantity and rate as of [posting].
  Future<void> fillCurrent(
    List<ReconciliationLine> lines,
    String posting,
  ) async {
    for (final l in lines) {
      final b = await balanceAt(l.itemId, l.warehouseId, posting);
      l
        ..currentQty = b.qty
        ..currentRate = b.rate;
    }
  }

  /// "Fetch Items": every stocked item with a balance in [warehouseId] as
  /// of [posting], counted as it stands.
  Future<List<ReconciliationLine>> fetchItems(
    int warehouseId,
    String posting,
  ) async {
    final rows = await customSelect(
      'SELECT DISTINCT l.item_id FROM stock_ledger_entry l '
      'JOIN item i ON i.id = l.item_id WHERE l.warehouse_id = ? '
      'AND l.is_cancelled = 0 AND i.has_batch_no = 0 AND i.has_serial_no = 0 '
      'ORDER BY i.item_code',
      variables: [Variable(warehouseId)],
    ).get();
    final lines = <ReconciliationLine>[];
    for (final r in rows) {
      final b = await balanceAt(r.read<int>('item_id'), warehouseId, posting);
      if (b.qty == 0) continue;
      lines.add(
        ReconciliationLine(
          itemId: r.read<int>('item_id'),
          warehouseId: warehouseId,
          qty: b.qty,
          rate: b.rate,
          currentQty: b.qty,
          currentRate: b.rate,
        ),
      );
    }
    return lines;
  }

  /// Saves a draft and returns its id. Rows whose quantity and rate equal
  /// the current values are dropped. [posting] null: Edit Posting Date and
  /// Time is off (as in `saveStockEntry`).
  Future<int> saveStockReconciliation(
    StockReconciliationCompanion header,
    List<ReconciliationLine> lines, {
    String? posting,
  }) => transaction(() async {
    final now = toStorage(DateTime.now());
    final at = posting ?? now;
    if (header.id.present) {
      final old = await (select(
        stockReconciliation,
      )..where((r) => r.id.equals(header.id.value))).getSingle();
      if (old.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    }
    refuseFirst(
      checkReconciliationLines(
        lines,
        items: await itemFacts(lines.map((l) => l.itemId)),
        usableWarehouses: await usableWarehouses(),
        date: at.substring(0, 10),
      ),
    );
    final id = await upsert(
      stockReconciliation,
      header.copyWith(
        postingDatetime: Value(at),
        modifiedAt: Value(now),
        docstatus: const Value(0),
      ),
      header.id,
    );
    await _writeLines(id, lines, at);
    return id;
  });

  Future<void> _writeLines(
    int id,
    List<ReconciliationLine> lines,
    String posting,
  ) async {
    await (delete(
      stockReconciliationItem,
    )..where((i) => i.stockReconciliationId.equals(id))).go();
    final precision = await currencyPrecision();
    final floats = await floatPrecision();
    var difference = 0.0;
    var idx = 0;
    for (final l in lines) {
      final current = await balanceAt(l.itemId, l.warehouseId, posting);
      l
        ..currentQty = current.qty
        ..currentRate = current.rate;
      if (l.qty == l.currentQty && l.rate == l.currentRate) continue;
      final amount = flt(l.qty * l.rate - current.value, precision);
      difference += amount;
      l.id = await into(stockReconciliationItem).insert(
        StockReconciliationItemCompanion.insert(
          stockReconciliationId: id,
          idx: ++idx,
          itemId: l.itemId,
          warehouseId: l.warehouseId,
          qty: l.qty,
          valuationRate: l.rate,
          currentQty: Value(l.currentQty),
          currentValuationRate: Value(l.currentRate),
          quantityDifference: Value(flt(l.qty - l.currentQty, floats)),
          amountDifference: Value(amount),
        ),
      );
    }
    await (update(stockReconciliation)..where((r) => r.id.equals(id))).write(
      StockReconciliationCompanion(
        differenceAmount: Value(flt(difference, precision)),
      ),
    );
  }

  Future<List<ReconciliationLine>> reconciliationLines(int id) =>
      (select(stockReconciliationItem)
            ..where((i) => i.stockReconciliationId.equals(id))
            ..orderBy([(i) => OrderingTerm(expression: i.idx)]))
          .map(
            (r) => ReconciliationLine(
              id: r.id,
              itemId: r.itemId,
              warehouseId: r.warehouseId,
              qty: r.qty,
              rate: r.valuationRate,
              currentQty: r.currentQty,
              currentRate: r.currentValuationRate,
            ),
          )
          .get();

  /// Each row writes a ledger entry that sets the balance to the counted
  /// quantity at its rate (STK-R42).
  Future<void> submitStockReconciliation(int id) => transaction(() async {
    final r = await (select(
      stockReconciliation,
    )..where((x) => x.id.equals(id))).getSingle();
    if (r.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    final posting = postingAt(r.postingDatetime, r.modifiedAt);
    await checkNotFrozen(posting);
    final lines = await reconciliationLines(id);
    refuseFirst(
      checkReconciliationLines(
        lines,
        items: await itemFacts(lines.map((l) => l.itemId)),
        usableWarehouses: await usableWarehouses(),
        date: posting.substring(0, 10),
      ),
    );
    // The current values are taken again at the moment it posts.
    await _writeLines(id, lines, posting);
    final name = switch (r.amendedFromId) {
      final from? => await amendedName('stock_reconciliation', from),
      null => await nextName(
        await defaultSeries(stockReconciliationType),
        DateTime.parse(posting),
      ),
    };
    await (update(stockReconciliation)..where((x) => x.id.equals(id))).write(
      StockReconciliationCompanion(
        name: Value(name),
        docstatus: const Value(1),
        postingDatetime: Value(posting),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
    );
    await postLedger([
      for (final l in await reconciliationLines(id))
        StockLedgerEntryCompanion.insert(
          itemId: l.itemId,
          warehouseId: l.warehouseId,
          postingDatetime: posting,
          voucherType: stockReconciliationType,
          voucherId: id,
          voucherNo: name,
          voucherDetailId: l.id!,
          actualQty: l.qty - l.currentQty,
          // The counted quantity and rate: the engine sets the balance to
          // them (stock_ledger.dart).
          qtyAfterTransaction: l.qty,
          incomingRate: Value(l.rate),
        ),
    ]);
  });

  Future<void> cancelStockReconciliation(int id) => transaction(() async {
    final r = await (select(
      stockReconciliation,
    )..where((x) => x.id.equals(id))).getSingle();
    if (r.docstatus != 1) throw const RefusedException(Refusal.docstatus);
    await checkNotFrozen(r.postingDatetime);
    await (update(stockReconciliation)..where((x) => x.id.equals(id))).write(
      StockReconciliationCompanion(
        docstatus: const Value(2),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
    );
    await cancelLedger(stockReconciliationType, id);
  });

  Future<int> amendStockReconciliation(int id) async {
    final r = await (select(
      stockReconciliation,
    )..where((x) => x.id.equals(id))).getSingle();
    if (r.docstatus != 2) throw const RefusedException(Refusal.docstatus);
    return saveStockReconciliation(
      StockReconciliationCompanion.insert(
        purpose: r.purpose,
        postingDatetime: r.postingDatetime,
        setWarehouseId: Value(r.setWarehouseId),
        amendedFromId: Value(id),
      ),
      [for (final l in await reconciliationLines(id)) l..id = null],
      posting: r.postingDatetime,
    );
  }
}

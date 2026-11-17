import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// The filters a stock report may use (STK-R43). Dates are `YYYY-MM-DD`.
/// A group warehouse or item group includes everything under it.
class StockFilters {
  StockFilters({
    this.from,
    this.to,
    this.warehouseId,
    this.itemId,
    this.itemGroupId,
    this.batchId,
    this.serialId,
    this.priceListId,
    this.voucherNo,
  });

  String? from;
  String? to;
  int? warehouseId;
  int? itemId;
  int? itemGroupId;
  int? batchId;
  int? serialId;
  int? priceListId;
  String? voucherNo;
}

/// The ids of [table] row [id] and everything under it in the tree.
String _subtree(String table, int id) =>
    '(WITH RECURSIVE t(id) AS (SELECT $id UNION '
    'SELECT x.id FROM $table x JOIN t ON x.parent_id = t.id) SELECT id FROM t)';

/// Report rows: one value per column, then hidden values the screen uses
/// (a voucher's type and id). Every report reads only entries that are not
/// cancelled (STK-R43).
typedef ReportRows = List<List<Object?>>;

extension StockReports on AppDatabase {
  Future<ReportRows> _rows(String sql, List<Object?> args, int width) async {
    final rows = await customSelect(
      sql,
      variables: [for (final a in args) Variable(a)],
    ).get();
    return [
      for (final r in rows) [for (var i = 0; i < width; i++) r.data['c$i']],
    ];
  }

  /// Conditions on `l` (ledger), `i` (item) and `w` (warehouse).
  (String, List<Object?>) _where(StockFilters f, {bool range = true}) {
    final parts = <String>['l.is_cancelled = 0'];
    final args = <Object?>[];
    if (range && f.from != null) {
      parts.add('substr(l.posting_datetime, 1, 10) >= ?');
      args.add(f.from);
    }
    if (f.to != null) {
      parts.add('substr(l.posting_datetime, 1, 10) <= ?');
      args.add(f.to);
    }
    if (f.itemId != null) {
      parts.add('l.item_id = ?');
      args.add(f.itemId);
    }
    if (f.warehouseId case final w?) {
      parts.add('l.warehouse_id IN ${_subtree('warehouse', w)}');
    }
    if (f.itemGroupId case final g?) {
      parts.add('i.item_group_id IN ${_subtree('item_group', g)}');
    }
    if (f.batchId != null) {
      parts.add('l.batch_id = ?');
      args.add(f.batchId);
    }
    if (f.voucherNo case final v? when v.isNotEmpty) {
      parts.add('l.voucher_no LIKE ?');
      args.add('%$v%');
    }
    return (parts.join(' AND '), args);
  }

  /// Date, Item, Stock UOM, In Qty, Out Qty, Balance Qty, Warehouse,
  /// Incoming Rate, Valuation Rate, Balance Value, Value Change, Voucher
  /// Type, Voucher #, Batch; then voucher type and id.
  Future<ReportRows> stockLedgerReport(StockFilters f) {
    final (where, args) = _where(f);
    return _rows(
      'SELECT l.posting_datetime c0, i.item_code c1, u.name c2, '
      'CASE WHEN l.actual_qty > 0 THEN l.actual_qty END c3, '
      'CASE WHEN l.actual_qty < 0 THEN -l.actual_qty END c4, '
      'l.qty_after_transaction c5, w.name c6, l.incoming_rate c7, '
      'l.valuation_rate c8, l.stock_value c9, l.stock_value_difference c10, '
      'l.voucher_type c11, l.voucher_no c12, b.batch_id c13, '
      'l.voucher_type c14, l.voucher_id c15 '
      'FROM stock_ledger_entry l JOIN item i ON i.id = l.item_id '
      'JOIN uom u ON u.id = i.stock_uom_id '
      'JOIN warehouse w ON w.id = l.warehouse_id '
      'LEFT JOIN batch b ON b.id = l.batch_id '
      'WHERE $where ORDER BY l.posting_datetime, l.id',
      args,
      16,
    );
  }

  /// Item, Item Name, Warehouse, Stock UOM, Opening Qty, Opening Value, In
  /// Qty, In Value, Out Qty, Out Value, Balance Qty, Balance Value,
  /// Valuation Rate. Opening is everything before From; an entry that adds
  /// or keeps the quantity counts as In, as in ERPNext.
  Future<ReportRows> stockBalanceReport(StockFilters f) async {
    final (where, args) = _where(f, range: false);
    final from = f.from ?? '0000-00-00';
    final rows = await _rows(
      'SELECT i.item_code c0, i.item_name c1, w.name c2, u.name c3, '
      'SUM(CASE WHEN d < ?1 THEN l.actual_qty ELSE 0 END) c4, '
      'SUM(CASE WHEN d < ?1 THEN l.stock_value_difference ELSE 0 END) c5, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty >= 0 THEN l.actual_qty ELSE 0 END) c6, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty >= 0 THEN l.stock_value_difference ELSE 0 END) c7, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty < 0 THEN -l.actual_qty ELSE 0 END) c8, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty < 0 THEN -l.stock_value_difference ELSE 0 END) c9, '
      'SUM(l.actual_qty) c10, SUM(l.stock_value_difference) c11 '
      'FROM (SELECT *, substr(posting_datetime, 1, 10) AS d FROM stock_ledger_entry) l '
      'JOIN item i ON i.id = l.item_id JOIN uom u ON u.id = i.stock_uom_id '
      'JOIN warehouse w ON w.id = l.warehouse_id '
      'WHERE $where GROUP BY l.item_id, l.warehouse_id ORDER BY i.item_code, w.name',
      [from, ...args],
      12,
    );
    return [
      for (final r in rows)
        [
          ...r,
          (r[10] as double) == 0 ? 0.0 : (r[11] as double) / (r[10] as double),
        ],
    ];
  }

  /// Item, Batch, Warehouse, Opening, In, Out, Balance, Expiry (status is
  /// added by the screen).
  Future<ReportRows> batchBalanceReport(StockFilters f) {
    final (where, args) = _where(f, range: false);
    return _rows(
      'SELECT i.item_code c0, b.batch_id c1, w.name c2, '
      'SUM(CASE WHEN d < ?1 THEN l.actual_qty ELSE 0 END) c3, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty > 0 THEN l.actual_qty ELSE 0 END) c4, '
      'SUM(CASE WHEN d >= ?1 AND l.actual_qty < 0 THEN -l.actual_qty ELSE 0 END) c5, '
      'SUM(l.actual_qty) c6, b.expiry_date c7 '
      'FROM (SELECT *, substr(posting_datetime, 1, 10) AS d FROM stock_ledger_entry) l '
      'JOIN batch b ON b.id = l.batch_id JOIN item i ON i.id = l.item_id '
      'JOIN warehouse w ON w.id = l.warehouse_id '
      'WHERE $where GROUP BY l.item_id, l.batch_id, l.warehouse_id '
      'ORDER BY i.item_code, b.batch_id',
      [f.from ?? '0000-00-00', ...args],
      8,
    );
  }

  /// Date, Serial No, Voucher Type, Voucher #, Warehouse, In or Out (1 or
  /// -1), resulting Status; then voucher type and id.
  Future<ReportRows> serialLedgerReport(StockFilters f) {
    final args = <Object?>[];
    final where = [
      if (f.serialId != null) 's.id = ?',
      if (f.itemId != null) 's.item_id = ?',
    ];
    args
      ..addAll([?f.serialId])
      ..addAll([?f.itemId]);
    return _rows(
      'SELECT l.posting_datetime c0, s.serial_no c1, l.voucher_type c2, '
      'l.voucher_no c3, w.name c4, CASE WHEN l.actual_qty > 0 THEN 1 ELSE -1 END c5, '
      "CASE WHEN l.actual_qty > 0 THEN 'Available' WHEN EXISTS (SELECT 1 FROM "
      'stock_ledger_entry p WHERE p.voucher_type = l.voucher_type AND '
      'p.voucher_detail_id = l.voucher_detail_id AND p.actual_qty > 0 AND '
      "p.is_cancelled = 0) THEN 'Available' ELSE 'Delivered' END c6, "
      'l.voucher_type c7, l.voucher_id c8 '
      'FROM serial_and_batch_entry e JOIN serial_no s ON s.id = e.serial_no_id '
      'JOIN stock_ledger_entry l ON l.voucher_type = e.voucher_type AND '
      'l.voucher_detail_id = e.voucher_detail_id AND l.batch_id IS e.batch_id '
      'AND l.is_cancelled = 0 JOIN warehouse w ON w.id = l.warehouse_id '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
      'ORDER BY s.serial_no, l.posting_datetime, l.id',
      args,
      9,
    );
  }

  /// Item, Price List, Rate, UOM, Available Qty (all warehouses).
  Future<ReportRows> itemPriceStockReport(StockFilters f) => _rows(
    'SELECT i.item_code c0, p.name c1, ip.price_list_rate c2, '
    'COALESCE(u.name, su.name) c3, '
    '(SELECT COALESCE(SUM(actual_qty), 0) FROM bin WHERE item_id = i.id) c4 '
    'FROM item_price ip JOIN item i ON i.id = ip.item_id '
    'JOIN price_list p ON p.id = ip.price_list_id '
    'LEFT JOIN uom u ON u.id = ip.uom_id JOIN uom su ON su.id = i.stock_uom_id '
    'WHERE (?1 IS NULL OR i.id = ?1) AND (?2 IS NULL OR p.id = ?2) '
    'ORDER BY i.item_code, p.name',
    [f.itemId, f.priceListId],
    5,
  );

  static const _lowStock =
      'FROM item_reorder r JOIN item i ON i.id = r.item_id '
      'JOIN warehouse w ON w.id = r.warehouse_id '
      'LEFT JOIN bin b ON b.item_id = r.item_id AND b.warehouse_id = r.warehouse_id '
      'WHERE i.disabled = 0 AND COALESCE(b.actual_qty, 0) <= r.warehouse_reorder_level';

  /// STK-R12. Item, Item Name, Warehouse, Actual Qty, Re-order Level,
  /// Re-order Qty, Shortage.
  Future<ReportRows> lowStockReport(StockFilters f) => _rows(
    'SELECT i.item_code c0, i.item_name c1, w.name c2, '
    'COALESCE(b.actual_qty, 0) c3, r.warehouse_reorder_level c4, '
    'r.warehouse_reorder_qty c5, '
    'r.warehouse_reorder_level - COALESCE(b.actual_qty, 0) c6 $_lowStock'
    '${f.warehouseId == null ? '' : ' AND r.warehouse_id IN ${_subtree('warehouse', f.warehouseId!)}'}'
    '${f.itemGroupId == null ? '' : ' AND i.item_group_id IN ${_subtree('item_group', f.itemGroupId!)}'}'
    ' ORDER BY i.item_code',
    const [],
    7,
  );

  /// The number of low-stock rows, for the badges (STK-R12).
  Stream<int> watchLowStockCount() => customSelect(
    'SELECT COUNT(*) AS n $_lowStock',
    readsFrom: {itemReorder, item, bin},
  ).watchSingle().map((r) => r.read<int>('n'));
}

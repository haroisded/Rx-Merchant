import '../../../core/db/app_database.dart';
import '../../stock/data/stock_reports.dart' show ReportRows, subtreeIds;
import '../logic/periods.dart';
import 'dashboard_db.dart';

// The three sales reports behind the dashboard (04-sales-dashboard DSH-R7
// to R9). Rows hold one value per column, then hidden values for the
// screen.

/// Gross Profit's Group By.
enum ProfitBy { invoice, item, itemGroup, brand }

/// The filters of a sales report. An item group includes its subgroups.
class SalesFilters {
  SalesFilters({
    required this.span,
    this.itemId,
    this.itemGroupId,
    this.byGroup = false,
    this.qty = false,
    this.range = Range.monthly,
    this.groupBy = ProfitBy.item,
  });

  Span span;
  int? itemId;
  int? itemGroupId;

  /// Sales Analytics' Tree Type: Item Group rather than Item.
  bool byGroup;

  /// Quantity rather than value.
  bool qty;
  Range range;
  ProfitBy groupBy;
}

/// Sales Analytics: one value per bucket and a Total, per row.
typedef Analytics = ({List<Span> buckets, ReportRows rows});

/// Lines `i` of submitted invoices `s` in the filters' span, with item `it`
/// and any further [joins].
String _lines(SalesFilters f, [String joins = '']) =>
    'FROM sales_invoice_item i JOIN sales_invoice s ON s.id = i.sales_invoice_id '
    'JOIN item it ON it.id = i.item_id $joins WHERE $submittedIn'
    '${f.itemId == null ? '' : ' AND i.item_id = ${f.itemId}'}'
    '${f.itemGroupId == null ? '' : ' AND it.item_group_id IN ${subtreeIds('item_group', f.itemGroupId!)}'}';

extension SalesReports on AppDatabase {
  /// DSH-R7. Rows: name (indented by depth for groups), one value per
  /// bucket, Total; then the item or group id and the depth (0 for items).
  /// With Tree Type Item Group each parent holds the sum of its children.
  Future<Analytics> salesAnalytics(
    SalesFilters f,
    String firstDayOfWeek,
  ) async {
    final buckets = bucketsOf(f.span, f.range, firstDayOfWeek);
    final index = dayIndex(buckets);
    final values = <int, List<double>>{};
    for (final r in await customSelect(
      'SELECT ${f.byGroup ? 'it.item_group_id' : 'i.item_id'} AS k, '
      'substr(s.posting_datetime, 1, 10) AS d, '
      'SUM(${f.qty ? 'i.qty' : 'i.net_amount'}) AS v ${_lines(f)} GROUP BY k, d',
      variables: spanArgs(f.span),
    ).get()) {
      final i = index[r.read<String>('d')];
      if (i == null) continue;
      (values[r.read<int>('k')] ??= List.filled(buckets.length, 0.0))[i] += r
          .read<double>('v');
    }
    List<Object?> row(String name, List<double> v, int id, [int depth = 0]) => [
      name,
      ...v,
      v.fold<double>(0, (s, x) => s + x),
      id,
      depth,
    ];
    if (!f.byGroup) {
      final items = await (select(
        item,
      )..where((i) => i.id.isIn(values.keys))).get();
      items.sort((a, b) => a.itemCode.compareTo(b.itemCode));
      return (
        buckets: buckets,
        rows: [for (final i in items) row(i.itemCode, values[i.id]!, i.id)],
      );
    }
    final groups = await select(itemGroup).get()
      ..sort((a, b) => a.name.compareTo(b.name));
    final rows = <List<Object?>>[];
    // Depth-first, so each group sits above its children.
    List<double>? walk(ItemGroupData g, int depth) {
      final at = rows.length;
      var sum = values[g.id];
      for (final c in groups.where((c) => c.parentId == g.id)) {
        final child = walk(c, depth + 1);
        if (child == null) continue;
        sum = [
          for (var i = 0; i < buckets.length; i++) (sum?[i] ?? 0) + child[i],
        ];
      }
      if (sum != null) {
        rows.insert(at, row('${'   ' * depth}${g.name}', sum, g.id, depth));
      }
      return sum;
    }

    for (final root in groups.where((g) => g.parentId == null)) {
      walk(root, 0);
    }
    return (buckets: buckets, rows: rows);
  }

  /// DSH-R8. Date, Invoice, Item Code, Item Name, Item Group, Quantity, UOM,
  /// Rate, Net Amount, Tax, Total; then the invoice id. A line's tax comes
  /// from the invoice's item-wise tax detail; the invoice's rounding
  /// remainder sits on its last line, so the Tax column adds up to the
  /// invoices' taxes.
  Future<ReportRows> itemWiseSales(SalesFilters f) async {
    const lineTax =
        "SELECT COALESCE(SUM(json_extract(j.value, '\$[1]')), 0.0) "
        'FROM sales_invoice_tax t, json_each(t.item_wise_tax_detail) j '
        'WHERE t.sales_invoice_id = s.id';
    final rows = await customSelect(
      'SELECT s.posting_datetime AS c0, s.name AS c1, it.item_code AS c2, '
      'i.item_name AS c3, g.name AS c4, i.qty AS c5, u.name AS c6, '
      'i.rate AS c7, i.net_amount AS c8, ($lineTax AND j.key = CAST(i.id AS TEXT)) '
      '+ CASE WHEN i.idx = (SELECT MAX(idx) FROM sales_invoice_item '
      'WHERE sales_invoice_id = s.id) THEN s.total_taxes_and_charges - ($lineTax) '
      'ELSE 0.0 END AS c9, s.id AS c10 '
      '${_lines(f, 'JOIN item_group g ON g.id = it.item_group_id JOIN uom u ON u.id = i.uom_id')} '
      'ORDER BY s.posting_datetime, s.id, i.idx',
      variables: spanArgs(f.span),
    ).get();
    return [
      for (final r in rows)
        [
          for (var c = 0; c < 10; c++) r.data['c$c'],
          r.read<double>('c8') + r.read<double>('c9'),
          r.data['c10'],
        ],
    ];
  }

  /// DSH-R9. Name, Quantity, Selling Amount, Buying Amount, Gross Profit,
  /// Gross Profit %; by Item also Average Selling Rate and Valuation Rate;
  /// then whether a stock item sold in the row has no cost (a return
  /// keeps the cost of its sale; a price-only credit note has none, rightly).
  Future<ReportRows> grossProfit(SalesFilters f) async {
    final (key, name) = switch (f.groupBy) {
      ProfitBy.invoice => ('s.id', 's.name'),
      ProfitBy.item => ('i.item_id', 'it.item_code'),
      ProfitBy.itemGroup => ('it.item_group_id', 'g.name'),
      ProfitBy.brand => ('it.brand_id', 'b.name'),
    };
    final rows = await customSelect(
      'SELECT $name AS name, SUM(i.qty) AS qty, SUM(i.stock_qty) AS sq, '
      'SUM(i.net_amount) AS sell, SUM(i.stock_qty * i.incoming_rate) AS buy, '
      'MAX(it.is_stock_item = 1 AND i.incoming_rate = 0 AND s.is_return = 0) AS missing '
      '${_lines(f, 'LEFT JOIN item_group g ON g.id = it.item_group_id LEFT JOIN brand b ON b.id = it.brand_id')} '
      'GROUP BY $key ORDER BY $name',
      variables: spanArgs(f.span),
    ).get();
    return [
      for (final r in rows)
        () {
          final (qty, sell, buy) = (
            r.read<double>('qty'),
            r.read<double>('sell'),
            r.read<double>('buy'),
          );
          return <Object?>[
            r.data['name'],
            qty,
            sell,
            buy,
            sell - buy,
            sell == 0 ? 0.0 : (sell - buy) / sell * 100,
            if (f.groupBy == ProfitBy.item) ...[
              qty == 0 ? 0.0 : sell / qty,
              r.read<double>('sq') == 0 ? 0.0 : buy / r.read<double>('sq'),
            ],
            r.read<int>('missing') == 1,
          ];
        }(),
    ];
  }
}

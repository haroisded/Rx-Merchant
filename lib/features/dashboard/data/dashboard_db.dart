import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../pos/data/pos_closing_db.dart' show changeModeOf;
import '../logic/periods.dart';

// The Sales Dashboard's figures (04-sales-dashboard DSH-R1 to R6). Every
// figure is a query: no table of its own.

/// Submitted invoices `s` posted in the span bound to ?1 (first day) and ?2
/// (the day after the last), so the (docstatus, posting) index serves it.
/// Drafts and cancelled invoices never count; returns count as negatives
/// (DSH-R1, R2).
const submittedIn =
    's.docstatus = 1 AND s.posting_datetime >= ?1 AND s.posting_datetime < ?2';

/// The values for [submittedIn].
List<Variable> spanArgs(Span s) => [
  Variable(ymd(s.from)),
  Variable(ymd(s.to.add(const Duration(days: 1)))),
];

/// The DSH-R4 figures of one period.
typedef Figures = ({
  double netSales,
  double taxes,
  double totalSales,
  int invoices,
  int returns,
  double returned,
  double averageSale,
  double itemsSold,
  double cost,
  double grossProfit,
  double grossProfitPercent,
});

/// DSH-R5: Total Monthly Sales ÷ Monthly Sales Target × 100.
double achievement(double sales, double target) =>
    target == 0 ? 0 : sales / target * 100;

/// One bar of a chart; [id] is the item, group or mode it stands for (null
/// for "Other").
typedef Bar = ({int? id, String label, double value});

extension DashboardDb on AppDatabase {
  /// DSH-R4 for [span].
  Future<Figures> figures(Span span) async {
    final args = spanArgs(span);
    final s = await customSelect(
      'SELECT COALESCE(SUM(net_total), 0.0) AS net, '
      'COALESCE(SUM(total_taxes_and_charges), 0.0) AS taxes, '
      'COALESCE(SUM(grand_total), 0.0) AS grand, '
      'COUNT(CASE WHEN is_return = 0 THEN 1 END) AS invoices, '
      'COALESCE(SUM(CASE WHEN is_return = 0 THEN grand_total END), 0.0) AS sold, '
      'COUNT(CASE WHEN is_return = 1 THEN 1 END) AS returns, '
      'COALESCE(-SUM(CASE WHEN is_return = 1 THEN grand_total END), 0.0) AS returned '
      'FROM sales_invoice s WHERE $submittedIn',
      variables: args,
    ).getSingle();
    final lines = await customSelect(
      'SELECT COALESCE(SUM(i.qty), 0.0) AS qty, '
      'COALESCE(SUM(i.stock_qty * i.incoming_rate), 0.0) AS cost '
      'FROM sales_invoice_item i JOIN sales_invoice s '
      'ON s.id = i.sales_invoice_id WHERE $submittedIn',
      variables: args,
    ).getSingle();
    final net = s.read<double>('net');
    final cost = lines.read<double>('cost');
    final invoices = s.read<int>('invoices');
    return (
      netSales: net,
      taxes: s.read<double>('taxes'),
      totalSales: s.read<double>('grand'),
      invoices: invoices,
      returns: s.read<int>('returns'),
      returned: s.read<double>('returned'),
      averageSale: invoices == 0 ? 0.0 : s.read<double>('sold') / invoices,
      itemsSold: lines.read<double>('qty'),
      cost: cost,
      grossProfit: net - cost,
      grossProfitPercent: net == 0 ? 0.0 : (net - cost) / net * 100,
    );
  }

  /// DSH-R5: Σ Grand Total of the calendar month of [now], returns included.
  Future<double> monthlySales(DateTime now) async {
    final from = DateTime.utc(now.year, now.month);
    final to = DateTime.utc(now.year, now.month + 1, 0);
    return (await customSelect(
      'SELECT COALESCE(SUM(grand_total), 0.0) AS v FROM sales_invoice s '
      'WHERE $submittedIn',
      variables: spanArgs((from: from, to: to)),
    ).getSingle()).read<double>('v');
  }

  /// Σ `bin.stock_value`, as of now.
  Future<double> stockValue() async => (await customSelect(
    'SELECT COALESCE(SUM(stock_value), 0.0) AS v FROM bin',
  ).getSingle()).read<double>('v');

  /// Whether any sale was ever submitted.
  Future<bool> hasAnySale() async => (await customSelect(
    'SELECT EXISTS (SELECT 1 FROM sales_invoice WHERE docstatus = 1) AS x',
  ).getSingle()).read<bool>('x');

  /// Sales Trend (DSH-R6): Net Sales, or quantity, per bucket.
  Future<List<double>> trend(
    Span span,
    List<Span> buckets, {
    bool qty = false,
  }) async {
    final index = dayIndex(buckets);
    final out = List.filled(buckets.length, 0.0);
    for (final r in await customSelect(
      qty
          ? 'SELECT substr(s.posting_datetime, 1, 10) AS d, SUM(i.qty) AS v '
                'FROM sales_invoice_item i JOIN sales_invoice s '
                'ON s.id = i.sales_invoice_id WHERE $submittedIn GROUP BY d'
          : 'SELECT substr(s.posting_datetime, 1, 10) AS d, '
                'SUM(s.net_total) AS v FROM sales_invoice s '
                'WHERE $submittedIn GROUP BY d',
      variables: spanArgs(span),
    ).get()) {
      final i = index[r.read<String>('d')];
      if (i != null) out[i] += r.read<double>('v');
    }
    return out;
  }

  Future<List<Bar>> _bars(String sql, Span span) async => [
    for (final r in await customSelect(sql, variables: spanArgs(span)).get())
      (
        id: r.read<int>('id'),
        label: r.read<String>('label'),
        value: r.read<double>('v'),
      ),
  ];

  /// Net Sales per Item Group, largest first: the top 8, then "Other"
  /// (id null) when there are more (DSH-R6).
  Future<List<Bar>> salesByGroup(Span span) async {
    final all = await _bars(
      'SELECT g.id AS id, g.name AS label, SUM(i.net_amount) AS v '
      'FROM sales_invoice_item i JOIN sales_invoice s ON s.id = i.sales_invoice_id '
      'JOIN item it ON it.id = i.item_id JOIN item_group g ON g.id = it.item_group_id '
      'WHERE $submittedIn GROUP BY g.id ORDER BY v DESC',
      span,
    );
    if (all.length <= 8) return all;
    return [
      ...all.take(8),
      (
        id: null,
        label: '',
        value: all.skip(8).fold(0.0, (s, b) => s + b.value),
      ),
    ];
  }

  /// The top 10 items by Net Sales or by quantity (DSH-R6).
  Future<List<Bar>> topItems(Span span, {bool qty = false}) => _bars(
    'SELECT it.id AS id, it.item_name AS label, '
    'SUM(${qty ? 'i.qty' : 'i.net_amount'}) AS v '
    'FROM sales_invoice_item i JOIN sales_invoice s ON s.id = i.sales_invoice_id '
    'JOIN item it ON it.id = i.item_id WHERE $submittedIn '
    'GROUP BY it.id ORDER BY v DESC LIMIT 10',
    span,
  );

  /// Amount received per Mode of Payment: payments less refunds, change
  /// taken off the cash mode it was given from (DSH-R6, as POS-R20).
  Future<List<Bar>> paymentModes(Span span) => _bars(
    'SELECT m.id AS id, m.name AS label, SUM(x.amount) AS v FROM ('
    'SELECT p.mode_of_payment_id AS mode, p.amount AS amount '
    'FROM sales_invoice_payment p JOIN sales_invoice s ON s.id = p.sales_invoice_id '
    'WHERE $submittedIn UNION ALL '
    'SELECT $changeModeOf AS mode, -s.change_amount AS amount '
    'FROM sales_invoice s WHERE $submittedIn AND s.change_amount != 0'
    ') x JOIN mode_of_payment m ON m.id = x.mode GROUP BY m.id ORDER BY v DESC',
    span,
  );
}

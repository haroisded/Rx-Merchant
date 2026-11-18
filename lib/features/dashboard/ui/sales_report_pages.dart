import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../invoices/ui/invoice_providers.dart' show invoicePath;
import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/report_table.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../stock/data/stock_reports.dart' show ReportRows;
import '../../stock/ui/stock_providers.dart'
    show ItemRow, itemGroupsProvider, itemRowsProvider, searchItems;
import '../data/sales_reports.dart';
import '../logic/periods.dart';
import 'dashboard_charts.dart';
import 'dashboard_providers.dart';

// Sales Analytics, Item-wise Sales and Gross Profit (04-sales-dashboard
// DSH-R7 to R9, section 5, Reports).

enum SalesReport {
  salesAnalytics('sales-analytics'),
  itemWiseSales('item-wise-sales'),
  grossProfit('gross-profit');

  const SalesReport(this.slug);
  final String slug;

  String title(AppLocalizations l) => switch (this) {
    salesAnalytics => l.reportSalesAnalytics,
    itemWiseSales => l.reportItemWiseSales,
    grossProfit => l.grossProfit,
  };
}

/// The report at `/dashboard/[slug]`, filtered by [query]: `from`, `to`,
/// `item`, `group`, `qty=1`; null for an unknown slug.
Widget? salesReportPage(String slug, Map<String, String> query) =>
    switch (SalesReport.values.where((r) => r.slug == slug).firstOrNull) {
      final report? => SalesReportPage(
        key: ValueKey('$slug?$query'),
        report: report,
        query: query,
      ),
      null => null,
    };

enum _Col { text, money, qty, date, percent }

class SalesReportPage extends ConsumerStatefulWidget {
  const SalesReportPage({
    super.key,
    required this.report,
    this.query = const {},
  });

  final SalesReport report;
  final Map<String, String> query;

  @override
  ConsumerState<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends ConsumerState<SalesReportPage> {
  late final SalesFilters _f = () {
    final q = widget.query;
    final today = dayOf(DateTime.now());
    final span = (
      from: q['from'] == null
          ? DateTime.utc(today.year, today.month)
          : parseDay(q['from']!),
      to: q['to'] == null ? today : parseDay(q['to']!),
    );
    return SalesFilters(
      span: span,
      itemId: int.tryParse(q['item'] ?? ''),
      itemGroupId: int.tryParse(q['group'] ?? ''),
      qty: q['qty'] == '1',
      range: trendRange(span),
    );
  }();
  late Future<Analytics> _data = _load();

  /// Sales Analytics rows drawn in the chart, by name.
  Set<String>? _selected;

  Future<Analytics> _load() async {
    final db = ref.read(appDatabaseProvider);
    return switch (widget.report) {
      SalesReport.salesAnalytics => await db.salesAnalytics(
        _f,
        ref.read(firstDayOfWeekProvider),
      ),
      SalesReport.itemWiseSales => (
        buckets: const <Span>[],
        rows: await db.itemWiseSales(_f),
      ),
      SalesReport.grossProfit => (
        buckets: const <Span>[],
        rows: await db.grossProfit(_f),
      ),
    };
  }

  void _changed() => setState(() {
    _selected = null;
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final report = widget.report;
    return Scaffold(
      appBar: AppBar(title: Text(report.title(l))),
      body: FutureBuilder(
        future: _data,
        builder: (context, snap) {
          final data = snap.data;
          // The first five rows are drawn until the owner picks others.
          // Not from the previous rows while new ones load.
          if (snap.connectionState == ConnectionState.done &&
              data != null &&
              report == SalesReport.salesAnalytics) {
            _selected ??= {
              for (final r in data.rows.take(5)) r.first as String,
            };
          }
          final table = _table(context, l, formats, data);
          if (report != SalesReport.salesAnalytics || data == null) {
            return table;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _chart(context, l, formats, data),
              Expanded(child: table),
            ],
          );
        },
      ),
    );
  }

  /// The columns and their kinds.
  List<(String, _Col)> _columns(
    AppLocalizations l,
    Formats formats,
    Analytics? data,
  ) {
    final value = _f.qty ? _Col.qty : _Col.money;
    return switch (widget.report) {
      SalesReport.salesAnalytics => [
        (_f.byGroup ? l.itemGroup : l.item, _Col.text),
        for (final b in data?.buckets ?? const <Span>[])
          (bucketLabel(b.from, _f.range, formats, l), value),
        (l.total, value),
      ],
      SalesReport.itemWiseSales => [
        (l.date, _Col.date),
        (l.invoice, _Col.text),
        (l.itemCode, _Col.text),
        (l.itemName, _Col.text),
        (l.itemGroup, _Col.text),
        (l.quantity, _Col.qty),
        (l.uom, _Col.text),
        (l.rate, _Col.money),
        (l.netAmount, _Col.money),
        (l.tax, _Col.money),
        (l.total, _Col.money),
      ],
      SalesReport.grossProfit => [
        (_groupByText(l, _f.groupBy), _Col.text),
        (l.quantity, _Col.qty),
        (l.sellingAmount, _Col.money),
        (l.buyingAmount, _Col.money),
        (l.grossProfit, _Col.money),
        (l.grossProfitPercent, _Col.percent),
        if (_f.groupBy == ProfitBy.item) ...[
          (l.averageSellingRate, _Col.money),
          (l.valuationRate, _Col.money),
        ],
        (l.check, _Col.text),
      ],
    };
  }

  Widget _table(
    BuildContext context,
    AppLocalizations l,
    Formats formats,
    Analytics? data,
  ) {
    final report = widget.report;
    var columns = _columns(l, formats, data);
    var rows = data?.rows ?? const <List<Object?>>[];
    if (report == SalesReport.grossProfit) {
      // The flag as text, so the export reads the same; a row without a
      // brand is "Not Set".
      rows = [
        for (final r in rows)
          [
            r.first ?? l.notSet,
            ...r.skip(1).take(r.length - 2),
            r.last == true ? l.costMissing : '',
          ],
      ];
    }
    // Rounded as shown, so the export holds the same figures (DSH-R11).
    double round(_Col kind, double v) => switch (kind) {
      _Col.money => flt(v, formats.system.currencyPrecision, formats.rounding),
      _Col.percent => flt(v, 1, formats.rounding),
      _ => flt(v, formats.system.floatPrecision, formats.rounding),
    };
    rows = [
      for (final r in rows)
        [
          for (final (c, v) in r.indexed)
            c < columns.length && v is double ? round(columns[c].$2, v) : v,
        ],
    ];
    var totals = _totals(l, rows, columns.length);
    // On a phone, Sales Analytics shows the Total first.
    if (report == SalesReport.salesAnalytics &&
        WindowSize.of(context) == WindowSize.compact) {
      final n = columns.length;
      List<T> totalFirst<T>(List<T> r) => [
        r[0],
        r[n - 1],
        ...r.sublist(1, n - 1),
        ...r.sublist(n),
      ];
      columns = totalFirst(columns);
      rows = [for (final r in rows) totalFirst(r)];
      if (totals != null) totals = totalFirst(totals);
    }
    final selected = _selected ?? {};
    return ReportTable(
      columns: [for (final (c, _) in columns) c],
      rows: rows,
      exportName: report.slug,
      exportPreamble: _preamble(l),
      emptyText: data == null ? null : l.noEntries,
      filters: ReportFilters(
        fields: (changed) => _FilterBar(
          report: report,
          value: _f,
          onChanged: () {
            _changed();
            changed();
          },
        ),
      ),
      totals: totals,
      cell: (c, v) {
        final text = _format(formats, columns[c].$2, v);
        return c == 0 && selected.contains(v) ? '● $text' : text;
      },
      onRowTap: switch (report) {
        SalesReport.salesAnalytics => (row) => setState(() {
          final name = row.first as String;
          _selected = {...selected};
          if (!_selected!.remove(name)) _selected!.add(name);
        }),
        // DSH-R10: a line opens its invoice (the id rides after the columns).
        SalesReport.itemWiseSales => (row) => context.go(
          invoicePath(row.last! as int),
        ),
        SalesReport.grossProfit => null,
      },
    );
  }

  /// The totals row; Sales Analytics by group adds up its top rows only,
  /// as the others are inside them.
  List<Object?>? _totals(AppLocalizations l, ReportRows rows, int width) {
    if (rows.isEmpty) return null;
    final (sum, top) = switch (widget.report) {
      SalesReport.salesAnalytics => (
        {for (var c = 1; c < width; c++) c},
        rows.where((r) => r.last == 0),
      ),
      SalesReport.itemWiseSales => ({5, 8, 9, 10}, rows),
      SalesReport.grossProfit => ({1, 2, 3, 4}, rows),
    };
    final out = <Object?>[
      for (var c = 0; c < width; c++)
        c == 0
            ? l.total
            : sum.contains(c)
            ? top.fold<double>(0, (s, r) => s + (r[c] as num).toDouble())
            : null,
    ];
    if (widget.report == SalesReport.grossProfit) {
      final sell = out[2] as double;
      out[5] = sell == 0 ? 0.0 : (out[4] as double) / sell * 100;
    }
    return out;
  }

  /// The filters, written above the export's header (DSH-R11).
  List<List<Object?>> _preamble(AppLocalizations l) => [
    [l.fromDate, ymd(_f.span.from)],
    [l.toDate, ymd(_f.span.to)],
    if (widget.report == SalesReport.salesAnalytics) ...[
      [l.treeType, _f.byGroup ? l.itemGroup : l.item],
      [l.valueOrQty, _f.qty ? l.quantity : l.value],
      [l.rangeLabel, _rangeText(l, _f.range)],
    ],
    if (_f.itemId case final id?)
      [
        l.item,
        ref
            .watch(itemRowsProvider)
            .value
            ?.where((i) => i.id == id)
            .firstOrNull
            ?.code,
      ],
    if (_f.itemGroupId case final id?)
      [
        l.itemGroup,
        ref
            .watch(itemGroupsProvider)
            .value
            ?.where((g) => g.id == id)
            .firstOrNull
            ?.name,
      ],
    if (widget.report == SalesReport.grossProfit)
      [l.groupBy, _groupByText(l, _f.groupBy)],
  ];

  Widget _chart(
    BuildContext context,
    AppLocalizations l,
    Formats formats,
    Analytics data,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
    ];
    final picked = _selected ?? const {};
    final rows = [
      for (final r in data.rows)
        if (picked.contains(r.first)) r,
    ];
    final n = data.buckets.length;
    final compact = WindowSize.of(context) == WindowSize.compact;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 140 : 200,
            child: rows.isEmpty
                ? Center(child: Text(l.noEntries))
                : LinesChart(
                    labels: [
                      for (final b in data.buckets)
                        bucketLabel(b.from, _f.range, formats, l),
                    ],
                    series: [
                      for (final (i, r) in rows.indexed)
                        (
                          [for (var c = 1; c <= n; c++) r[c] as double],
                          colors[i % colors.length],
                        ),
                    ],
                    format: (v) =>
                        _f.qty ? formats.number(v) : formats.money(v),
                  ),
          ),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              for (final (i, r) in rows.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: colors[i % colors.length],
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text((r.first as String).trim()),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _rangeText(AppLocalizations l, Range r) => switch (r) {
  Range.daily => l.rangeDaily,
  Range.weekly => l.rangeWeekly,
  Range.monthly => l.rangeMonthly,
  Range.quarterly => l.rangeQuarterly,
  Range.yearly => l.rangeYearly,
};

String _groupByText(AppLocalizations l, ProfitBy g) => switch (g) {
  ProfitBy.invoice => l.invoice,
  ProfitBy.item => l.item,
  ProfitBy.itemGroup => l.itemGroup,
  ProfitBy.brand => l.brand,
};

String _format(Formats f, _Col kind, Object? v) {
  if (v is! num) {
    if (kind == _Col.date && v is String && DateTime.tryParse(v) != null) {
      return f.date(DateTime.parse(v));
    }
    return v?.toString() ?? '';
  }
  return switch (kind) {
    _Col.money => f.money(v),
    _Col.qty => f.number(v),
    _Col.percent => percent(f, v.toDouble()),
    _Col.text || _Col.date => '$v',
  };
}

/// The filter fields of one report.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.report,
    required this.value,
    required this.onChanged,
  });

  final SalesReport report;
  final SalesFilters value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final f = value;
    Widget box(Widget child) => SizedBox(width: 200, child: child);
    void set(void Function() change) {
      change();
      onChanged();
    }

    DropdownMenu<T> menu<T>(
      String label,
      T current,
      List<(T, String)> options,
      void Function(T) choose,
    ) => DropdownMenu<T>(
      label: Text(label),
      initialSelection: current,
      expandedInsets: EdgeInsets.zero,
      onSelected: (v) => set(() => choose(v as T)),
      dropdownMenuEntries: [
        for (final (v, name) in options)
          DropdownMenuEntry(value: v, label: name),
      ],
    );

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        box(
          DateField(
            label: l.fromDate,
            value: ymd(f.span.from),
            formats: formats,
            mandatory: true,
            onChanged: (v) {
              if (v != null) {
                set(() => f.span = (from: parseDay(v), to: f.span.to));
              }
            },
          ),
        ),
        box(
          DateField(
            label: l.toDate,
            value: ymd(f.span.to),
            formats: formats,
            mandatory: true,
            onChanged: (v) {
              if (v != null) {
                set(() => f.span = (from: f.span.from, to: parseDay(v)));
              }
            },
          ),
        ),
        if (report == SalesReport.salesAnalytics) ...[
          box(
            menu(l.treeType, f.byGroup, [
              (false, l.item),
              (true, l.itemGroup),
            ], (v) => f.byGroup = v),
          ),
          box(
            menu(l.valueOrQty, f.qty, [
              (false, l.value),
              (true, l.quantity),
            ], (v) => f.qty = v),
          ),
          box(
            menu(l.rangeLabel, f.range, [
              for (final r in Range.values) (r, _rangeText(l, r)),
            ], (v) => f.range = v),
          ),
        ],
        if (report == SalesReport.itemWiseSales) ...[
          box(
            LinkField<ItemRow>(
              label: l.item,
              value: (ref.watch(itemRowsProvider).value ?? [])
                  .where((i) => i.id == f.itemId)
                  .firstOrNull,
              search: (q) =>
                  searchItems(ref.read(itemRowsProvider).value ?? [], q),
              labelOf: (r) => r.code,
              onChanged: (r) => set(() => f.itemId = r?.id),
            ),
          ),
          box(
            menu<int?>(l.itemGroup, f.itemGroupId, [
              (null, l.all),
              for (final ItemGroupData g
                  in ref.watch(itemGroupsProvider).value ?? [])
                (g.id, g.name),
            ], (v) => f.itemGroupId = v),
          ),
        ],
        if (report == SalesReport.grossProfit)
          box(
            menu(l.groupBy, f.groupBy, [
              for (final g in ProfitBy.values) (g, _groupByText(l, g)),
            ], (v) => f.groupBy = v),
          ),
      ],
    );
  }
}

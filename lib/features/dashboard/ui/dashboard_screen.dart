import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../invoices/data/invoice_db.dart' show InvoiceFilters;
import '../../invoices/ui/invoice_providers.dart' show invoicesLink;
import '../../pos/ui/pos_providers.dart' show posPath;
import '../../setup/ui/setup_screen.dart' show setupPath;
import '../../stock/ui/report_pages.dart' show StockReport;
import '../../stock/ui/stock_providers.dart' show lowStockCountProvider;
import '../../stock/ui/stock_screen.dart' show stockPath;
import '../data/dashboard_db.dart';
import '../logic/periods.dart';
import 'dashboard_charts.dart';
import 'dashboard_providers.dart';
import 'sales_report_pages.dart';

// The Dashboard destination (04-sales-dashboard section 5).

/// The invoice list with [statuses] posted in [span] (DSH-R10).
String invoicesIn(Span span, Set<String> statuses) => invoicesLink(
  InvoiceFilters(statuses: statuses, from: ymd(span.from), to: ymd(span.to)),
);

/// The link to [report] for [span], with [extra] query parameters.
String reportLink(SalesReport report, Span span, [String extra = '']) =>
    '$dashboardPath/${report.slug}?from=${ymd(span.from)}&to=${ymd(span.to)}$extra';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dashboard = ref.watch(dashboardProvider);
    final d = dashboard.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navDashboard),
        automaticallyImplyLeading: false,
      ),
      body: switch (d) {
        null when dashboard.hasError => Center(
          child: Text(
            '${l.dashboardLoadError}\n${dashboard.error}',
            textAlign: TextAlign.center,
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        _ when !d.anySale => const _FirstSale(),
        _ => _Body(d: d),
      },
    );
  }
}

/// No sale yet: one card pointing to the Cash Register.
class _FirstSale extends StatelessWidget {
  const _FirstSale();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.firstSaleHint, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(posPath),
                child: Text(l.openCashRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.d});

  final Dashboard d;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  // The Value / Quantity switches of the trend and Top Items.
  var _trendQty = false;
  var _itemsQty = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final scheme = Theme.of(context).colorScheme;
    final size = WindowSize.of(context);
    final d = widget.d;
    final span = d.span;
    final x = d.now;
    final low = ref.watch(lowStockCountProvider).value ?? 0;
    final target = StoreProfile(
      ref.watch(singleProvider(StoreProfile.doctype)).value ?? const {},
    ).monthlySalesTarget;
    void go(String link) => context.go(link);
    String money(double v) => formats.money(v);
    String number(double v) => formats.number(v);

    final cards = [
      _NumberCard(
        label: l.netSales,
        value: money(x.netSales),
        now: x.netSales,
        before: d.before.netSales,
        onTap: () => go(reportLink(SalesReport.salesAnalytics, span)),
      ),
      // Invoices, Average Sale and Returns open the invoice list for the
      // period (DSH-R10).
      _NumberCard(
        label: l.navInvoices,
        value: '${x.invoices}',
        now: x.invoices.toDouble(),
        before: d.before.invoices.toDouble(),
        onTap: () => go(invoicesIn(span, const {'Paid', 'Credit Note Issued'})),
      ),
      _NumberCard(
        label: l.averageSale,
        value: money(x.averageSale),
        now: x.averageSale,
        before: d.before.averageSale,
        onTap: () => go(invoicesIn(span, const {'Paid', 'Credit Note Issued'})),
      ),
      _NumberCard(
        label: l.itemsSold,
        value: number(x.itemsSold),
        now: x.itemsSold,
        before: d.before.itemsSold,
        onTap: () => go(reportLink(SalesReport.salesAnalytics, span, '&qty=1')),
      ),
      _NumberCard(
        label: l.grossProfit,
        value: money(x.grossProfit),
        detail: percent(formats, x.grossProfitPercent),
        now: x.grossProfit,
        before: d.before.grossProfit,
        onTap: () => go(reportLink(SalesReport.grossProfit, span)),
      ),
      _NumberCard(
        label: l.taxes,
        value: money(x.taxes),
        now: x.taxes,
        before: d.before.taxes,
        onTap: () => go(reportLink(SalesReport.itemWiseSales, span)),
      ),
      _NumberCard(
        label: l.returns,
        value: '${x.returns}',
        detail: money(x.returned),
        now: x.returns.toDouble(),
        before: d.before.returns.toDouble(),
        onTap: () => go(invoicesIn(span, const {'Return'})),
      ),
      _NumberCard(
        label: l.stockValue,
        value: money(d.stockValue),
        onTap: () => go('$stockPath/${StockReport.stockBalance.slug}'),
        extra: low == 0
            ? null
            : TextButton.icon(
                onPressed: () => go('$stockPath/${StockReport.lowStock.slug}'),
                icon: Badge.count(
                  count: low,
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                label: Text(l.reportLowStock),
              ),
      ),
    ];

    final labels = [
      for (final b in d.buckets)
        bucketLabel(b.from, trendRange(span), formats, l),
    ];
    final trend = _trendQty ? d.trendQty : d.trendValue;
    final items = _itemsQty ? d.itemsByQty : d.itemsByValue;
    Widget valueOrQty(bool qty, ValueChanged<bool> set) =>
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l.value)),
            ButtonSegment(value: true, label: Text(l.quantity)),
          ],
          selected: {qty},
          onSelectionChanged: (s) => setState(() => set(s.single)),
        );
    List<(String, String)> rowsOf(List<Bar> bars, String Function(double) f) =>
        [for (final b in bars) (b.id == null ? l.other : b.label, f(b.value))];

    final trendChart = ChartCard(
      title: l.salesTrend,
      empty: trend.every((v) => v == 0),
      rows: [
        for (final (i, v) in trend.indexed)
          (labels[i], _trendQty ? number(v) : money(v)),
      ],
      action: valueOrQty(_trendQty, (q) => _trendQty = q),
      chart: LinesChart(
        labels: labels,
        series: [(trend, scheme.primary)],
        format: _trendQty ? number : money,
      ),
    );
    // A bar, or its row in the table, opens Item-wise Sales (DSH-R10).
    void groupSales(Bar b) => b.id == null
        ? null
        : go(reportLink(SalesReport.itemWiseSales, span, '&group=${b.id}'));
    void itemSales(Bar b) =>
        go(reportLink(SalesReport.itemWiseSales, span, '&item=${b.id}'));
    final charts = [
      ChartCard(
        title: l.salesByItemGroup,
        empty: d.groups.isEmpty,
        rows: rowsOf(d.groups, money),
        onRowTap: (i) => groupSales(d.groups[i]),
        chart: BarsChart(
          bars: d.groups,
          color: scheme.secondary,
          format: money,
          onTap: groupSales,
        ),
      ),
      ChartCard(
        title: l.topItems,
        empty: items.isEmpty,
        rows: rowsOf(items, _itemsQty ? number : money),
        onRowTap: (i) => itemSales(items[i]),
        action: valueOrQty(_itemsQty, (q) => _itemsQty = q),
        chart: BarsChart(
          bars: items,
          color: scheme.tertiary,
          format: _itemsQty ? number : money,
          onTap: itemSales,
        ),
      ),
      ChartCard(
        title: l.paymentModes,
        empty: d.modes.isEmpty,
        rows: rowsOf(d.modes, money),
        chart: BarsChart(bars: d.modes, color: scheme.primary, format: money),
      ),
    ];
    final goal = target == 0
        ? Align(
            alignment: AlignmentDirectional.topStart,
            child: TextButton.icon(
              onPressed: () => go('$setupPath/store-profile'),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l.setSalesTarget),
            ),
          )
        : _GoalCard(target: target, sales: d.monthlySales);

    final reports = Card(
      child: Column(
        children: [
          for (final r in SalesReport.values)
            ListTile(
              title: Text(r.title(l)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(reportLink(r, span)),
            ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        const _PeriodBar(),
        const SizedBox(height: AppSpacing.sm),
        ..._grid(cards, size == WindowSize.compact ? 2 : 4),
        ...switch (size) {
          WindowSize.compact => [goal, trendChart, ...charts],
          WindowSize.medium => [
            goal,
            ..._grid([trendChart, ...charts], 2),
          ],
          WindowSize.expanded => [
            ..._grid([goal, trendChart], 2),
            ..._grid(charts, 3),
          ],
        },
        reports,
      ],
    );
  }
}

/// [children] in rows of [columns], each row as tall as its tallest.
List<Widget> _grid(List<Widget> children, int columns) => [
  for (var i = 0; i < children.length; i += columns)
    IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = i; j < i + columns; j++)
            Expanded(
              child: j < children.length
                  ? children[j]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    ),
];

/// Today, Yesterday, This Week, This Month, This Year and Custom (DSH-R3);
/// scrolls sideways when it does not fit.
class _PeriodBar extends ConsumerWidget {
  const _PeriodBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final choice = ref.watch(periodProvider);
    final notifier = ref.read(periodProvider.notifier);
    final custom = choice.custom;
    String label(Period p) => switch (p) {
      Period.today => l.periodToday,
      Period.yesterday => l.periodYesterday,
      Period.thisWeek => l.periodThisWeek,
      Period.thisMonth => l.periodThisMonth,
      Period.thisYear => l.periodThisYear,
      Period.custom when custom != null =>
        '${formats.date(custom.from)} – ${formats.date(custom.to)}',
      Period.custom => l.periodCustom,
    };
    Future<void> pickRange() async {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: custom == null
            ? null
            : DateTimeRange(
                start: DateTime(
                  custom.from.year,
                  custom.from.month,
                  custom.from.day,
                ),
                end: DateTime(custom.to.year, custom.to.month, custom.to.day),
              ),
      );
      if (range != null) {
        notifier.choose(Period.custom, (
          from: dayOf(range.start),
          to: dayOf(range.end),
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in Period.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilterChip(
                label: Text(label(p)),
                selected: choice.period == p,
                onSelected: (_) =>
                    p == Period.custom ? pickRange() : notifier.choose(p),
              ),
            ),
        ],
      ),
    );
  }
}

/// A figure with its change against the previous period (DSH-R3): the
/// primary colour when up, the error colour when down.
class _NumberCard extends ConsumerWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    this.detail,
    this.now,
    this.before,
    this.onTap,
    this.extra,
  });

  final String label;
  final String value;
  final String? detail;

  /// The figure now and in the previous period; no change line without
  /// both.
  final double? now;
  final double? before;
  final VoidCallback? onTap;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formats = ref.watch(formatsProvider);
    final (now, before) = (this.now, this.before);
    final change = now == null || before == null || before == 0
        ? null
        : (now - before) / before.abs() * 100;
    final color = switch (change) {
      null || 0 => theme.colorScheme.onSurfaceVariant,
      > 0 => theme.colorScheme.primary,
      _ => theme.colorScheme.error,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: theme.textTheme.titleLarge),
              if (detail != null)
                Text(detail!, style: theme.textTheme.bodyMedium),
              if (change != null)
                Row(
                  children: [
                    Icon(
                      change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: color,
                    ),
                    Text(
                      percent(formats, change.abs()),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
              ?extra,
            ],
          ),
        ),
      ),
    );
  }
}

/// DSH-R5: always the current month, whatever period is chosen.
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.target, required this.sales});

  final double target;
  final double sales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formats = ref.watch(formatsProvider);
    final done = achievement(sales, target);
    Widget line(String label, String value) => Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.sectionSalesGoal, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            line(l.monthlySalesTarget, formats.money(target)),
            line(l.totalMonthlySales, formats.money(sales)),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(value: (done / 100).clamp(0, 1)),
            const SizedBox(height: AppSpacing.sm),
            line(l.achievement, percent(formats, done)),
          ],
        ),
      ),
    );
  }
}

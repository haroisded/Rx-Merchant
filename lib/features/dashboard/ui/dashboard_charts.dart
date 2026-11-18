import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/dashboard_db.dart';
import '../logic/periods.dart';

// The dashboard's charts (04-sales-dashboard DSH-R6, section 5). fl_chart is
// the one non-Material visual; every colour comes from the ColorScheme.

const double chartHeight = 240;

/// The text under a bucket of [range] starting at [from].
String bucketLabel(
  DateTime from,
  Range range,
  Formats formats,
  AppLocalizations l,
) => switch (range) {
  Range.daily || Range.weekly => formats.date(from),
  // Month names stay English, as dates do (D-7).
  Range.monthly => DateFormat.yMMM('en_US').format(from),
  Range.quarterly => l.quarterOf((from.month - 1) ~/ 3 + 1, from.year),
  Range.yearly => '${from.year}',
};

/// A percentage with one decimal (DSH-R11).
String percent(Formats formats, double v) => '${formats.number(v, 1)}%';

/// A chart in a card. Tapping its title opens the same data as a table,
/// the chart's text alternative; [onRowTap] makes its rows open what the
/// bars open, with a full-size touch target.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.rows,
    required this.chart,
    this.empty = false,
    this.action,
    this.onRowTap,
  });

  final String title;

  /// The data as label and shown value.
  final List<(String, String)> rows;
  final Widget chart;

  /// Shows "No sales in this period" instead of [chart].
  final bool empty;
  final Widget? action;
  final ValueChanged<int>? onRowTap;

  void _table(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (i, (label, value)) in rows.indexed)
              ListTile(
                title: Text(label),
                trailing: Text(value),
                onTap: onRowTap == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        onRowTap!(i);
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _table(context),
                    icon: const Icon(Icons.table_rows_outlined),
                    label: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              ?action,
            ],
          ),
          SizedBox(
            height: chartHeight,
            child: empty
                ? Center(
                    child: Text(AppLocalizations.of(context).noSalesInPeriod),
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: chart,
                  ),
          ),
        ],
      ),
    ),
  );
}

TextStyle? _small(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall;

/// A value-axis label in the Number Format. fl_chart also labels the axis
/// ends, which crowd the regular steps; only the steps are shown.
Widget _axisLabel(
  BuildContext context,
  Formats formats,
  double v,
  TitleMeta meta,
) {
  final step = meta.appliedInterval;
  if (step > 0 && (v / step - (v / step).round()).abs() > 1e-6) {
    return const SizedBox.shrink();
  }
  return SideTitleWidget(
    meta: meta,
    child: Text(
      formats.number(v, v == v.roundToDouble() ? 0 : 1),
      style: _small(context),
    ),
  );
}

/// One line per series over the same [labels] (Sales Trend, Sales
/// Analytics).
class LinesChart extends ConsumerWidget {
  const LinesChart({
    super.key,
    required this.labels,
    required this.series,
    required this.format,
  });

  final List<String> labels;
  final List<(List<double>, Color)> series;
  final String Function(double) format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final formats = ref.watch(formatsProvider);
    final n = labels.length;
    // About four labels along the bottom.
    final step = math.max(1, (n / 4).ceil());
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, n - 1).toDouble(),
        // From zero, or below it when returns outweigh sales.
        minY: [for (final (v, _) in series) ...v].fold<double>(0, math.min),
        lineBarsData: [
          for (final (values, color) in series)
            LineChartBarData(
              spots: [
                for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v),
              ],
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: n <= 31),
              belowBarData: BarAreaData(
                show: series.length == 1,
                color: color.withValues(alpha: 0.12),
              ),
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, meta) =>
                  _axisLabel(context, formats, v, meta),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: step.toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                // fl_chart also asks for the last point; it would overlap.
                if (v != i || i < 0 || i >= n || i % step != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(labels[i], style: _small(context)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${labels[s.x.toInt()]}: ${format(s.y)}',
                  TextStyle(color: scheme.onInverseSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal bars, largest at the top; [onTap] gets the bar tapped.
class BarsChart extends ConsumerWidget {
  const BarsChart({
    super.key,
    required this.bars,
    required this.color,
    required this.format,
    this.onTap,
  });

  final List<Bar> bars;
  final Color color;
  final String Function(double) format;
  final ValueChanged<Bar>? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final formats = ref.watch(formatsProvider);
    final other = AppLocalizations.of(context).other;
    return BarChart(
      BarChartData(
        rotationQuarterTurns: 1,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (final (i, b) in bars.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: b.value,
                  color: color,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) =>
                  _axisLabel(context, formats, v, meta),
            ),
          ),
          // The bars' names, on the left once the chart is turned.
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 104,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: SizedBox(
                  width: 96,
                  child: Text(
                    bars[v.toInt()].id == null ? other : bars[v.toInt()].label,
                    style: _small(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          // 14 + 2 × 17: a 48dp touch target (R1 §7.2).
          touchExtraThreshold: const EdgeInsets.all(17),
          touchCallback: (event, response) {
            final spot = response?.spot;
            if (event is FlTapUpEvent && spot != null) {
              onTap?.call(bars[spot.touchedBarGroupIndex]);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (_, _, rod, _) => BarTooltipItem(
              format(rod.toY),
              TextStyle(color: scheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}

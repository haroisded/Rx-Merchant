import 'dart:io';

import 'package:csv/csv.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import 'child_table.dart';
import 'spacing.dart';
import 'window_size.dart';

/// The CSV text of a report: the [preamble] lines (such as the filters),
/// a header line, then one line per row.
String toCsv(
  List<String> columns,
  List<List<Object?>> rows, [
  List<List<Object?>> preamble = const [],
]) => csv.encode([...preamble, columns, ...rows]);

const double _rowHeight = 48;
const double _firstWidth = 160;
const double _width = 128;

/// A report (00-overview, section 7.1): a filter bar, a table, a totals row
/// and a CSV export action.
///
/// Each row holds one value per column; values beyond the last column are
/// carried for [onRowTap] and are neither shown nor exported. Rows are built
/// as they scroll into view, so thousands stay smooth. The first column stays
/// put while the others scroll sideways. Columns whose values are all
/// numbers are right-aligned. [cell] gives the text shown for a value (the
/// export keeps the raw value). Needs a bounded height, e.g. the body of a
/// Scaffold.
class ReportTable extends StatefulWidget {
  const ReportTable({
    super.key,
    required this.columns,
    required this.rows,
    this.filters,
    required this.exportName,
    this.totals,
    this.cell,
    this.onRowTap,
    this.emptyText,
    this.exportPreamble = const [],
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final Widget? filters;

  /// File name of the export, without `.csv`.
  final String exportName;

  /// One value per column (null where nothing is totalled).
  final List<Object?>? totals;
  final String Function(int column, Object? value)? cell;
  final ValueChanged<List<Object?>>? onRowTap;
  final String? emptyText;

  /// Lines written above the header of the export, such as the filters.
  final List<List<Object?>> exportPreamble;

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  final _pinned = ScrollController();
  final _body = ScrollController();
  var _syncing = false;

  @override
  void initState() {
    super.initState();
    // The pinned column and the body scroll up and down together.
    void follow(ScrollController from, ScrollController to) =>
        from.addListener(() {
          if (_syncing || !to.hasClients) return;
          _syncing = true;
          to.jumpTo(from.offset);
          _syncing = false;
        });
    follow(_pinned, _body);
    follow(_body, _pinned);
  }

  @override
  void dispose() {
    _pinned.dispose();
    _body.dispose();
    super.dispose();
  }

  List<Object?> _shown(List<Object?> row) =>
      row.take(widget.columns.length).toList();

  // Writes the CSV to the cache folder and hands it to Android's share sheet.
  Future<void> _export() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${widget.exportName}.csv');
    await file.writeAsString(
      toCsv(widget.columns, [
        for (final r in widget.rows) _shown(r),
      ], widget.exportPreamble),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
    );
  }

  bool _isNumeric(int column) =>
      widget.rows.any((row) => row[column] is num) &&
      widget.rows.every((row) => row[column] == null || row[column] is num);

  String _text(int column, Object? value) =>
      widget.cell?.call(column, value) ?? value?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = widget.columns;
    final numeric = [for (var i = 0; i < columns.length; i++) _isNumeric(i)];
    final restWidth = _width * (columns.length - 1);
    final header = theme.textTheme.titleSmall;
    final divider = BorderSide(color: theme.colorScheme.outlineVariant);

    Widget cellBox(int column, String text, {TextStyle? style}) => Container(
      width: column == 0 ? _firstWidth : _width,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: numeric[column]
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(border: Border(bottom: divider)),
      child: Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    Widget line(List<Object?> row, {required bool first, TextStyle? style}) =>
        Row(
          children: [
            for (var c = first ? 0 : 1; c < (first ? 1 : columns.length); c++)
              cellBox(c, _text(c, row[c]), style: style),
          ],
        );

    Widget rows({required bool first}) => ListView.builder(
      controller: first ? _pinned : _body,
      itemExtent: _rowHeight,
      itemCount: widget.rows.length,
      itemBuilder: (context, i) => InkWell(
        onTap: widget.onRowTap == null
            ? null
            : () => widget.onRowTap!(widget.rows[i]),
        child: line(widget.rows[i], first: first),
      ),
    );

    Widget part({required bool first}) => Column(
      children: [
        Row(
          children: [
            for (var c = first ? 0 : 1; c < (first ? 1 : columns.length); c++)
              cellBox(c, columns[c], style: header),
          ],
        ),
        Expanded(child: rows(first: first)),
        if (widget.totals case final totals?)
          line(totals, first: first, style: header),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: widget.filters ?? const SizedBox.shrink()),
              IconButton(
                tooltip: AppLocalizations.of(context).exportCsv,
                icon: const Icon(Icons.download),
                onPressed: _export,
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.rows.isEmpty && widget.emptyText != null
              ? Center(child: Text(widget.emptyText!))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: _firstWidth, child: part(first: true)),
                    VerticalDivider(
                      width: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: restWidth,
                          child: part(first: false),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// A report's filter fields: in place, or on a phone a Filters chip that
/// opens them in a sheet (00-overview, section 7.2). [fields] gets a
/// callback to call after a filter changes, so an open sheet shows it.
class ReportFilters extends StatelessWidget {
  const ReportFilters({super.key, required this.fields});

  final Widget Function(VoidCallback changed) fields;

  @override
  Widget build(BuildContext context) {
    if (WindowSize.of(context) != WindowSize.compact) return fields(() {});
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionChip(
        avatar: const Icon(Icons.filter_list),
        label: Text(AppLocalizations.of(context).filters),
        onPressed: () => showRowEditor<void>(
          context,
          (_) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: StatefulBuilder(
              builder: (context, setSheet) => fields(() => setSheet(() {})),
            ),
          ),
        ),
      ),
    );
  }
}

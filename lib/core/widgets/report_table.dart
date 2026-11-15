import 'dart:io';

import 'package:csv/csv.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import 'spacing.dart';

/// The CSV text of a report: a header line, then one line per row.
String toCsv(List<String> columns, List<List<Object?>> rows) =>
    csv.encode([columns, ...rows]);

/// A report (00-overview, section 7.1): a filter bar, a table that scrolls
/// sideways on a narrow window, and a CSV export action.
///
/// Each row holds one value per column. Columns whose values are all numbers
/// are right-aligned. Needs a bounded height, e.g. the body of a Scaffold.
class ReportTable extends StatelessWidget {
  const ReportTable({
    super.key,
    required this.columns,
    required this.rows,
    this.filters,
    required this.exportName,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final Widget? filters;

  /// File name of the export, without `.csv`.
  final String exportName;

  // Writes the CSV to the cache folder and hands it to Android's share sheet.
  Future<void> _export() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$exportName.csv');
    await file.writeAsString(toCsv(columns, rows));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
    );
  }

  bool _isNumeric(int column) =>
      rows.any((row) => row[column] is num) &&
      rows.every((row) => row[column] == null || row[column] is num);

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: filters ?? const SizedBox.shrink()),
              IconButton(
                tooltip: AppLocalizations.of(context).exportCsv,
                icon: const Icon(Icons.download),
                onPressed: _export,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final (i, column) in columns.indexed)
                    DataColumn(label: Text(column), numeric: _isNumeric(i)),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        for (final value in row)
                          DataCell(Text(value?.toString() ?? '')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

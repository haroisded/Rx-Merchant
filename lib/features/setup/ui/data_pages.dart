import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup.dart';
import '../data/data_import_db.dart';
import '../logic/data_import.dart';
import 'form_kit.dart';

// Data Import, Data Export (SET-R16) and Backups (SET-R17, R18).

/// Lets the owner save [bytes] anywhere outside the app (Android's save
/// dialog). True when saved.
Future<bool> saveOutside(
  String fileName,
  List<int> bytes,
  String mimeType,
) async =>
    await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType,
    ) !=
    null;

List<int> _csvBytes(List<List<String>> rows) => utf8.encode(Csv().encode(rows));

/// Saves [rows] as a CSV file wherever the owner chooses. True when saved.
Future<bool> saveCsv(String fileName, List<List<String>> rows) =>
    saveOutside(fileName, _csvBytes(rows), 'text/csv');

/// Lets the owner pick a CSV file and returns its name and rows as text;
/// null when none was picked.
Future<(String, List<List<String>>)?> pickCsv() async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (picked.isEmpty) return null;
  final text = utf8.decode(
    await picked.single.readAsBytes(),
    allowMalformed: true,
  );
  return (
    picked.single.name,
    [
      for (final row in Csv().decode(text.replaceFirst('﻿', '')))
        [for (final cell in row) '${cell ?? ''}'],
    ],
  );
}

String importProblemText(AppLocalizations l, ImportProblemKind kind) =>
    switch (kind) {
      ImportProblemKind.missing => l.importMissing,
      ImportProblemKind.duplicate => l.importDuplicate,
      ImportProblemKind.notFound => l.importNotFound,
      ImportProblemKind.unknownLink => l.importUnknownLink,
      ImportProblemKind.badNumber => l.notANumber,
      ImportProblemKind.badValue => l.importBadValue,
      ImportProblemKind.badDate => l.importBadDate,
      ImportProblemKind.badBarcode => l.importBadBarcode,
      ImportProblemKind.overlappingPrice => l.importOverlappingPrice,
    };

class _RecordTypePicker extends StatelessWidget {
  const _RecordTypePicker({required this.value, required this.onChanged});

  final ImportRecordType value;
  final ValueChanged<ImportRecordType> onChanged;

  @override
  Widget build(BuildContext context) => DropdownMenu<ImportRecordType>(
    label: Text(AppLocalizations.of(context).recordType),
    initialSelection: value,
    expandedInsets: EdgeInsets.zero,
    onSelected: (t) => onChanged(t!),
    dropdownMenuEntries: [
      for (final t in ImportRecordType.values)
        DropdownMenuEntry(value: t, label: t.label),
    ],
  );
}

class DataImportPage extends ConsumerStatefulWidget {
  const DataImportPage({super.key});

  @override
  ConsumerState<DataImportPage> createState() => _DataImportPageState();
}

class _DataImportPageState extends ConsumerState<DataImportPage> {
  var _type = ImportRecordType.item;
  var _importType = ImportType.insert;
  String? _fileName;
  List<String> _header = [];
  List<List<String>> _body = [];

  /// The column each header cell maps to; null = not imported.
  List<String?> _mapping = [];
  List<ImportProblem>? _problems;
  List<ImportLogLine>? _log;
  var _busy = false;

  void _reset() {
    _fileName = null;
    _header = [];
    _body = [];
    _mapping = [];
    _problems = null;
    _log = null;
  }

  Future<void> _chooseFile() async {
    final picked = await pickCsv();
    if (picked == null) return;
    final (name, table) = picked;
    setState(() {
      _reset();
      _fileName = name;
      if (table.isEmpty) return;
      _header = table.first;
      _body = table.skip(1).toList();
      _mapping = matchHeaders(_type, _header);
    });
  }

  Future<void> _start() async {
    final db = ref.read(appDatabaseProvider);
    final rows = rowsOf(_body, _mapping);
    setState(() => _busy = true);
    try {
      final problems = validateImport(
        _type,
        _importType,
        rows,
        await db.importLookups(),
      );
      if (problems.isNotEmpty) {
        setState(() => _problems = problems);
        return;
      }
      final log = await db.runImport(_type, _importType, rows);
      setState(() {
        _problems = null;
        _log = log;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mandatory = [
      for (final c in _type.columns)
        if (_importType == ImportType.insert
            ? c.mandatory
            : _type.keys.contains(c.label))
          c.label,
    ];
    final problems = _problems;
    final log = _log;

    return FormPage(
      title: l.dataImport,
      children: [
        FieldGrid(
          children: [
            _RecordTypePicker(
              value: _type,
              onChanged: (t) => setState(() {
                _type = t;
                _reset();
              }),
            ),
            SegmentedButton<ImportType>(
              segments: [
                ButtonSegment(
                  value: ImportType.insert,
                  label: Text(l.insertNewRecords),
                ),
                ButtonSegment(
                  value: ImportType.update,
                  label: Text(l.updateExistingRecords),
                ),
              ],
              selected: {_importType},
              onSelectionChanged: (s) => setState(() {
                _importType = s.single;
                _problems = null;
                _log = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l.mandatoryColumns(mandatory.join(', '))),
        Text(l.importNotes, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => saveOutside(
                '${_type.label}.csv',
                _csvBytes([
                  [for (final c in _type.columns) c.label],
                ]),
                'text/csv',
              ),
              icon: const Icon(Icons.download),
              label: Text(l.downloadTemplate),
            ),
            OutlinedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.upload_file),
              label: Text(l.chooseFile),
            ),
            if (_fileName != null)
              FilledButton(
                onPressed: _busy || _body.isEmpty ? null : _start,
                child: Text(l.startImport),
              ),
          ],
        ),
        if (_fileName case final name?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l.fileRows(name, _body.length)),
        ],
        // Unrecognised headers: the owner maps each to a field or skips it.
        for (final (i, header) in _header.indexed)
          if (matchHeaders(_type, [header]).single == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: DropdownMenu<String>(
                label: Text(l.mapColumn(header)),
                initialSelection: _mapping[i] ?? '',
                expandedInsets: EdgeInsets.zero,
                onSelected: (v) =>
                    setState(() => _mapping[i] = v == '' ? null : v),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: '', label: l.doNotImport),
                  for (final c in _type.columns)
                    DropdownMenuEntry(value: c.label, label: c.label),
                ],
              ),
            ),
        if (problems != null) ...[
          SectionHeading(l.importWarnings(problems.length)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: AppSpacing.md,
              columns: [
                DataColumn(label: Text(l.row), numeric: true),
                DataColumn(label: Text(l.column)),
                DataColumn(label: Text(l.problem)),
                DataColumn(label: Text(l.value)),
              ],
              rows: [
                for (final p in problems)
                  DataRow(
                    cells: [
                      DataCell(Text('${p.row}')),
                      DataCell(Text(p.column)),
                      DataCell(Text(importProblemText(l, p.kind))),
                      DataCell(Text(p.value)),
                    ],
                  ),
              ],
            ),
          ),
        ],
        if (log != null) ...[
          SectionHeading(l.importLog(log.length)),
          for (final line in log)
            ListTile(
              dense: true,
              leading: Text('${line.row}'),
              title: Text(line.name),
              trailing: Text(line.created ? l.created : l.updated),
            ),
        ],
      ],
    );
  }
}

class DataExportPage extends ConsumerStatefulWidget {
  const DataExportPage({super.key});

  @override
  ConsumerState<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends ConsumerState<DataExportPage> {
  var _type = ImportRecordType.item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormPage(
      title: l.dataExport,
      children: [
        _RecordTypePicker(
          value: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: () async {
              final rows = await ref
                  .read(appDatabaseProvider)
                  .exportRows(_type);
              final saved = await saveOutside(
                '${_type.label}.csv',
                _csvBytes(rows),
                'text/csv',
              );
              if (saved && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.exportedRows(rows.length - 1))),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: Text(l.export),
          ),
        ),
      ],
    );
  }
}

// ---- Backups ----------------------------------------------------------------

/// Lets the owner pick a backup file and returns the path of a private copy,
/// or null when nothing was picked. The picked file may be a content URI.
Future<String?> pickBackupCopy() async {
  final picked = await FilePicker.pickFiles();
  if (picked.isEmpty) return null;
  final copy = File('${(await getTemporaryDirectory()).path}/restore.sqlite');
  await copy.writeAsBytes(await picked.single.readAsBytes(), flush: true);
  return copy.path;
}

/// Restores the backup at [path] (SET-R18) and reopens the database: on the
/// restored file, or on the current one when the restore stopped part-way.
/// Used by the Backups page and the wizard's first step.
Future<void> restoreAndReopen(WidgetRef ref, String path) async {
  try {
    await restoreDatabase(ref.read(appDatabaseProvider), path);
  } finally {
    ref.invalidate(appDatabaseProvider);
  }
}

final _backupsProvider =
    FutureProvider.autoDispose<List<({File file, DateTime taken})>>(
      (ref) async => listBackups(await backupDirectory()),
    );

class BackupsPage extends ConsumerStatefulWidget {
  const BackupsPage({super.key});

  @override
  ConsumerState<BackupsPage> createState() => _BackupsPageState();
}

class _BackupsPageState extends ConsumerState<BackupsPage> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await attempt(context, action, done: done);
    } finally {
      ref.invalidate(_backupsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l = AppLocalizations.of(context);
    if (!await confirm(
          context,
          title: l.restoreTitle,
          body: l.restoreBody,
          action: l.restore,
        ) ||
        !mounted) {
      return;
    }
    final path = await pickBackupCopy();
    if (path == null || !mounted) return;
    await _run(() => restoreAndReopen(ref, path), l.restored);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final backups = ref.watch(_backupsProvider).value ?? [];
    final keep = formats.system.numberOfBackups;
    final db = ref.watch(appDatabaseProvider);

    return FormPage(
      title: l.backups,
      children: [
        Card.filled(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(l.backupWarning),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() => db.takeBackup(), l.backedUp),
              icon: const Icon(Icons.backup_outlined),
              label: Text(l.backUpNow),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: Text(l.restoreFromFile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownMenu<int>(
          label: Text(l.numberOfBackups),
          initialSelection: keep,
          onSelected: (n) =>
              db.writeSingle(SystemSettings.doctype, {'number_of_backups': n}),
          dropdownMenuEntries: [
            for (var n = 1; n <= (keep > 20 ? keep : 20); n++)
              DropdownMenuEntry(value: n, label: '$n'),
          ],
        ),
        SectionHeading(l.backups),
        if (backups.isEmpty) Text(l.noBackups),
        for (final b in backups)
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('${formats.date(b.taken)} ${formats.time(b.taken)}'),
            subtitle: Text(
              l.sizeKb(formats.number(b.file.lengthSync() / 1024, 0)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: l.export,
              onPressed: () async => saveOutside(
                b.file.uri.pathSegments.last,
                await b.file.readAsBytes(),
                'application/vnd.sqlite3',
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/data_pages.dart' show pickCsv, saveCsv;
import '../../setup/ui/tax_template_pages.dart' show NumberField;
import '../logic/serials.dart';
import '../logic/stock_documents.dart';
import 'scan.dart';

const _perPage = 10;
const _csvHeader = ['Serial No', 'Batch No', 'Qty'];

/// The Serial / Batch Entries of one line (STK-R27, "Use Inline Serial /
/// Batch Editor"): add, edit and delete; Auto Fetch; Scan; Create Serial Nos
/// from Range; CSV download and upload; 10 per page. [entries] is edited in
/// place and [onChanged] reports each change; [readOnly] once submitted.
class SerialBatchEditor extends StatefulWidget {
  const SerialBatchEditor({
    super.key,
    required this.entries,
    required this.hasSerial,
    required this.hasBatch,
    required this.incoming,
    required this.formats,
    required this.onChanged,
    this.onAutoFetch,
    this.readOnly = false,
  });

  final List<SbEntry> entries;
  final bool hasSerial;
  final bool hasBatch;

  /// A receipt line: Range applies; Auto Fetch does not.
  final bool incoming;
  final Formats formats;
  final VoidCallback onChanged;

  /// Replaces the table with picked entries (outgoing lines).
  final Future<List<SbEntry>> Function()? onAutoFetch;
  final bool readOnly;

  @override
  State<SerialBatchEditor> createState() => _SerialBatchEditorState();
}

class _SerialBatchEditorState extends State<SerialBatchEditor> {
  var _page = 0;

  List<SbEntry> get _entries => widget.entries;

  void _changed() {
    setState(() {
      final last = (_entries.length - 1) ~/ _perPage;
      if (_page > last) _page = last < 0 ? 0 : last;
    });
    widget.onChanged();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Scan: a batch scanned again adds 1; a serial scanned twice is refused.
  void _add(String code) {
    final l = AppLocalizations.of(context);
    if (widget.hasSerial) {
      if (_entries.any((e) => e.serialNo == code)) {
        return _message(l.serialScannedTwice(code));
      }
      _entries.add(SbEntry(serialNo: code));
    } else {
      final same = _entries.where((e) => e.batchNo == code).firstOrNull;
      if (same != null) {
        same.qty += 1;
      } else {
        _entries.add(SbEntry(batchNo: code));
      }
    }
    _changed();
  }

  Future<void> _range() async {
    final l = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(l.createSerialsFromRange),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.serialRange,
              hintText: 'SN-01::10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: Text(l.create),
            ),
          ],
        );
      },
    );
    if (text == null) return;
    final serials = serialRange(text);
    if (serials == null) return _message(l.badSerialRange);
    for (final s in serials) {
      if (!_entries.any((e) => e.serialNo == s)) {
        _entries.add(SbEntry(serialNo: s));
      }
    }
    _changed();
  }

  Future<void> _upload() async {
    final picked = await pickCsv();
    if (picked == null) return;
    final (_, rows) = picked;
    if (rows.isEmpty) return;
    final header = rows.first;
    String? cell(List<String> r, String column) {
      final i = header.indexOf(column);
      return i < 0 || i >= r.length || r[i].trim().isEmpty ? null : r[i].trim();
    }

    _entries
      ..clear()
      ..addAll([
        for (final r in rows.skip(1))
          if (cell(r, 'Serial No') != null || cell(r, 'Batch No') != null)
            SbEntry(
              serialNo: cell(r, 'Serial No'),
              batchNo: cell(r, 'Batch No'),
              qty: cell(r, 'Serial No') != null
                  ? 1
                  : double.tryParse(cell(r, 'Qty') ?? '') ?? 1,
            ),
      ]);
    _changed();
  }

  Future<void> _edit(SbEntry? entry) async {
    final edited = await showDialog<SbEntry>(
      context: context,
      builder: (context) => _EntryDialog(
        entry: entry,
        hasSerial: widget.hasSerial,
        hasBatch: widget.hasBatch,
        formats: widget.formats,
      ),
    );
    if (edited == null) return;
    if (entry == null) {
      _entries.add(edited);
    } else if (edited.qty == 0 &&
        edited.serialNo == null &&
        edited.batchNo == null) {
      _entries.remove(entry);
    } else {
      _entries[_entries.indexOf(entry)] = edited;
    }
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = (_entries.length + _perPage - 1) ~/ _perPage;
    final shown = _entries.skip(_page * _perPage).take(_perPage).toList();
    final total = _entries.fold(0.0, (s, e) => s + e.qty);
    final onAutoFetch = widget.onAutoFetch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l.serialBatchEntries} · ${widget.formats.number(total)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (!widget.readOnly)
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add),
                label: Text(l.addRow),
              ),
              if (onAutoFetch != null)
                TextButton.icon(
                  onPressed: () async {
                    final picked = await onAutoFetch();
                    _entries
                      ..clear()
                      ..addAll(picked);
                    _changed();
                  },
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(l.autoFetch),
                ),
              TextButton.icon(
                onPressed: () async {
                  final code = await scanBarcode(context);
                  if (code != null) _add(code);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l.scan),
              ),
              if (widget.incoming && widget.hasSerial)
                TextButton.icon(
                  onPressed: _range,
                  icon: const Icon(Icons.format_list_numbered),
                  label: Text(l.createSerialsFromRange),
                ),
              TextButton.icon(
                onPressed: () => saveCsv('serial-batch-entries.csv', [
                  _csvHeader,
                  for (final e in _entries)
                    [e.serialNo ?? '', e.batchNo ?? '', '${e.qty}'],
                ]),
                icon: const Icon(Icons.download),
                label: Text(l.download),
              ),
              TextButton.icon(
                onPressed: _upload,
                icon: const Icon(Icons.upload),
                label: Text(l.upload),
              ),
            ],
          ),
        for (final e in shown)
          ListTile(
            dense: true,
            title: Text(e.serialNo ?? e.batchNo ?? ''),
            subtitle: e.serialNo != null && e.batchNo != null
                ? Text(e.batchNo!)
                : null,
            trailing: Text(widget.formats.number(e.qty)),
            onTap: widget.readOnly ? null : () => _edit(e),
          ),
        if (pages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _page == 0 ? null : () => setState(() => _page--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(l.pageOf(_page + 1, pages)),
              IconButton(
                onPressed: _page >= pages - 1
                    ? null
                    : () => setState(() => _page++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    required this.entry,
    required this.hasSerial,
    required this.hasBatch,
    required this.formats,
  });

  final SbEntry? entry;
  final bool hasSerial;
  final bool hasBatch;
  final Formats formats;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final _serial = TextEditingController(text: widget.entry?.serialNo);
  late final _batch = TextEditingController(text: widget.entry?.batchNo);
  late var _qty = widget.entry?.qty ?? 1;

  @override
  void dispose() {
    _serial.dispose();
    _batch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          if (widget.hasSerial)
            TextField(
              controller: _serial,
              decoration: InputDecoration(labelText: '${l.serialNo} *'),
            ),
          if (widget.hasBatch)
            TextField(
              controller: _batch,
              decoration: InputDecoration(labelText: l.batchId),
            ),
          if (!widget.hasSerial)
            NumberField(
              label: l.qty,
              value: _qty,
              formats: widget.formats,
              onChanged: (v) => _qty = v,
            ),
        ],
      ),
      actions: [
        if (widget.entry != null)
          TextButton(
            // An empty entry tells the editor to delete the row.
            onPressed: () => Navigator.pop(context, SbEntry(qty: 0)),
            child: Text(l.delete),
          ),
        FilledButton(
          onPressed: () {
            final serial = text(_serial), batch = text(_batch);
            if (serial == null && batch == null) return;
            Navigator.pop(
              context,
              SbEntry(
                serialNo: serial,
                batchNo: batch,
                qty: serial != null ? 1 : _qty,
              ),
            );
          },
          child: Text(l.done),
        ),
      ],
    );
  }
}

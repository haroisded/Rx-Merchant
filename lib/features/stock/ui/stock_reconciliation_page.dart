import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/data_pages.dart' show pickCsv, saveCsv;
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/tax_template_pages.dart' show NumberField;
import '../data/stock_entry_db.dart';
import '../data/stock_ledger.dart';
import '../data/stock_reconciliation_db.dart';
import '../logic/stock_documents.dart';
import 'scan.dart';
import 'stock_entry_page.dart' show docStatus;
import 'stock_providers.dart';

// Stock Reconciliation list and form (STK-R42; 02-stock section 5).

const _purposes = ['Opening Stock', 'Stock Reconciliation'];
const _csvHeader = ['Item Code', 'Warehouse', 'Quantity', 'Valuation Rate'];

final _reconciliationsProvider = StreamProvider<List<StockReconciliationData>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.stockReconciliation)..orderBy([
        (r) => OrderingTerm.desc(r.postingDatetime),
        (r) => OrderingTerm.desc(r.id),
      ]))
      .watch();
});

class StockReconciliationPage extends ConsumerWidget {
  const StockReconciliationPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<StockReconciliationData>(
        title: l.stockReconciliation,
        rows: ref.watch(_reconciliationsProvider),
        labelOf: (r) => r.name ?? l.draftNumber(r.id),
        subtitleOf: (r) =>
            '${r.purpose} · ${formats.date(DateTime.parse(r.postingDatetime))}',
        trailingOf: (r) => StatusChip(docStatus(r.docstatus)),
        onOpen: (r) => context.go('$path/${r.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!ref.watch(itemRowsProvider).hasValue ||
        !ref.watch(warehousesProvider).hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ReconciliationForm(
      key: ValueKey(id),
      path: path,
      id: int.tryParse(id),
    );
  }
}

class _ReconciliationForm extends ConsumerStatefulWidget {
  const _ReconciliationForm({super.key, required this.path, this.id});

  final String path;
  final int? id;

  @override
  ConsumerState<_ReconciliationForm> createState() =>
      _ReconciliationFormState();
}

class _ReconciliationFormState extends ConsumerState<_ReconciliationForm> {
  StockReconciliationData? _doc;
  var _loaded = false;
  var _purpose = _purposes[1];
  var _editPosting = false;
  String _posting = toStorage(DateTime.now());
  int? _warehouseId;
  var _scanMode = false;
  var _lines = <ReconciliationLine>[];
  final _scan = TextEditingController();

  int get _docstatus => _doc?.docstatus ?? 0;
  bool get _draft => _docstatus == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final id = widget.id;
    if (id == null) {
      _warehouseId = (ref.read(warehousesProvider).value ?? [])
          .where(
            (w) => w.name == ref.read(stockSettingsProvider).defaultWarehouse,
          )
          .firstOrNull
          ?.id;
    } else {
      final r = await (db.select(
        db.stockReconciliation,
      )..where((x) => x.id.equals(id))).getSingle();
      _doc = r;
      _purpose = r.purpose;
      _editPosting =
          r.docstatus != 0 || postingSetByHand(r.postingDatetime, r.modifiedAt);
      _posting = r.postingDatetime;
      _warehouseId = r.setWarehouseId;
      _scanMode = r.scanMode == 1;
      _lines = await db.reconciliationLines(id);
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  String get _at => _editPosting ? _posting : toStorage(DateTime.now());

  /// Scan Mode adds 1 to the item's row in the Default Warehouse; otherwise
  /// the row is added with the quantity on hand.
  Future<void> _scanned(String code) async {
    final l = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    _scan.clear();
    final found = await itemByBarcode(db, code);
    final wh = _warehouseId;
    if (found == null || wh == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              found == null ? l.barcodeNotFound(code) : l.chooseWarehouseFirst,
            ),
          ),
        );
      }
      return;
    }
    final row = _lines
        .where((x) => x.itemId == found.itemId && x.warehouseId == wh)
        .firstOrNull;
    final b = await db.balanceAt(found.itemId, wh, _at);
    setState(() {
      if (row != null) {
        row.qty += 1;
      } else {
        _lines.add(
          ReconciliationLine(
            itemId: found.itemId,
            warehouseId: wh,
            qty: _scanMode ? 1 : b.qty,
            rate: b.rate,
            currentQty: b.qty,
            currentRate: b.rate,
          ),
        );
      }
    });
  }

  Future<void> _fetch() async {
    final wh = _warehouseId;
    if (wh == null) return;
    final fetched = await ref.read(appDatabaseProvider).fetchItems(wh, _at);
    setState(() {
      for (final f in fetched) {
        if (!_lines.any(
          (x) => x.itemId == f.itemId && x.warehouseId == f.warehouseId,
        )) {
          _lines.add(f);
        }
      }
    });
  }

  /// CSV upload: the four template columns, case-sensitive (STK-R42).
  Future<void> _upload() async {
    final l = AppLocalizations.of(context);
    final picked = await pickCsv();
    if (picked == null || !mounted) return;
    final (_, rows) = picked;
    final header = rows.isEmpty ? const <String>[] : rows.first;
    if (_csvHeader.any((c) => !header.contains(c))) {
      return showProblems(context, [
        l.csvHeadersChanged(_csvHeader.join(', ')),
      ]);
    }
    final items = {
      for (final r in ref.read(itemRowsProvider).value ?? <ItemRow>[])
        r.code: r.id,
    };
    final whs = {
      for (final w in ref.read(warehousesProvider).value ?? <WarehouseData>[])
        w.name: w.id,
    };
    final formats = ref.read(formatsProvider);
    final problems = <String>[];
    final lines = <ReconciliationLine>[];
    for (final (i, r) in rows.skip(1).indexed) {
      String cell(String c) {
        final at = header.indexOf(c);
        return at < r.length ? r[at].trim() : '';
      }

      if (r.every((c) => c.trim().isEmpty)) continue;
      final item = items[cell('Item Code')];
      final wh = whs[cell('Warehouse')];
      final qty = double.tryParse(cell('Quantity'));
      final rate = double.tryParse(cell('Valuation Rate')) ?? 0;
      if (item == null || wh == null || qty == null) {
        problems.add(l.rowProblem(i + 2, l.csvRowInvalid));
        continue;
      }
      lines.add(
        ReconciliationLine(itemId: item, warehouseId: wh, qty: qty, rate: rate),
      );
    }
    if (problems.isNotEmpty) return showProblems(context, problems);
    await ref.read(appDatabaseProvider).fillCurrent(lines, _at);
    setState(() => _lines = lines);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.rowsLoaded(formats.number(lines.length, 0)))),
      );
    }
  }

  Future<int?> _save() async {
    final l = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    final problems = checkReconciliationLines(
      _lines,
      items: await db.itemFacts(_lines.map((x) => x.itemId)),
      usableWarehouses: await db.usableWarehouses(),
      date: _at.substring(0, 10),
    );
    if (!mounted) return null;
    if (_lines.isEmpty || problems.isNotEmpty) {
      await showProblems(context, [
        if (_lines.isEmpty) l.noItems,
        for (final (row, p) in problems) lineProblemMessage(l, row, p),
      ]);
      return null;
    }
    int? id;
    final ok = await attempt(context, () async {
      id = await db.saveStockReconciliation(
        StockReconciliationCompanion(
          id: widget.id == null ? const Value.absent() : Value(widget.id!),
          purpose: Value(_purpose),
          postingDatetime: Value(_posting),
          setWarehouseId: Value(_warehouseId),
          scanMode: Value(_scanMode ? 1 : 0),
          amendedFromId: Value(_doc?.amendedFromId),
        ),
        _lines,
        posting: _editPosting ? _posting : null,
      );
    });
    return ok ? id : null;
  }

  Future<void> _act(
    String title,
    String body,
    String action,
    Future<void> Function(int) run,
  ) async {
    final l = AppLocalizations.of(context);
    if (!await confirm(context, title: title, body: body, action: action) ||
        !mounted) {
      return;
    }
    final id = _draft ? await _save() : widget.id;
    if (id == null || !mounted) return;
    final ok = await attempt(context, () => run(id), done: l.saved);
    if (ok && mounted) context.go('${widget.path}/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final db = ref.read(appDatabaseProvider);
    final formats = ref.watch(formatsProvider);
    final warehouses = ref.watch(warehousesProvider).value ?? [];
    final items = ref.watch(itemRowsProvider).value ?? [];
    final compact = WindowSize.of(context) == WindowSize.compact;
    final error = Theme.of(context).colorScheme.error;
    final money = formats.system.currencyPrecision;
    final d = _doc;
    String wh(int id) => warehouses.firstWhere((w) => w.id == id).name;
    String code(int id) =>
        items.where((i) => i.id == id).firstOrNull?.code ?? '';

    return FormPage(
      title:
          d?.name ??
          (d == null
              ? l.newRecord(l.stockReconciliation)
              : l.draftNumber(d.id)),
      onSave: _draft
          ? () async {
              final id = await _save();
              if (id != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.saved)));
                context.go('${widget.path}/$id');
              }
              return id != null;
            }
          : null,
      onDelete: d != null && _draft
          ? () async {
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(l.draftNumber(d.id)),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              final ok = await attempt(
                context,
                () => (db.delete(
                  db.stockReconciliation,
                )..where((x) => x.id.equals(d.id))).go(),
              );
              if (ok && context.mounted) context.go(widget.path);
            }
          : null,
      actions: [
        if (d != null) Center(child: StatusChip(docStatus(_docstatus))),
        if (_draft)
          FilledButton.tonal(
            onPressed: () => _act(
              l.submitTitle,
              l.submitBody,
              l.submit,
              db.submitStockReconciliation,
            ),
            child: Text(l.submit),
          ),
        if (_docstatus == 1)
          TextButton(
            onPressed: () => _act(
              l.cancelTitle,
              l.cancelBody,
              l.cancelDocument,
              db.cancelStockReconciliation,
            ),
            child: Text(l.cancelDocument),
          ),
        if (_docstatus == 2)
          TextButton(
            onPressed: () async {
              int? copy;
              final ok = await attempt(
                context,
                () async => copy = await db.amendStockReconciliation(d!.id),
              );
              if (ok && context.mounted) context.go('${widget.path}/$copy');
            },
            child: Text(l.amend),
          ),
      ],
      children: [
        FieldGrid(
          children: [
            DropdownMenu<String>(
              label: Text(l.purpose),
              initialSelection: _purpose,
              enabled: _draft,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _purpose = v ?? _purpose),
              dropdownMenuEntries: [
                for (final p in _purposes)
                  DropdownMenuEntry(
                    value: p,
                    label: p == _purposes[0]
                        ? l.openingStock
                        : l.stockReconciliation,
                  ),
              ],
            ),
            DropdownMenu<int?>(
              label: Text(l.defaultWarehouse),
              initialSelection: _warehouseId,
              enabled: _draft,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _warehouseId = v),
              dropdownMenuEntries: [
                for (final w in usable(warehouses))
                  DropdownMenuEntry(value: w.id, label: w.name),
              ],
            ),
            SwitchListTile(
              title: Text(l.editPostingDateTime),
              value: _editPosting,
              onChanged: _draft
                  ? (on) => setState(() => _editPosting = on)
                  : null,
            ),
            DateField(
              label: l.postingDateTime,
              value: _posting,
              withTime: true,
              mandatory: true,
              enabled: _draft && _editPosting,
              formats: formats,
              onChanged: (v) => setState(() => _posting = v ?? _posting),
            ),
            SwitchListTile(
              title: Text(l.scanMode),
              value: _scanMode,
              onChanged: _draft ? (on) => setState(() => _scanMode = on) : null,
            ),
          ],
        ),
        if (_draft) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: _warehouseId == null ? null : _fetch,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(l.fetchItems),
              ),
              OutlinedButton.icon(
                onPressed: () => saveCsv('stock-reconciliation.csv', [
                  _csvHeader,
                  for (final x in _lines)
                    [
                      code(x.itemId),
                      wh(x.warehouseId),
                      '${x.qty}',
                      '${x.rate}',
                    ],
                ]),
                icon: const Icon(Icons.download),
                label: Text(l.download),
              ),
              OutlinedButton.icon(
                onPressed: _upload,
                icon: const Icon(Icons.upload),
                label: Text(l.upload),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _scan,
            decoration: InputDecoration(
              labelText: l.scanBarcode,
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: ScanButton(onScanned: _scanned),
            ),
            onSubmitted: _scanned,
          ),
        ],
        SectionHeading(l.items),
        ChildTable<ReconciliationLine>(
          rows: _lines,
          readOnly: !_draft,
          rowBuilder: (context, x) {
            final qd = flt(x.qty - x.currentQty, formats.system.floatPrecision);
            final ad = flt(
              x.qty * x.rate - x.currentQty * x.currentRate,
              money,
            );
            return ListTile(
              title: Text(code(x.itemId)),
              subtitle: Text(
                compact
                    ? formats.number(x.qty)
                    : '${wh(x.warehouseId)} · ${formats.number(x.qty)} @ ${formats.money(x.rate)} · '
                          '${l.currentQty}: ${formats.number(x.currentQty)} @ ${formats.money(x.currentRate)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formats.number(qd),
                    style: TextStyle(color: qd < 0 ? error : null),
                  ),
                  if (!compact)
                    Text(
                      formats.money(ad),
                      style: TextStyle(color: ad < 0 ? error : null),
                    ),
                ],
              ),
            );
          },
          editorBuilder: (context, x) => _RowEditor(
            line: x,
            warehouseId: _warehouseId,
            posting: _at,
            readOnly: !_draft,
            onDone: (edited) => setState(() {
              if (x == null) {
                _lines.add(edited);
              } else {
                _lines[_lines.indexOf(x)] = edited;
              }
            }),
            onDelete: x == null || !_draft
                ? null
                : () => setState(() => _lines.remove(x)),
          ),
        ),
        if (d != null && !_draft) ...[
          SectionHeading(l.totals),
          ListTile(
            title: Text(l.differenceAmount),
            trailing: Text(formats.money(d.differenceAmount)),
          ),
        ],
      ],
    );
  }
}

class _RowEditor extends ConsumerStatefulWidget {
  const _RowEditor({
    required this.line,
    required this.warehouseId,
    required this.posting,
    required this.readOnly,
    required this.onDone,
    this.onDelete,
  });

  final ReconciliationLine? line;
  final int? warehouseId;
  final String posting;
  final bool readOnly;
  final ValueChanged<ReconciliationLine> onDone;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_RowEditor> createState() => _RowEditorState();
}

class _RowEditorState extends ConsumerState<_RowEditor> {
  late int? _itemId = widget.line?.itemId;
  late int? _wh = widget.line?.warehouseId ?? widget.warehouseId;
  late var _qty = widget.line?.qty ?? 0;
  late var _rate = widget.line?.rate ?? 0;
  late var _currentQty = widget.line?.currentQty ?? 0;
  late var _currentRate = widget.line?.currentRate ?? 0;
  var _key = 0;

  Future<void> _refresh() async {
    final item = _itemId, wh = _wh;
    if (item == null || wh == null) return;
    final b = await ref
        .read(appDatabaseProvider)
        .balanceAt(item, wh, widget.posting);
    if (!mounted) return;
    setState(() {
      _currentQty = b.qty;
      _currentRate = b.rate;
      if (widget.line == null) {
        _qty = b.qty;
        _rate = b.rate;
        _key++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final item = items.where((i) => i.id == _itemId).firstOrNull;
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: widget.readOnly
          ? () {}
          : _itemId == null || _wh == null
          ? null
          : () => widget.onDone(
              ReconciliationLine(
                id: widget.line?.id,
                itemId: _itemId!,
                warehouseId: _wh!,
                qty: _qty,
                rate: _rate,
                currentQty: _currentQty,
                currentRate: _currentRate,
              ),
            ),
      children: [
        LinkField<ItemRow>(
          label: l.item,
          mandatory: true,
          value: item,
          // STK-R42: batch and serial items are counted through Stock Entry.
          search: (q) async => [
            for (final r in await searchItems(items, q, stockOnly: true))
              if (!r.hasBatch && !r.hasSerial) r,
          ],
          labelOf: (r) => '${r.code} · ${r.name}',
          onChanged: (r) {
            setState(() => _itemId = r?.id);
            _refresh();
          },
        ),
        DropdownMenu<int?>(
          label: Text('${l.warehouse} *'),
          initialSelection: _wh,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) {
            setState(() => _wh = v);
            _refresh();
          },
          dropdownMenuEntries: [
            for (final w in usable(ref.watch(warehousesProvider).value ?? []))
              DropdownMenuEntry(value: w.id, label: w.name),
          ],
        ),
        NumberField(
          key: ValueKey('qty$_key'),
          label: l.quantity,
          value: _qty,
          formats: formats,
          onChanged: (v) => setState(() => _qty = v),
        ),
        NumberField(
          key: ValueKey('rate$_key'),
          label: l.valuationRate,
          value: _rate,
          formats: formats,
          precision: formats.system.currencyPrecision,
          onChanged: (v) => setState(() => _rate = v),
        ),
        Text(
          '${l.currentQty}: ${formats.number(_currentQty)} · '
          '${l.currentValuationRate}: ${formats.money(_currentRate)}\n'
          '${l.quantityDifference}: ${formats.number(_qty - _currentQty)} · '
          '${l.amountDifference}: ${formats.money(_qty * _rate - _currentQty * _currentRate)}',
        ),
      ],
    );
  }
}

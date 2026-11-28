import 'package:drift/drift.dart'
    show BooleanExpressionOperators, OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/tax_template_pages.dart' show NumberField;
import '../data/stock_entry_db.dart';
import '../logic/stock_documents.dart';
import '../logic/stock_rules.dart';
import 'scan.dart';
import 'serial_batch_editor.dart';
import 'stock_providers.dart';

// Stock Entry list and form (STK-R38 to R41; 02-stock section 5).

String docStatus(int docstatus) => switch (docstatus) {
  0 => 'Draft',
  1 => 'Submitted',
  _ => 'Cancelled',
};

final _entriesProvider = StreamProvider<List<StockEntryData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.stockEntry)..orderBy([
        (e) => OrderingTerm.desc(e.postingDatetime),
        (e) => OrderingTerm.desc(e.id),
      ]))
      .watch();
});

class StockEntryPage extends ConsumerWidget {
  const StockEntryPage({
    super.key,
    required this.path,
    this.id,
    this.query = const {},
  });

  final String path;
  final String? id;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<StockEntryData>(
        title: l.stockEntry,
        rows: ref.watch(_entriesProvider),
        labelOf: (e) => e.name ?? l.draftNumber(e.id),
        subtitleOf: (e) =>
            '${e.purpose} · ${formats.date(DateTime.parse(e.postingDatetime))}',
        trailingOf: (e) => StatusChip(docStatus(e.docstatus)),
        onOpen: (e) => context.go('$path/${e.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!ref.watch(itemRowsProvider).hasValue ||
        !ref.watch(warehousesProvider).hasValue ||
        !ref.watch(uomsProvider).hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _StockEntryForm(
      key: ValueKey(id),
      path: path,
      entryId: int.tryParse(id),
    );
  }
}

class _StockEntryForm extends ConsumerStatefulWidget {
  const _StockEntryForm({super.key, required this.path, this.entryId});

  final String path;
  final int? entryId;

  @override
  ConsumerState<_StockEntryForm> createState() => _StockEntryFormState();
}

class _StockEntryFormState extends ConsumerState<_StockEntryForm> {
  StockEntryData? _entry;
  var _loaded = false;
  var _purpose = StockPurpose.materialReceipt;
  var _editPosting = false;
  String _posting = toStorage(DateTime.now());
  int? _from, _to;
  var _isOpening = false;
  final _remarks = TextEditingController();
  final _scan = TextEditingController();
  var _lines = <EntryLine>[];
  var _costs = <(String, double)>[];

  int get _docstatus => _entry?.docstatus ?? 0;
  bool get _draft => _docstatus == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final id = widget.entryId;
    if (id == null) {
      final settings = ref.read(stockSettingsProvider);
      final stores = (ref.read(warehousesProvider).value ?? [])
          .where((w) => w.name == settings.defaultWarehouse)
          .firstOrNull
          ?.id;
      _from = stores;
      _to = stores;
    } else {
      final e = await (db.select(
        db.stockEntry,
      )..where((x) => x.id.equals(id))).getSingle();
      _entry = e;
      _purpose = StockPurpose.of(e.purpose);
      _editPosting =
          e.docstatus != 0 || postingSetByHand(e.postingDatetime, e.modifiedAt);
      _posting = e.postingDatetime;
      _from = e.fromWarehouseId;
      _to = e.toWarehouseId;
      _isOpening = e.isOpening == 1;
      _remarks.text = e.remarks ?? '';
      _lines = await db.stockEntryLines(id);
      _costs = [
        for (final c in await (db.select(
          db.stockEntryAdditionalCost,
        )..where((c) => c.stockEntryId.equals(id))).get())
          (c.description, c.amount),
      ];
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _remarks.dispose();
    _scan.dispose();
    super.dispose();
  }

  ItemRow? _item(int id) => (ref.read(itemRowsProvider).value ?? [])
      .where((r) => r.id == id)
      .firstOrNull;

  /// The rate an outgoing line is shown at: the current valuation rate of
  /// the source warehouse (STK-R38); the item's own for a receipt.
  Future<double> _rateFor(int itemId, int? warehouseId) async {
    final db = ref.read(appDatabaseProvider);
    final bin = warehouseId == null
        ? null
        : await (db.select(db.bin)..where(
                (b) =>
                    b.itemId.equals(itemId) & b.warehouseId.equals(warehouseId),
              ))
              .getSingleOrNull();
    if (bin != null && bin.valuationRate > 0) return bin.valuationRate;
    return (await (db.select(
      db.item,
    )..where((i) => i.id.equals(itemId))).getSingle()).valuationRate;
  }

  /// STK-R8: a scanned or typed barcode adds the item, or 1 to its row.
  Future<void> _scanned(String code) async {
    final l = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    final found = await itemByBarcode(db, code);
    _scan.clear();
    if (found == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.barcodeNotFound(code))));
      }
      return;
    }
    final units = await unitsOf(db, found.itemId);
    final unit = units.firstWhere(
      (u) => u.uomId == (found.uomId ?? units.first.uomId),
      orElse: () => units.first,
    );
    final same = _lines
        .where((x) => x.itemId == found.itemId && x.uomId == unit.uomId)
        .firstOrNull;
    if (same != null) {
      setState(() => same.qty += 1);
      return;
    }
    final rate = await _rateFor(found.itemId, _purpose.hasSource ? _from : _to);
    setState(
      () => _lines.add(
        EntryLine(
          itemId: found.itemId,
          sWarehouseId: _from,
          tWarehouseId: _to,
          uomId: unit.uomId,
          factor: unit.factor,
          basicRate: rate,
        ),
      ),
    );
  }

  /// Checks every line, then saves. Returns the saved id, or null.
  Future<int?> _save() async {
    final l = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    final problems = checkEntryLines(
      _purpose,
      _lines,
      items: await db.itemFacts(_lines.map((x) => x.itemId)),
      usableWarehouses: await db.usableWarehouses(),
      wholeUoms: await db.wholeUoms(),
      date: _posting.substring(0, 10),
      floatPrecision: await db.floatPrecision(),
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
      id = await db.saveStockEntry(
        StockEntryCompanion(
          id: widget.entryId == null
              ? const Value.absent()
              : Value(widget.entryId!),
          purpose: Value(_purpose.value),
          postingDatetime: Value(_posting),
          fromWarehouseId: Value(_from),
          toWarehouseId: Value(_to),
          isOpening: Value(_isOpening ? 1 : 0),
          remarks: Value(
            _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
          ),
          amendedFromId: Value(_entry?.amendedFromId),
        ),
        _lines,
        _costs,
        posting: _editPosting ? _posting : null,
      );
    });
    return ok ? id : null;
  }

  Future<void> _act(
    String title,
    String body,
    String action,
    Future<void> Function(int id) run,
  ) async {
    final l = AppLocalizations.of(context);
    if (!await confirm(context, title: title, body: body, action: action) ||
        !mounted) {
      return;
    }
    final id = _draft ? await _save() : widget.entryId;
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
    final open = usable(warehouses);
    final uoms = ref.watch(uomsProvider).value ?? [];
    final e = _entry;
    String wh(int? id) =>
        id == null ? '' : warehouses.firstWhere((w) => w.id == id).name;
    String uomName(int id) => uoms.firstWhere((u) => u.id == id).name;
    final floats = formats.system.floatPrecision;
    double amount(EntryLine x) => flt(
      stockQty(x.qty, x.factor, floats) * x.basicRate,
      formats.system.currencyPrecision,
    );
    final costTotal = _purpose.hasTarget
        ? _costs.fold(0.0, (s, c) => s + c.$2)
        : 0.0;
    final lineTotal = _lines.fold(0.0, (s, x) => s + amount(x));

    DropdownMenu<int?> warehouseMenu(
      String label,
      int? value,
      ValueChanged<int?> set,
    ) => DropdownMenu<int?>(
      key: ValueKey('$label$value'),
      label: Text(label),
      initialSelection: value,
      enabled: _draft,
      expandedInsets: EdgeInsets.zero,
      onSelected: set,
      dropdownMenuEntries: [
        for (final w in open) DropdownMenuEntry(value: w.id, label: w.name),
      ],
    );

    return FormPage(
      title:
          e?.name ??
          (e == null ? l.newRecord(l.stockEntry) : l.draftNumber(e.id)),
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
      onDelete: e != null && _draft
          ? () async {
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(l.draftNumber(e.id)),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              final ok = await attempt(
                context,
                () => db.deleteStockEntry(e.id),
              );
              if (ok && context.mounted) context.go(widget.path);
            }
          : null,
      actions: [
        if (e != null) Center(child: StatusChip(docStatus(_docstatus))),
        if (_draft)
          FilledButton.tonal(
            onPressed: () => _act(
              l.submitTitle,
              l.submitBody,
              l.submit,
              db.submitStockEntry,
            ),
            child: Text(l.submit),
          ),
        if (_docstatus == 1) ...[
          IconButton(
            tooltip: l.reportStockLedger,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.go(
              '/stock/stock-ledger?voucher=${Uri.encodeQueryComponent(e!.name!)}',
            ),
          ),
          TextButton(
            onPressed: () => _act(
              l.cancelTitle,
              l.cancelBody,
              l.cancelDocument,
              db.cancelStockEntry,
            ),
            child: Text(l.cancelDocument),
          ),
        ],
        if (_docstatus == 2)
          TextButton(
            onPressed: () async {
              int? copy;
              final ok = await attempt(
                context,
                () async => copy = await db.amendStockEntry(e!.id),
              );
              if (ok && context.mounted) context.go('${widget.path}/$copy');
            },
            child: Text(l.amend),
          ),
      ],
      children: [
        SegmentedButton<StockPurpose>(
          segments: [
            for (final p in StockPurpose.values)
              ButtonSegment(value: p, label: Text(purposeText(l, p))),
          ],
          selected: {_purpose},
          onSelectionChanged: _draft
              ? (s) => setState(() {
                  _purpose = s.first;
                  // A transfer needs two warehouses: the target is chosen.
                  if (_purpose == StockPurpose.materialTransfer &&
                      _to == _from) {
                    _to = null;
                  }
                })
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        FieldGrid(
          children: [
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
            if (_purpose.hasSource)
              warehouseMenu(
                l.defaultSourceWarehouse,
                _from,
                (v) => setState(() => _from = v),
              ),
            if (_purpose.hasTarget)
              warehouseMenu(
                l.defaultTargetWarehouse,
                _to,
                (v) => setState(() => _to = v),
              ),
          ],
        ),
        SectionHeading(l.items),
        if (_draft)
          TextField(
            controller: _scan,
            decoration: InputDecoration(
              labelText: l.scanBarcode,
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: ScanButton(onScanned: _scanned),
            ),
            onSubmitted: _scanned,
          ),
        ChildTable<EntryLine>(
          rows: _lines,
          readOnly: !_draft,
          rowBuilder: (context, x) {
            final it = _item(x.itemId);
            return ListTile(
              leading: Text('${_lines.indexOf(x) + 1}'),
              title: Text('${it?.code} · ${it?.name}'),
              subtitle: Text(
                [
                  '${formats.number(x.qty)} ${uomName(x.uomId)}',
                  if (_purpose.hasSource) wh(x.sWarehouseId),
                  if (_purpose.hasTarget) '→ ${wh(x.tWarehouseId)}',
                ].join(' · '),
              ),
              trailing: Text(formats.money(amount(x))),
            );
          },
          editorBuilder: (context, x) => _LineEditor(
            line: x,
            number: x == null ? _lines.length + 1 : _lines.indexOf(x) + 1,
            purpose: _purpose,
            readOnly: !_draft,
            from: _from,
            to: _to,
            posting: _posting,
            rateFor: _rateFor,
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
        if (_purpose.hasTarget) ...[
          SectionHeading(l.additionalCosts),
          ChildTable<(String, double)>(
            rows: _costs,
            readOnly: !_draft,
            rowBuilder: (context, c) => ListTile(
              title: Text(c.$1),
              trailing: Text(formats.money(c.$2)),
            ),
            editorBuilder: (context, c) => _CostEditor(
              cost: c,
              formats: formats,
              onDone: (edited) => setState(() {
                if (c == null) {
                  _costs.add(edited);
                } else {
                  _costs[_costs.indexOf(c)] = edited;
                }
              }),
              onDelete: c == null || !_draft
                  ? null
                  : () => setState(() => _costs.remove(c)),
            ),
          ),
        ],
        SectionHeading(l.totals),
        Card.filled(
          child: Column(
            children: [
              if (e != null && !_draft) ...[
                _total(
                  l.totalOutgoingValue,
                  formats.money(e.totalOutgoingValue),
                ),
                _total(
                  l.totalIncomingValue,
                  formats.money(e.totalIncomingValue),
                ),
              ],
              _total(l.totalAdditionalCosts, formats.money(costTotal)),
              _total(
                l.totalAmount,
                formats.money(
                  e != null && !_draft ? e.totalAmount : lineTotal + costTotal,
                ),
              ),
            ],
          ),
        ),
        SectionHeading(l.moreInformation),
        FieldGrid(
          children: [
            SwitchListTile(
              title: Text(l.isOpening),
              value: _isOpening,
              onChanged: _draft
                  ? (on) => setState(() => _isOpening = on)
                  : null,
            ),
            TextField(
              controller: _remarks,
              readOnly: !_draft,
              maxLines: null,
              decoration: InputDecoration(labelText: l.remarks),
            ),
          ],
        ),
      ],
    );
  }

  Widget _total(String label, String value) =>
      ListTile(dense: true, title: Text(label), trailing: Text(value));
}

String purposeText(AppLocalizations l, StockPurpose p) => switch (p) {
  StockPurpose.materialReceipt => l.materialReceipt,
  StockPurpose.materialIssue => l.materialIssue,
  StockPurpose.materialTransfer => l.materialTransfer,
};

class _LineEditor extends ConsumerStatefulWidget {
  const _LineEditor({
    required this.line,
    required this.number,
    required this.purpose,
    required this.readOnly,
    required this.from,
    required this.to,
    required this.posting,
    required this.rateFor,
    required this.onDone,
    this.onDelete,
  });

  final EntryLine? line;
  final int number;
  final StockPurpose purpose;
  final bool readOnly;
  final int? from, to;
  final String posting;
  final Future<double> Function(int itemId, int? warehouseId) rateFor;
  final ValueChanged<EntryLine> onDone;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends ConsumerState<_LineEditor> {
  late int? _itemId = widget.line?.itemId;
  late int? _uomId = widget.line?.uomId;
  late var _factor = widget.line?.factor ?? 1;
  late var _qty = widget.line?.qty ?? 1;
  late var _rate = widget.line?.basicRate ?? 0;
  late var _allowZero = widget.line?.allowZero ?? false;
  late int? _s = widget.line?.sWarehouseId ?? widget.from;
  late int? _t = widget.line?.tWarehouseId ?? widget.to;
  late final _entries = [
    for (final e in widget.line?.entries ?? const <SbEntry>[])
      SbEntry(serialNo: e.serialNo, batchNo: e.batchNo, qty: e.qty),
  ];
  // Rebuilt when the rate is fetched, so the field shows it.
  var _rateKey = 0;

  bool get _incoming => widget.purpose == StockPurpose.materialReceipt;

  Future<void> _pickItem(ItemRow? item) async {
    setState(() {
      _itemId = item?.id;
      _uomId = item?.stockUomId;
      _factor = 1;
      _entries.clear();
    });
    if (item == null) return;
    final rate = await widget.rateFor(
      item.id,
      widget.purpose.hasSource ? _s : _t,
    );
    if (mounted) {
      setState(() {
        _rate = rate;
        _rateKey++;
      });
    }
  }

  /// STK-R27 Auto Fetch for an outgoing line.
  Future<List<SbEntry>> _autoFetch(ItemRow item) async {
    final db = ref.read(appDatabaseProvider);
    final settings = ref.read(stockSettingsProvider);
    final formats = ref.read(formatsProvider);
    final picks = await db.availableEntries(
      item.id,
      _s!,
      widget.posting,
      serials: item.hasSerial,
      allowExpired: widget.purpose == StockPurpose.materialIssue,
    );
    final taken = autoPick(
      picks,
      stockQty(_qty, _factor, formats.system.floatPrecision),
      settings.pickSerialAndBatchBasedOn,
    );
    return [
      for (final (e, qty) in taken)
        SbEntry(serialNo: e.serialNo, batchNo: e.batchNo, qty: qty),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final uoms = ref.watch(uomsProvider).value ?? [];
    final open = usable(ref.watch(warehousesProvider).value ?? []);
    final itemId = _itemId;
    final item = items.where((i) => i.id == itemId).firstOrNull;
    final units = itemId == null
        ? const <({int uomId, double factor})>[]
        : ref.watch(itemUnitsProvider(itemId)).value ?? const [];
    final stock = stockQty(_qty, _factor, formats.system.floatPrecision);
    final tracked = item != null && (item.hasBatch || item.hasSerial);
    final ro = widget.readOnly;

    DropdownMenu<int?> whMenu(
      String label,
      int? value,
      ValueChanged<int?> set,
    ) => DropdownMenu<int?>(
      label: Text('$label *'),
      initialSelection: value,
      enabled: !ro,
      expandedInsets: EdgeInsets.zero,
      onSelected: set,
      dropdownMenuEntries: [
        for (final w in open) DropdownMenuEntry(value: w.id, label: w.name),
      ],
    );

    return RowEditorBody(
      title: l.rowNumber(widget.number),
      onDelete: widget.onDelete,
      onDone: ro || itemId == null || _uomId == null
          ? (ro ? () {} : null)
          : () => widget.onDone(
              EntryLine(
                id: widget.line?.id,
                itemId: itemId,
                sWarehouseId: _s,
                tWarehouseId: _t,
                // STK-R27: the line quantity is the total of its entries.
                qty: tracked && _entries.isNotEmpty
                    ? flt(
                        _entries.fold(0.0, (s, e) => s + e.qty) / _factor,
                        formats.system.floatPrecision,
                      )
                    : _qty,
                uomId: _uomId!,
                factor: _factor,
                basicRate: _rate,
                allowZero: _allowZero,
                entries: _entries,
              ),
            ),
      children: [
        LinkField<ItemRow>(
          label: l.item,
          mandatory: true,
          value: item,
          search: (q) => searchItems(items, q, stockOnly: true),
          labelOf: (r) => '${r.code} · ${r.name}',
          onChanged: ro ? (_) {} : _pickItem,
        ),
        NumberField(
          label: '${l.qty} *',
          value: _qty,
          formats: formats,
          onChanged: (v) => setState(() => _qty = v),
        ),
        DropdownMenu<int>(
          key: ValueKey('uom$itemId${units.length}'),
          label: Text('${l.uom} *'),
          initialSelection: _uomId,
          enabled: !ro,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() {
            _uomId = v;
            _factor = units.firstWhere((u) => u.uomId == v).factor;
          }),
          dropdownMenuEntries: [
            for (final u in units)
              DropdownMenuEntry(
                value: u.uomId,
                label: uoms.firstWhere((x) => x.id == u.uomId).name,
              ),
          ],
        ),
        Text(
          '${l.conversionFactor}: ${formats.number(_factor)} · '
          '${l.stockQty}: ${formats.number(stock)}',
        ),
        if (widget.purpose.hasSource)
          whMenu(l.sourceWarehouse, _s, (v) => setState(() => _s = v)),
        if (widget.purpose.hasTarget)
          whMenu(l.targetWarehouse, _t, (v) => setState(() => _t = v)),
        // STK-R38: issue and transfer show the current rate, read-only.
        if (_incoming)
          NumberField(
            key: ValueKey('rate$_rateKey'),
            label: l.basicRatePerStockUom,
            value: _rate,
            formats: formats,
            precision: formats.system.currencyPrecision,
            onChanged: (v) => _rate = v,
          )
        else
          InputDecorator(
            decoration: InputDecoration(labelText: l.basicRatePerStockUom),
            child: Text(formats.money(_rate)),
          ),
        if (_incoming)
          SwitchListTile(
            title: Text(l.allowZeroValuationRate),
            value: _allowZero,
            onChanged: ro ? null : (on) => setState(() => _allowZero = on),
          ),
        if (tracked)
          SerialBatchEditor(
            entries: _entries,
            hasSerial: item.hasSerial,
            hasBatch: item.hasBatch,
            incoming: _incoming,
            formats: formats,
            readOnly: ro,
            onChanged: () => setState(() {}),
            onAutoFetch: _incoming || _s == null
                ? null
                : () => _autoFetch(item),
          ),
      ],
    );
  }
}

class _CostEditor extends StatefulWidget {
  const _CostEditor({
    required this.cost,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final (String, double)? cost;
  final Formats formats;
  final ValueChanged<(String, double)> onDone;
  final VoidCallback? onDelete;

  @override
  State<_CostEditor> createState() => _CostEditorState();
}

class _CostEditorState extends State<_CostEditor> {
  late final _description = TextEditingController(text: widget.cost?.$1);
  late var _amount = widget.cost?.$2 ?? 0;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _description.text.trim().isEmpty
          ? null
          : () => widget.onDone((_description.text.trim(), _amount)),
      children: [
        TextField(
          controller: _description,
          decoration: InputDecoration(labelText: '${l.description} *'),
          onChanged: (_) => setState(() {}),
        ),
        NumberField(
          label: l.amount,
          value: _amount,
          formats: widget.formats,
          precision: widget.formats.system.currencyPrecision,
          onChanged: (v) => _amount = v,
        ),
      ],
    );
  }
}

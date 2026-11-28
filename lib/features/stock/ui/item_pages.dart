import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/tax_template_pages.dart'
    show NumberField, itemTaxTemplatesProvider;
import '../data/stock_lists.dart';
import '../data/stock_masters.dart';
import '../logic/barcode.dart';
import '../logic/stock_rules.dart' show maxDiscountOk;
import '../logic/variants.dart';
import 'scan.dart';
import 'stock_masters_pages.dart' show deleteAndLeave;
import 'stock_providers.dart';

// Item list and Item form (02-stock section 5; STK-R4 to R9, R13 to R18).

class ItemPage extends ConsumerWidget {
  const ItemPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) return _ItemList(path: path);
    // A DropdownMenu shows its selection only if its entries exist on the
    // first build (D-22), so the form waits for every list it offers.
    if ([
      ref.watch(itemGroupsProvider),
      ref.watch(uomsProvider),
      ref.watch(brandsProvider),
      ref.watch(warehousesProvider),
      ref.watch(itemAttributesProvider),
      ref.watch(itemTaxTemplatesProvider),
    ].any((v) => !v.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ItemForm(key: ValueKey(id), path: path, itemId: int.tryParse(id));
  }
}

// ---- Item list ---------------------------------------------------------------

class _ItemList extends ConsumerStatefulWidget {
  const _ItemList({required this.path});

  final String path;

  @override
  ConsumerState<_ItemList> createState() => _ItemListState();
}

class _ItemListState extends ConsumerState<_ItemList> {
  final _search = TextEditingController();
  int? _groupId;
  var _disabledOnly = false;
  var _templatesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickGroup(List<ItemGroupData> groups) async {
    final l = AppLocalizations.of(context);
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.itemGroup),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, -1),
            child: Text(l.all),
          ),
          for (final g in groups)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, g.id),
              child: Text(g.name),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _groupId = picked == -1 ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(itemRowsProvider);
    final groups = ref.watch(itemGroupsProvider).value ?? [];
    final formats = ref.watch(formatsProvider);
    final scheme = Theme.of(context).colorScheme;
    final q = _search.text.toLowerCase();
    final shown = [
      for (final r in rows.value ?? const <ItemRow>[])
        if ('${r.code} ${r.name} ${r.barcodes}'.toLowerCase().contains(q) &&
            (_groupId == null || r.groupId == _groupId) &&
            (!_disabledOnly || r.disabled) &&
            (!_templatesOnly || r.template))
          r,
    ];
    void add() => context.go('${widget.path}/new');

    return Scaffold(
      appBar: AppBar(title: Text(l.item)),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        tooltip: l.add,
        child: const Icon(Icons.add),
      ),
      body: rows.hasValue && rows.value!.isEmpty
          ? Center(
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  Text(l.emptyList),
                  FilledButton.tonalIcon(
                    onPressed: add,
                    icon: const Icon(Icons.add),
                    label: Text(l.addItem),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/setup/data-import'),
                    icon: const Icon(Icons.upload_file),
                    label: Text(l.importItems),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: SearchBar(
                    controller: _search,
                    hintText: l.searchItems,
                    leading: const Icon(Icons.search),
                    onChanged: (_) => setState(() {}),
                    // STK-R8: a scan finds the item by its barcode.
                    trailing: [
                      ScanButton(
                        onScanned: (code) =>
                            setState(() => _search.text = code),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      FilterChip(
                        label: Text(
                          _groupId == null
                              ? l.itemGroup
                              : groups.firstWhere((g) => g.id == _groupId).name,
                        ),
                        selected: _groupId != null,
                        onSelected: (_) => _pickGroup(groups),
                      ),
                      FilterChip(
                        label: Text(l.disabled),
                        selected: _disabledOnly,
                        onSelected: (on) => setState(() => _disabledOnly = on),
                      ),
                      FilterChip(
                        label: Text(l.hasVariants),
                        selected: _templatesOnly,
                        onSelected: (on) => setState(() => _templatesOnly = on),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final r = shown[i];
                      return ListTile(
                        leading: _Thumbnail(item: r),
                        title: Text(r.name),
                        subtitle: Text(r.code),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (r.price case final p?) Text(formats.money(p)),
                            if (r.stockItem && !r.template)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: AppSpacing.xs,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: r.qty > 0
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                  Text(formats.number(r.qty)),
                                ],
                              ),
                          ],
                        ),
                        onTap: () => context.go('${widget.path}/${r.id}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.item});

  final ItemRow item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = item.hasImage
        ? ref.watch(itemImageProvider(item.id)).value
        : null;
    return CircleAvatar(
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Text(item.name.isEmpty ? '?' : item.name[0].toUpperCase())
          : null,
    );
  }
}

// ---- Item form ---------------------------------------------------------------

typedef _Barcode = ({String barcode, String? type, int? uomId});
typedef _Unit = ({int uomId, double factor});
typedef _Reorder = ({int warehouseId, double level, double qty});
typedef _Tax = ({int templateId, String? validFrom});

class _ItemForm extends ConsumerStatefulWidget {
  const _ItemForm({super.key, required this.path, this.itemId});

  final String path;

  /// Null for a new item.
  final int? itemId;

  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<_ItemForm> with DiscardGuard {
  @override
  final formKey = GlobalKey<FormState>();
  ItemData? _old;
  var _loaded = false;
  var _stocked = false;
  var _hasVariantChildren = false;
  ItemData? _template;
  Map<int, String> _variantValues = {};

  final _code = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _batchSeries = TextEditingController();
  final _serialSeries = TextEditingController();
  int? _groupId, _uomId, _brandId, _warehouseId, _salesUomId;
  var _disabled = false, _stockItem = true, _salesItem = true;
  var _hasVariants = false, _allowNegative = false;
  var _hasBatch = false, _newBatch = false, _hasExpiry = false;
  var _hasSerial = false;
  String? _valuationMethod, _endOfLife;
  int? _shelfLife, _warranty;
  double _opening = 0, _valuationRate = 0, _standardRate = 0;
  double _maxDiscount = 0;
  Uint8List? _image;
  var _barcodes = <_Barcode>[];
  var _units = <_Unit>[];
  var _reorder = <_Reorder>[];
  var _taxes = <_Tax>[];
  var _attributes = <int>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final settings = ref.read(stockSettingsProvider);
    final id = widget.itemId;
    if (id == null) {
      // STK-R5: defaults from Stock Settings.
      _groupId = await db.idByName('item_group', settings.itemGroup);
      _uomId = await db.idByName('uom', settings.stockUom);
      _warehouseId = await db.idByName('warehouse', settings.defaultWarehouse);
      if (mounted) setState(() => _loaded = true);
      return;
    }
    final it = await (db.select(
      db.item,
    )..where((i) => i.id.equals(id))).getSingle();
    _barcodes = [
      for (final b
          in await (db.select(db.itemBarcode)
                ..where((b) => b.itemId.equals(id))
                ..orderBy([(b) => OrderingTerm(expression: b.id)]))
              .get())
        (barcode: b.barcode, type: b.barcodeType, uomId: b.uomId),
    ];
    _units = [
      for (final u in await (db.select(
        db.itemUom,
      )..where((u) => u.itemId.equals(id))).get())
        (uomId: u.uomId, factor: u.conversionFactor),
    ];
    _reorder = [
      for (final r in await (db.select(
        db.itemReorder,
      )..where((r) => r.itemId.equals(id))).get())
        (
          warehouseId: r.warehouseId,
          level: r.warehouseReorderLevel,
          qty: r.warehouseReorderQty,
        ),
    ];
    _taxes = [
      for (final x in await (db.select(
        db.itemTax,
      )..where((x) => x.itemId.equals(id))).get())
        (templateId: x.itemTaxTemplateId, validFrom: x.validFrom),
    ];
    final attrs =
        await (db.select(db.itemVariantAttribute)
              ..where((a) => a.itemId.equals(id))
              ..orderBy([(a) => OrderingTerm(expression: a.id)]))
            .get();
    _attributes = [for (final a in attrs) a.attributeId];
    _variantValues = {
      for (final a in attrs) a.attributeId: a.attributeValue ?? '',
    };
    _stocked = await db.hasLedger(id);
    _hasVariantChildren =
        (await (db.select(db.item)
                  ..where((i) => i.variantOfId.equals(id))
                  ..limit(1))
                .get())
            .isNotEmpty;
    if (it.variantOfId case final t?) {
      _template = await (db.select(
        db.item,
      )..where((i) => i.id.equals(t))).getSingle();
    }
    _old = it;
    _code.text = it.itemCode;
    _name.text = it.itemName;
    _description.text = it.description ?? '';
    _batchSeries.text = it.batchNumberSeries ?? '';
    _serialSeries.text = it.serialNoSeries ?? '';
    _groupId = it.itemGroupId;
    _uomId = it.stockUomId;
    _brandId = it.brandId;
    _warehouseId = it.defaultWarehouseId;
    _salesUomId = it.salesUomId;
    _disabled = it.disabled == 1;
    _stockItem = it.isStockItem == 1;
    _salesItem = it.isSalesItem == 1;
    _hasVariants = it.hasVariants == 1;
    _allowNegative = it.allowNegativeStock == 1;
    _hasBatch = it.hasBatchNo == 1;
    _newBatch = it.createNewBatch == 1;
    _hasExpiry = it.hasExpiryDate == 1;
    _hasSerial = it.hasSerialNo == 1;
    _valuationMethod = it.valuationMethod;
    _endOfLife = it.endOfLife;
    _shelfLife = it.shelfLifeInDays;
    _warranty = it.warrantyPeriod;
    _valuationRate = it.valuationRate;
    _standardRate = it.standardRate;
    _maxDiscount = it.maxDiscount;
    _image = it.image;
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _description, _batchSeries, _serialSeries]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    final byCode = ref.read(stockSettingsProvider).itemNamingBy == 'Item Code';
    final isNew = _old == null;
    // STK-R5: Opening Stock counts only where the form offers it.
    final opening =
        isNew && !_hasVariants && _stockItem && !_hasBatch && !_hasSerial
        ? _opening
        : 0.0;
    final problems = [
      if (isNew && byCode && _code.text.trim().isEmpty)
        l.fieldMissing(l.itemCode),
      if (_name.text.trim().isEmpty && !(isNew && byCode))
        l.fieldMissing(l.itemName),
      if (_groupId == null) l.fieldMissing(l.itemGroup),
      if (_uomId == null) l.fieldMissing(l.defaultUom),
      if (!maxDiscountOk(_maxDiscount)) l.maxDiscountRange,
      if (opening < 0) l.openingStockNegative,
      // STK-R38: a Material Receipt needs a rate above zero.
      if (opening > 0 && _valuationRate <= 0) l.openingNeedsValuationRate,
    ];
    if (problems.isNotEmpty) {
      await showProblems(context, problems);
      return false;
    }
    final code = _code.text.trim();
    final db = ref.read(appDatabaseProvider);
    int? saved;
    final ok = await attempt(context, () async {
      saved = await db.saveItem(
        ItemCompanion(
          id: isNew ? const Value.absent() : Value(_old!.id),
          itemCode: Value(code),
          // STK-R4: Item Name is pre-filled with the code.
          itemName: Value(_text(_name) ?? code),
          itemGroupId: Value(_groupId!),
          stockUomId: Value(_uomId!),
          disabled: Value(_disabled ? 1 : 0),
          isStockItem: Value(_stockItem ? 1 : 0),
          isSalesItem: Value(_salesItem ? 1 : 0),
          description: Value(_text(_description)),
          image: Value(_image),
          brandId: Value(_brandId),
          standardRate: Value(_standardRate),
          valuationRate: Value(_valuationRate),
          valuationMethod: Value(_valuationMethod),
          allowNegativeStock: Value(_allowNegative ? 1 : 0),
          shelfLifeInDays: Value(_shelfLife),
          endOfLife: Value(_endOfLife),
          warrantyPeriod: Value(_warranty),
          salesUomId: Value(_salesUomId),
          maxDiscount: Value(_maxDiscount),
          defaultWarehouseId: Value(_warehouseId),
          hasVariants: Value(_hasVariants ? 1 : 0),
          hasBatchNo: Value(_hasBatch ? 1 : 0),
          createNewBatch: Value(_hasBatch && _newBatch ? 1 : 0),
          batchNumberSeries: Value(_hasBatch ? _text(_batchSeries) : null),
          hasExpiryDate: Value(_hasBatch && _hasExpiry ? 1 : 0),
          hasSerialNo: Value(_hasSerial ? 1 : 0),
          serialNoSeries: Value(_hasSerial ? _text(_serialSeries) : null),
        ),
        (
          barcodes: [
            for (final b in _barcodes)
              ItemBarcodeCompanion.insert(
                itemId: 0,
                barcode: b.barcode,
                barcodeType: Value(b.type),
                uomId: Value(b.uomId),
              ),
          ],
          uoms: [
            for (final u in _units)
              ItemUomCompanion.insert(
                itemId: 0,
                uomId: u.uomId,
                conversionFactor: u.factor,
              ),
          ],
          reorder: [
            for (final r in _reorder)
              ItemReorderCompanion.insert(
                itemId: 0,
                warehouseId: r.warehouseId,
                warehouseReorderLevel: Value(r.level),
                warehouseReorderQty: Value(r.qty),
              ),
          ],
          taxes: [
            for (final x in _taxes)
              ItemTaxCompanion.insert(
                itemId: 0,
                itemTaxTemplateId: x.templateId,
                validFrom: Value(x.validFrom),
              ),
          ],
          attributes: _hasVariants || _template != null
              ? _attributes
              : const <int>[],
        ),
        opening: isNew ? (qty: _opening, rate: _valuationRate) : null,
      );
    }, done: l.saved);
    if (ok && mounted) context.go('${widget.path}/$saved');
    return ok;
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _image = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final old = _old;
    final db = ref.read(appDatabaseProvider);
    final compact = WindowSize.of(context) == WindowSize.compact;
    final tabs = [
      (l.tabDetails, _details()),
      (l.tabInventory, _inventory()),
      (l.tabVariants, _variants()),
      (l.tabSales, _sales()),
      (l.tabTax, _tax()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(old?.itemName ?? l.newRecord(l.item)),
          actions: [
            if (old != null)
              IconButton(
                onPressed: () => deleteAndLeave(
                  context,
                  old.itemCode,
                  widget.path,
                  () => db.deleteMaster(db.item, old.id),
                ),
                icon: const Icon(Icons.delete_outline),
                tooltip: l.delete,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilledButton(
                onPressed: () => validateAndSave(_save),
                child: Text(l.save),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: compact,
            // No leading offset, so more of the five tabs fit on a phone.
            tabAlignment: compact ? TabAlignment.start : null,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
        ),
        body: guard(
          Column(
            children: [
              if (old != null) _Strip(itemId: old.id, template: _hasVariants),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final (_, children) in tabs)
                      _KeptAlive(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: children,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STK-R7: why a frozen field is read-only.
  Widget? _frozen() =>
      _stocked ? LockNote(AppLocalizations.of(context).lockedAfterStock) : null;

  List<Widget> _details() {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final settings = ref.watch(stockSettingsProvider);
    final groups = ref.watch(itemGroupsProvider).value ?? [];
    final uoms = ref.watch(uomsProvider).value ?? [];
    final brands = ref.watch(brandsProvider).value ?? [];
    final isNew = _old == null;
    final bySeries = isNew && settings.itemNamingBy == 'Naming Series';
    return [
      FieldGrid(
        children: [
          TextFormField(
            controller: _code,
            readOnly: !isNew || bySeries,
            decoration: InputDecoration(
              labelText: bySeries ? l.itemCodeBySeries : '${l.itemCode} *',
              // STK-R4: Item Codification help.
              suffixIcon: IconButton(
                tooltip: l.itemCodificationTitle,
                icon: const Icon(Icons.help_outline),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l.itemCodificationTitle),
                    content: Text(l.itemCodificationHelp),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          MaterialLocalizations.of(context).okButtonLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            onChanged: (v) {
              // STK-R4: Item Name follows the code until typed over.
              if (isNew && (_name.text.isEmpty || _name.text == _lastCode)) {
                _name.text = v;
              }
              _lastCode = v;
            },
          ),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: '${l.itemName} *'),
          ),
          DropdownMenu<int>(
            label: Text('${l.itemGroup} *'),
            initialSelection: _groupId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => _groupId = v),
            dropdownMenuEntries: [
              for (final g in groups)
                DropdownMenuEntry(value: g.id, label: g.name),
            ],
          ),
          _locked(
            DropdownMenu<int>(
              label: Text('${l.defaultUom} *'),
              initialSelection: _uomId,
              enabled: !_stocked,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _uomId = v),
              dropdownMenuEntries: [
                for (final u in uoms)
                  if (u.enabled == 1 || u.id == _uomId)
                    DropdownMenuEntry(value: u.id, label: u.name),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(l.disabled),
            value: _disabled,
            onChanged: (on) => setState(() => _disabled = on),
          ),
          _locked(
            SwitchListTile(
              title: Text(l.maintainStock),
              value: _stockItem,
              onChanged: _stocked
                  ? null
                  : (on) => setState(() => _stockItem = on),
            ),
          ),
          // STK-R14: fixed once the item has variants or stock.
          SwitchListTile(
            title: Text(l.hasVariants),
            value: _hasVariants,
            onChanged: _stocked || _hasVariantChildren || _template != null
                ? null
                : (on) => setState(() => _hasVariants = on),
          ),
          if (isNew && !_hasVariants) ...[
            if (_stockItem && !_hasBatch && !_hasSerial)
              NumberField(
                label: l.openingStock,
                value: _opening,
                formats: formats,
                onChanged: (v) => _opening = v,
              ),
            NumberField(
              label: l.valuationRate,
              value: _valuationRate,
              formats: formats,
              precision: formats.system.currencyPrecision,
              onChanged: (v) => _valuationRate = v,
            ),
            NumberField(
              label: l.standardSellingRate,
              value: _standardRate,
              formats: formats,
              precision: formats.system.currencyPrecision,
              onChanged: (v) => _standardRate = v,
            ),
          ],
          DropdownMenu<int?>(
            label: Text(l.brand),
            initialSelection: _brandId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => _brandId = v),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: null, label: l.none),
              for (final b in brands)
                DropdownMenuEntry(value: b.id, label: b.name),
            ],
          ),
          TextFormField(
            controller: _description,
            maxLines: null,
            decoration: InputDecoration(labelText: l.description),
          ),
        ],
      ),
      SectionHeading(l.image),
      Row(
        spacing: AppSpacing.sm,
        children: [
          if (_image case final bytes?)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
          IconButton.filledTonal(
            tooltip: l.takePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton.filledTonal(
            tooltip: l.choosePhoto,
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          if (_image != null)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _image = null),
            ),
        ],
      ),
      if (settings.showBarcodeField) ...[
        SectionHeading(l.barcodes),
        ChildTable<_Barcode>(
          rows: _barcodes,
          rowBuilder: (context, b) => ListTile(
            title: Text(b.barcode),
            subtitle: Text(
              [?b.type, if (b.uomId != null) _uomName(b.uomId!)].join(' · '),
            ),
          ),
          editorBuilder: (context, b) => _BarcodeEditor(
            row: b,
            units: [?_uomId, for (final u in _units) u.uomId],
            uomName: _uomName,
            onDone: (edited) => setState(() {
              if (b == null) {
                _barcodes.add(edited);
              } else {
                _barcodes[_barcodes.indexOf(b)] = edited;
              }
            }),
            onDelete: b == null
                ? null
                : () => setState(() => _barcodes.remove(b)),
          ),
        ),
      ],
    ];
  }

  String _lastCode = '';

  String _uomName(int id) =>
      (ref.read(uomsProvider).value ?? [])
          .where((u) => u.id == id)
          .firstOrNull
          ?.name ??
      '';

  Widget _locked(Widget field) {
    final note = _frozen();
    return note == null
        ? field
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, note],
          );
  }

  List<Widget> _inventory() {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final settings = ref.watch(stockSettingsProvider);
    final uoms = ref.watch(uomsProvider).value ?? [];
    final warehouses = usable(ref.watch(warehousesProvider).value ?? []);
    String warehouseName(int id) => (ref.read(warehousesProvider).value ?? [])
        .firstWhere((w) => w.id == id)
        .name;
    return [
      FieldGrid(
        children: [
          TextFormField(
            initialValue: _shelfLife?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.shelfLifeInDays),
            onChanged: (v) => _shelfLife = int.tryParse(v.trim()),
          ),
          DateField(
            label: l.endOfLife,
            value: _endOfLife,
            formats: formats,
            onChanged: (v) => setState(() => _endOfLife = v),
          ),
          TextFormField(
            initialValue: _warranty?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.warrantyPeriodDays),
            onChanged: (v) => _warranty = int.tryParse(v.trim()),
          ),
          _locked(
            DropdownMenu<String?>(
              label: Text(l.valuationMethod),
              initialSelection: _valuationMethod,
              enabled: !_stocked,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _valuationMethod = v),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: null, label: l.asInStockSettings),
                const DropdownMenuEntry(value: 'FIFO', label: 'FIFO'),
                const DropdownMenuEntry(
                  value: 'Moving Average',
                  label: 'Moving Average',
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(l.allowNegativeStock),
            value: _allowNegative,
            onChanged: (on) => setState(() => _allowNegative = on),
          ),
          DropdownMenu<int?>(
            label: Text(l.defaultWarehouse),
            initialSelection: _warehouseId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => _warehouseId = v),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: null, label: l.none),
              for (final w in warehouses)
                DropdownMenuEntry(value: w.id, label: w.name),
            ],
          ),
        ],
      ),
      SectionHeading(l.unitsOfMeasure),
      // STK-R9: stock units in one of each unit.
      ChildTable<_Unit>(
        rows: _units,
        rowBuilder: (context, u) => ListTile(
          title: Text(_uomName(u.uomId)),
          subtitle: Text('${l.conversionFactor}: ${formats.number(u.factor)}'),
        ),
        editorBuilder: (context, u) => _UnitEditor(
          row: u,
          uoms: [
            for (final x in uoms)
              if (x.enabled == 1 && x.id != _uomId) x,
          ],
          formats: formats,
          onDone: (edited) => setState(() {
            if (u == null) {
              _units.add(edited);
            } else {
              _units[_units.indexOf(u)] = edited;
            }
          }),
          onDelete: u == null ? null : () => setState(() => _units.remove(u)),
        ),
      ),
      SectionHeading(l.autoReorder),
      ChildTable<_Reorder>(
        rows: _reorder,
        rowBuilder: (context, r) => ListTile(
          title: Text(warehouseName(r.warehouseId)),
          subtitle: Text(
            '${l.reorderLevel}: ${formats.number(r.level)} · ${l.reorderQty}: ${formats.number(r.qty)}',
          ),
        ),
        editorBuilder: (context, r) => _ReorderEditor(
          row: r,
          warehouses: warehouses,
          formats: formats,
          onDone: (edited) => setState(() {
            if (r == null) {
              _reorder.add(edited);
            } else {
              _reorder[_reorder.indexOf(r)] = edited;
            }
          }),
          onDelete: r == null ? null : () => setState(() => _reorder.remove(r)),
        ),
      ),
      // STK-R18: only when Stock Settings switches serials and batches on.
      if (settings.enableSerialAndBatchNoForItem ||
          _hasBatch ||
          _hasSerial) ...[
        SectionHeading(l.groupSerialAndBatch),
        FieldGrid(
          children: [
            _locked(
              SwitchListTile(
                title: Text(l.hasBatchNo),
                value: _hasBatch,
                onChanged: _stocked
                    ? null
                    : (on) => setState(() => _hasBatch = on),
              ),
            ),
            if (_hasBatch) ...[
              SwitchListTile(
                title: Text(l.createNewBatch),
                value: _newBatch,
                onChanged: (on) => setState(() => _newBatch = on),
              ),
              TextFormField(
                controller: _batchSeries,
                decoration: InputDecoration(labelText: l.batchNumberSeries),
              ),
              SwitchListTile(
                title: Text(l.hasExpiryDate),
                value: _hasExpiry,
                onChanged: (on) => setState(() => _hasExpiry = on),
              ),
            ],
            _locked(
              SwitchListTile(
                title: Text(l.hasSerialNo),
                value: _hasSerial,
                onChanged: _stocked
                    ? null
                    : (on) => setState(() => _hasSerial = on),
              ),
            ),
            if (_hasSerial)
              TextFormField(
                controller: _serialSeries,
                decoration: InputDecoration(labelText: l.serialNoSeries),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _variants() {
    final l = AppLocalizations.of(context);
    final attributes = ref.watch(itemAttributesProvider).value ?? [];
    String attributeName(int id) =>
        attributes.where((a) => a.id == id).firstOrNull?.name ?? '';
    final template = _template;
    if (template != null) {
      return [
        ListTile(
          title: Text(l.variantOf),
          subtitle: Text('${template.itemCode} · ${template.itemName}'),
          onTap: () => context.go('${widget.path}/${template.id}'),
        ),
        for (final a in _attributes)
          ListTile(
            title: Text(attributeName(a)),
            trailing: Text(_variantValues[a] ?? ''),
          ),
      ];
    }
    if (!_hasVariants) return [Text(l.variantsHelp)];
    final old = _old;
    return [
      SectionHeading(l.attributes),
      ChildTable<int>(
        rows: _attributes,
        readOnly: _hasVariantChildren,
        rowBuilder: (context, a) => ListTile(title: Text(attributeName(a))),
        editorBuilder: (context, a) => _AttributeEditor(
          value: a,
          attributes: attributes,
          onDone: (edited) => setState(() {
            if (a == null) {
              if (!_attributes.contains(edited)) _attributes.add(edited);
            } else {
              _attributes[_attributes.indexOf(a)] = edited;
            }
          }),
          onDelete: a == null || _hasVariantChildren
              ? null
              : () => setState(() => _attributes.remove(a)),
        ),
      ),
      if (old != null && old.hasVariants == 1 && _attributes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            FilledButton.tonal(
              onPressed: () => _createVariants(single: true),
              child: Text(l.singleVariant),
            ),
            FilledButton.tonal(
              onPressed: () => _createVariants(single: false),
              child: Text(l.multipleVariants),
            ),
          ],
        ),
        SectionHeading(l.variants),
        _VariantList(templateId: old.id, path: widget.path),
      ],
    ];
  }

  /// STK-R16: Create > Single Variant / Multiple Variants.
  Future<void> _createVariants({required bool single}) async {
    final l = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    final all = await db.select(db.itemAttribute).get();
    final values = await db.select(db.itemAttributeValue).get();
    final options = [
      for (final id in _attributes)
        switch (all.firstWhere((a) => a.id == id)) {
          final a when a.numericValues == 1 => [
            for (final v in numericValues(
              a.fromRange ?? 0,
              a.toRange ?? 0,
              a.increment ?? 0,
            ))
              (attributeId: id, value: v, abbr: v),
          ],
          _ => [
            for (final v in values)
              if (v.attributeId == id)
                (attributeId: id, value: v.attributeValue, abbr: v.abbr),
          ],
        },
    ];
    if (!mounted) return;
    final names = [
      for (final id in _attributes) all.firstWhere((a) => a.id == id).name,
    ];
    final combos = await showDialog<List<List<AttributeValue>>>(
      context: context,
      builder: (context) =>
          _VariantDialog(names: names, options: options, single: single),
    );
    if (combos == null || !mounted) return;
    var created = 0;
    final ok = await attempt(
      context,
      () async => created = await db.createVariants(_old!.id, combos),
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.variantsCreated(created))));
      setState(() => _hasVariantChildren = _hasVariantChildren || created > 0);
    }
  }

  List<Widget> _sales() {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    return [
      FieldGrid(
        children: [
          DropdownMenu<int?>(
            label: Text(l.defaultSalesUom),
            initialSelection: _salesUomId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) => setState(() => _salesUomId = v),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: null, label: l.none),
              for (final id in [?_uomId, for (final u in _units) u.uomId])
                DropdownMenuEntry(value: id, label: _uomName(id)),
            ],
          ),
          NumberField(
            label: l.maxDiscount,
            value: _maxDiscount,
            formats: formats,
            onChanged: (v) => _maxDiscount = v,
          ),
          SwitchListTile(
            title: Text(l.isSalesItem),
            value: _salesItem,
            onChanged: (on) => setState(() => _salesItem = on),
          ),
        ],
      ),
    ];
  }

  List<Widget> _tax() {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final templates = ref.watch(itemTaxTemplatesProvider).value ?? [];
    String title(int id) =>
        templates.where((t) => t.id == id).firstOrNull?.title ?? '';
    return [
      Text(l.itemTaxHelp, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: AppSpacing.sm),
      ChildTable<_Tax>(
        rows: _taxes,
        rowBuilder: (context, x) => ListTile(
          title: Text(title(x.templateId)),
          subtitle: x.validFrom == null
              ? null
              : Text(
                  '${l.validFrom}: ${formats.date(DateTime.parse(x.validFrom!))}',
                ),
        ),
        editorBuilder: (context, x) => _TaxEditor(
          row: x,
          templates: templates,
          formats: formats,
          onDone: (edited) => setState(() {
            if (x == null) {
              _taxes.add(edited);
            } else {
              _taxes[_taxes.indexOf(x)] = edited;
            }
          }),
          onDelete: x == null ? null : () => setState(() => _taxes.remove(x)),
        ),
      ),
    ];
  }
}

/// Stock Levels and Item Prices of a saved item, above its tabs.
class _Strip extends ConsumerWidget {
  const _Strip({required this.itemId, required this.template});

  final int itemId;
  final bool template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final chips = ref.watch(itemStripProvider(itemId)).value ?? const [];
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: c.stock
                  ? Chip(
                      avatar: const Icon(Icons.inventory_2_outlined),
                      label: Text('${c.label}: ${formats.number(c.value)}'),
                    )
                  : ActionChip(
                      avatar: const Icon(Icons.sell_outlined),
                      label: Text('${c.label}: ${formats.money(c.value)}'),
                      onPressed: () =>
                          context.go('/stock/item-price/${c.priceId}'),
                    ),
            ),
          if (!template)
            ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(l.addPrice),
              onPressed: () => context.go('/stock/item-price/new?item=$itemId'),
            ),
        ],
      ),
    );
  }
}

class _VariantList extends ConsumerWidget {
  const _VariantList({required this.templateId, required this.path});

  final int templateId;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(itemRowsProvider).value ?? const <ItemRow>[];
    return Column(
      children: [
        for (final r in rows)
          if (r.variantOf == templateId)
            ListTile(
              title: Text(r.code),
              subtitle: Text(r.name),
              onTap: () => context.go('$path/${r.id}'),
            ),
      ],
    );
  }
}

class _VariantDialog extends StatefulWidget {
  const _VariantDialog({
    required this.names,
    required this.options,
    required this.single,
  });

  final List<String> names;
  final List<List<AttributeValue>> options;
  final bool single;

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late final _ticked = [for (final _ in widget.options) <AttributeValue>{}];

  List<List<AttributeValue>> get _combos => _ticked.any((t) => t.isEmpty)
      ? const []
      : combinations([for (final t in _ticked) t.toList()]);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final combos = _combos;
    return AlertDialog(
      title: Text(widget.single ? l.singleVariant : l.multipleVariants),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, values) in widget.options.indexed) ...[
              SectionHeading(widget.names[i]),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final v in values)
                    widget.single
                        ? ChoiceChip(
                            label: Text(v.value),
                            selected: _ticked[i].contains(v),
                            onSelected: (_) => setState(
                              () => _ticked[i]
                                ..clear()
                                ..add(v),
                            ),
                          )
                        : FilterChip(
                            label: Text(v.value),
                            selected: _ticked[i].contains(v),
                            onSelected: (on) => setState(
                              () =>
                                  on ? _ticked[i].add(v) : _ticked[i].remove(v),
                            ),
                          ),
                ],
              ),
            ],
            if (!widget.single) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l.variantsToCreate(combos.length)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: combos.isEmpty
              ? null
              : () => Navigator.pop(context, combos),
          child: Text(l.create),
        ),
      ],
    );
  }
}

// ---- Row editors ---------------------------------------------------------------

class _BarcodeEditor extends StatefulWidget {
  const _BarcodeEditor({
    required this.row,
    required this.units,
    required this.uomName,
    required this.onDone,
    this.onDelete,
  });

  final _Barcode? row;
  final List<int> units;
  final String Function(int) uomName;
  final ValueChanged<_Barcode> onDone;
  final VoidCallback? onDelete;

  @override
  State<_BarcodeEditor> createState() => _BarcodeEditorState();
}

class _BarcodeEditorState extends State<_BarcodeEditor> {
  late final _code = TextEditingController(text: widget.row?.barcode);
  late String? _type = widget.row?.type;
  late int? _uomId = widget.row?.uomId;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = _code.text.trim();
    final valid = validBarcode(_type, code);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: valid
          ? () => widget.onDone((barcode: code, type: _type, uomId: _uomId))
          : null,
      children: [
        TextField(
          controller: _code,
          decoration: InputDecoration(
            labelText: '${l.barcode} *',
            errorText: code.isNotEmpty && !valid ? l.badBarcodeHelp : null,
            suffixIcon: ScanButton(
              onScanned: (c) => setState(() => _code.text = c),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        DropdownMenu<String?>(
          label: Text(l.barcodeType),
          initialSelection: _type,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _type = v),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: null, label: l.none),
            const DropdownMenuEntry(value: 'EAN', label: 'EAN'),
            const DropdownMenuEntry(value: 'UPC', label: 'UPC'),
          ],
        ),
        DropdownMenu<int?>(
          label: Text(l.uom),
          initialSelection: _uomId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _uomId = v),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: null, label: l.none),
            for (final u in widget.units)
              DropdownMenuEntry(value: u, label: widget.uomName(u)),
          ],
        ),
      ],
    );
  }
}

class _UnitEditor extends StatefulWidget {
  const _UnitEditor({
    required this.row,
    required this.uoms,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final _Unit? row;
  final List<UomData> uoms;
  final Formats formats;
  final ValueChanged<_Unit> onDone;
  final VoidCallback? onDelete;

  @override
  State<_UnitEditor> createState() => _UnitEditorState();
}

class _UnitEditorState extends State<_UnitEditor> {
  late int? _uomId = widget.row?.uomId;
  late var _factor = widget.row?.factor ?? 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _uomId == null || _factor <= 0
          ? null
          : () => widget.onDone((uomId: _uomId!, factor: _factor)),
      children: [
        DropdownMenu<int>(
          label: Text('${l.uom} *'),
          initialSelection: _uomId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _uomId = v),
          dropdownMenuEntries: [
            for (final u in widget.uoms)
              DropdownMenuEntry(value: u.id, label: u.name),
          ],
        ),
        NumberField(
          label: '${l.conversionFactor} *',
          value: _factor,
          formats: widget.formats,
          onChanged: (v) => setState(() => _factor = v),
        ),
      ],
    );
  }
}

class _ReorderEditor extends StatefulWidget {
  const _ReorderEditor({
    required this.row,
    required this.warehouses,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final _Reorder? row;
  final List<WarehouseData> warehouses;
  final Formats formats;
  final ValueChanged<_Reorder> onDone;
  final VoidCallback? onDelete;

  @override
  State<_ReorderEditor> createState() => _ReorderEditorState();
}

class _ReorderEditorState extends State<_ReorderEditor> {
  late int? _warehouseId = widget.row?.warehouseId;
  late var _level = widget.row?.level ?? 0;
  late var _qty = widget.row?.qty ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _warehouseId == null
          ? null
          : () => widget.onDone((
              warehouseId: _warehouseId!,
              level: _level,
              qty: _qty,
            )),
      children: [
        DropdownMenu<int>(
          label: Text('${l.warehouse} *'),
          initialSelection: _warehouseId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _warehouseId = v),
          dropdownMenuEntries: [
            for (final w in widget.warehouses)
              DropdownMenuEntry(value: w.id, label: w.name),
          ],
        ),
        NumberField(
          label: l.reorderLevel,
          value: _level,
          formats: widget.formats,
          onChanged: (v) => _level = v,
        ),
        NumberField(
          label: l.reorderQty,
          value: _qty,
          formats: widget.formats,
          onChanged: (v) => _qty = v,
        ),
      ],
    );
  }
}

class _TaxEditor extends StatefulWidget {
  const _TaxEditor({
    required this.row,
    required this.templates,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final _Tax? row;
  final List<ItemTaxTemplateData> templates;
  final Formats formats;
  final ValueChanged<_Tax> onDone;
  final VoidCallback? onDelete;

  @override
  State<_TaxEditor> createState() => _TaxEditorState();
}

class _TaxEditorState extends State<_TaxEditor> {
  late int? _templateId = widget.row?.templateId;
  late String? _from = widget.row?.validFrom;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _templateId == null
          ? null
          : () => widget.onDone((templateId: _templateId!, validFrom: _from)),
      children: [
        DropdownMenu<int>(
          label: Text('${l.itemTaxTemplate} *'),
          initialSelection: _templateId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _templateId = v),
          dropdownMenuEntries: [
            for (final t in widget.templates)
              if (t.disabled == 0 || t.id == _templateId)
                DropdownMenuEntry(value: t.id, label: t.title),
          ],
        ),
        DateField(
          label: l.validFrom,
          value: _from,
          formats: widget.formats,
          onChanged: (v) => setState(() => _from = v),
        ),
      ],
    );
  }
}

class _AttributeEditor extends StatefulWidget {
  const _AttributeEditor({
    required this.value,
    required this.attributes,
    required this.onDone,
    this.onDelete,
  });

  final int? value;
  final List<ItemAttributeData> attributes;
  final ValueChanged<int> onDone;
  final VoidCallback? onDelete;

  @override
  State<_AttributeEditor> createState() => _AttributeEditorState();
}

class _AttributeEditorState extends State<_AttributeEditor> {
  late int? _id = widget.value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _id == null ? null : () => widget.onDone(_id!),
      children: [
        DropdownMenu<int>(
          label: Text('${l.itemAttribute} *'),
          initialSelection: _id,
          expandedInsets: EdgeInsets.zero,
          onSelected: (v) => setState(() => _id = v),
          dropdownMenuEntries: [
            for (final a in widget.attributes)
              DropdownMenuEntry(value: a.id, label: a.name),
          ],
        ),
      ],
    );
  }
}

/// Keeps an Item form tab built while another one shows, so Save checks its
/// fields too (a "Not a number." left on another tab still stops Save).
class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

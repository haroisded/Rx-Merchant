import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/settings_pages.dart';
import '../../setup/ui/simple_masters.dart';
import '../../setup/ui/tax_template_pages.dart' show NumberField;
import '../data/stock_entry_db.dart';
import '../data/stock_lists.dart';
import '../data/stock_masters.dart';
import '../data/stock_reports.dart';
import '../logic/stock_rules.dart';
import '../logic/variants.dart';
import 'stock_providers.dart';

// UoM, Brand, Item Attribute, Item Price, Stock Settings, Batch and Serial
// No (02-stock sections 3 to 5).

const _loading = Scaffold(body: Center(child: CircularProgressIndicator()));

/// Deletes [label] after confirming, then returns to [path].
Future<void> deleteAndLeave(
  BuildContext context,
  String label,
  String path,
  Future<void> Function() delete,
) async {
  final l = AppLocalizations.of(context);
  if (!await confirm(
        context,
        title: l.deleteTitle,
        body: l.deleteBody(label),
        action: l.delete,
      ) ||
      !context.mounted) {
    return;
  }
  if (await attempt(context, delete) && context.mounted) context.go(path);
}

class UomPage extends ConsumerWidget {
  const UomPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(uomsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<UomData>(
        title: l.uom,
        rows: rows,
        labelOf: (u) => u.name,
        subtitleOf: (u) =>
            u.mustBeWholeNumber == 1 ? l.mustBeWholeNumber : null,
        isDisabled: (u) => u.enabled == 0,
        onOpen: (u) => context.go('$path/${u.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final u = recordFor(rows.value!, id, (u) => u.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: u?.name ?? l.newRecord(l.uom),
      listPath: path,
      name: u?.name ?? '',
      switches: [
        // STK-R3: a fractional quantity in this unit is refused.
        (l.mustBeWholeNumber, u?.mustBeWholeNumber == 1),
        (l.enabled, (u?.enabled ?? 1) == 1),
      ],
      onSave: (name, s, _, _) => db.saveUom(
        UomCompanion(
          id: u == null ? const Value.absent() : Value(u.id),
          name: Value(name),
          mustBeWholeNumber: Value(s[0] ? 1 : 0),
          enabled: Value(s[1] ? 1 : 0),
        ),
      ),
      onDelete: u == null ? null : () => db.deleteMaster(db.uom, u.id),
    );
  }
}

class BrandPage extends ConsumerWidget {
  const BrandPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(brandsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<BrandData>(
        title: l.brand,
        rows: rows,
        labelOf: (b) => b.name,
        subtitleOf: (b) => b.description,
        onOpen: (b) => context.go('$path/${b.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final b = recordFor(rows.value!, id, (b) => b.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: b?.name ?? l.newRecord(l.brand),
      listPath: path,
      name: b?.name ?? '',
      text: (l.description, b?.description ?? ''),
      switches: const [],
      onSave: (name, _, _, description) => db.saveBrand(
        BrandCompanion(
          id: b == null ? const Value.absent() : Value(b.id),
          name: Value(name),
          description: Value(description),
        ),
      ),
      onDelete: b == null ? null : () => db.deleteMaster(db.brand, b.id),
    );
  }
}

// ---- Item Attribute (STK-R15) ----------------------------------------------

typedef _Value = ({String value, String abbr});

class ItemAttributePage extends ConsumerWidget {
  const ItemAttributePage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(itemAttributesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<ItemAttributeData>(
        title: l.itemAttribute,
        rows: rows,
        labelOf: (a) => a.name,
        subtitleOf: (a) => a.numericValues == 1 ? l.numericValues : null,
        onOpen: (a) => context.go('$path/${a.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    return _ItemAttributeForm(
      key: ValueKey(id),
      path: path,
      attribute: recordFor(rows.value!, id, (a) => a.id),
    );
  }
}

class _ItemAttributeForm extends ConsumerStatefulWidget {
  const _ItemAttributeForm({super.key, required this.path, this.attribute});

  final String path;
  final ItemAttributeData? attribute;

  @override
  ConsumerState<_ItemAttributeForm> createState() => _ItemAttributeFormState();
}

class _ItemAttributeFormState extends ConsumerState<_ItemAttributeForm> {
  late final _name = TextEditingController(text: widget.attribute?.name);
  late var _numeric = widget.attribute?.numericValues == 1;
  late var _from = widget.attribute?.fromRange ?? 0;
  late var _to = widget.attribute?.toRange ?? 0;
  late var _increment = widget.attribute?.increment ?? 1;
  List<_Value>? _values;

  @override
  void initState() {
    super.initState();
    final a = widget.attribute;
    if (a == null) {
      _values = [];
      return;
    }
    final db = ref.read(appDatabaseProvider);
    (db.select(db.itemAttributeValue)
          ..where((v) => v.attributeId.equals(a.id))
          ..orderBy([(v) => OrderingTerm(expression: v.id)]))
        .get()
        .then((rows) {
          if (mounted) {
            setState(
              () => _values = [
                for (final r in rows) (value: r.attributeValue, abbr: r.abbr),
              ],
            );
          }
        });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    final values = _values!;
    final problems = [
      if (_numeric && numericValues(_from, _to, _increment).isEmpty)
        l.badNumericRange,
      if (!_numeric && values.isEmpty) l.attributeNeedsValues,
    ];
    if (problems.isNotEmpty) {
      await showProblems(context, problems);
      return false;
    }
    final a = widget.attribute;
    final ok = await attempt(
      context,
      () => ref.read(appDatabaseProvider).saveItemAttribute(
        ItemAttributeCompanion(
          id: a == null ? const Value.absent() : Value(a.id),
          name: Value(_name.text.trim()),
          numericValues: Value(_numeric ? 1 : 0),
          fromRange: Value(_numeric ? _from : null),
          toRange: Value(_numeric ? _to : null),
          increment: Value(_numeric ? _increment : null),
        ),
        [
          if (!_numeric)
            for (final v in values)
              ItemAttributeValueCompanion.insert(
                attributeId: 0,
                attributeValue: v.value,
                abbr: v.abbr,
              ),
        ],
      ),
      done: l.saved,
    );
    if (ok && mounted) context.go(widget.path);
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final values = _values;
    final formats = ref.watch(formatsProvider);
    if (values == null) return _loading;
    final a = widget.attribute;
    final db = ref.read(appDatabaseProvider);
    return FormPage(
      title: a?.name ?? l.newRecord(l.itemAttribute),
      onSave: _save,
      onDelete: a == null
          ? null
          : () => deleteAndLeave(
              context,
              a.name,
              widget.path,
              () => db.deleteMaster(db.itemAttribute, a.id),
            ),
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.attributeName} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            SwitchListTile(
              title: Text(l.numericValues),
              value: _numeric,
              onChanged: (on) => setState(() => _numeric = on),
            ),
            if (_numeric) ...[
              NumberField(
                label: l.fromRange,
                value: _from,
                formats: formats,
                onChanged: (v) => setState(() => _from = v),
              ),
              NumberField(
                label: l.toRange,
                value: _to,
                formats: formats,
                onChanged: (v) => setState(() => _to = v),
              ),
              NumberField(
                label: l.increment,
                value: _increment,
                formats: formats,
                onChanged: (v) => setState(() => _increment = v),
              ),
            ],
          ],
        ),
        if (_numeric)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(numericValues(_from, _to, _increment).join(', ')),
          )
        else ...[
          SectionHeading(l.attributeValues),
          ChildTable<_Value>(
            rows: values,
            rowBuilder: (context, v) =>
                ListTile(title: Text(v.value), subtitle: Text(v.abbr)),
            editorBuilder: (context, v) => _ValueEditor(
              value: v,
              onDone: (edited) => setState(() {
                if (v == null) {
                  values.add(edited);
                } else {
                  values[values.indexOf(v)] = edited;
                }
              }),
              onDelete: v == null
                  ? null
                  : () => setState(() => values.remove(v)),
            ),
          ),
        ],
      ],
    );
  }
}

class _ValueEditor extends StatefulWidget {
  const _ValueEditor({
    required this.value,
    required this.onDone,
    this.onDelete,
  });

  final _Value? value;
  final ValueChanged<_Value> onDone;
  final VoidCallback? onDelete;

  @override
  State<_ValueEditor> createState() => _ValueEditorState();
}

class _ValueEditorState extends State<_ValueEditor> {
  late final _value = TextEditingController(text: widget.value?.value);
  late final _abbr = TextEditingController(text: widget.value?.abbr);

  @override
  void dispose() {
    _value.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: _value.text.trim().isEmpty || _abbr.text.trim().isEmpty
          ? null
          : () => widget.onDone((
              value: _value.text.trim(),
              abbr: _abbr.text.trim(),
            )),
      children: [
        TextField(
          controller: _value,
          decoration: InputDecoration(labelText: '${l.attributeValue} *'),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _abbr,
          decoration: InputDecoration(labelText: '${l.abbreviation} *'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// ---- Item Price (STK-R10) ----------------------------------------------------

typedef PriceRow = ({
  ItemPriceData price,
  String item,
  String list,
  String uom,
});

final _itemPricesProvider = StreamProvider<List<PriceRow>>(
  (ref) => ref.watch(appDatabaseProvider).watchItemPrices(),
);

class ItemPricePage extends ConsumerWidget {
  const ItemPricePage({
    super.key,
    required this.path,
    this.id,
    this.query = const {},
  });

  final String path;
  final String? id;

  /// `item`: the item a new price is for (from the item form's strip).
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(_itemPricesProvider);
    final formats = ref.watch(formatsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<PriceRow>(
        title: l.itemPrice,
        rows: rows,
        labelOf: (r) => '${r.item} · ${r.list}',
        subtitleOf: (r) => '${formats.money(r.price.priceListRate)} / ${r.uom}',
        onOpen: (r) => context.go('$path/${r.price.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue ||
        !ref.watch(itemRowsProvider).hasValue ||
        !ref.watch(priceListsProvider).hasValue ||
        !ref.watch(uomsProvider).hasValue) {
      return _loading;
    }
    final row = recordFor(rows.value!, id, (r) => r.price.id);
    return _ItemPriceForm(
      key: ValueKey(id),
      path: path,
      price: row?.price,
      itemId: row?.price.itemId ?? int.tryParse(query['item'] ?? ''),
    );
  }
}

class _ItemPriceForm extends ConsumerStatefulWidget {
  const _ItemPriceForm({
    super.key,
    required this.path,
    this.price,
    this.itemId,
  });

  final String path;
  final ItemPriceData? price;
  final int? itemId;

  @override
  ConsumerState<_ItemPriceForm> createState() => _ItemPriceFormState();
}

class _ItemPriceFormState extends ConsumerState<_ItemPriceForm> {
  late int? _itemId = widget.itemId;
  late int? _listId = widget.price?.priceListId;
  late int? _uomId = widget.price?.uomId;
  late int? _batchId = widget.price?.batchId;
  late var _rate = widget.price?.priceListRate ?? 0;
  late String? _from = widget.price?.validFrom;
  late String? _upto = widget.price?.validUpto;
  late final _note = TextEditingController(text: widget.price?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final lists = ref.watch(priceListsProvider).value ?? [];
    final uoms = ref.watch(uomsProvider).value ?? [];
    final itemId = _itemId;
    final it = items.where((i) => i.id == itemId).firstOrNull;
    final units = itemId == null
        ? const <({int uomId, double factor})>[]
        : ref.watch(itemUnitsProvider(itemId)).value ?? const [];
    final itemBatches = itemId == null
        ? const <BatchRow>[]
        : ref.watch(itemBatchesProvider(itemId)).value ?? const [];
    _listId ??= lists
        .where(
          (p) =>
              p.name ==
              SellingSettings(
                ref.watch(singleProvider(SellingSettings.doctype)).value ??
                    const {},
              ).sellingPriceList,
        )
        .firstOrNull
        ?.id;
    final p = widget.price;
    final db = ref.read(appDatabaseProvider);
    String uomName(int id) => uoms.firstWhere((u) => u.id == id).name;

    return FormPage(
      title: p == null
          ? l.newRecord(l.itemPrice)
          : '${it?.code} · ${formats.money(p.priceListRate)}',
      onSave: () async {
        final problems = [
          if (itemId == null) l.fieldMissing(l.item),
          if (_listId == null) l.fieldMissing(l.priceList),
          if (_from != null && _upto != null && _upto!.compareTo(_from!) < 0)
            l.validUptoBeforeFrom,
        ];
        if (problems.isNotEmpty) {
          await showProblems(context, problems);
          return false;
        }
        final ok = await attempt(
          context,
          () => db.saveItemPrice(
            ItemPriceCompanion(
              id: p == null ? const Value.absent() : Value(p.id),
              itemId: Value(itemId!),
              priceListId: Value(_listId!),
              uomId: Value(_uomId ?? it?.stockUomId),
              priceListRate: Value(_rate),
              validFrom: Value(_from),
              validUpto: Value(_upto),
              batchId: Value(_batchId),
              note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
        return ok;
      },
      onDelete: p == null
          ? null
          : () => deleteAndLeave(
              context,
              it?.code ?? '',
              widget.path,
              () => db.deleteMaster(db.itemPrice, p.id),
            ),
      children: [
        FieldGrid(
          children: [
            LinkField<ItemRow>(
              label: l.item,
              mandatory: true,
              value: it,
              search: (q) async => [
                for (final r in await searchItems(items, q))
                  if (!r.template) r,
              ],
              labelOf: (r) => '${r.code} · ${r.name}',
              onChanged: (r) => setState(() {
                _itemId = r?.id;
                _uomId = null;
                _batchId = null;
              }),
            ),
            DropdownMenu<int>(
              key: ValueKey('list$_listId'),
              label: Text('${l.priceList} *'),
              initialSelection: _listId,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _listId = v),
              dropdownMenuEntries: [
                for (final pl in lists)
                  if (pl.enabled == 1 || pl.id == _listId)
                    DropdownMenuEntry(value: pl.id, label: pl.name),
              ],
            ),
            DropdownMenu<int>(
              key: ValueKey('uom$itemId${units.length}'),
              label: Text(l.uom),
              initialSelection: _uomId ?? it?.stockUomId,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _uomId = v),
              dropdownMenuEntries: [
                for (final u in units)
                  DropdownMenuEntry(value: u.uomId, label: uomName(u.uomId)),
              ],
            ),
            NumberField(
              label: '${l.rate} *',
              value: _rate,
              formats: formats,
              precision: formats.system.currencyPrecision,
              onChanged: (v) => _rate = v,
            ),
            DateField(
              label: l.validFrom,
              value: _from,
              formats: formats,
              onChanged: (v) => setState(() => _from = v),
            ),
            DateField(
              label: l.validUpto,
              value: _upto,
              formats: formats,
              onChanged: (v) => setState(() => _upto = v),
            ),
            if (itemBatches.isNotEmpty)
              DropdownMenu<int?>(
                label: Text(l.batch),
                initialSelection: _batchId,
                expandedInsets: EdgeInsets.zero,
                onSelected: (v) => setState(() => _batchId = v),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: null, label: l.none),
                  for (final b in itemBatches)
                    DropdownMenuEntry(value: b.id, label: b.batchId),
                ],
              ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Stock Settings (STK-B4) ------------------------------------------------

final _valuationLockedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(appDatabaseProvider).valuationMethodLocked(),
);

class StockSettingsPage extends ConsumerWidget {
  const StockSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final groups = ref.watch(itemGroupsProvider).value;
    final uoms = ref.watch(uomsProvider).value;
    final warehouses = ref.watch(warehousesProvider).value;
    final locked = ref.watch(_valuationLockedProvider).value;
    if (groups == null ||
        uoms == null ||
        warehouses == null ||
        locked == null) {
      return _loading;
    }
    String flag(bool on) => on ? '1' : '0';
    SingleField check(
      String key,
      String label,
      bool Function(StockSettings) read,
    ) => SingleField(
      key,
      label,
      kind: FieldKind.check,
      read: (v) => flag(read(StockSettings(v))),
    );
    return SinglesForm(
      doctype: StockSettings.doctype,
      title: l.stockSettings,
      sections: [
        (
          l.sectionDefaults,
          [
            SingleField(
              'item_naming_by',
              l.itemNamingBy,
              kind: FieldKind.choice,
              options: const ['Item Code', 'Naming Series'],
              read: (v) => StockSettings(v).itemNamingBy,
            ),
            SingleField(
              'item_group',
              l.defaultItemGroup,
              kind: FieldKind.choice,
              options: [for (final g in groups) g.name],
              read: (v) => StockSettings(v).itemGroup,
            ),
            SingleField(
              'stock_uom',
              l.defaultStockUom,
              kind: FieldKind.choice,
              options: [
                for (final u in uoms)
                  if (u.enabled == 1) u.name,
              ],
              read: (v) => StockSettings(v).stockUom,
            ),
            // STK-R1: the Cash Register sells from it.
            SingleField(
              'default_warehouse',
              l.defaultWarehouse,
              kind: FieldKind.choice,
              options: [for (final w in usable(warehouses)) w.name],
              read: (v) => StockSettings(v).defaultWarehouse,
            ),
            SingleField(
              'valuation_method',
              l.defaultValuationMethod,
              kind: FieldKind.choice,
              options: const ['FIFO', 'Moving Average'],
              lockReason: locked ? l.lockedValuationMethod : null,
              read: (v) => StockSettings(v).valuationMethod,
            ),
          ],
        ),
        (
          l.sectionStockTransactions,
          [
            check(
              'show_barcode_field',
              l.showBarcodeField,
              (s) => s.showBarcodeField,
            ),
            check(
              'auto_insert_price_list_rate_if_missing',
              l.autoInsertPriceListRate,
              (s) => s.autoInsertPriceListRateIfMissing,
            ),
            check(
              'allow_negative_stock',
              l.allowNegativeStock,
              (s) => s.allowNegativeStock,
            ),
            check('auto_indent', l.showLowStockAlerts, (s) => s.autoIndent),
            SingleField(
              'stock_frozen_upto',
              l.stockFrozenUpto,
              kind: FieldKind.date,
              read: (v) => StockSettings(v).stockFrozenUpto ?? '',
            ),
          ],
        ),
        (
          l.groupSerialAndBatch,
          [
            check(
              'enable_serial_and_batch_no_for_item',
              l.enableSerialAndBatch,
              (s) => s.enableSerialAndBatchNoForItem,
            ),
            SingleField(
              'pick_serial_and_batch_based_on',
              l.pickSerialBatchBasedOn,
              kind: FieldKind.choice,
              options: const ['FIFO', 'LIFO', 'Expiry'],
              read: (v) => StockSettings(v).pickSerialAndBatchBasedOn,
            ),
            check(
              'auto_create_serial_and_batch_bundle_for_outward',
              l.autoCreateBundleForOutward,
              (s) => s.autoCreateSerialAndBatchBundleForOutward,
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Batch (STK-R19) ---------------------------------------------------------

final _batchesProvider = StreamProvider<List<BatchListRow>>(
  (ref) => ref.watch(appDatabaseProvider).watchBatchList(),
);

String batchStatusText(AppLocalizations l, String? expiry) =>
    switch (batchStatus(expiry, toStorage(DateTime.now()).substring(0, 10))) {
      BatchStatus.notSet => l.batchNotSet,
      BatchStatus.notExpired => l.batchNotExpired,
      BatchStatus.expired => l.batchExpired,
    };

class BatchPage extends ConsumerWidget {
  const BatchPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(_batchesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<BatchListRow>(
        title: l.batch,
        rows: rows,
        labelOf: (r) => r.batch.batchId,
        subtitleOf: (r) =>
            '${r.item} · ${batchStatusText(l, r.batch.expiryDate)}',
        isDisabled: (r) => r.batch.disabled == 1,
        onOpen: (r) => context.go('$path/${r.batch.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue || !ref.watch(itemRowsProvider).hasValue) {
      return _loading;
    }
    return _BatchForm(
      key: ValueKey(id),
      path: path,
      batch: recordFor(rows.value!, id, (r) => r.batch.id)?.batch,
    );
  }
}

class _BatchForm extends ConsumerStatefulWidget {
  const _BatchForm({super.key, required this.path, this.batch});

  final String path;
  final BatchRow? batch;

  @override
  ConsumerState<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends ConsumerState<_BatchForm> {
  late final _batchId = TextEditingController(text: widget.batch?.batchId);
  late int? _itemId = widget.batch?.itemId;
  late String? _made = widget.batch?.manufacturingDate;
  late String? _expiry = widget.batch?.expiryDate;
  late var _disabled = widget.batch?.disabled == 1;

  @override
  void dispose() {
    _batchId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final b = widget.batch;
    final db = ref.read(appDatabaseProvider);
    final it = items.where((i) => i.id == _itemId).firstOrNull;
    return FormPage(
      title: b?.batchId ?? l.newRecord(l.batch),
      actions: [if (b != null) StatusChip(batchStatusText(l, _expiry))],
      onSave: () async {
        final problems = [if (_itemId == null) l.fieldMissing(l.item)];
        if (problems.isNotEmpty) {
          await showProblems(context, problems);
          return false;
        }
        final ok = await attempt(
          context,
          () => db.saveBatch(
            BatchesCompanion(
              id: b == null ? const Value.absent() : Value(b.id),
              batchId: Value(_batchId.text.trim()),
              itemId: Value(_itemId!),
              manufacturingDate: Value(_made),
              expiryDate: Value(_expiry),
              disabled: Value(_disabled ? 1 : 0),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
        return ok;
      },
      onDelete: b == null
          ? null
          : () => deleteAndLeave(
              context,
              b.batchId,
              widget.path,
              () => db.deleteMaster(db.batches, b.id),
            ),
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _batchId,
              readOnly: b != null,
              decoration: InputDecoration(labelText: '${l.batchId} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            if (b == null)
              LinkField<ItemRow>(
                label: l.item,
                mandatory: true,
                value: it,
                search: (q) async => [
                  for (final r in await searchItems(items, q, stockOnly: true))
                    if (r.hasBatch) r,
                ],
                labelOf: (r) => '${r.code} · ${r.name}',
                onChanged: (r) => setState(() => _itemId = r?.id),
              )
            else
              InputDecorator(
                decoration: InputDecoration(labelText: l.item),
                child: Text('${it?.code} · ${it?.name}'),
              ),
            DateField(
              label: l.manufacturingDate,
              value: _made,
              formats: formats,
              onChanged: (v) => setState(() => _made = v),
            ),
            DateField(
              label: l.expiryDate,
              value: _expiry,
              formats: formats,
              onChanged: (v) => setState(() => _expiry = v),
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
        if (b != null) ...[
          SectionHeading(l.stockLevels),
          _BatchStock(batchId: b.id),
        ],
      ],
    );
  }
}

/// Quantity of one batch per warehouse.
class _BatchStock extends ConsumerWidget {
  const _BatchStock({required this.batchId});

  final int batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final formats = ref.watch(formatsProvider);
    return FutureBuilder(
      future: db.batchStock(batchId),
      builder: (context, snap) => Column(
        children: [
          for (final (warehouse, qty)
              in snap.data ?? const <(String, double)>[])
            ListTile(
              title: Text(warehouse),
              trailing: Text(formats.number(qty)),
            ),
        ],
      ),
    );
  }
}

// ---- Serial No (STK-R23, R24) ------------------------------------------------

final _serialsProvider = StreamProvider<List<SerialListRow>>(
  (ref) => ref.watch(appDatabaseProvider).watchSerialList(),
);

class SerialNoPage extends ConsumerWidget {
  const SerialNoPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(_serialsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<SerialListRow>(
        title: l.serialNo,
        rows: rows,
        labelOf: (r) => r.serial.serialNo,
        subtitleOf: (r) =>
            [r.item, l.serialStatus(r.serial.status), ?r.warehouse].join(' · '),
        onOpen: (r) => context.go('$path/${r.serial.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue || !ref.watch(itemRowsProvider).hasValue) {
      return _loading;
    }
    return _SerialForm(
      key: ValueKey(id),
      path: path,
      row: recordFor(rows.value!, id, (r) => r.serial.id),
    );
  }
}

class _SerialForm extends ConsumerStatefulWidget {
  const _SerialForm({super.key, required this.path, this.row});

  final String path;
  final SerialListRow? row;

  @override
  ConsumerState<_SerialForm> createState() => _SerialFormState();
}

class _SerialFormState extends ConsumerState<_SerialForm> {
  late final _serial = TextEditingController(text: widget.row?.serial.serialNo);
  late int? _itemId = widget.row?.serial.itemId;
  late int? _batchId = widget.row?.serial.batchId;
  late String? _warranty = widget.row?.serial.warrantyExpiryDate;

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final s = widget.row?.serial;
    final db = ref.read(appDatabaseProvider);
    final it = items.where((i) => i.id == _itemId).firstOrNull;
    final itemBatches = _itemId == null
        ? const <BatchRow>[]
        : ref.watch(itemBatchesProvider(_itemId!)).value ?? const [];
    return FormPage(
      title: s?.serialNo ?? l.newRecord(l.serialNo),
      actions: [if (s != null) StatusChip(l.serialStatus(s.status))],
      onSave: () async {
        final problems = [if (_itemId == null) l.fieldMissing(l.item)];
        if (problems.isNotEmpty) {
          await showProblems(context, problems);
          return false;
        }
        final ok = await attempt(
          context,
          () => db.saveSerialNo(
            SerialNoCompanion(
              id: s == null ? const Value.absent() : Value(s.id),
              serialNo: Value(_serial.text.trim()),
              itemId: Value(_itemId!),
              batchId: Value(_batchId),
              warrantyExpiryDate: Value(_warranty),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
        return ok;
      },
      onDelete: s == null
          ? null
          : () => deleteAndLeave(
              context,
              s.serialNo,
              widget.path,
              () => db.deleteMaster(db.serialNo, s.id),
            ),
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _serial,
              readOnly: s != null,
              decoration: InputDecoration(labelText: '${l.serialNo} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            if (s == null)
              LinkField<ItemRow>(
                label: l.item,
                mandatory: true,
                value: it,
                search: (q) async => [
                  for (final r in await searchItems(items, q, stockOnly: true))
                    if (r.hasSerial) r,
                ],
                labelOf: (r) => '${r.code} · ${r.name}',
                onChanged: (r) => setState(() {
                  _itemId = r?.id;
                  _batchId = null;
                }),
              )
            else
              InputDecorator(
                decoration: InputDecoration(labelText: l.item),
                child: Text('${it?.code} · ${it?.name}'),
              ),
            if (s != null)
              InputDecorator(
                decoration: InputDecoration(labelText: l.warehouse),
                child: Text(widget.row?.warehouse ?? ''),
              ),
            if (itemBatches.isNotEmpty)
              DropdownMenu<int?>(
                label: Text(l.batch),
                initialSelection: _batchId,
                expandedInsets: EdgeInsets.zero,
                onSelected: (v) => setState(() => _batchId = v),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: null, label: l.none),
                  for (final b in itemBatches)
                    DropdownMenuEntry(value: b.id, label: b.batchId),
                ],
              ),
            DateField(
              label: l.warrantyExpiryDate,
              value: _warranty,
              formats: formats,
              onChanged: (v) => setState(() => _warranty = v),
            ),
          ],
        ),
        if (s != null) ...[
          SectionHeading(l.reportSerialNoLedger),
          FutureBuilder(
            future: db.serialLedgerReport(StockFilters(serialId: s.id)),
            builder: (context, snap) => Column(
              children: [
                for (final r in snap.data ?? const <List<Object?>>[])
                  ListTile(
                    title: Text('${r[3]} · ${r[4]}'),
                    subtitle: Text(
                      formats.date(DateTime.parse(r[0]! as String)),
                    ),
                    trailing: Text(l.serialStatus(r[6]! as String)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

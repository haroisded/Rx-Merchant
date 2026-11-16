import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/setup_queries.dart';
import 'form_kit.dart';
import 'simple_masters.dart';

// POS Profile (SET-R14): how the cash register behaves.

final posProfilesProvider = StreamProvider<List<PosProfileData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.posProfile).watch();
});

/// What the profile's links can point at, read before the form is built: a
/// DropdownMenu shows its initial selection only if its entries exist then.
typedef _Choices = ({
  List<WarehouseData> warehouses,
  List<ItemGroupData> itemGroups,
  List<LetterHeadData> letterHeads,
  List<PrintHeadingData> printHeadings,
  List<TermsAndCondition> terms,
  List<ModeOfPaymentData> modes,
  List<PriceListData> priceLists,
  List<SalesTaxesTemplateData> templates,
});

final _choicesProvider = FutureProvider.autoDispose<_Choices>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return (
    // SET-R14: a group warehouse holds no stock.
    warehouses: await (db.select(
      db.warehouse,
    )..where((w) => w.isGroup.equals(0) & w.disabled.equals(0))).get(),
    itemGroups: await db.select(db.itemGroup).get(),
    letterHeads: await (db.select(
      db.letterHead,
    )..where((h) => h.disabled.equals(0))).get(),
    printHeadings: await db.select(db.printHeading).get(),
    terms: await (db.select(
      db.termsAndConditions,
    )..where((t) => t.disabled.equals(0))).get(),
    modes: await db.select(db.modeOfPayment).get(),
    priceLists: await db.select(db.priceList).get(),
    templates: await db.select(db.salesTaxesTemplate).get(),
  );
});

class PosProfilePage extends ConsumerWidget {
  const PosProfilePage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(posProfilesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<PosProfileData>(
        title: l.posProfile,
        rows: rows,
        labelOf: (p) => p.name,
        subtitleOf: (p) => p.isDefault == 1 ? l.isDefault : null,
        isDisabled: (p) => p.disabled == 1,
        onOpen: (p) => context.go('$path/${p.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    final choices = ref.watch(_choicesProvider);
    if (!rows.hasValue || !choices.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _PosProfileForm(
      key: ValueKey(id),
      path: path,
      profile: recordFor(rows.value!, id, (p) => p.id),
      choices: choices.value!,
    );
  }
}

typedef _Payment = ({int? modeId, bool isDefault, bool allowInReturns});

const _actionsOnNewInvoice = [
  'Always Ask',
  'Save Changes and Load New Invoice',
  'Discard Changes and Load New Invoice',
];

class _PosProfileForm extends ConsumerStatefulWidget {
  const _PosProfileForm({
    super.key,
    required this.path,
    required this.profile,
    required this.choices,
  });

  final String path;
  final PosProfileData? profile;
  final _Choices choices;

  @override
  ConsumerState<_PosProfileForm> createState() => _PosProfileFormState();
}

class _PosProfileFormState extends ConsumerState<_PosProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.name);
  late PosProfileCompanion _p =
      widget.profile?.toCompanion(false) ??
      const PosProfileCompanion(
        isDefault: Value(0),
        disabled: Value(0),
        applyDiscountOn: Value('Grand Total'),
        hideImages: Value(0),
        hideUnavailableItems: Value(0),
        allowRateChange: Value(0),
        autoAddItemToCart: Value(0),
        allowDiscountChange: Value(0),
        validateStockOnSave: Value(0),
        setGrandTotalToDefaultMop: Value(1),
        printReceiptOnOrderComplete: Value(0),
        actionOnNewInvoice: Value('Always Ask'),
        printFormat: Value('POS Receipt'),
        taxesTemplateId: Value(null),
        letterHeadId: Value(null),
        printHeadingId: Value(null),
        tcId: Value(null),
      );
  List<_Payment>? _payments;
  Set<int>? _groups;

  @override
  void initState() {
    super.initState();
    final id = widget.profile?.id;
    if (id == null) {
      _payments = [];
      _groups = {};
      return;
    }
    ref.read(appDatabaseProvider).posProfileLines(id).then((lines) {
      if (!mounted) return;
      setState(() {
        _payments = [
          for (final p in lines.payments)
            (
              modeId: p.modeOfPaymentId,
              isDefault: p.isDefault == 1,
              allowInReturns: p.allowInReturns == 1,
            ),
        ];
        _groups = lines.itemGroupIds;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _set(PosProfileCompanion p) => setState(() => _p = p);

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final problems = [
      if (!_formKey.currentState!.validate()) l.formHasErrors,
      if (!_p.warehouseId.present) l.fieldMissing(l.warehouse),
      if (!_p.priceListId.present) l.fieldMissing(l.priceList),
      for (final (i, p) in _payments!.indexed)
        if (p.modeId == null)
          l.rowProblem(i + 1, l.fieldMissing(l.modeOfPayment)),
    ];
    if (problems.isNotEmpty) return showProblems(context, problems);
    final ok = await attempt(
      context,
      () => ref.read(appDatabaseProvider).savePosProfile(
        _p.copyWith(name: Value(_name.text.trim())),
        [
          for (final p in _payments!)
            PosProfilePaymentCompanion(
              modeOfPaymentId: Value(p.modeId!),
              isDefault: Value(p.isDefault ? 1 : 0),
              allowInReturns: Value(p.allowInReturns ? 1 : 0),
            ),
        ],
        _groups!,
      ),
      done: l.saved,
    );
    if (ok && mounted) context.go(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final payments = _payments;
    final groups = _groups;
    if (payments == null || groups == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = widget.choices;
    final (modes, lists, templates) = (c.modes, c.priceLists, c.templates);
    final profile = widget.profile;
    String modeName(int? id) =>
        modes.where((m) => m.id == id).firstOrNull?.name ?? '';

    Widget flag(
      String label,
      Value<int> value,
      PosProfileCompanion Function(Value<int>) set,
    ) => SwitchListTile(
      title: Text(label),
      value: value.value == 1,
      onChanged: (on) => _set(set(Value(on ? 1 : 0))),
    );

    Widget optional<T extends Object>(
      String label,
      int? selected,
      List<T> options,
      int Function(T) idOf,
      String Function(T) nameOf,
      void Function(int?) onSelected,
    ) => DropdownMenu<int>(
      label: Text(label),
      initialSelection: selected,
      expandedInsets: EdgeInsets.zero,
      onSelected: (id) => onSelected(id == -1 ? null : id),
      dropdownMenuEntries: [
        DropdownMenuEntry(value: -1, label: l.none),
        for (final o in options)
          DropdownMenuEntry(value: idOf(o), label: nameOf(o)),
      ],
    );

    return FormPage(
      title: profile?.name ?? l.newRecord(l.posProfile),
      formKey: _formKey,
      onSave: _save,
      onDelete: profile == null
          ? null
          : () async {
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(profile.name),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              final db = ref.read(appDatabaseProvider);
              if (await attempt(
                    context,
                    () => db.deletePosProfile(profile.id),
                  ) &&
                  context.mounted) {
                context.go(widget.path);
              }
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.name} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            DropdownMenu<int>(
              label: Text('${l.warehouse} *'),
              initialSelection: _p.warehouseId.present
                  ? _p.warehouseId.value
                  : null,
              expandedInsets: EdgeInsets.zero,
              onSelected: (id) => _set(_p.copyWith(warehouseId: Value(id!))),
              dropdownMenuEntries: [
                for (final w in c.warehouses)
                  DropdownMenuEntry(value: w.id, label: w.name),
              ],
            ),
            flag(l.isDefault, _p.isDefault, (v) => _p.copyWith(isDefault: v)),
            flag(l.disabled, _p.disabled, (v) => _p.copyWith(disabled: v)),
          ],
        ),
        SectionHeading(l.paymentMethods),
        ChildTable<_Payment>(
          rows: payments,
          rowBuilder: (context, p) => ListTile(
            title: Text(modeName(p.modeId)),
            subtitle: Text(
              [
                if (p.isDefault) l.isDefault,
                if (p.allowInReturns) l.allowInReturns,
              ].join(' · '),
            ),
          ),
          editorBuilder: (context, p) => _PaymentEditor(
            row: p,
            modes: [
              for (final m in modes)
                if (m.enabled == 1 || m.id == p?.modeId) m,
            ],
            onDone: (edited) => setState(() {
              if (p == null) {
                payments.add(edited);
              } else {
                payments[payments.indexOf(p)] = edited;
              }
            }),
            onDelete: p == null
                ? null
                : () => setState(() => payments.remove(p)),
          ),
        ),
        if (payments.isEmpty)
          Text(
            l.noPaymentMethodsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        SectionHeading(l.configurations),
        FieldGrid(
          children: [
            flag(
              l.hideImages,
              _p.hideImages,
              (v) => _p.copyWith(hideImages: v),
            ),
            flag(
              l.hideUnavailableItems,
              _p.hideUnavailableItems,
              (v) => _p.copyWith(hideUnavailableItems: v),
            ),
            flag(
              l.allowRateChange,
              _p.allowRateChange,
              (v) => _p.copyWith(allowRateChange: v),
            ),
            flag(
              l.autoAddItemToCart,
              _p.autoAddItemToCart,
              (v) => _p.copyWith(autoAddItemToCart: v),
            ),
            flag(
              l.allowDiscountChange,
              _p.allowDiscountChange,
              (v) => _p.copyWith(allowDiscountChange: v),
            ),
            flag(
              l.validateStockOnSave,
              _p.validateStockOnSave,
              (v) => _p.copyWith(validateStockOnSave: v),
            ),
            flag(
              l.setGrandTotalToDefaultMop,
              _p.setGrandTotalToDefaultMop,
              (v) => _p.copyWith(setGrandTotalToDefaultMop: v),
            ),
            flag(
              l.printReceiptOnOrderComplete,
              _p.printReceiptOnOrderComplete,
              (v) => _p.copyWith(printReceiptOnOrderComplete: v),
            ),
            DropdownMenu<String>(
              label: Text(l.actionOnNewInvoice),
              initialSelection: _p.actionOnNewInvoice.value,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) =>
                  _set(_p.copyWith(actionOnNewInvoice: Value(v!))),
              dropdownMenuEntries: [
                for (final a in _actionsOnNewInvoice)
                  DropdownMenuEntry(value: a, label: a),
              ],
            ),
          ],
        ),
        SectionHeading(l.itemGroups),
        Text(l.itemGroupsHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final g in c.itemGroups)
              FilterChip(
                label: Text(g.name),
                selected: groups.contains(g.id),
                onSelected: (on) =>
                    setState(() => on ? groups.add(g.id) : groups.remove(g.id)),
              ),
          ],
        ),
        SectionHeading(l.printSettings),
        FieldGrid(
          children: [
            DropdownMenu<String>(
              label: Text(l.printFormat),
              initialSelection: _p.printFormat.value,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => _set(_p.copyWith(printFormat: Value(v!))),
              dropdownMenuEntries: [
                for (final f in const ['POS Receipt', 'Standard'])
                  DropdownMenuEntry(value: f, label: f),
              ],
            ),
            optional(
              l.letterHead,
              _p.letterHeadId.value,
              c.letterHeads,
              (h) => h.id,
              (h) => h.name,
              (id) => _set(_p.copyWith(letterHeadId: Value(id))),
            ),
            optional(
              l.printHeading,
              _p.printHeadingId.value,
              c.printHeadings,
              (h) => h.id,
              (h) => h.name,
              (id) => _set(_p.copyWith(printHeadingId: Value(id))),
            ),
            optional(
              l.termsAndConditions,
              _p.tcId.value,
              c.terms,
              (t) => t.id,
              (t) => t.title,
              (id) => _set(_p.copyWith(tcId: Value(id))),
            ),
          ],
        ),
        SectionHeading(l.pricingAndTaxes),
        FieldGrid(
          children: [
            DropdownMenu<int>(
              label: Text('${l.priceList} *'),
              initialSelection: _p.priceListId.present
                  ? _p.priceListId.value
                  : null,
              expandedInsets: EdgeInsets.zero,
              onSelected: (id) => _set(_p.copyWith(priceListId: Value(id!))),
              dropdownMenuEntries: [
                for (final p in lists)
                  if (p.enabled == 1 || p.id == _p.priceListId.value)
                    DropdownMenuEntry(value: p.id, label: p.name),
              ],
            ),
            optional(
              l.taxesAndCharges,
              _p.taxesTemplateId.value,
              [
                for (final t in templates)
                  if (t.disabled == 0 || t.id == _p.taxesTemplateId.value) t,
              ],
              (t) => t.id,
              (t) => t.title,
              (id) => _set(_p.copyWith(taxesTemplateId: Value(id))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l.applyDiscountOn, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        // SET-R14: Net Total spreads the discount over the items before tax;
        // Grand Total takes it off the after-tax total.
        SegmentedButton<String>(
          segments: [
            for (final s in const ['Grand Total', 'Net Total'])
              ButtonSegment(value: s, label: Text(s)),
          ],
          selected: {_p.applyDiscountOn.value},
          onSelectionChanged: (s) =>
              _set(_p.copyWith(applyDiscountOn: Value(s.single))),
        ),
      ],
    );
  }
}

class _PaymentEditor extends StatefulWidget {
  const _PaymentEditor({
    required this.row,
    required this.modes,
    required this.onDone,
    this.onDelete,
  });

  final _Payment? row;
  final List<ModeOfPaymentData> modes;
  final ValueChanged<_Payment> onDone;
  final VoidCallback? onDelete;

  @override
  State<_PaymentEditor> createState() => _PaymentEditorState();
}

class _PaymentEditorState extends State<_PaymentEditor> {
  late int? _modeId = widget.row?.modeId;
  late var _isDefault = widget.row?.isDefault ?? false;
  late var _allowInReturns = widget.row?.allowInReturns ?? false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DropdownMenu<int>(
          label: Text('${l.modeOfPayment} *'),
          initialSelection: _modeId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (id) => setState(() => _modeId = id),
          dropdownMenuEntries: [
            for (final m in widget.modes)
              DropdownMenuEntry(value: m.id, label: m.name),
          ],
        ),
        SwitchListTile(
          title: Text(l.isDefault),
          value: _isDefault,
          onChanged: (on) => setState(() => _isDefault = on),
        ),
        SwitchListTile(
          title: Text(l.allowInReturns),
          value: _allowInReturns,
          onChanged: (on) => setState(() => _allowInReturns = on),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (widget.onDelete case final onDelete?)
              TextButton.icon(
                onPressed: () {
                  onDelete();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l.delete),
              ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                widget.onDone((
                  modeId: _modeId,
                  isDefault: _isDefault,
                  allowInReturns: _allowInReturns,
                ));
                Navigator.pop(context);
              },
              child: Text(l.done),
            ),
          ],
        ),
      ],
    );
  }
}

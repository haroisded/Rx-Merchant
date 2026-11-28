import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/setup_queries.dart';
import '../logic/tax_template.dart';
import 'form_kit.dart';
import 'simple_masters.dart';

// Sales Taxes and Charges Template and Item Tax Template (SET-R9 to R12).

final salesTaxesTemplatesProvider =
    StreamProvider<List<SalesTaxesTemplateData>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return db.select(db.salesTaxesTemplate).watch();
    });

final itemTaxTemplatesProvider = StreamProvider<List<ItemTaxTemplateData>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.itemTaxTemplate).watch();
});

String taxRowProblemText(AppLocalizations l, (int, TaxRowProblem) p) =>
    l.rowProblem(p.$1, switch (p.$2) {
      TaxRowProblem.missingTax => l.taxRowMissingTax,
      TaxRowProblem.previousRowInFirstRow => l.taxRowPreviousRowInFirstRow,
      TaxRowProblem.missingReferenceRow => l.taxRowMissingReferenceRow,
      TaxRowProblem.referenceRowNotEarlier => l.taxRowReferenceRowNotEarlier,
      TaxRowProblem.actualIncluded => l.taxRowActualIncluded,
      TaxRowProblem.includedReferenceNotIncluded =>
        l.taxRowIncludedReferenceNotIncluded,
    });

/// A typed number field that shows and reads values in the Number Format.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.formats,
    required this.onChanged,
    this.precision,
  });

  final String label;
  final double value;
  final Formats formats;
  final ValueChanged<double> onChanged;
  final int? precision;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: formats.number(value, precision),
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (t) => formats.parse(t!) == null
        ? AppLocalizations.of(context).notANumber
        : null,
    onChanged: (t) {
      if (formats.parse(t) case final v?) onChanged(v);
    },
  );
}

class SalesTaxesTemplatePage extends ConsumerWidget {
  const SalesTaxesTemplatePage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(salesTaxesTemplatesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<SalesTaxesTemplateData>(
        title: l.salesTaxesTemplate,
        rows: rows,
        labelOf: (t) => t.title,
        subtitleOf: (t) => t.isDefault == 1 ? l.isDefault : null,
        isDisabled: (t) => t.disabled == 1,
        onOpen: (t) => context.go('$path/${t.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _SalesTaxesTemplateForm(
      key: ValueKey(id),
      path: path,
      template: recordFor(rows.value!, id, (t) => t.id),
    );
  }
}

class _SalesTaxesTemplateForm extends ConsumerStatefulWidget {
  const _SalesTaxesTemplateForm({super.key, required this.path, this.template});

  final String path;
  final SalesTaxesTemplateData? template;

  @override
  ConsumerState<_SalesTaxesTemplateForm> createState() =>
      _SalesTaxesTemplateFormState();
}

class _SalesTaxesTemplateFormState
    extends ConsumerState<_SalesTaxesTemplateForm> {
  late final _title = TextEditingController(text: widget.template?.title);
  late var _isDefault = widget.template?.isDefault == 1;
  late var _disabled = widget.template?.disabled == 1;
  List<TaxRow>? _rows;
  var _tryNet = 1000.0;
  var _tryQty = 5.0;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t == null) {
      _rows = [];
    } else {
      ref.read(appDatabaseProvider).salesTaxesTemplateRows(t.id).then((rows) {
        if (mounted) setState(() => _rows = rows);
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    final problems = [
      for (final p in validateTaxRows(_rows!)) taxRowProblemText(l, p),
    ];
    if (problems.isNotEmpty) {
      await showProblems(context, problems);
      return false;
    }
    final t = widget.template;
    final ok = await attempt(
      context,
      () => ref
          .read(appDatabaseProvider)
          .saveSalesTaxesTemplate(
            SalesTaxesTemplateCompanion(
              id: t == null ? const Value.absent() : Value(t.id),
              title: Value(_title.text.trim()),
              isDefault: Value(_isDefault ? 1 : 0),
              disabled: Value(_disabled ? 1 : 0),
            ),
            _rows!,
          ),
      done: l.saved,
    );
    if (ok && mounted) context.go(widget.path);
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = _rows;
    final taxes = ref.watch(taxesProvider).value ?? [];
    final formats = ref.watch(formatsProvider);
    if (rows == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = widget.template;
    String taxName(int? id) =>
        taxes.where((x) => x.id == id).firstOrNull?.name ?? '';

    return FormPage(
      title: t?.title ?? l.newRecord(l.salesTaxesTemplate),
      onSave: _save,
      onDelete: t == null
          ? null
          : () async {
              final db = ref.read(appDatabaseProvider);
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(t.title),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              if (await attempt(
                    context,
                    () => db.deleteMaster(db.salesTaxesTemplate, t.id),
                  ) &&
                  context.mounted) {
                context.go(widget.path);
              }
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: '${l.title} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            SwitchListTile(
              title: Text(l.isDefault),
              value: _isDefault,
              onChanged: (on) => setState(() => _isDefault = on),
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
        SectionHeading(l.salesTaxesAndCharges),
        ChildTable<TaxRow>(
          rows: rows,
          rowBuilder: (context, r) => ListTile(
            leading: Text('${rows.indexOf(r) + 1}'),
            title: Text('${r.chargeType.value} · ${taxName(r.taxId)}'),
            subtitle: Text(
              [
                r.chargeType == ChargeType.actual
                    ? '${l.taxAmount}: ${formats.number(r.taxAmount, formats.system.currencyPrecision)}'
                    : '${l.taxRate}: ${formats.number(r.rate)}',
                if (r.rowId != null) '${l.referenceRow}: ${r.rowId}',
                if (r.included) l.includedInBasicRate,
              ].join(' · '),
            ),
          ),
          editorBuilder: (context, r) => _TaxRowEditor(
            row: r,
            number: r == null ? rows.length + 1 : rows.indexOf(r) + 1,
            taxes: taxes,
            formats: formats,
            onDone: (edited) => setState(() {
              if (r == null) {
                rows.add(edited);
              } else {
                rows[rows.indexOf(r)] = edited;
              }
            }),
            onDelete: r == null
                ? null
                : () => setState(
                    () => _rows = removeTaxRow(rows, rows.indexOf(r) + 1),
                  ),
          ),
        ),
        SectionHeading(l.tryIt),
        FieldGrid(
          children: [
            NumberField(
              label: l.netTotal,
              value: _tryNet,
              formats: formats,
              precision: formats.system.currencyPrecision,
              onChanged: (v) => setState(() => _tryNet = v),
            ),
            NumberField(
              label: l.totalQuantity,
              value: _tryQty,
              formats: formats,
              onChanged: (v) => setState(() => _tryQty = v),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TryItTable(rows: rows, net: _tryNet, qty: _tryQty, formats: formats),
      ],
    );
  }
}

/// Each row's Amount and running Total for the "Try it" inputs.
class _TryItTable extends StatelessWidget {
  const _TryItTable({
    required this.rows,
    required this.net,
    required this.qty,
    required this.formats,
  });

  final List<TaxRow> rows;
  final double net;
  final double qty;
  final Formats formats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();
    if (validateTaxRows(rows).isNotEmpty) return Text(l.tryItFixRows);
    final results = tryTaxes(
      rows,
      net: net,
      qty: qty,
      precision: formats.system.currencyPrecision,
      method: formats.rounding,
    );
    String money(double v) =>
        formats.number(v, formats.system.currencyPrecision);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppSpacing.md,
        columns: [
          const DataColumn(label: Text('#')),
          DataColumn(label: Text(l.type)),
          DataColumn(label: Text(l.amount), numeric: true),
          DataColumn(label: Text(l.total), numeric: true),
        ],
        rows: [
          for (final (i, r) in results.indexed)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(rows[i].chargeType.value)),
                DataCell(Text(money(r.amount))),
                DataCell(Text(money(r.total))),
              ],
            ),
        ],
      ),
    );
  }
}

class _TaxRowEditor extends StatefulWidget {
  const _TaxRowEditor({
    required this.row,
    required this.number,
    required this.taxes,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final TaxRow? row;
  final int number;
  final List<TaxData> taxes;
  final Formats formats;
  final ValueChanged<TaxRow> onDone;
  final VoidCallback? onDelete;

  @override
  State<_TaxRowEditor> createState() => _TaxRowEditorState();
}

class _TaxRowEditorState extends State<_TaxRowEditor> {
  late var _type = widget.row?.chargeType ?? ChargeType.onNetTotal;
  late int? _taxId = widget.row?.taxId;
  late final _description = TextEditingController(
    text: widget.row?.description,
  );
  late var _rate = widget.row?.rate ?? 0;
  late var _amount = widget.row?.taxAmount ?? 0;
  late int? _rowId = widget.row?.rowId;
  late var _included = widget.row?.included ?? false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = widget.formats;
    final enabledTaxes = [
      for (final t in widget.taxes)
        if (t.disabled == 0 || t.id == _taxId) t,
    ];
    return RowEditorBody(
      title: l.rowNumber(widget.number),
      onDelete: widget.onDelete,
      onDone: () => widget.onDone(
        TaxRow(
          chargeType: _type,
          taxId: _taxId,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          rate: _type == ChargeType.actual ? 0 : _rate,
          taxAmount: _type == ChargeType.actual ? _amount : 0,
          rowId: _type.isPreviousRow ? _rowId : null,
          included: _included,
        ),
      ),
      children: [
        DropdownMenu<ChargeType>(
          label: Text('${l.type} *'),
          initialSelection: _type,
          expandedInsets: EdgeInsets.zero,
          onSelected: (t) => setState(() {
            _type = t!;
            if (!_type.isPreviousRow) _rowId = null;
          }),
          dropdownMenuEntries: [
            for (final t in ChargeType.values)
              DropdownMenuEntry(value: t, label: t.value),
          ],
        ),
        DropdownMenu<int>(
          label: Text('${l.tax} *'),
          initialSelection: _taxId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (id) => setState(() => _taxId = id),
          dropdownMenuEntries: [
            for (final t in enabledTaxes)
              DropdownMenuEntry(value: t.id, label: t.name),
          ],
        ),
        TextField(
          controller: _description,
          decoration: InputDecoration(labelText: l.description),
        ),
        // SET-R9: Actual takes an amount; On Item Quantity an amount per unit;
        // the others a percentage.
        if (_type == ChargeType.actual)
          NumberField(
            key: const ValueKey('amount'),
            label: l.taxAmount,
            value: _amount,
            formats: formats,
            precision: formats.system.currencyPrecision,
            onChanged: (v) => _amount = v,
          )
        else
          NumberField(
            key: const ValueKey('rate'),
            label: _type == ChargeType.onItemQuantity
                ? l.amountPerUnit
                : l.taxRate,
            value: _rate,
            formats: formats,
            onChanged: (v) => _rate = v,
          ),
        if (_type.isPreviousRow)
          DropdownMenu<int>(
            label: Text('${l.referenceRow} *'),
            initialSelection: _rowId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (n) => setState(() => _rowId = n),
            dropdownMenuEntries: [
              for (var n = 1; n < widget.number; n++)
                DropdownMenuEntry(value: n, label: '$n'),
            ],
          ),
        SwitchListTile(
          title: Text(l.includedInBasicRate),
          value: _included,
          onChanged: (on) => setState(() => _included = on),
        ),
      ],
    );
  }
}

// ---- Item Tax Template ---------------------------------------------------------

typedef ItemTaxRow = ({int? taxId, double rate, bool notApplicable});

class ItemTaxTemplatePage extends ConsumerWidget {
  const ItemTaxTemplatePage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(itemTaxTemplatesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<ItemTaxTemplateData>(
        title: l.itemTaxTemplate,
        rows: rows,
        labelOf: (t) => t.title,
        isDisabled: (t) => t.disabled == 1,
        onOpen: (t) => context.go('$path/${t.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ItemTaxTemplateForm(
      key: ValueKey(id),
      path: path,
      template: recordFor(rows.value!, id, (t) => t.id),
    );
  }
}

class _ItemTaxTemplateForm extends ConsumerStatefulWidget {
  const _ItemTaxTemplateForm({super.key, required this.path, this.template});

  final String path;
  final ItemTaxTemplateData? template;

  @override
  ConsumerState<_ItemTaxTemplateForm> createState() =>
      _ItemTaxTemplateFormState();
}

class _ItemTaxTemplateFormState extends ConsumerState<_ItemTaxTemplateForm> {
  late final _title = TextEditingController(text: widget.template?.title);
  late var _disabled = widget.template?.disabled == 1;
  List<ItemTaxRow>? _rows;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t == null) {
      _rows = [];
      return;
    }
    ref.read(appDatabaseProvider).itemTaxTemplateRows(t.id).then((rows) {
      if (mounted) {
        setState(
          () => _rows = [
            for (final r in rows)
              (
                taxId: r.taxId,
                rate: r.taxRate,
                notApplicable: r.notApplicable == 1,
              ),
          ],
        );
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    final rows = _rows!;
    final seen = <int>{};
    final problems = [
      for (final (i, r) in rows.indexed)
        if (r.taxId == null)
          l.rowProblem(i + 1, l.taxRowMissingTax)
        else if (!seen.add(r.taxId!))
          l.rowProblem(i + 1, l.taxRowDuplicateTax),
    ];
    if (problems.isNotEmpty) {
      await showProblems(context, problems);
      return false;
    }
    final t = widget.template;
    final ok = await attempt(
      context,
      () => ref.read(appDatabaseProvider).saveItemTaxTemplate(
        ItemTaxTemplateCompanion(
          id: t == null ? const Value.absent() : Value(t.id),
          title: Value(_title.text.trim()),
          disabled: Value(_disabled ? 1 : 0),
        ),
        [
          for (final r in rows)
            ItemTaxTemplateRowCompanion(
              taxId: Value(r.taxId!),
              taxRate: Value(r.rate),
              notApplicable: Value(r.notApplicable ? 1 : 0),
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
    final rows = _rows;
    final taxes = ref.watch(taxesProvider).value ?? [];
    final formats = ref.watch(formatsProvider);
    if (rows == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = widget.template;
    String taxName(int? id) =>
        taxes.where((x) => x.id == id).firstOrNull?.name ?? '';

    return FormPage(
      title: t?.title ?? l.newRecord(l.itemTaxTemplate),
      onSave: _save,
      onDelete: t == null
          ? null
          : () async {
              final db = ref.read(appDatabaseProvider);
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(t.title),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              if (await attempt(
                    context,
                    () => db.deleteMaster(db.itemTaxTemplate, t.id),
                  ) &&
                  context.mounted) {
                context.go(widget.path);
              }
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: '${l.title} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
        SectionHeading(l.taxRates),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l.itemTaxTemplateHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ChildTable<ItemTaxRow>(
          rows: rows,
          rowBuilder: (context, r) => ListTile(
            title: Text(taxName(r.taxId)),
            subtitle: Text(
              r.notApplicable
                  ? l.notApplicable
                  : '${l.taxRate}: ${formats.number(r.rate)}',
            ),
          ),
          editorBuilder: (context, r) => _ItemTaxRowEditor(
            row: r,
            taxes: taxes,
            formats: formats,
            onDone: (edited) => setState(() {
              if (r == null) {
                rows.add(edited);
              } else {
                rows[rows.indexOf(r)] = edited;
              }
            }),
            onDelete: r == null ? null : () => setState(() => rows.remove(r)),
          ),
        ),
      ],
    );
  }
}

class _ItemTaxRowEditor extends StatefulWidget {
  const _ItemTaxRowEditor({
    required this.row,
    required this.taxes,
    required this.formats,
    required this.onDone,
    this.onDelete,
  });

  final ItemTaxRow? row;
  final List<TaxData> taxes;
  final Formats formats;
  final ValueChanged<ItemTaxRow> onDone;
  final VoidCallback? onDelete;

  @override
  State<_ItemTaxRowEditor> createState() => _ItemTaxRowEditorState();
}

class _ItemTaxRowEditorState extends State<_ItemTaxRowEditor> {
  late int? _taxId = widget.row?.taxId;
  late var _rate = widget.row?.rate ?? 0;
  late var _notApplicable = widget.row?.notApplicable ?? false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RowEditorBody(
      onDelete: widget.onDelete,
      onDone: () => widget.onDone((
        taxId: _taxId,
        rate: _rate,
        notApplicable: _notApplicable,
      )),
      children: [
        DropdownMenu<int>(
          label: Text('${l.tax} *'),
          initialSelection: _taxId,
          expandedInsets: EdgeInsets.zero,
          onSelected: (id) => setState(() => _taxId = id),
          dropdownMenuEntries: [
            for (final t in widget.taxes)
              if (t.disabled == 0 || t.id == _taxId)
                DropdownMenuEntry(value: t.id, label: t.name),
          ],
        ),
        NumberField(
          label: l.taxRate,
          value: _rate,
          formats: widget.formats,
          onChanged: (v) => _rate = v,
        ),
        // SET-R12: Not Applicable removes the tax; a rate of 0 keeps the item
        // taxable at zero.
        SwitchListTile(
          title: Text(l.notApplicable),
          value: _notApplicable,
          onChanged: (on) => setState(() => _notApplicable = on),
        ),
      ],
    );
  }
}

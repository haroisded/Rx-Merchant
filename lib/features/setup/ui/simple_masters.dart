import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/setup_queries.dart';
import 'form_kit.dart';

// Currency, and the three masters that are a name plus a few switches:
// Mode of Payment, Tax and Price List. Each master page shows its list, or
// the form of record [id] ('new' for a new one); [path] is its route.

class CurrencyPage extends ConsumerStatefulWidget {
  const CurrencyPage({super.key});

  @override
  ConsumerState<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends ConsumerState<CurrencyPage> {
  final _formKey = GlobalKey<FormState>();
  CurrencyCompanion? _edit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(storeCurrencyProvider).value;
    if (current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final edit = _edit ??= current.toCompanion(false);
    final formats = ref.watch(formatsProvider);
    void set(CurrencyCompanion c) => setState(() => _edit = c);

    return FormPage(
      title: l.currency,
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return showProblems(context, [l.formHasErrors]);
        }
        _formKey.currentState!.save();
        await attempt(
          context,
          () => ref.read(appDatabaseProvider).saveCurrency(_edit!),
          done: l.saved,
        );
      },
      children: [
        FieldGrid(
          children: [
            InputDecorator(
              decoration: InputDecoration(labelText: l.currencyCode),
              child: Text(current.code ?? ''),
            ),
            TextFormField(
              initialValue: edit.symbol.value,
              decoration: InputDecoration(labelText: l.symbol),
              onChanged: (v) => set(edit.copyWith(symbol: Value(v.trim()))),
            ),
            TextFormField(
              initialValue: edit.fraction.value,
              decoration: InputDecoration(labelText: l.fraction),
              onSaved: (v) =>
                  _edit = _edit!.copyWith(fraction: Value(v!.trim())),
            ),
            TextFormField(
              initialValue: '${edit.fractionUnits.value}',
              decoration: InputDecoration(labelText: l.fractionUnits),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v!.trim()) == null ? l.notAWholeNumber : null,
              onSaved: (v) => _edit = _edit!.copyWith(
                fractionUnits: Value(int.parse(v!.trim())),
              ),
            ),
            TextFormField(
              initialValue: formats.number(
                edit.smallestCurrencyFractionValue.value,
              ),
              decoration: InputDecoration(
                labelText: l.smallestCurrencyFractionValue,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => formats.parse(v!) == null ? l.notANumber : null,
              onSaved: (v) => _edit = _edit!.copyWith(
                smallestCurrencyFractionValue: Value(formats.parse(v!)!),
              ),
            ),
            SwitchListTile(
              title: Text(l.symbolOnRight),
              value: edit.symbolOnRight.value == 1,
              onChanged: (on) =>
                  set(edit.copyWith(symbolOnRight: Value(on ? 1 : 0))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card.filled(
          child: ListTile(
            title: Text(l.preview),
            // Shows how amounts print with the symbol as edited.
            subtitle: Text(
              formatCurrency(
                1234.5,
                numberFormat: formats.system.numberFormat,
                precision: formats.system.currencyPrecision,
                symbol: edit.symbol.value,
                symbolOnRight: edit.symbolOnRight.value == 1,
                hideSymbol: formats.defaults.hideCurrencySymbol,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A form for a master that is a name, a few switches and at most one
/// dropdown. Saving or deleting returns to the list at [listPath].
class NamedMasterForm extends StatefulWidget {
  const NamedMasterForm({
    super.key,
    required this.title,
    required this.listPath,
    required this.name,
    required this.switches,
    required this.onSave,
    this.choice,
    this.onDelete,
  });

  final String title;
  final String listPath;
  final String name;
  final List<(String label, bool value)> switches;
  final (String label, List<String> options, String value)? choice;
  final Future<void> Function(String name, List<bool> switches, String? choice)
  onSave;
  final Future<void> Function()? onDelete;

  @override
  State<NamedMasterForm> createState() => _NamedMasterFormState();
}

class _NamedMasterFormState extends State<NamedMasterForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _switches = [for (final s in widget.switches) s.$2];
  late var _choice = widget.choice?.$3;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final onDelete = widget.onDelete;
    return FormPage(
      title: widget.title,
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return showProblems(context, [l.formHasErrors]);
        }
        final ok = await attempt(
          context,
          () => widget.onSave(_name.text.trim(), _switches, _choice),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.listPath);
      },
      onDelete: onDelete == null
          ? null
          : () async {
              final yes = await confirm(
                context,
                title: l.deleteTitle,
                body: l.deleteBody(widget.name),
                action: l.delete,
              );
              if (!yes || !context.mounted) return;
              final ok = await attempt(context, onDelete);
              if (ok && context.mounted) context.go(widget.listPath);
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.name} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            if (widget.choice case (final label, final options, _))
              DropdownMenu<String>(
                label: Text(label),
                initialSelection: _choice,
                expandedInsets: EdgeInsets.zero,
                onSelected: (v) => setState(() => _choice = v),
                dropdownMenuEntries: [
                  for (final o in options)
                    DropdownMenuEntry(value: o, label: o),
                ],
              ),
            for (final (i, (label, _)) in widget.switches.indexed)
              SwitchListTile(
                title: Text(label),
                value: _switches[i],
                onChanged: (on) => setState(() => _switches[i] = on),
              ),
          ],
        ),
      ],
    );
  }
}

final modesOfPaymentProvider = StreamProvider<List<ModeOfPaymentData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.modeOfPayment).watch();
});

final taxesProvider = StreamProvider<List<TaxData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.tax).watch();
});

final priceListsProvider = StreamProvider<List<PriceListData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.priceList).watch();
});

const _loading = Scaffold(body: Center(child: CircularProgressIndicator()));

/// Finds record [id] in [rows]; null for 'new'.
T? recordFor<T>(List<T> rows, String id, int Function(T) idOf) =>
    rows.where((r) => '${idOf(r)}' == id).firstOrNull;

class ModeOfPaymentPage extends ConsumerWidget {
  const ModeOfPaymentPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(modesOfPaymentProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<ModeOfPaymentData>(
        title: l.modeOfPayment,
        rows: rows,
        labelOf: (m) => m.name,
        subtitleOf: (m) => m.type,
        isDisabled: (m) => m.enabled == 0,
        onOpen: (m) => context.go('$path/${m.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final m = recordFor(rows.value ?? [], id, (m) => m.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: m?.name ?? l.newRecord(l.modeOfPayment),
      listPath: path,
      name: m?.name ?? '',
      // SET-R8: Type classifies the mode; change and cash counts use Cash.
      choice: (
        l.type,
        const ['Cash', 'Bank', 'General', 'Phone'],
        m?.type ?? 'General',
      ),
      switches: [(l.enabled, (m?.enabled ?? 1) == 1)],
      onSave: (name, s, type) => db.saveModeOfPayment(
        ModeOfPaymentCompanion(
          id: m == null ? const Value.absent() : Value(m.id),
          name: Value(name),
          type: Value(type!),
          enabled: Value(s[0] ? 1 : 0),
        ),
      ),
      onDelete: m == null
          ? null
          : () => db.deleteMaster(db.modeOfPayment, m.id),
    );
  }
}

class TaxPage extends ConsumerWidget {
  const TaxPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(taxesProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<TaxData>(
        title: l.tax,
        rows: rows,
        labelOf: (t) => t.name,
        isDisabled: (t) => t.disabled == 1,
        onOpen: (t) => context.go('$path/${t.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final t = recordFor(rows.value ?? [], id, (t) => t.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: t?.name ?? l.newRecord(l.tax),
      listPath: path,
      name: t?.name ?? '',
      switches: [(l.disabled, t?.disabled == 1)],
      onSave: (name, s, _) => db.saveTax(
        TaxCompanion(
          id: t == null ? const Value.absent() : Value(t.id),
          name: Value(name),
          disabled: Value(s[0] ? 1 : 0),
        ),
      ),
      onDelete: t == null ? null : () => db.deleteMaster(db.tax, t.id),
    );
  }
}

class PriceListPage extends ConsumerWidget {
  const PriceListPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(priceListsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<PriceListData>(
        title: l.priceList,
        rows: rows,
        labelOf: (p) => p.name,
        isDisabled: (p) => p.enabled == 0,
        onOpen: (p) => context.go('$path/${p.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final p = recordFor(rows.value ?? [], id, (p) => p.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: p?.name ?? l.newRecord(l.priceList),
      listPath: path,
      name: p?.name ?? '',
      switches: [
        (l.enabled, (p?.enabled ?? 1) == 1),
        // SET-R13: on, a stock-unit price is multiplied by the conversion
        // factor for other units.
        (l.priceNotUomDependent, p?.priceNotUomDependent == 1),
      ],
      onSave: (name, s, _) => db.savePriceList(
        PriceListCompanion(
          id: p == null ? const Value.absent() : Value(p.id),
          name: Value(name),
          enabled: Value(s[0] ? 1 : 0),
          priceNotUomDependent: Value(s[1] ? 1 : 0),
        ),
      ),
      onDelete: p == null ? null : () => db.deleteMaster(db.priceList, p.id),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_info.dart';
import '../data/setup_queries.dart';
import 'form_kit.dart';

enum FieldKind { text, money, wholeNumber, check, choice, date, info }

/// One field of a settings page. [read] gives its current text from the
/// stored values, applying the default (`singles.dart`); checks are '1'/'0'.
class SingleField {
  const SingleField(
    this.key,
    this.label, {
    required this.read,
    this.kind = FieldKind.text,
    this.options = const [],
    this.optionLabel,
    this.mandatory = false,
    this.lockReason,
  });

  final String key;
  final String label;
  final String Function(Map<String, String> stored) read;
  final FieldKind kind;
  final List<String> options;
  final String Function(String option)? optionLabel;
  final bool mandatory;

  /// Non-null makes the field read-only, with this reason under it.
  final String? lockReason;
}

/// A one-record settings page kept in `singles` (00-overview 6.5): sections
/// of fields, Save, and an optional live [preview] of the edited values.
class SinglesForm extends ConsumerStatefulWidget {
  const SinglesForm({
    super.key,
    required this.doctype,
    required this.title,
    required this.sections,
    this.preview,
    this.beforeSave,
  });

  final String doctype;
  final String title;
  final List<(String, List<SingleField>)> sections;
  final Widget Function(Map<String, String> values)? preview;

  /// Runs inside Save, before the values are written.
  final Future<void> Function(Map<String, String> values)? beforeSave;

  @override
  ConsumerState<SinglesForm> createState() => _SinglesFormState();
}

class _SinglesFormState extends ConsumerState<SinglesForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, String>? _values;

  Iterable<SingleField> get _fields => widget.sections.expand((s) => s.$2);

  @override
  void initState() {
    super.initState();
    ref.read(appDatabaseProvider).readSingle(widget.doctype).then((stored) {
      if (mounted) {
        setState(
          () =>
              _values = {for (final f in _fields) f.key: _readField(f, stored)},
        );
      }
    });
  }

  /// A stored choice that is no longer offered (a Mode of Payment or Terms
  /// disabled since) reads as blank, so Save does not write it back.
  String _readField(SingleField f, Map<String, String> stored) {
    final value = f.read(stored);
    return f.kind == FieldKind.choice && !f.options.contains(value)
        ? ''
        : value;
  }

  Future<bool> _save() async {
    final l = AppLocalizations.of(context);
    _formKey.currentState!.save();
    final values = {
      for (final f in _fields)
        if (f.kind != FieldKind.info && f.lockReason == null)
          f.key: _values![f.key]!,
    };
    final db = ref.read(appDatabaseProvider);
    return attempt(context, () async {
      await widget.beforeSave?.call(values);
      await db.writeSingle(widget.doctype, values);
    }, done: l.saved);
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    if (values == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return FormPage(
      title: widget.title,
      formKey: _formKey,
      onSave: _save,
      children: [
        for (final (heading, fields) in widget.sections) ...[
          SectionHeading(heading),
          FieldGrid(children: [for (final f in fields) _field(f, values)]),
        ],
        if (widget.preview case final preview?) ...[
          const SizedBox(height: AppSpacing.lg),
          preview(values),
        ],
      ],
    );
  }

  Widget _field(SingleField f, Map<String, String> values) {
    final l = AppLocalizations.of(context);
    final formats = ref.read(formatsProvider);
    final locked = f.lockReason != null;
    final label = f.mandatory ? '${f.label} *' : f.label;
    final value = values[f.key]!;
    void set(String v) => setState(() => values[f.key] = v);

    final Widget field = switch (f.kind) {
      FieldKind.info => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
      FieldKind.check => SwitchListTile(
        title: Text(f.label),
        value: value == '1',
        onChanged: locked ? null : (on) => set(on ? '1' : '0'),
      ),
      FieldKind.choice => DropdownMenu<String>(
        label: Text(label),
        initialSelection: value,
        enabled: !locked,
        expandedInsets: EdgeInsets.zero,
        // Long lists (countries) can be searched by typing.
        enableFilter: f.options.length > 20,
        requestFocusOnTap: f.options.length > 20,
        menuHeight: 320,
        onSelected: (v) => v == null ? null : set(v),
        dropdownMenuEntries: [
          for (final o in f.options)
            DropdownMenuEntry(value: o, label: f.optionLabel?.call(o) ?? o),
        ],
      ),
      // Stored as YYYY-MM-DD; blank is none.
      FieldKind.date => DateField(
        label: f.label,
        value: value.isEmpty ? null : value,
        formats: formats,
        enabled: !locked,
        onChanged: (v) => set(v ?? ''),
      ),
      FieldKind.text ||
      FieldKind.money ||
      FieldKind.wholeNumber => TextFormField(
        initialValue: f.kind == FieldKind.money
            ? formats.number(
                double.tryParse(value) ?? 0,
                formats.system.currencyPrecision,
              )
            : value,
        readOnly: locked,
        decoration: InputDecoration(labelText: label),
        keyboardType: f.kind == FieldKind.text
            ? null
            : TextInputType.numberWithOptions(
                decimal: f.kind == FieldKind.money,
              ),
        validator: (text) {
          final t = text!.trim();
          if (t.isEmpty) return f.mandatory ? l.mandatoryField : null;
          return switch (f.kind) {
            FieldKind.money when formats.parse(t) == null => l.notANumber,
            FieldKind.wholeNumber when (int.tryParse(t) ?? 0) < 1 =>
              l.notAWholeNumber,
            _ => null,
          };
        },
        onSaved: (text) => values[f.key] = switch (f.kind) {
          FieldKind.money => '${formats.parse(text!) ?? 0}',
          _ => text!.trim(),
        },
      ),
    };
    if (!locked) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [field, LockNote(f.lockReason!)],
    );
  }
}

// ---- The four settings pages ------------------------------------------------

/// The bundled countries, read once.
final countryInfoProvider = FutureProvider<List<CountryInfo>>(
  (ref) => loadCountryInfo(),
);

/// SET-R2: true once any document is submitted.
final submittedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(appDatabaseProvider).anySubmittedDocument(),
);

const dateFormats = [
  'yyyy-mm-dd', 'dd-mm-yyyy', 'dd/mm/yyyy', 'dd.mm.yyyy', 'mm/dd/yyyy', //
  'mm-dd-yyyy',
];
const numberFormats = [
  '#,###.##', '#.###,##', '# ###.##', '#,##,###.##', '#,###', '#.###', //
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
  'Sunday',
];

/// The shipped languages, each named in its own language.
List<String> get languageCodes => [
  for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
];
String languageName(String code) =>
    lookupAppLocalizations(Locale(code)).languageName;

String _flag(bool on) => on ? '1' : '0';
List<String> _range(int from, int to) => [
  for (var i = from; i <= to; i++) '$i',
];

/// Waits for what a page's fields need, then builds it.
Widget _when<T>(AsyncValue<T> value, Widget Function(T) build) =>
    switch (value) {
      AsyncData(:final value) => build(value),
      AsyncError(:final error) => Scaffold(
        body: Center(
          child: Builder(
            builder: (context) =>
                Text(AppLocalizations.of(context).unexpectedError('$error')),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };

class StoreProfilePage extends ConsumerWidget {
  const StoreProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final db = ref.watch(appDatabaseProvider);
    return _when(ref.watch(countryInfoProvider), (countries) {
      return _when(ref.watch(submittedProvider), (locked) {
        final currencies = {for (final c in countries) ?c.currency: c};
        return SinglesForm(
          doctype: StoreProfile.doctype,
          title: l.storeProfile,
          sections: [
            (
              l.sectionStore,
              [
                SingleField(
                  'store_name',
                  l.storeName,
                  mandatory: true,
                  read: (v) => StoreProfile(v).storeName,
                ),
                SingleField(
                  'abbr',
                  l.abbreviation,
                  read: (v) => StoreProfile(v).abbr,
                ),
                SingleField(
                  'country',
                  l.country,
                  kind: FieldKind.choice,
                  options: [for (final c in countries) c.name],
                  read: (v) => StoreProfile(v).country ?? '',
                ),
                SingleField(
                  'default_currency',
                  l.defaultCurrency,
                  kind: FieldKind.choice,
                  options: currencies.keys.toList()..sort(),
                  lockReason: locked ? l.lockedAfterSubmit : null,
                  read: (v) => StoreProfile(v).defaultCurrency ?? '',
                ),
              ],
            ),
            (
              l.sectionSalesGoal,
              [
                SingleField(
                  'monthly_sales_target',
                  l.monthlySalesTarget,
                  kind: FieldKind.money,
                  read: (v) => '${StoreProfile(v).monthlySalesTarget}',
                ),
              ],
            ),
          ],
          // A newly chosen currency gets its Currency record from the
          // bundled country data.
          beforeSave: (values) async {
            final source = currencies[values['default_currency']];
            if (source != null) await db.addCurrency(source);
          },
        );
      });
    });
  }
}

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _when(ref.watch(countryInfoProvider), (countries) {
      return _when(ref.watch(submittedProvider), (locked) {
        return SinglesForm(
          doctype: SystemSettings.doctype,
          title: l.systemSettings,
          sections: [
            (
              l.sectionRegion,
              [
                SingleField(
                  'country',
                  l.country,
                  kind: FieldKind.choice,
                  options: [for (final c in countries) c.name],
                  read: (v) => SystemSettings(v).country ?? '',
                ),
                SingleField(
                  'language',
                  l.language,
                  kind: FieldKind.choice,
                  options: languageCodes,
                  optionLabel: languageName,
                  read: (v) => SystemSettings(v).language,
                ),
                SingleField(
                  'time_zone',
                  l.timeZone,
                  kind: FieldKind.info,
                  read: (_) => DateTime.now().timeZoneName,
                ),
                SingleField(
                  'date_format',
                  l.dateFormat,
                  kind: FieldKind.choice,
                  options: dateFormats,
                  read: (v) => SystemSettings(v).dateFormat,
                ),
                SingleField(
                  'time_format',
                  l.timeFormat,
                  kind: FieldKind.choice,
                  options: const ['HH:mm:ss', 'HH:mm'],
                  read: (v) => SystemSettings(v).timeFormat,
                ),
                SingleField(
                  'number_format',
                  l.numberFormat,
                  kind: FieldKind.choice,
                  options: numberFormats,
                  read: (v) => SystemSettings(v).numberFormat,
                ),
                SingleField(
                  'first_day_of_week',
                  l.firstDayOfWeek,
                  kind: FieldKind.choice,
                  options: _weekdays,
                  read: (v) => SystemSettings(v).firstDayOfWeek,
                ),
              ],
            ),
            (
              l.sectionNumbers,
              [
                SingleField(
                  'float_precision',
                  l.floatPrecision,
                  kind: FieldKind.choice,
                  options: _range(2, 9),
                  read: (v) => '${SystemSettings(v).floatPrecision}',
                ),
                SingleField(
                  'currency_precision',
                  l.currencyPrecision,
                  kind: FieldKind.choice,
                  options: _range(0, 9),
                  lockReason: locked ? l.lockedAfterSubmit : null,
                  read: (v) => '${SystemSettings(v).currencyPrecision}',
                ),
                SingleField(
                  'rounding_method',
                  l.roundingMethod,
                  kind: FieldKind.choice,
                  options: const ["Banker's Rounding", 'Commercial Rounding'],
                  read: (v) => SystemSettings(v).roundingMethod,
                ),
              ],
            ),
            (
              l.sectionBackups,
              [
                SingleField(
                  'number_of_backups',
                  l.numberOfBackups,
                  kind: FieldKind.wholeNumber,
                  read: (v) => '${SystemSettings(v).numberOfBackups}',
                ),
              ],
            ),
          ],
          preview: (values) => _FormatPreview(values),
        );
      });
    });
  }
}

/// Today's date and 1234567.891 in the formats being edited (SET-R5).
class _FormatPreview extends ConsumerWidget {
  const _FormatPreview(this.values);

  final Map<String, String> values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(formatsProvider);
    final f = Formats(
      system: SystemSettings(values),
      defaults: current.defaults,
      currency: current.currency,
    );
    final now = DateTime.now();
    return Card.filled(
      child: ListTile(
        title: Text(AppLocalizations.of(context).preview),
        subtitle: Text(
          '${f.date(now)}  ${f.time(now)}\n${f.number(1234567.891)}  ·  ${f.money(1234567.891)}',
        ),
      ),
    );
  }
}

class GlobalDefaultsPage extends ConsumerWidget {
  const GlobalDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(singleProvider(StoreProfile.doctype));
    return _when(store, (store) {
      return SinglesForm(
        doctype: GlobalDefaults.doctype,
        title: l.globalDefaults,
        sections: [
          (
            l.sectionDefaults,
            [
              SingleField(
                'default_currency',
                l.defaultCurrency,
                kind: FieldKind.info,
                read: (_) => StoreProfile(store).defaultCurrency ?? '',
              ),
              SingleField(
                'hide_currency_symbol',
                l.hideCurrencySymbol,
                kind: FieldKind.check,
                read: (v) => _flag(GlobalDefaults(v).hideCurrencySymbol),
              ),
              SingleField(
                'disable_rounded_total',
                l.disableRoundedTotal,
                kind: FieldKind.check,
                read: (v) => _flag(GlobalDefaults(v).disableRoundedTotal),
              ),
              SingleField(
                'disable_in_words',
                l.disableInWords,
                kind: FieldKind.check,
                read: (v) => _flag(GlobalDefaults(v).disableInWords),
              ),
            ],
          ),
        ],
      );
    });
  }
}

final _enabledPriceListsProvider = StreamProvider.autoDispose<List<String>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.priceList,
  )..where((p) => p.enabled.equals(1))).map((p) => p.name).watch();
});

class SellingSettingsPage extends ConsumerWidget {
  const SellingSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _when(ref.watch(_enabledPriceListsProvider), (lists) {
      return SinglesForm(
        doctype: SellingSettings.doctype,
        title: l.sellingSettings,
        sections: [
          (
            l.sectionDefaults,
            [
              SingleField(
                'selling_price_list',
                l.defaultPriceList,
                kind: FieldKind.choice,
                options: lists,
                read: (v) => SellingSettings(v).sellingPriceList,
              ),
              SingleField(
                'fallback_to_default_price_list',
                l.fallbackToDefaultPriceList,
                kind: FieldKind.check,
                read: (v) =>
                    _flag(SellingSettings(v).fallbackToDefaultPriceList),
              ),
              SingleField(
                'editable_price_list_rate',
                l.editablePriceListRate,
                kind: FieldKind.check,
                read: (v) => _flag(SellingSettings(v).editablePriceListRate),
              ),
              SingleField(
                'validate_selling_price',
                l.validateSellingPrice,
                kind: FieldKind.check,
                read: (v) => _flag(SellingSettings(v).validateSellingPrice),
              ),
            ],
          ),
        ],
      );
    });
  }
}

/// What the POS Settings links can name: enabled modes, print headings,
/// enabled terms.
final _posChoicesProvider =
    FutureProvider.autoDispose<
      ({List<String> modes, List<String> headings, List<String> terms})
    >((ref) async {
      final db = ref.watch(appDatabaseProvider);
      return (
        modes: await (db.select(
          db.modeOfPayment,
        )..where((m) => m.enabled.equals(1))).map((m) => m.name).get(),
        headings: await db.select(db.printHeading).map((h) => h.name).get(),
        terms: await (db.select(
          db.termsAndConditions,
        )..where((t) => t.disabled.equals(0))).map((t) => t.title).get(),
      );
    });

/// The one Cash Register's settings (SET-R14). The warehouse, price list,
/// taxes and letter head are the store defaults: Stock Settings, Selling
/// Settings, the default tax template and the default Letter Head.
class PosSettingsPage extends ConsumerWidget {
  const PosSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _when(ref.watch(_posChoicesProvider), (choices) {
      String noneOr(String o) => o.isEmpty ? l.none : o;
      SingleField check(
        String key,
        String label,
        bool Function(PosSettings) read,
      ) => SingleField(
        key,
        label,
        kind: FieldKind.check,
        read: (v) => _flag(read(PosSettings(v))),
      );
      return SinglesForm(
        doctype: PosSettings.doctype,
        title: l.posSettings,
        sections: [
          (
            l.paymentMethods,
            [
              SingleField(
                'default_mode_of_payment',
                l.defaultModeOfPayment,
                kind: FieldKind.choice,
                options: choices.modes,
                read: (v) => PosSettings(v).defaultModeOfPayment,
              ),
            ],
          ),
          (
            l.configurations,
            [
              check('hide_images', l.hideImages, (s) => s.hideImages),
              check(
                'hide_unavailable_items',
                l.hideUnavailableItems,
                (s) => s.hideUnavailableItems,
              ),
              check(
                'allow_rate_change',
                l.allowRateChange,
                (s) => s.allowRateChange,
              ),
              check(
                'auto_add_item_to_cart',
                l.autoAddItemToCart,
                (s) => s.autoAddItemToCart,
              ),
              check(
                'allow_discount_change',
                l.allowDiscountChange,
                (s) => s.allowDiscountChange,
              ),
              check(
                'validate_stock_on_save',
                l.validateStockOnSave,
                (s) => s.validateStockOnSave,
              ),
              check(
                'set_grand_total_to_default_mop',
                l.setGrandTotalToDefaultMop,
                (s) => s.setGrandTotalToDefaultMop,
              ),
              check(
                'print_receipt_on_order_complete',
                l.printReceiptOnOrderComplete,
                (s) => s.printReceiptOnOrderComplete,
              ),
              SingleField(
                'action_on_new_invoice',
                l.actionOnNewInvoice,
                kind: FieldKind.choice,
                options: const [
                  'Always Ask',
                  'Save Changes and Load New Invoice',
                  'Discard Changes and Load New Invoice',
                ],
                read: (v) => PosSettings(v).actionOnNewInvoice,
              ),
              // Net Total spreads the discount over the items before tax;
              // Grand Total takes it off the after-tax total.
              SingleField(
                'apply_discount_on',
                l.applyDiscountOn,
                kind: FieldKind.choice,
                options: const ['Grand Total', 'Net Total'],
                read: (v) => PosSettings(v).applyDiscountOn,
              ),
            ],
          ),
          (
            l.printSettings,
            [
              SingleField(
                'print_format',
                l.printFormat,
                kind: FieldKind.choice,
                options: const ['POS Receipt', 'Standard'],
                read: (v) => PosSettings(v).printFormat,
              ),
              SingleField(
                'select_print_heading',
                l.printHeading,
                kind: FieldKind.choice,
                options: ['', ...choices.headings],
                optionLabel: noneOr,
                read: (v) => PosSettings(v).selectPrintHeading ?? '',
              ),
              SingleField(
                'tc_name',
                l.termsAndConditions,
                kind: FieldKind.choice,
                options: ['', ...choices.terms],
                optionLabel: noneOr,
                read: (v) => PosSettings(v).tcName ?? '',
              ),
            ],
          ),
        ],
      );
    });
  }
}

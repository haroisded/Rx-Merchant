import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_info.dart';
import '../data/seed.dart';
import 'data_pages.dart';
import 'form_kit.dart';
import 'settings_pages.dart';

const _steps = 4;

/// The first-run wizard (SET-R1, SET-B1): Language, Region, Store, Done.
/// Finishing writes every seed record in one transaction; the router then
/// leaves the wizard for the destination named in `?next=`.
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  var _step = 0;
  var _language = languageCodes.first;
  CountryInfo? _country;
  CountryInfo? _currencyOf;
  final _storeName = TextEditingController();
  final _abbr = TextEditingController();
  var _abbrEdited = false;
  var _busy = false;

  @override
  void dispose() {
    _storeName.dispose();
    _abbr.dispose();
    super.dispose();
  }

  bool get _canGoOn => switch (_step) {
    1 => _country != null && _currencyOf != null,
    2 => _storeName.text.trim().isNotEmpty,
    _ => true,
  };

  void _pickCountry(CountryInfo? c) => setState(() {
    _country = c;
    // The currency follows the country until changed (01-setup, section 5).
    _currencyOf = c?.currency == null ? null : c;
  });

  /// Restores a backup instead of setting up. With setup complete in the
  /// restored data, the router leaves the wizard by itself.
  Future<void> _restore() async {
    final l = AppLocalizations.of(context);
    final path = await pickBackupCopy();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    final ok = await attempt(
      context,
      () => restoreAndReopen(ref, path),
      done: l.restored,
    );
    if (!ok && mounted) setState(() => _busy = false);
  }

  Future<void> _finish(String next) async {
    setState(() => _busy = true);
    context.go('/wizard?next=$next');
    final ok = await attempt(
      context,
      () => ref
          .read(appDatabaseProvider)
          .completeSetup(
            language: _language,
            country: _country!,
            currencyOf: _currencyOf!,
            storeName: _storeName.text.trim(),
            abbr: _abbr.text.trim(),
          ),
    );
    if (!ok && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final countries = ref.watch(countryInfoProvider);
    // Preselects the device's country once the list is read.
    if (countries.value case final list? when _country == null) {
      final code =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      final here = list
          .where((c) => c.code == code && c.currency != null)
          .firstOrNull;
      if (here != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _pickCountry(here));
      }
    }

    final step = switch (_step) {
      0 => _languageStep(l),
      1 => _regionStep(l, countries.value ?? []),
      2 => _storeStep(l),
      _ => _doneStep(l),
    };
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.stepOf(_step + 1, _steps),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: (_step + 1) / _steps),
        const SizedBox(height: AppSpacing.lg),
        Flexible(child: SingleChildScrollView(child: step)),
        const SizedBox(height: AppSpacing.lg),
        if (_step < _steps - 1)
          Row(
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(l.back),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _canGoOn ? () => setState(() => _step++) : null,
                child: Text(l.next),
              ),
            ],
          ),
      ],
    );

    final compact = WindowSize.of(context) == WindowSize.compact;
    return Scaffold(
      appBar: compact ? AppBar(title: Text(l.wizardTitle)) : null,
      body: SafeArea(
        child: compact
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: content,
              )
            : Center(
                child: SizedBox(
                  width: 560,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.wizardTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Flexible(child: content),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _languageStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l.wizardLanguage, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.md),
      for (final code in languageCodes)
        ListTile(
          title: Text(languageName(code)),
          selected: code == _language,
          trailing: code == _language ? const Icon(Icons.check) : null,
          onTap: () => setState(() => _language = code),
        ),
      // A new device can take an old store's data instead of setting up
      // again (SET-R18). Setup is behind the wizard gate, so it starts here.
      const SizedBox(height: AppSpacing.lg),
      const Divider(),
      const SizedBox(height: AppSpacing.md),
      Text(l.wizardRestoreHint),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: _busy ? null : _restore,
        icon: const Icon(Icons.restore),
        label: Text(l.restoreFromBackup),
      ),
    ],
  );

  Widget _regionStep(AppLocalizations l, List<CountryInfo> countries) {
    final country = _country;
    final currencies = {for (final c in countries) ?c.currency: c};
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.wizardRegion, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        LinkField<CountryInfo>(
          label: l.country,
          mandatory: true,
          value: country,
          labelOf: (c) => c.name,
          search: (q) async => countries.where(
            (c) => c.name.toLowerCase().contains(q.toLowerCase()),
          ),
          onChanged: _pickCountry,
        ),
        const SizedBox(height: AppSpacing.md),
        LinkField<CountryInfo>(
          label: l.currency,
          mandatory: true,
          value: _currencyOf,
          labelOf: (c) => '${c.currency} · ${c.currencyName ?? ''}',
          search: (q) async =>
              (currencies.values.toList()
                    ..sort((a, b) => a.currency!.compareTo(b.currency!)))
                  .where(
                    (c) => '${c.currency} ${c.currencyName}'
                        .toLowerCase()
                        .contains(q.toLowerCase()),
                  ),
          onChanged: (c) => setState(() => _currencyOf = c),
        ),
        if (country != null) ...[
          const SizedBox(height: AppSpacing.md),
          Card.filled(
            child: ListTile(
              title: Text(l.preview),
              subtitle: Text(
                '${l.dateFormat}: ${formatDate(now, country.dateFormat)}\n'
                '${l.numberFormat}: ${formatNumber(1234567.891, country.numberFormat, _currencyOf?.currencyPrecision ?? 2)}',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _storeStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l.wizardStore, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _storeName,
        decoration: InputDecoration(labelText: '${l.storeName} *'),
        textCapitalization: TextCapitalization.words,
        onChanged: (name) => setState(() {
          // Suggested from the initials until the owner edits it.
          if (!_abbrEdited) {
            _abbr.text = StoreProfile({'store_name': name}).abbr;
          }
        }),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _abbr,
        decoration: InputDecoration(labelText: l.abbreviation),
        onChanged: (_) => _abbrEdited = true,
      ),
    ],
  );

  Widget _doneStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l.wizardDone, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      Text(l.wizardDoneBody(_storeName.text.trim())),
      const SizedBox(height: AppSpacing.lg),
      FilledButton.icon(
        onPressed: _busy ? null : () => _finish('/pos'),
        icon: const Icon(Icons.point_of_sale),
        label: Text(l.openCashRegister),
      ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _finish('/stock/item/new'),
        icon: const Icon(Icons.inventory_2_outlined),
        label: Text(l.addFirstItem),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _step--),
        child: Text(l.back),
      ),
    ],
  );
}

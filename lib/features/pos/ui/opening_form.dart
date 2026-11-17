import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/simple_masters.dart' show modesOfPaymentProvider;
import '../data/pos_closing_db.dart';
import '../data/pos_db.dart';
import 'pos_providers.dart';
import 'pos_widgets.dart';

/// POS-R1, R2: shown while no session is open. One Opening Amount per
/// enabled Mode of Payment, zero by default; "Open" submits the POS Opening
/// Entry. When the last session was closed and nothing newer exists, its
/// closing entry can be cancelled here, which reopens it (POS-R20).
class OpeningForm extends ConsumerStatefulWidget {
  const OpeningForm({super.key});

  @override
  ConsumerState<OpeningForm> createState() => _OpeningFormState();
}

class _OpeningFormState extends ConsumerState<OpeningForm> {
  final _amounts = <int, double>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final db = ref.watch(appDatabaseProvider);
    final modes = [
      for (final m in ref.watch(modesOfPaymentProvider).value ?? [])
        if (m.enabled == 1) m,
    ];
    final closing = ref.watch(cancellableClosingProvider).value;
    final fields = [
      Text(l.openingHelp),
      for (final m in modes)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: LiveNumberField(
            key: ValueKey(m.id),
            label: '${m.name} · ${l.openingAmount}',
            value: _amounts[m.id] ?? 0,
            precision: formats.system.currencyPrecision,
            formats: formats,
            onChanged: (v) => _amounts[m.id] = v,
          ),
        ),
    ];
    final actions = [
      if (closing != null)
        TextButton(
          onPressed: () async {
            final name = closing.name ?? '';
            if (await confirm(
                  context,
                  title: l.cancelLastClosing(name),
                  body: l.cancelClosingBody,
                  action: l.cancelLastClosing(name),
                ) &&
                context.mounted) {
              await attempt(context, db.cancelLastClosing);
            }
          },
          child: Text(l.cancelLastClosing(closing.name ?? '')),
        ),
      FilledButton(
        onPressed: () => attempt(
          context,
          () => db.openSessionWith({
            for (final m in modes) m.id: _amounts[m.id] ?? 0,
          }),
        ),
        child: Text(l.openSession),
      ),
    ];
    // Section 5: an AlertDialog on Compact, a centred card otherwise.
    if (WindowSize.of(context) == WindowSize.compact) {
      return AlertDialog(
        scrollable: true,
        title: Text(l.posOpeningEntry),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: fields,
        ),
        actions: actions,
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.posOpeningEntry,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...fields,
                  const SizedBox(height: AppSpacing.lg),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: AppSpacing.sm,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

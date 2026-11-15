import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder for the first-run wizard, which is built in milestone M1
/// (SET-B1). It does the one thing the gate needs: mark setup as complete.
/// The real wizard replaces this file.
class WizardScreen extends ConsumerWidget {
  const WizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wizardTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.wizardPlaceholder, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => ref.read(appDatabaseProvider).writeSingle(
                    SystemSettings.doctype,
                    {'setup_complete': true},
                  ),
                  child: Text(l10n.wizardFinish),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

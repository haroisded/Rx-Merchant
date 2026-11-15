import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/db/providers.dart';
import 'core/widgets/adaptive_shell.dart';
import 'features/setup/ui/wizard_screen.dart';
import 'l10n/app_localizations.dart';

const _loading = '/loading';
const _wizard = '/wizard';
const _home = '/pos';

/// The five destinations, in the order of 00-overview section 7.3, each with
/// its screen title. Each is a placeholder until its feature milestone
/// replaces the builder.
final _destinations = <(String, String Function(AppLocalizations))>[
  (_home, (l) => l.titleCashRegister),
  ('/invoices', (l) => l.navInvoices),
  ('/stock', (l) => l.navStock),
  ('/dashboard', (l) => l.navDashboard),
  ('/setup', (l) => l.navSetup),
];

final routerProvider = Provider<GoRouter>((ref) {
  // null while System Settings is still being read.
  final setupComplete = ValueNotifier<bool?>(null);
  ref.listen(
    systemSettingsProvider,
    (_, settings) => setupComplete.value = settings.value?.setupComplete,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: _home,
    refreshListenable: setupComplete,
    // The setup gate (SET-R1): until setup is complete the app shows only
    // the wizard; afterwards the wizard is unreachable.
    redirect: (context, state) {
      final at = state.matchedLocation;
      final target = switch (setupComplete.value) {
        null => _loading,
        false => _wizard,
        true => at == _wizard || at == _loading ? _home : at,
      };
      return target == at ? null : target;
    },
    routes: [
      GoRoute(path: _loading, builder: (_, _) => const _LoadingScreen()),
      GoRoute(path: _wizard, builder: (_, _) => const WizardScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdaptiveShell(navigationShell: shell),
        branches: [
          for (final (path, title) in _destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (context, _) => _PlaceholderScreen(
                    title: title(AppLocalizations.of(context)),
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    setupComplete.dispose();
  });
  return router;
});

/// Shown for the moment it takes to read System Settings; blank unless the
/// database cannot be opened.
class _LoadingScreen extends ConsumerWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(systemSettingsProvider).error;
    return Scaffold(
      body: error == null
          ? null
          : Center(
              child: Text(
                '${AppLocalizations.of(context).startupError}\n$error',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(AppLocalizations.of(context).comingSoon)),
    );
  }
}

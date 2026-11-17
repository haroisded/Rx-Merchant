import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/db/providers.dart';
import 'core/widgets/adaptive_shell.dart';
import 'core/widgets/window_size.dart';
import 'features/pos/ui/pos_providers.dart' show posPath;
import 'features/pos/ui/pos_screen.dart';
import 'features/setup/ui/setup_screen.dart';
import 'features/stock/ui/stock_providers.dart';
import 'features/stock/ui/stock_screen.dart';
import 'features/setup/ui/wizard_screen.dart';
import 'l10n/app_localizations.dart';

const _loading = '/loading';
const _wizard = '/wizard';
const _home = posPath;

/// The five destinations, in the order of 00-overview section 7.3, each with
/// its screen title. Each is a placeholder until its feature milestone
/// replaces the builder.
final _destinations = <(String, String Function(AppLocalizations))>[
  (_home, (l) => l.titleCashRegister),
  ('/invoices', (l) => l.navInvoices),
  (stockPath, (l) => l.navStock),
  ('/dashboard', (l) => l.navDashboard),
  (setupPath, (l) => l.navSetup),
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
        // The wizard's Done step names where to land in `?next=`.
        true when at == _wizard => state.uri.queryParameters['next'] ?? _home,
        true => at == _loading ? _home : at,
      };
      return target == at ? null : target;
    },
    routes: [
      GoRoute(path: _loading, builder: (_, _) => const _LoadingScreen()),
      GoRoute(path: _wizard, builder: (_, _) => const WizardScreen()),
      StatefulShellRoute.indexedStack(
        // STK-R12: the low-stock count on the Stock destination.
        builder: (_, _, shell) => Consumer(
          builder: (_, ref, _) => AdaptiveShell(
            navigationShell: shell,
            stockBadge: ref.watch(stockSettingsProvider).autoIndent
                ? ref.watch(lowStockCountProvider).value ?? 0
                : 0,
          ),
        ),
        branches: [
          for (final (path, title) in _destinations)
            StatefulShellBranch(
              routes: [
                if (path == posPath)
                  _workspaceRoute(posPath, (page, _, _) => posPage(page))
                else if (path == setupPath)
                  _workspaceRoute(
                    setupPath,
                    (page, id, _) => SetupScreen(page: page, id: id),
                  )
                else if (path == stockPath)
                  _workspaceRoute(
                    stockPath,
                    (page, id, query) =>
                        StockScreen(page: page, id: id, query: query),
                  )
                else
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

/// A workspace destination: `[path]`, `[path]/:page` and `[path]/:page/:id`
/// (`id` is `new` for a new record; report filters come as query
/// parameters). On an expanded window the list stays put beside the page,
/// so moving between them does not animate.
GoRoute _workspaceRoute(
  String path,
  Widget Function(String? page, String? id, Map<String, String> query) build,
) {
  Page<void> page(BuildContext context, GoRouterState state) {
    final child = build(
      state.pathParameters['page'],
      state.pathParameters['id'],
      state.uri.queryParameters,
    );
    return WindowSize.of(context) == WindowSize.expanded
        ? NoTransitionPage(key: state.pageKey, child: child)
        : MaterialPage(key: state.pageKey, child: child);
  }

  return GoRoute(
    path: path,
    pageBuilder: page,
    routes: [
      GoRoute(
        path: ':page',
        pageBuilder: page,
        routes: [GoRoute(path: ':id', pageBuilder: page)],
      ),
    ],
  );
}

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

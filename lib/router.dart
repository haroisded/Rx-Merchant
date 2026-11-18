import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/db/providers.dart';
import 'core/widgets/adaptive_shell.dart';
import 'core/widgets/window_size.dart';
import 'features/dashboard/ui/dashboard_providers.dart' show dashboardPath;
import 'features/dashboard/ui/dashboard_screen.dart';
import 'features/dashboard/ui/sales_report_pages.dart';
import 'features/invoices/ui/invoice_providers.dart' show invoicesPath;
import 'features/invoices/ui/invoices_screen.dart';
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
        // The five destinations, in the order of 00-overview section 7.3.
        branches: [
          for (final route in [
            _workspaceRoute(posPath, (page, _, query) => posPage(page, query)),
            _workspaceRoute(
              invoicesPath,
              (page, id, query) =>
                  InvoicesScreen(page: page, id: id, query: query),
            ),
            _workspaceRoute(
              stockPath,
              (page, id, query) =>
                  StockScreen(page: page, id: id, query: query),
            ),
            // Full width: the reports open over the dashboard.
            _workspaceRoute(
              dashboardPath,
              (page, _, query) =>
                  (page == null ? null : salesReportPage(page, query)) ??
                  const DashboardScreen(),
            ),
            _workspaceRoute(
              setupPath,
              (page, id, _) => SetupScreen(page: page, id: id),
            ),
          ])
            StatefulShellBranch(routes: [route]),
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

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'window_size.dart';

/// The frame around the five destinations (00-overview, sections 7.2, 7.3):
/// a bottom NavigationBar on compact windows, a NavigationRail on medium ones,
/// and a NavigationRail with labels on expanded ones.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
    this.stockBadge = 0,
  });

  final StatefulNavigationShell navigationShell;

  /// A count shown on the Stock destination (the low-stock items, STK-R12);
  /// 0 shows none.
  final int stockBadge;

  // Tapping the destination already shown returns it to its first screen.
  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Order is fixed by section 7.3 and must match the router's branches.
    final destinations = [
      (
        Icons.point_of_sale_outlined,
        Icons.point_of_sale,
        l10n.navCashRegister,
        0,
      ),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navInvoices, 0),
      (
        Icons.inventory_2_outlined,
        Icons.inventory_2,
        l10n.navStock,
        stockBadge,
      ),
      (Icons.dashboard_outlined, Icons.dashboard, l10n.navDashboard, 0),
      (Icons.settings_outlined, Icons.settings, l10n.navSetup, 0),
    ];
    Widget icon(IconData data, int badge) =>
        badge > 0 ? Badge.count(count: badge, child: Icon(data)) : Icon(data);
    final size = WindowSize.of(context);

    if (size == WindowSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (final (outline, selected, label, badge) in destinations)
              NavigationDestination(
                icon: icon(outline, badge),
                selectedIcon: icon(selected, badge),
                label: label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              // A short landscape window scrolls the rail instead of overflowing.
              scrollable: true,
              labelType: size == WindowSize.expanded
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.none,
              destinations: [
                for (final (outline, selected, label, badge) in destinations)
                  NavigationRailDestination(
                    icon: icon(outline, badge),
                    selectedIcon: icon(selected, badge),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}

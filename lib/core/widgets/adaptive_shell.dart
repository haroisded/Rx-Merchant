import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'window_size.dart';

/// The frame around the five destinations (00-overview, sections 7.2, 7.3):
/// a bottom NavigationBar on compact windows, a NavigationRail on medium ones,
/// and a NavigationRail with labels on expanded ones.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
      (Icons.point_of_sale_outlined, Icons.point_of_sale, l10n.navCashRegister),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navInvoices),
      (Icons.inventory_2_outlined, Icons.inventory_2, l10n.navStock),
      (Icons.dashboard_outlined, Icons.dashboard, l10n.navDashboard),
      (Icons.settings_outlined, Icons.settings, l10n.navSetup),
    ];
    final size = WindowSize.of(context);

    if (size == WindowSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (final (icon, selectedIcon, label) in destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selectedIcon),
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
                for (final (icon, selectedIcon, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
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

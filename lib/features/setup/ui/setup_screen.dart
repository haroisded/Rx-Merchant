import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/list_detail_pane.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../invoices/ui/printing_pages.dart';
import '../../stock/ui/stock_masters_pages.dart';
import 'data_pages.dart';
import 'naming_series_page.dart';
import 'settings_pages.dart';
import 'simple_masters.dart';
import 'tax_template_pages.dart';

const setupPath = '/setup';

/// The page at `/setup/[slug]`, with record [id] for masters; null for an
/// unknown slug.
Widget? setupPage(String slug, String? id) {
  final path = '$setupPath/$slug';
  return switch (slug) {
    'store-profile' => const StoreProfilePage(),
    'system-settings' => const SystemSettingsPage(),
    'global-defaults' => const GlobalDefaultsPage(),
    'currency' => const CurrencyPage(),
    'pos-settings' => const PosSettingsPage(),
    'mode-of-payment' => ModeOfPaymentPage(path: path, id: id),
    'price-list' => PriceListPage(path: path, id: id),
    'selling-settings' => const SellingSettingsPage(),
    'tax' => TaxPage(path: path, id: id),
    'sales-taxes-template' => SalesTaxesTemplatePage(path: path, id: id),
    'item-tax-template' => ItemTaxTemplatePage(path: path, id: id),
    'stock-settings' => const StockSettingsPage(),
    'naming-series' => const NamingSeriesPage(),
    'data-import' => const DataImportPage(),
    'data-export' => const DataExportPage(),
    'backups' => const BackupsPage(),
    'print-settings' => const PrintSettingsPage(),
    'letter-head' => LetterHeadPage(path: path, id: id),
    'print-heading' => PrintHeadingPage(path: path, id: id),
    'terms-and-conditions' => TermsPage(path: path, id: id),
    _ => null,
  };
}

/// The Setup destination: the workspace list, and the chosen page beside it
/// on an expanded window or instead of it otherwise (01-setup, section 5).
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.page, this.id});

  final String? page;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final page = this.page;
    return ListDetailPane(
      list: SetupHome(selected: page),
      detail: page == null
          ? null
          : KeyedSubtree(
              key: ValueKey('$page/$id'),
              child: setupPage(page, id) ?? const SizedBox.shrink(),
            ),
    );
  }
}

/// The workspace: grouped cards of links, as on an ERPNext workspace.
class SetupHome extends StatelessWidget {
  const SetupHome({super.key, this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = <(String, List<(String, String)>)>[
      (
        l.groupStore,
        [
          ('store-profile', l.storeProfile),
          ('system-settings', l.systemSettings),
          ('global-defaults', l.globalDefaults),
          ('currency', l.currency),
        ],
      ),
      (
        l.groupSelling,
        [
          ('pos-settings', l.posSettings),
          ('mode-of-payment', l.modeOfPayment),
          ('price-list', l.priceList),
          ('selling-settings', l.sellingSettings),
        ],
      ),
      (
        l.groupTaxes,
        [
          ('tax', l.tax),
          ('sales-taxes-template', l.salesTaxesTemplate),
          ('item-tax-template', l.itemTaxTemplate),
        ],
      ),
      (l.groupStock, [('stock-settings', l.stockSettings)]),
      (
        l.groupPrinting,
        [
          ('print-settings', l.printSettings),
          ('letter-head', l.letterHead),
          ('print-heading', l.printHeading),
          ('terms-and-conditions', l.termsAndConditions),
        ],
      ),
      (
        l.groupData,
        [
          ('naming-series', l.namingSeries),
          ('data-import', l.dataImport),
          ('data-export', l.dataExport),
          ('backups', l.backups),
        ],
      ),
    ];
    return Scaffold(
      // The workspace is the root of Setup; beside a page it has no Back.
      appBar: AppBar(title: Text(l.navSetup), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          for (final (title, links) in groups)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final (slug, label) in links)
                    ListTile(
                      title: Text(label),
                      selected: slug == selected,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('$setupPath/$slug'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/list_detail_pane.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import 'item_pages.dart';
import 'report_pages.dart';
import 'stock_entry_page.dart';
import 'stock_masters_pages.dart';
import 'stock_providers.dart';
import 'stock_reconciliation_page.dart';
import 'tree_masters.dart';

const stockPath = '/stock';

/// The page at `/stock/[slug]`, with record [id] for masters and documents
/// and report filters in [query]; null for an unknown slug.
Widget? stockPage(String slug, String? id, Map<String, String> query) {
  final path = '$stockPath/$slug';
  return switch (slug) {
    'item' => ItemPage(path: path, id: id),
    'item-group' => ItemGroupPage(path: path, id: id, query: query),
    'item-price' => ItemPricePage(path: path, id: id, query: query),
    'brand' => BrandPage(path: path, id: id),
    'item-attribute' => ItemAttributePage(path: path, id: id),
    'stock-entry' => StockEntryPage(path: path, id: id, query: query),
    'stock-reconciliation' => StockReconciliationPage(path: path, id: id),
    'serial-no' => SerialNoPage(path: path, id: id),
    'batch' => BatchPage(path: path, id: id),
    'stock-settings' => const StockSettingsPage(),
    'warehouse' => WarehousePage(path: path, id: id, query: query),
    'uom' => UomPage(path: path, id: id),
    _ => switch (StockReport.of(slug)) {
      final report? => ReportPage(
        key: ValueKey('$slug?$query'),
        report: report,
        query: query,
      ),
      null => null,
    },
  };
}

/// The Stock destination: the workspace, and the chosen page beside it on
/// an expanded window. With a record open, its list takes the left pane, as
/// the Item list does beside the Item form (02-stock section 5).
class StockScreen extends StatelessWidget {
  const StockScreen({super.key, this.page, this.id, this.query = const {}});

  final String? page;
  final String? id;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final page = this.page;
    return ListDetailPane(
      list: page != null && id != null
          ? stockPage(page, null, const {}) ?? StockHome(selected: page)
          : StockHome(selected: page),
      detail: page == null
          ? null
          : KeyedSubtree(
              key: ValueKey('$page/$id/$query'),
              child: stockPage(page, id, query) ?? const SizedBox.shrink(),
            ),
    );
  }
}

/// Grouped cards, as on ERPNext's Stock workspace (02-stock section 5).
class StockHome extends ConsumerWidget {
  const StockHome({super.key, this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(stockSettingsProvider);
    final low = settings.autoIndent
        ? ref.watch(lowStockCountProvider).value ?? 0
        : 0;
    final groups = <(String, List<(String, String)>)>[
      (
        l.groupItemsAndPricing,
        [
          ('item', l.item),
          ('item-group', l.itemGroup),
          ('item-price', l.itemPrice),
          ('brand', l.brand),
          ('item-attribute', l.itemAttribute),
        ],
      ),
      (
        l.groupStockTransactions,
        [
          ('stock-entry', l.stockEntry),
          ('stock-reconciliation', l.stockReconciliation),
        ],
      ),
      if (settings.enableSerialAndBatchNoForItem)
        (
          l.groupSerialAndBatch,
          [('serial-no', l.serialNo), ('batch', l.batch)],
        ),
      (
        l.groupSettings,
        [
          ('stock-settings', l.stockSettings),
          ('warehouse', l.warehouse),
          ('uom', l.uom),
        ],
      ),
      (
        l.groupReports,
        [for (final r in StockReport.values) (r.slug, r.title(l))],
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navStock), automaticallyImplyLeading: false),
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
                      trailing: slug == StockReport.lowStock.slug && low > 0
                          ? Badge.count(count: low)
                          : const Icon(Icons.chevron_right),
                      onTap: () => context.go('$stockPath/$slug'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

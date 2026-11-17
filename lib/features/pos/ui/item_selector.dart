import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../../stock/logic/stock_documents.dart';
import '../../stock/ui/scan.dart';
import '../../stock/ui/stock_providers.dart';
import '../../stock/ui/stock_screen.dart' show stockPath;
import '../data/pos_db.dart';
import 'pos_providers.dart';

/// POS-R3, R4, R21: the items the register sells. Search by name, code,
/// barcode or serial number; filter by Item Group; tap to add. An exact
/// barcode or Available serial number adds at once.
class ItemSelector extends ConsumerStatefulWidget {
  const ItemSelector({super.key});

  @override
  ConsumerState<ItemSelector> createState() => _ItemSelectorState();
}

class _ItemSelectorState extends ConsumerState<ItemSelector> {
  final _search = TextEditingController();
  var _query = '';
  int? _group;
  Timer? _autoAdd;

  @override
  void dispose() {
    _autoAdd?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<RegisterItem> _shown(List<RegisterItem> items) {
    final hideUnavailable = ref.read(posSettingsProvider).hideUnavailableItems;
    final groups = _group == null
        ? null
        : _descendants(ref.read(itemGroupsProvider).value ?? [], _group!);
    final q = _query.trim().toLowerCase();
    return [
      for (final i in items)
        if ((groups == null || groups.contains(i.groupId)) &&
            (!hideUnavailable || !i.stockItem || i.qty > 0) &&
            '${i.code} ${i.name} ${i.barcodes}'.toLowerCase().contains(q))
          i,
    ];
  }

  Future<void> _add(RegisterItem item, {int? uomId, SbEntry? entry}) => attempt(
    context,
    () => ref.read(cartProvider.notifier).add(item, uomId: uomId, entry: entry),
  );

  void _clear() {
    _search.clear();
    setState(() => _query = '');
  }

  /// POS-R4, R21: a scanned or entered code: a barcode (in its unit), else
  /// an Available serial number in the sale's warehouse.
  Future<void> _submit(String code) async {
    if (code.trim().isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    final items = ref.read(registerItemsProvider).value ?? [];
    RegisterItem? of(int id) => items.where((i) => i.id == id).firstOrNull;
    final byBarcode = await itemByBarcode(db, code);
    if (byBarcode case (:final itemId, :final uomId)?) {
      if (of(itemId) case final item?) {
        _clear();
        return _add(item, uomId: uomId);
      }
    }
    final sale = ref.read(cartProvider).value;
    if (sale == null) return;
    final serial = await db.availableSerial(code, sale.warehouseId);
    if (serial case (:final itemId, :final entry)?) {
      if (of(itemId) case final item?) {
        _clear();
        return _add(item, entry: entry);
      }
    }
    if (_shown(items).isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).barcodeNotFound(code)),
        ),
      );
    }
  }

  /// Automatically Add Filtered Item To Cart: a search that leaves exactly
  /// one item adds it.
  void _changed(String q) {
    setState(() => _query = q);
    _autoAdd?.cancel();
    if (!ref.read(posSettingsProvider).autoAddItemToCart || q.isEmpty) return;
    _autoAdd = Timer(const Duration(milliseconds: 300), () {
      final shown = _shown(ref.read(registerItemsProvider).value ?? []);
      if (mounted && shown.length == 1) {
        _clear();
        _add(shown.single);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pos = ref.watch(posSettingsProvider);
    final groups = ref.watch(itemGroupsProvider).value ?? [];
    final shown = _shown(ref.watch(registerItemsProvider).value ?? []);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SearchBar(
            controller: _search,
            hintText: l.searchItemHint,
            leading: const Icon(Icons.search),
            trailing: [ScanButton(onScanned: _submit)],
            onChanged: _changed,
            onSubmitted: _submit,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: DropdownMenu<int?>(
            expandedInsets: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            label: Text(l.itemGroup),
            initialSelection: _group,
            onSelected: (g) => setState(() => _group = g),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: null, label: l.all),
              for (final g in groups)
                DropdownMenuEntry(value: g.id, label: g.name),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.noItemsFound),
                      if (_query.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () => context.go('$stockPath/item/new'),
                          icon: const Icon(Icons.add),
                          label: Text(l.addItem),
                        ),
                    ],
                  ),
                )
              : pos.hideImages
              ? ListView(
                  children: [
                    for (final i in shown)
                      _ItemTile(item: i, onTap: () => _add(i)),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, box) => GridView.count(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    // Section 5: 2 columns on a phone, 2 to 3 on Medium, 4 or
                    // more on Expanded.
                    crossAxisCount: switch (WindowSize.of(context)) {
                      WindowSize.compact => 2,
                      WindowSize.medium => (box.maxWidth / 170).floor().clamp(
                        2,
                        3,
                      ),
                      WindowSize.expanded => math.max(
                        4,
                        (box.maxWidth / 170).floor(),
                      ),
                    },
                    childAspectRatio: 0.8,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    children: [
                      for (final i in shown)
                        _ItemCard(item: i, onTap: () => _add(i)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// [root] and every group below it.
Set<int> _descendants(List<ItemGroupData> all, int root) {
  final out = {root};
  for (var grew = true; grew;) {
    grew = false;
    for (final g in all) {
      if (g.parentId != null && out.contains(g.parentId) && out.add(g.id)) {
        grew = true;
      }
    }
  }
  return out;
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.onTap});

  final RegisterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formats = ref.watch(formatsProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bytes = item.hasImage
        ? ref.watch(itemImageProvider(item.id)).value
        : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                          style: text.headlineMedium,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  Text(formats.money(item.price ?? 0), style: text.bodyMedium),
                  if (item.stockItem)
                    Text(
                      formats.number(item.qty),
                      style: text.bodySmall?.copyWith(
                        color: item.qty <= 0 ? scheme.error : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list form of the selector when Hide images is on.
class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.onTap});

  final RegisterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formats = ref.watch(formatsProvider);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.code),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formats.money(item.price ?? 0)),
          if (item.stockItem)
            Text(
              formats.number(item.qty),
              style: TextStyle(color: item.qty <= 0 ? scheme.error : null),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

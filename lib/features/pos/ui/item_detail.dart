import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../../stock/data/stock_entry_db.dart';
import '../../stock/logic/stock_documents.dart';
import '../../stock/logic/stock_rules.dart';
import '../../stock/ui/serial_batch_editor.dart';
import '../../stock/ui/stock_providers.dart';
import '../logic/sale.dart';
import 'pos_providers.dart';
import 'pos_widgets.dart';

/// The item detail panel (POS-R5 to R8, R21): quantity, unit, rate and
/// discount of one cart line, Price List Rate, available quantity and
/// warehouse, and its Serial / Batch Entries. Fields POS Settings and
/// Selling Settings do not allow are read-only.
class ItemDetail extends ConsumerWidget {
  const ItemDetail({super.key, required this.line, this.onClose});

  final SaleLine line;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sale = ref.watch(cartProvider).value;
    final formats = ref.watch(formatsProvider);
    final pos = ref.watch(posSettingsProvider);
    final selling = ref.watch(sellingSettingsProvider);
    final cart = ref.read(cartProvider.notifier);
    final item = (ref.watch(registerItemsProvider).value ?? [])
        .where((i) => i.id == line.itemId)
        .firstOrNull;
    final units = ref.watch(itemUnitsProvider(line.itemId)).value ?? [];
    final uomNames = {
      for (final u in ref.watch(uomsProvider).value ?? []) u.id: u.name,
    };
    final warehouse = (ref.watch(warehousesProvider).value ?? [])
        .where((w) => w.id == sale?.warehouseId)
        .firstOrNull;
    final money = formats.system.currencyPrecision;
    // POS-R8: a discount above the item's Max Discount (%) is refused.
    String? over(double percentage) {
      final max = item?.maxDiscount ?? 0;
      return max > 0 && percentage > max ? l.lineDiscountAboveMax : null;
    }

    final list = line.priceListRate;
    double pctOf(double off) => list == 0 ? 0 : off / list * 100;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                line.itemName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            IconButton.outlined(
              tooltip: l.remove,
              onPressed: line.qty > 1
                  ? () => cart.setQty(line, line.qty - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LiveNumberField(
                label: l.quantity,
                value: line.qty,
                formats: formats,
                onChanged: (v) => cart.setQty(line, v),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.outlined(
              tooltip: l.add,
              onPressed: () => cart.setQty(line, line.qty + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // D-22: the menu waits for its choices and their names.
        if (units.isNotEmpty && uomNames.isNotEmpty)
          DropdownMenu<int>(
            key: ValueKey(('uom', line.uomId)),
            expandedInsets: EdgeInsets.zero,
            label: Text(l.uom),
            initialSelection: line.uomId,
            onSelected: (u) {
              if (u != null) attempt(context, () => cart.setUnit(line, u));
            },
            dropdownMenuEntries: [
              for (final u in units)
                DropdownMenuEntry(
                  value: u.uomId,
                  label: uomNames[u.uomId] ?? '',
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        LiveNumberField(
          label: l.rate,
          value: line.rate,
          formats: formats,
          precision: money,
          enabled: pos.allowRateChange,
          check: (v) => over(pctOf(list - v)),
          onChanged: (v) => cart.setPrice(line, rate: v),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: LiveNumberField(
                label: l.discountPercentage,
                value: line.discountPercentage,
                formats: formats,
                precision: 2,
                enabled: pos.allowDiscountChange,
                check: over,
                onChanged: (v) => cart.setPrice(line, percentage: v),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LiveNumberField(
                label: l.discountAmount,
                value: line.discountAmount,
                formats: formats,
                precision: money,
                enabled: pos.allowDiscountChange,
                check: (v) => over(pctOf(v)),
                onChanged: (v) => cart.setPrice(line, amount: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LiveNumberField(
          label: l.priceListRate,
          value: line.priceListRate,
          formats: formats,
          precision: money,
          enabled: selling.editablePriceListRate,
          onChanged: (v) => cart.setPrice(line, priceListRate: v),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.availableQty),
          trailing: Text(formats.number(item?.qty ?? 0)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.warehouse),
          trailing: Text(warehouse?.name ?? ''),
        ),
        if (item != null && (item.hasBatch || item.hasSerial) && sale != null)
          SerialBatchEditor(
            key: ObjectKey(line),
            entries: line.entries,
            hasSerial: item.hasSerial,
            hasBatch: item.hasBatch,
            incoming: false,
            formats: formats,
            onChanged: cart.changed,
            onAutoFetch: () async {
              final db = ref.read(appDatabaseProvider);
              final picks = await db.availableEntries(
                line.itemId,
                sale.warehouseId,
                toStorage(DateTime.now()),
                serials: item.hasSerial,
                allowExpired: false,
              );
              return [
                for (final (e, qty) in autoPick(
                  picks,
                  stockQty(
                    line.qty,
                    line.factor,
                    formats.system.floatPrecision,
                  ),
                  ref.read(stockSettingsProvider).pickSerialAndBatchBasedOn,
                ))
                  SbEntry(serialNo: e.serialNo, batchNo: e.batchNo, qty: qty),
              ];
            },
          ),
      ],
    );
  }
}

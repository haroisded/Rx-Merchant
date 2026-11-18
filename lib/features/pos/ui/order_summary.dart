import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../invoices/ui/print_page.dart';
import '../../setup/ui/simple_masters.dart' show modesOfPaymentProvider;
import '../data/pos_db.dart';
import '../logic/sale.dart';
import '../logic/totals.dart';
import 'cart_panel.dart';
import 'pos_widgets.dart';

/// The order summary after Submit (POS-R17): name and status, lines,
/// totals, payments and change, Print Receipt (INV-R24) and New Order. A
/// return's summary too (INV-R9), whose New Order starts the exchange.
class OrderSummary extends ConsumerWidget {
  const OrderSummary({
    super.key,
    required this.sale,
    required this.name,
    required this.onNewOrder,
  });

  final Sale sale;
  final String name;
  final VoidCallback onNewOrder;

  bool get _return => sale.returnAgainstId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final totals = totalsOf(sale, saleSettingsOf(formats));
    final modes = {
      for (final m in ref.watch(modesOfPaymentProvider).value ?? []) m.id: m,
    };
    final paid = settle(
      totals.toPay,
      [
        for (final MapEntry(:key, :value) in sale.payments.entries)
          (amount: value, cash: modes[key]?.type == 'Cash'),
      ],
      precision: formats.system.currencyPrecision,
      method: formats.rounding,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleLarge),
            ),
            StatusChip(_return ? 'Return' : 'Paid'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, line) in sale.lines.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(line.itemName),
            subtitle: Text(
              '${formats.number(line.qty)} × ${formats.money(line.rate)}',
            ),
            trailing: Text(formats.money(totals.lines[i].amount)),
          ),
        const Divider(),
        ...totalsRows(context, ref, sale, totals),
        const Divider(),
        for (final MapEntry(:key, :value) in sale.payments.entries)
          if (value != 0)
            TotalRow(modes[key]?.name ?? '', formats.money(value)),
        TotalRow(l.paidAmount, formats.money(paid.paid)),
        if (!_return)
          TotalRow(l.changeAmount, formats.money(paid.change), strong: true),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => openPrint(context, sale.id!),
              icon: const Icon(Icons.print_outlined),
              label: Text(l.printReceipt),
            ),
            FilledButton(onPressed: onNewOrder, child: Text(l.newOrder)),
          ],
        ),
      ],
    );
  }
}

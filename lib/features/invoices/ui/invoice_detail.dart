import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/ui/pos_widgets.dart';
import '../../setup/ui/form_kit.dart';
import '../../stock/ui/report_pages.dart';
import '../../stock/ui/stock_screen.dart';
import '../data/returns_db.dart';
import '../logic/invoice.dart';
import 'invoice_providers.dart';
import 'print_page.dart';

/// INV-R2: a submitted (or cancelled) invoice, read-only: header, items,
/// taxes and totals, payments and change, terms, and the links between a
/// sale and its returns. Print; Create > Return / Credit Note; Stock
/// Ledger; Cancel.
class InvoiceDetail extends ConsumerWidget {
  const InvoiceDetail({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return switch (ref.watch(invoiceViewProvider(id))) {
      AsyncData(value: final inv) => _Detail(inv),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.unexpectedError('$error'))),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Detail extends ConsumerWidget {
  const _Detail(this.inv);

  final Invoice inv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final submitted = inv.docstatus == 1;
    final canReturn = submitted && !inv.isReturn;
    return Scaffold(
      appBar: AppBar(
        title: Text(inv.name ?? l.draftNumber(inv.id)),
        actions: [
          IconButton(
            tooltip: l.print,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => openPrint(context, inv.id),
          ),
          if (canReturn)
            MenuAnchor(
              builder: (context, menu, _) => TextButton.icon(
                onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                icon: const Icon(Icons.arrow_drop_down),
                label: Text(l.create),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.assignment_return_outlined),
                  onPressed: () => context.go(returnPath(inv.id)),
                  child: Text(l.returnCreditNote),
                ),
              ],
            ),
          MenuAnchor(
            builder: (context, menu, _) => IconButton(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              onPressed: () => menu.isOpen ? menu.close() : menu.open(),
              icon: const Icon(Icons.more_vert),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.list_alt_outlined),
                onPressed: inv.name == null || !inv.updateStock
                    ? null
                    : () => context.go(
                        '$stockPath/${StockReport.stockLedger.slug}'
                        '?voucher=${Uri.encodeQueryComponent(inv.name!)}',
                      ),
                child: Text(l.reportStockLedger),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.cancel_outlined),
                onPressed: submitted ? () => _cancel(context, ref) : null,
                child: Text(l.cancelDocument),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inv.name ?? l.draftNumber(inv.id),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      StatusChip(inv.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${formats.date(inv.posting)} ${formats.time(inv.posting)}',
                  ),
                  if (inv.session case final s?)
                    Text('${l.posOpeningEntry}: $s'),
                  Text('${l.warehouse}: ${inv.warehouse}'),
                  if (inv.isReturn && !inv.updateStock) Text(l.priceOnlyCredit),
                ],
              ),
            ),
          ),
          SectionHeading(l.items),
          if (WindowSize.of(context) == WindowSize.expanded)
            _itemTable(l, formats)
          else
            for (final line in inv.lines)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.itemName),
                subtitle: Text(
                  [
                    '${formats.number(line.qty)} ${line.uom} × '
                        '${formats.money(line.rate)}',
                    ...line.batches,
                    ...line.serials,
                  ].join('\n'),
                ),
                trailing: Text(formats.money(line.amount)),
              ),
          const Divider(),
          ...invoiceTotals(l, formats, inv),
          if (inv.payments.isNotEmpty) ...[
            SectionHeading(l.payments),
            for (final p in inv.payments)
              TotalRow(p.mode, formats.money(p.amount)),
            TotalRow(l.paidAmount, formats.money(inv.paidAmount)),
            if (inv.changeAmount != 0)
              TotalRow(l.changeAmount, formats.money(inv.changeAmount)),
          ],
          if (inv.terms case final terms? when terms.trim().isNotEmpty) ...[
            SectionHeading(l.termsAndConditions),
            Text(terms),
          ],
          if (inv.against case final a?) ...[
            SectionHeading(l.returnAgainst),
            _link(context, a),
          ],
          if (inv.returns.isNotEmpty) ...[
            SectionHeading(l.returns),
            for (final r in inv.returns) _link(context, r),
          ],
        ],
      ),
    );
  }

  Widget _itemTable(AppLocalizations l, Formats formats) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l.item)),
            DataColumn(label: Text(l.qty), numeric: true),
            DataColumn(label: Text(l.uom)),
            DataColumn(label: Text(l.rate), numeric: true),
            DataColumn(label: Text(l.amount), numeric: true),
          ],
          rows: [
            for (final line in inv.lines)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      [
                        line.itemName,
                        ...line.batches,
                        ...line.serials,
                      ].join('\n'),
                    ),
                  ),
                  DataCell(Text(formats.number(line.qty))),
                  DataCell(Text(line.uom)),
                  DataCell(Text(formats.money(line.rate))),
                  DataCell(Text(formats.money(line.amount))),
                ],
              ),
          ],
        ),
      );

  Widget _link(BuildContext context, InvoiceRef r) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.receipt_long_outlined),
    title: Text(r.name),
    trailing: StatusChip(r.status),
    onTap: () => context.go(invoicePath(r.id)),
  );

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    if (!await confirm(
          context,
          title: l.cancelTitle,
          body: l.cancelInvoiceBody,
          action: '${l.cancelDocument} ${inv.name}',
        ) ||
        !context.mounted) {
      return;
    }
    await attempt(
      context,
      () => ref.read(appDatabaseProvider).cancelInvoice(inv.id),
      done: l.statusCancelled,
    );
  }
}

/// INV-R18's totals block, as the print lays it out, every tax row shown.
List<Widget> invoiceTotals(AppLocalizations l, Formats formats, Invoice inv) {
  final doc = layoutFor(inv, l, formats, (
    compact: true,
    withLetterhead: false,
    zeroTaxes: true,
    draftHeading: false,
    roundedTotal: true,
    inWords: true,
  ));
  return [
    for (final r in doc.totals) TotalRow(r.label, r.value, strong: r.strong),
    if (doc.inWords case final words?) TotalRow(words, ''),
  ];
}

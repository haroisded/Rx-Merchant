import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../invoices/ui/invoice_providers.dart';
import '../../invoices/ui/invoices_screen.dart' show openScanned;
import '../../invoices/ui/print_page.dart';
import '../../setup/ui/form_kit.dart';
import '../../stock/ui/scan.dart';
import '../data/pos_db.dart';
import 'pos_providers.dart';

/// Recent Orders (POS-R19): the register's invoices by status, searchable
/// by name or by scanning a receipt (INV-R23). A held order offers Edit and
/// Delete; a submitted invoice opens, prints, and a sale offers Return
/// (INV-R5).
class RecentOrders extends ConsumerStatefulWidget {
  const RecentOrders({super.key, required this.onEdit});

  final ValueChanged<int> onEdit;

  @override
  ConsumerState<RecentOrders> createState() => _RecentOrdersState();
}

class _RecentOrdersState extends ConsumerState<RecentOrders> {
  var _status = 'Draft';
  var _query = '';

  bool _keep(SalesInvoiceData s) =>
      switch (_status) {
        'Draft' => s.docstatus == 0,
        'Return' => s.isReturn == 1,
        _ => s.status == _status,
      } &&
      (s.name ?? '').toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final rows = [
      for (final s in ref.watch(recentOrdersProvider).value ?? [])
        if (_keep(s)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SearchBar(
            hintText: l.search,
            leading: const Icon(Icons.search),
            trailing: [
              ScanButton(onScanned: (code) => openScanned(context, ref, code)),
            ],
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final (value, label) in [
                ('Draft', l.statusDraft),
                ('Paid', l.statusPaid),
                ('Return', l.statusReturn),
              ])
                FilterChip(
                  label: Text(label),
                  selected: _status == value,
                  onSelected: (_) => setState(() => _status = value),
                ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(l.emptyList))
              : ListView(
                  children: [
                    for (final s in rows)
                      ListTile(
                        title: Text(s.name ?? l.draftName(s.id)),
                        subtitle: Text(
                          '${formats.date(DateTime.parse(s.postingDatetime))} '
                          '${formats.time(DateTime.parse(s.postingDatetime))}'
                          '  ·  ${formats.money(s.grandTotal)}',
                        ),
                        trailing: s.docstatus == 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: l.edit,
                                    onPressed: () => widget.onEdit(s.id),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: l.delete,
                                    onPressed: () => _delete(s),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusChip(s.status),
                                  IconButton(
                                    tooltip: l.printReceipt,
                                    onPressed: () => openPrint(context, s.id),
                                    icon: const Icon(Icons.print_outlined),
                                  ),
                                  if (s.docstatus == 1 && s.isReturn == 0)
                                    IconButton(
                                      tooltip: l.returnCreditNote,
                                      onPressed: () =>
                                          context.go(returnPath(s.id)),
                                      icon: const Icon(
                                        Icons.assignment_return_outlined,
                                      ),
                                    ),
                                ],
                              ),
                        onTap: s.docstatus == 0
                            ? () => widget.onEdit(s.id)
                            : () => context.go(invoicePath(s.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _delete(SalesInvoiceData s) async {
    final l = AppLocalizations.of(context);
    if (await confirm(
          context,
          title: l.deleteTitle,
          body: l.deleteBody(s.name ?? l.draftName(s.id)),
          action: l.delete,
        ) &&
        mounted) {
      await attempt(context, () async {
        await ref.read(appDatabaseProvider).deleteSale(s.id);
        // The cart was this held order: start afresh.
        if (ref.read(cartProvider).value?.id == s.id) {
          await ref.read(cartProvider.notifier).reset();
        }
      });
    }
  }
}

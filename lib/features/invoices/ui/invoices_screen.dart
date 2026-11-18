import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/format.dart';
import '../../../core/widgets/list_detail_pane.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/ui/pos_providers.dart';
import '../../stock/ui/scan.dart';
import '../data/invoice_db.dart';
import 'invoice_detail.dart';
import 'invoice_providers.dart';
import 'return_form.dart';

/// The Invoices destination (05-invoices-and-receipts section 5): the list,
/// and an invoice (`invoice/:id`) or a return being made against one
/// (`return/:id`) beside it on an expanded window. The list's filters ride
/// in the query, so they survive opening a record.
class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key, this.page, this.id, this.query = const {}});

  final String? page;
  final String? id;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(this.id ?? '');
    return ListDetailPane(
      // A new query (a dashboard card, the closing entry) starts the list
      // afresh; opening a record keeps the same one.
      list: InvoiceList(
        key: ValueKey(Uri(queryParameters: query).query),
        query: query,
        selected: id,
      ),
      detail: switch ((page, id)) {
        ('invoice', final id?) => InvoiceDetail(key: ValueKey(id), id: id),
        ('return', final id?) => ReturnForm(key: ValueKey(id), saleId: id),
        _ => null,
      },
    );
  }
}

/// INV-R1: every invoice, newest first, with status chips, a date range and
/// a search by name; a scanned receipt barcode opens its invoice (INV-R23).
class InvoiceList extends ConsumerStatefulWidget {
  const InvoiceList({super.key, required this.query, this.selected});

  final Map<String, String> query;
  final int? selected;

  @override
  ConsumerState<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends ConsumerState<InvoiceList> {
  late var _filters = InvoiceFilters.of(widget.query);
  late final _search = TextEditingController(text: _filters.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _statuses = [
    'Draft',
    'Paid',
    'Credit Note Issued',
    'Return',
    'Cancelled',
  ];

  /// The filters as the route's query.
  String get _query => Uri(queryParameters: _filters.params).query;

  void _open(SalesInvoiceData s) {
    if (s.docstatus == 0) {
      // INV-R2: a draft opens in the Cash Register.
      return context.go('$posPath?heldOrder=${s.id}');
    }
    context.go('${invoicePath(s.id)}?$_query');
  }

  void _set(InvoiceFilters f) {
    setState(() => _filters = f);
    // The list on its own keeps the filters in the route for Back.
    if (widget.selected == null) context.go(invoicesLink(f));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final f = _filters;
    final rows = ref.watch(invoiceListProvider(f));
    final filtered =
        f.statuses.isNotEmpty ||
        f.from != null ||
        f.query.isNotEmpty ||
        f.session != null;
    final range = f.from == null || f.to == null
        ? null
        : DateTimeRange(
            start: DateTime.parse(f.from!),
            end: DateTime.parse(f.to!),
          );
    String day(DateTime d) => toStorage(d).substring(0, 10);
    InvoiceFilters copy({
      Set<String>? statuses,
      String? from,
      String? to,
      String? query,
      bool session = true,
    }) => InvoiceFilters(
      statuses: statuses ?? f.statuses,
      from: from,
      to: to,
      query: query ?? f.query,
      session: session ? f.session : null,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navInvoices),
        automaticallyImplyLeading: false,
      ),
      body: Column(
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
              hintText: l.search,
              leading: const Icon(Icons.search),
              trailing: [
                ScanButton(
                  onScanned: (code) => openScanned(context, ref, code, _query),
                ),
              ],
              onChanged: (q) => setState(
                () => _filters = copy(from: f.from, to: f.to, query: q),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                for (final s in _statuses)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: FilterChip(
                      label: Text(statusLabel(l, s)),
                      selected: f.statuses.contains(s),
                      onSelected: (on) => _set(
                        copy(
                          statuses: on
                              ? {...f.statuses, s}
                              : ({...f.statuses}..remove(s)),
                          from: f.from,
                          to: f.to,
                        ),
                      ),
                    ),
                  ),
                // The closing entry's link: one POS session's invoices.
                if (f.session != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: InputChip(
                      label: Text(l.posOpeningEntry),
                      selected: true,
                      onDeleted: () =>
                          _set(copy(from: f.from, to: f.to, session: false)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: InputChip(
                    avatar: const Icon(Icons.date_range),
                    label: Text(
                      range == null
                          ? l.dateRange
                          : '${formats.date(range.start)} – '
                                '${formats.date(range.end)}',
                    ),
                    selected: range != null,
                    showCheckmark: false,
                    onDeleted: range == null
                        ? null
                        : () => _set(copy(from: null, to: null)),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: now,
                        initialDateRange: range,
                      );
                      if (picked != null) {
                        _set(
                          copy(from: day(picked.start), to: day(picked.end)),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (rows) {
              AsyncError(:final error) => Center(
                child: Text(l.unexpectedError('$error')),
              ),
              AsyncData(value: final list) when list.isEmpty => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    filtered ? l.noEntries : l.invoicesEmpty,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              AsyncData(value: final list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final s = list[i];
                  final at = DateTime.parse(s.postingDatetime);
                  return ListTile(
                    selected: s.id == widget.selected,
                    title: Text(s.name ?? l.draftNumber(s.id)),
                    subtitle: Text(
                      '${formats.date(at)} ${formats.time(at)}'
                      '  ·  ${formats.money(s.grandTotal)}',
                    ),
                    trailing: StatusChip(s.status),
                    onTap: () => _open(s),
                  );
                },
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// INV-R23: opens the invoice named [code] (a scanned receipt barcode),
/// keeping the list's [query]; says so when there is none.
Future<void> openScanned(
  BuildContext context,
  WidgetRef ref,
  String code, [
  String query = '',
]) async {
  final l = AppLocalizations.of(context);
  final id = await ref.read(appDatabaseProvider).invoiceIdByName(code);
  if (!context.mounted) return;
  if (id == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.noInvoiceNamed(code))));
    return;
  }
  context.go('${invoicePath(id)}?$query');
}

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../pos/data/pos_db.dart';
import '../../stock/data/stock_entry_db.dart';
import '../logic/invoice.dart';

// The invoice list and the invoice view (05-invoices-and-receipts INV-R1 to
// R4).

/// INV-R1: the list's filters. An empty [statuses] means every status.
class InvoiceFilters {
  const InvoiceFilters({
    this.statuses = const {},
    this.from,
    this.to,
    this.query = '',
    this.session,
  });

  /// From the route's query: `status` (comma-separated), `from`, `to` (both
  /// `YYYY-MM-DD`), `q`, `session`.
  factory InvoiceFilters.of(Map<String, String> q) => InvoiceFilters(
    statuses: {
      for (final s in (q['status'] ?? '').split(','))
        if (s.isNotEmpty) s,
    },
    from: q['from'],
    to: q['to'],
    query: q['q'] ?? '',
    session: int.tryParse(q['session'] ?? ''),
  );

  final Set<String> statuses;
  final String? from;
  final String? to;
  final String query;

  /// One POS session's invoices (the closing entry's count).
  final int? session;

  /// As route query parameters, the inverse of [InvoiceFilters.of].
  Map<String, String> get params => {
    if (statuses.isNotEmpty) 'status': (statuses.toList()..sort()).join(','),
    'from': ?from,
    'to': ?to,
    if (query.isNotEmpty) 'q': query,
    if (session case final s?) 'session': '$s',
  };

  @override
  bool operator ==(Object other) =>
      other is InvoiceFilters && '$params' == '${other.params}';

  @override
  int get hashCode => '$params'.hashCode;
}

extension InvoiceDb on AppDatabase {
  /// INV-R1: invoices in [f], newest first.
  Stream<List<SalesInvoiceData>> watchInvoices(InvoiceFilters f) {
    final q = select(salesInvoice)
      ..orderBy([
        (s) => OrderingTerm.desc(s.postingDatetime),
        (s) => OrderingTerm.desc(s.id),
      ]);
    if (f.statuses.isNotEmpty) q.where((s) => s.status.isIn(f.statuses));
    if (f.from case final from?) {
      q.where((s) => s.postingDatetime.isBiggerOrEqualValue(from));
    }
    // Before the day after [to], so the whole last day counts.
    if (f.to case final to?) {
      q.where((s) => s.postingDatetime.isSmallerThanValue('$to~'));
    }
    if (f.query.trim() case final text when text.isNotEmpty) {
      q.where((s) => s.name.like('%$text%'));
    }
    if (f.session case final id?) {
      q.where((s) => s.posOpeningEntryId.equals(id));
    }
    return q.watch();
  }

  /// INV-R23: the invoice named [name] (a scanned receipt barcode).
  Future<int?> invoiceIdByName(String name) =>
      (select(salesInvoice)..where((s) => s.name.equals(name.trim())))
          .map((s) => s.id)
          .getSingleOrNull();

  /// INV-R2: invoice [id] with its lines, taxes, payments and links.
  Future<Invoice> invoiceView(int id) async {
    final h = await (select(
      salesInvoice,
    )..where((s) => s.id.equals(id))).getSingle();
    final session = await (select(
      posOpeningEntry,
    )..where((s) => s.id.equals(h.posOpeningEntryId))).getSingle();
    final lines = await customSelect(
      'SELECT l.*, i.item_code, u.name AS uom FROM sales_invoice_item l '
      'JOIN item i ON i.id = l.item_id JOIN uom u ON u.id = l.uom_id '
      'WHERE l.sales_invoice_id = ? ORDER BY l.idx',
      variables: [Variable(id)],
      readsFrom: {salesInvoiceItem, item, uom},
    ).get();
    final taxes = await customSelect(
      'SELECT t.*, x.name AS tax FROM sales_invoice_tax t '
      'JOIN tax x ON x.id = t.tax_id WHERE t.sales_invoice_id = ? ORDER BY t.idx',
      variables: [Variable(id)],
    ).get();
    final payments = await customSelect(
      'SELECT m.name, p.amount FROM sales_invoice_payment p '
      'JOIN mode_of_payment m ON m.id = p.mode_of_payment_id '
      'WHERE p.sales_invoice_id = ? ORDER BY p.id',
      variables: [Variable(id)],
    ).get();
    InvoiceRef refOf(SalesInvoiceData s) =>
        (id: s.id, name: s.name ?? '', status: s.status);
    final against = h.returnAgainstId == null
        ? null
        : await (select(
            salesInvoice,
          )..where((s) => s.id.equals(h.returnAgainstId!))).getSingle();
    final returns =
        await (select(salesInvoice)
              ..where(
                (s) => s.returnAgainstId.equals(id) & s.docstatus.isNotValue(0),
              )
              ..orderBy([(s) => OrderingTerm(expression: s.id)]))
            .get();
    // INV-R14: the invoice's own letter head, else the default.
    final head =
        await (select(letterHead)..where(
              (x) => h.letterHeadId == null
                  ? x.isDefault.equals(1) & x.disabled.equals(0)
                  : x.id.equals(h.letterHeadId!),
            ))
            .getSingleOrNull();
    final heading = h.printHeadingId == null
        ? null
        : await (select(printHeading)
                ..where((x) => x.id.equals(h.printHeadingId!)))
              .map((x) => x.name)
              .getSingleOrNull();
    return Invoice(
      id: h.id,
      name: h.name,
      status: h.status,
      docstatus: h.docstatus,
      isReturn: h.isReturn == 1,
      posting: DateTime.parse(h.postingDatetime),
      session: session.name,
      sessionOpen: session.status == 'Open',
      updateStock: h.updateStock == 1,
      warehouse:
          await (select(warehouse)..where((w) => w.id.equals(h.setWarehouseId)))
              .map((w) => w.name)
              .getSingle(),
      against: against == null ? null : refOf(against),
      returns: [for (final r in returns) refOf(r)],
      lines: [for (final r in lines) await _line(r)],
      taxes: [
        for (final t in taxes)
          InvoiceTax(
            description: t.read<String?>('description') ?? t.read('tax'),
            amount: t.read('tax_amount_after_discount_amount'),
            included: t.read<int>('included_in_print_rate') == 1,
          ),
      ],
      payments: [
        for (final p in payments)
          (mode: p.read<String>('name'), amount: p.read<double>('amount')),
      ],
      netTotal: h.netTotal,
      discountAmount: h.discountAmount,
      grandTotal: h.grandTotal,
      roundingAdjustment: h.roundingAdjustment,
      roundedTotal: h.roundedTotal,
      paidAmount: h.paidAmount,
      changeAmount: h.changeAmount,
      inWords: h.inWords,
      heading: heading,
      terms: h.terms,
      letterHead: head == null
          ? null
          : PrintLetterHead(
              image: head.image,
              header: head.header,
              footer: head.footer,
            ),
    );
  }

  Future<InvoiceLine> _line(QueryRow r) async {
    final entries = await entriesOf(salesInvoiceType, r.read<int>('id'));
    return InvoiceLine(
      id: r.read('id'),
      itemCode: r.read('item_code'),
      itemName: r.read('item_name'),
      description: r.read('description'),
      qty: r.read('qty'),
      uom: r.read('uom'),
      rate: r.read('rate'),
      discountPercentage: r.read('discount_percentage'),
      discountAmount: r.read('discount_amount'),
      amount: r.read('amount'),
      serials: [for (final e in entries) ?e.serialNo],
      batches: {for (final e in entries) ?e.batchNo}.toList(),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../data/invoice_db.dart';
import '../logic/invoice.dart';

const invoicesPath = '/invoices';

/// An invoice's page, and the return form against sale [saleId].
String invoicePath(int id) => '$invoicesPath/invoice/$id';
String returnPath(int saleId) => '$invoicesPath/return/$saleId';

/// INV-R1: the invoice list showing [f].
String invoicesLink(InvoiceFilters f) =>
    '$invoicesPath?${Uri(queryParameters: f.params).query}';

/// The invoice list's rows for one set of filters (INV-R1).
final invoiceListProvider = StreamProvider.autoDispose
    .family<List<SalesInvoiceData>, InvoiceFilters>(
      (ref, f) => ref.watch(appDatabaseProvider).watchInvoices(f),
    );

/// Invoice [id], read again whenever an invoice changes (a return made
/// against it, a cancel).
final invoiceViewProvider = StreamProvider.autoDispose.family<Invoice, int>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.salesInvoice)..where((s) => s.id.equals(id)))
      .watchSingle()
      .asyncMap((_) => db.invoiceView(id));
});

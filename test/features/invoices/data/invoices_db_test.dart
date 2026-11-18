import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/features/dashboard/data/dashboard_db.dart';
import 'package:rx_merchant/core/db/singles.dart';
import 'package:rx_merchant/features/invoices/data/invoice_db.dart';
import 'package:rx_merchant/features/invoices/data/print_masters.dart';
import 'package:rx_merchant/features/invoices/data/returns_db.dart';
import 'package:rx_merchant/features/invoices/logic/returns.dart';
import 'package:rx_merchant/features/pos/data/pos_db.dart';
import 'package:rx_merchant/features/pos/logic/sale.dart';
import 'package:rx_merchant/features/pos/logic/totals.dart';
import 'package:rx_merchant/features/setup/data/refusal.dart';
import 'package:rx_merchant/features/setup/data/setup_queries.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';

import '../../pos/data/pos_db_test.dart'
    show cart, invoice, paid, receipt, refusedAll, register;
import '../../setup/data/setup_db_test.dart' show refused;
import '../../stock/data/stock_db_test.dart' show binOf, idOf, move, newItem;

// 05-invoices-and-receipts section 7: database tests.

/// Sale [id]'s return with [qty] per line (all that is left when null),
/// rescaled and refunded in full in cash, as the return form does.
Future<Sale> giveBack(AppDatabase db, int id, [List<double>? qty]) async {
  final d = await db.returnDraft(id);
  final f = await db.formats();
  if (qty != null) {
    for (final (i, q) in qty.indexed) {
      d.sale.lines[i].qty = -q;
    }
    d.sale.lines.removeWhere((l) => l.qty == 0);
  }
  scaleReturn(d.sale, d.basis, precision: f.system.currencyPrecision);
  d.sale.payments[await idOf(db, 'mode_of_payment', 'Cash')] = totalsOf(
    d.sale,
    saleSettingsOf(f),
  ).toPay;
  return d.sale;
}

/// A submitted sale of [qty] [item] at [rate]; its id.
Future<int> sell(AppDatabase db, int item, double qty, double rate) async {
  final name = await db.submitSale(
    await paid(db, await cart(db, [(item, qty, rate)])),
  );
  return (await invoice(db, name)).id;
}

void main() {
  final year = DateTime.now().year;

  test('INV-A10, A11 a return offers what is still returnable', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 20, rate: 50);
    final sale = await sell(db, tea, 10, 80);
    expect((await db.returnDraft(sale)).sale.lines.single.qty, -10);
    await db.submitReturn(await giveBack(db, sale, [3]));
    expect((await db.returnDraft(sale)).sale.lines.single.qty, -7);
  });

  test('INV-A12 returning more than is left is refused', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 20, rate: 50);
    final sale = await sell(db, tea, 10, 80);
    await db.submitReturn(await giveBack(db, sale, [3]));
    final more = await giveBack(db, sale);
    more.lines.single.qty = -8;
    await expectLater(db.submitReturn(more), refusedAll(Refusal.returnTooMuch));
  });

  test('INV-A13 a return of one 108 item with 8% included', () async {
    final db = await register();
    final vat = await db.into(db.tax).insert(TaxCompanion.insert(name: 'VAT'));
    await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion.insert(
        title: 'VAT 8% incl',
        isDefault: const Value(1),
      ),
      [
        TaxRow(
          chargeType: ChargeType.onNetTotal,
          taxId: vat,
          rate: 8,
          included: true,
        ),
      ],
    );
    final pen = await newItem(db, 'PEN');
    await move(db, receipt, pen, 5, rate: 40);
    final sale = await sell(db, pen, 2, 108);
    final name = await db.submitReturn(await giveBack(db, sale, [1]));
    final r = await invoice(db, name);
    expect(
      (r.netTotal, r.totalTaxesAndCharges, r.grandTotal, r.paidAmount),
      (-100, -8, -108, -108),
    );
  });

  test('INV-A14 stock comes back at the cost it went out at', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 1, rate: 100);
    final sale = await sell(db, tea, 1, 150);
    // The cost of the next unit is different.
    await move(db, receipt, tea, 1, rate: 300);
    final name = await db.submitReturn(await giveBack(db, sale));
    final r = await invoice(db, name);
    final line = await (db.select(
      db.salesInvoiceItem,
    )..where((l) => l.salesInvoiceId.equals(r.id))).getSingle();
    expect(line.incomingRate, 100);
    final bin = await binOf(db, tea);
    expect((bin.actualQty, bin.stockValue), (2, 400));
    final day = DateTime.now();
    final f = await db.figures((from: day, to: day));
    expect((f.netSales, f.cost, f.grossProfit), (0, 0, 0));
  });

  test('INV-A15, A16 a return names and marks; cancelling it undoes', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    final name = await db.submitReturn(await giveBack(db, sale, [1]));
    expect(name, 'ACC-SINV-RET-$year-00001');
    final r = await invoice(db, name);
    expect((r.status, r.isReturn, r.returnAgainstId), ('Return', 1, sale));
    expect((await db.invoiceView(sale)).status, 'Credit Note Issued');
    expect((await binOf(db, tea)).actualQty, 7);
    await db.cancelInvoice(r.id);
    expect((await invoice(db, name)).status, 'Cancelled');
    expect((await db.invoiceView(sale)).status, 'Paid');
    expect((await binOf(db, tea)).actualQty, 6);
    // The cancelled return no longer counts against the sale.
    expect((await db.returnDraft(sale)).sale.lines.single.qty, -4);
  });

  test('INV-A17 a price-only credit moves no stock but counts', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    final ret = await giveBack(db, sale, [1]);
    ret
      ..updateStock = false
      ..lines.single.rate = 20;
    final f = await db.formats();
    ret.payments[await idOf(db, 'mode_of_payment', 'Cash')] = totalsOf(
      ret,
      saleSettingsOf(f),
    ).toPay;
    final name = await db.submitReturn(ret);
    final r = await invoice(db, name);
    expect(r.grandTotal, -20);
    final ledger = await (db.select(
      db.stockLedgerEntry,
    )..where((s) => s.voucherId.equals(r.id))).get();
    expect(ledger, isEmpty);
    expect((await binOf(db, tea)).actualQty, 6);
    expect((await db.returnDraft(sale)).sale.lines.single.qty, -3);
  });

  test('INV-R6 the rate stays; a refund in full, enabled modes', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 2, 80);
    final dearer = await giveBack(db, sale);
    dearer.lines.single.rate = 70;
    await expectLater(db.submitReturn(dearer), refusedAll(Refusal.returnRate));
    final short = await giveBack(db, sale);
    short.payments.updateAll((_, v) => v + 1);
    await expectLater(
      db.submitReturn(short),
      refusedAll(Refusal.refundNotEqual),
    );
    // INV-A18: a refund in a disabled Mode of Payment.
    final card = await idOf(db, 'mode_of_payment', 'Credit Card');
    await (db.update(db.modeOfPayment)..where((m) => m.id.equals(card))).write(
      const ModeOfPaymentCompanion(enabled: Value(0)),
    );
    final byCard = await giveBack(db, sale);
    byCard.payments[card] = byCard.payments.values.first;
    byCard.payments.removeWhere((k, _) => k != card);
    await expectLater(
      db.submitReturn(byCard),
      refusedAll(Refusal.modeDisabled),
    );
  });

  test('INV-A19 a returned serial number is Available at its cost', () async {
    final db = await register();
    final phone = await newItem(db, 'PHONE', serial: true);
    await move(
      db,
      receipt,
      phone,
      2,
      rate: 100,
      entries: [
        SbEntry(serialNo: 'SN-1'),
        SbEntry(serialNo: 'SN-2'),
      ],
    );
    final s = await cart(db, [(phone, 2, 200)]);
    s.lines.single.entries.addAll([
      SbEntry(serialNo: 'SN-1'),
      SbEntry(serialNo: 'SN-2'),
    ]);
    final sale = (await invoice(db, await db.submitSale(await paid(db, s)))).id;
    final ret = await giveBack(db, sale, [1]);
    ret.lines.single.entries.removeWhere((e) => e.serialNo == 'SN-1');
    final name = await db.submitReturn(ret);
    final sn = await (db.select(
      db.serialNo,
    )..where((x) => x.serialNo.equals('SN-2'))).getSingle();
    expect(
      (sn.status, sn.incomingRate, sn.warrantyExpiryDate),
      ('Available', 100, null),
    );
    expect((await binOf(db, phone)).stockValue, 100);
    // SN-2 cannot come back twice.
    expect((await db.returnDraft(sale)).serials.values.single, ['SN-1']);
    // Cancelling the return delivers it again.
    await db.cancelInvoice((await invoice(db, name)).id);
    final again = await (db.select(
      db.serialNo,
    )..where((x) => x.serialNo.equals('SN-2'))).getSingle();
    expect(again.status, 'Delivered');
  });

  test('INV-A20 a sale with a submitted return cannot be cancelled', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    await db.submitReturn(await giveBack(db, sale, [1]));
    await expectLater(
      db.cancelInvoice(sale),
      refused(Refusal.cancelHasReturns),
    );
  });

  test('INV-A21 a sale in a closed session cannot be cancelled', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    await (db.update(db.posOpeningEntry))
        .write(const PosOpeningEntryCompanion(status: Value('Closed')));
    await expectLater(
      db.cancelInvoice(sale),
      refused(Refusal.cancelSessionClosed),
    );
    // INV-R5: it can still be returned, in a new session.
    await db.openSessionWith({});
    await db.submitReturn(await giveBack(db, sale, [1]));
  });

  test('INV-A22 cancelling a sale in the open session', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    await db.cancelInvoice(sale);
    final s = await (db.select(
      db.salesInvoice,
    )..where((x) => x.id.equals(sale))).getSingle();
    expect(
      (s.status, s.docstatus, s.name),
      ('Cancelled', 2, 'ACC-SINV-$year-00001'),
    );
    final ledger =
        await (db.select(db.stockLedgerEntry)..where(
              (x) =>
                  x.voucherId.equals(sale) &
                  x.voucherType.equals(salesInvoiceType),
            ))
            .getSingle();
    expect(ledger.isCancelled, 1);
    expect((await binOf(db, tea)).actualQty, 10);
    final next = await sell(db, tea, 1, 80);
    expect((await db.invoiceView(next)).name, 'ACC-SINV-$year-00002');
  });

  test('INV-R11 a return whose stock was sold since stays', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 2, rate: 50);
    final sale = await sell(db, tea, 2, 80);
    final name = await db.submitReturn(await giveBack(db, sale, [1]));
    await sell(db, tea, 1, 80);
    await expectLater(
      db.cancelInvoice((await invoice(db, name)).id),
      refused(Refusal.negativeStock),
    );
  });

  test('D-62 a full return refunds a discount and charge exactly', () async {
    final db = await register();
    final vat = await db.into(db.tax).insert(TaxCompanion.insert(name: 'VAT'));
    final fee = await db.into(db.tax).insert(TaxCompanion.insert(name: 'Fee'));
    await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion.insert(
        title: 'VAT and fee',
        isDefault: const Value(1),
      ),
      [
        TaxRow(chargeType: ChargeType.onNetTotal, taxId: vat, rate: 12),
        TaxRow(chargeType: ChargeType.actual, taxId: fee, taxAmount: 7),
      ],
    );
    final a = await newItem(db, 'A');
    final b = await newItem(db, 'B');
    await move(db, receipt, a, 10, rate: 10);
    await move(db, receipt, b, 10, rate: 10);
    final s = await cart(db, [(a, 3, 33.33), (b, 1, 19.99)]);
    s.discountAmount = 10;
    final sale = (await invoice(db, await db.submitSale(await paid(db, s)))).id;
    final original = await invoice(db, (await db.invoiceView(sale)).name!);
    // B's share only: part of the fee and the discount is refunded.
    final part = await giveBack(db, sale, [0, 1]);
    expect(part.discountAmount, lessThan(0));
    expect(part.taxes.last.taxAmount, lessThan(0));
    final r = await invoice(
      db,
      await db.submitReturn(await giveBack(db, sale)),
    );
    expect(
      (r.netTotal, r.totalTaxesAndCharges, r.discountAmount, r.grandTotal),
      (
        -original.netTotal,
        -original.totalTaxesAndCharges,
        -original.discountAmount,
        -original.grandTotal,
      ),
    );
  });

  test('INV-R1 the list filters by status, date and name', () async {
    final db = await register();
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 4, 80);
    await db.submitReturn(await giveBack(db, sale, [1]));
    await db.saveSale(await cart(db, [(tea, 1, 80)]));
    Future<List<String>> names(InvoiceFilters f) async => [
      for (final s in await db.watchInvoices(f).first) s.status,
    ];
    expect(await names(const InvoiceFilters()), [
      'Draft',
      'Return',
      'Credit Note Issued',
    ]);
    expect(await names(const InvoiceFilters(statuses: {'Return', 'Draft'})), [
      'Draft',
      'Return',
    ]);
    expect(await names(const InvoiceFilters(query: 'RET')), ['Return']);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    expect(await names(InvoiceFilters(from: today, to: today)), hasLength(3));
    expect(await names(const InvoiceFilters(to: '2000-01-01')), isEmpty);
    expect(await db.invoiceIdByName('ACC-SINV-$year-00001'), sale);
    final view = await db.invoiceView(sale);
    expect(view.returns.single.status, 'Return');
    expect(view.lines.single.itemCode, 'TEA');
  });

  test('INV-A24 a later edit of the terms leaves the sale alone', () async {
    final db = await register();
    final tc = await db.saveTerms(
      TermsAndConditionsCompanion.insert(
        title: 'Store terms',
        terms: 'No refund after 7 days.',
      ),
    );
    await db.writeSingle(PosSettings.doctype, {'tc_name': 'Store terms'});
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await sell(db, tea, 1, 80);
    await db.saveTerms(
      TermsAndConditionsCompanion(
        id: Value(tc),
        title: const Value('House terms'),
        terms: const Value('Changed.'),
      ),
    );
    expect((await db.invoiceView(sale)).terms, 'No refund after 7 days.');
    // The rename follows into POS Settings, which keeps it by title.
    expect(
      PosSettings(await db.readSingle(PosSettings.doctype)).tcName,
      'House terms',
    );
  });

  test('INV-R14 one Letter Head is the Default', () async {
    final db = await register();
    final second = await db.saveLetterHead(
      LetterHeadCompanion.insert(
        name: 'Branch',
        isDefault: const Value(1),
        header: const Value('Branch'),
      ),
    );
    final defaults = await (db.select(
      db.letterHead,
    )..where((h) => h.isDefault.equals(1))).get();
    expect(defaults.single.id, second);
    expect((await db.newSale()).letterHeadId, second);
    // A sale made with no letter head prints with the default (INV-R14).
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 50);
    final sale = await db.newSale()
      ..letterHeadId = null;
    sale.lines.add(
      await db.newLine(sale, tea)
        ..rate = 80
        ..priceListRate = 80,
    );
    final name = await db.submitSale(await paid(db, sale));
    final view = await db.invoiceView((await invoice(db, name)).id);
    expect(view.letterHead?.header, 'Branch');
  });
}

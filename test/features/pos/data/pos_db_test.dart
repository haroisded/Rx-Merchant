import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/numbers/format.dart';
import 'package:rx_merchant/features/pos/data/pos_closing_db.dart';
import 'package:rx_merchant/features/pos/data/pos_db.dart';
import 'package:rx_merchant/features/pos/logic/sale.dart';
import 'package:rx_merchant/features/pos/logic/totals.dart';
import 'package:rx_merchant/features/setup/data/refusal.dart';
import 'package:rx_merchant/features/setup/data/setup_queries.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';
import 'package:rx_merchant/features/stock/data/stock_entry_db.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';

import '../../setup/data/setup_db_test.dart' show refused, seeded;
import '../../stock/data/stock_db_test.dart' show binOf, idOf, move, newItem;

// 03-cash-register section 7: database tests.

const receipt = StockPurpose.materialReceipt;

/// A database with an open session: 500 in Cash.
Future<AppDatabase> register() async {
  final db = await seeded();
  await db.openSessionWith({await idOf(db, 'mode_of_payment', 'Cash'): 500});
  return db;
}

/// A cart of [lines] (item, qty, rate) at the register's defaults.
Future<Sale> cart(
  AppDatabase db,
  List<(int, double, double)> lines, {
  Map<String, double> pay = const {},
}) async {
  final sale = await db.newSale();
  for (final (item, qty, rate) in lines) {
    sale.lines.add(
      await db.newLine(sale, item)
        ..qty = qty
        ..priceListRate = rate
        ..rate = rate,
    );
  }
  for (final MapEntry(:key, :value) in pay.entries) {
    sale.payments[await idOf(db, 'mode_of_payment', key)] = value;
  }
  return sale;
}

/// Pays [sale] in full in cash.
Future<Sale> paid(AppDatabase db, Sale sale) async {
  final t = totalsOf(sale, saleSettingsOf(await db.formats()));
  sale.payments[await idOf(db, 'mode_of_payment', 'Cash')] = t.toPay;
  return sale;
}

Matcher refusedAll(Refusal r) => throwsA(
  isA<RefusedAll>().having(
    (e) => e.all.map((x) => x.reason),
    'reasons',
    contains(r),
  ),
);

Future<SalesInvoiceData> invoice(AppDatabase db, String name) =>
    (db.select(db.salesInvoice)..where((s) => s.name.equals(name))).getSingle();

void main() {
  final year = DateTime.now().year;

  test('POS-A17 a sale posts the ledger, its cost and its name', () async {
    final db = await register();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 10, rate: 100);
    final name = await db.submitSale(
      await paid(db, await cart(db, [(apple, 2, 150)])),
    );
    expect(name, 'ACC-SINV-$year-00001');
    final s = await invoice(db, name);
    expect((s.status, s.docstatus, s.grandTotal), ('Paid', 1, 300));
    final line = await (db.select(
      db.salesInvoiceItem,
    )..where((l) => l.salesInvoiceId.equals(s.id))).getSingle();
    expect(line.incomingRate, 100);
    final sle = await (db.select(
      db.stockLedgerEntry,
    )..where((x) => x.voucherType.equals(salesInvoiceType))).getSingle();
    expect((sle.actualQty, sle.voucherNo), (-2, name));
    expect((await binOf(db, apple)).actualQty, 8);
    expect(s.inWords, 'PHP Three Hundred only.');
  });

  test('POS-A18 discarded drafts leave no gap in receipt numbers', () async {
    final db = await register();
    final soap = await newItem(db, 'SOAP');
    await move(db, receipt, soap, 10, rate: 10);
    final drafts = [
      for (var i = 0; i < 3; i++)
        await cart(db, [(soap, 1, 20)]).then((s) async {
          await db.saveSale(s);
          return s;
        }),
    ];
    await db.deleteSale(drafts[0].id!);
    await db.deleteSale(drafts[1].id!);
    final third = await db.loadSale(drafts[2].id!);
    expect(await db.submitSale(await paid(db, third)), 'ACC-SINV-$year-00001');
  });

  test(
    'POS-A19 selling more than is in stock is refused; nothing written',
    () async {
      final db = await register();
      final pen = await newItem(db, 'PEN');
      await move(db, receipt, pen, 3, rate: 5);
      await expectLater(
        db.submitSale(await paid(db, await cart(db, [(pen, 5, 10)]))),
        refusedAll(Refusal.itemUnavailable),
      );
      expect(await db.select(db.salesInvoice).get(), isEmpty);
      expect((await binOf(db, pen)).actualQty, 3);
    },
  );

  test('POS-A20 payments below the amount to pay are refused', () async {
    final db = await register();
    final pen = await newItem(db, 'PEN');
    await move(db, receipt, pen, 3, rate: 5);
    await expectLater(
      db.submitSale(await cart(db, [(pen, 1, 10)], pay: {'Cash': 9})),
      refusedAll(Refusal.paymentShort),
    );
    await expectLater(
      db.submitSale(await cart(db, [(pen, 1, 10)], pay: {'Credit Card': 11})),
      refusedAll(Refusal.nonCashOverpaid),
    );
  });

  test('POS-A21 a second session cannot open while one is Open', () async {
    final db = await register();
    expect(db.openSessionWith({}), refused(Refusal.anotherSessionOpen));
  });

  test('POS-R2 an Opening Amount below zero is refused', () async {
    final db = await seeded();
    final cash = await idOf(db, 'mode_of_payment', 'Cash');
    await expectLater(
      db.openSessionWith({cash: -50}),
      refused(Refusal.negativeOpeningAmount),
    );
    expect(await db.openSession(), isNull);
  });

  test('POS-A10 a discount above Max Discount is refused', () async {
    final db = await register();
    final pen = await newItem(db, 'PEN');
    await move(db, receipt, pen, 3, rate: 5);
    await (db.update(db.item)..where((i) => i.id.equals(pen))).write(
      const ItemCompanion(maxDiscount: Value(20)),
    );
    final sale = await cart(db, [(pen, 1, 100)]);
    sale.lines.single
      ..discountPercentage = 25
      ..rate = 75;
    await expectLater(
      db.submitSale(await paid(db, sale)),
      refusedAll(Refusal.lineProblem),
    );
    final problems = await db.saleProblems(sale);
    expect(problems.single.args, [1, LineProblem.discountAboveMax]);
  });

  test('POS-A15 3 Cartons at factor 10 are 30 in stock', () async {
    final db = await register();
    final pen = await newItem(db, 'PEN');
    final carton = await idOf(db, 'uom', 'Carton');
    await db
        .into(db.itemUom)
        .insert(
          ItemUomCompanion.insert(
            itemId: pen,
            uomId: carton,
            conversionFactor: 10,
          ),
        );
    final sale = await db.newSale();
    sale.lines.add(
      await db.newLine(sale, pen, uomId: carton)
        ..qty = 3,
    );
    await db.saveSale(sale);
    final line = await db.select(db.salesInvoiceItem).getSingle();
    expect((line.conversionFactor, line.stockQty), (10, 30));
  });

  test('POS-A22 the closing example of POS-R20', () async {
    final db = await register();
    final cash = await idOf(db, 'mode_of_payment', 'Cash');
    final card = await idOf(db, 'mode_of_payment', 'Credit Card');
    final tea = await newItem(db, 'TEA');
    await move(db, receipt, tea, 10, rate: 100);
    await db.submitSale(
      await cart(db, [(tea, 1, 754.90)], pay: {'Cash': 1000}),
    );
    await db.submitSale(
      await cart(
        db,
        [(tea, 1, 754.90)],
        pay: {'Credit Card': 500, 'Cash': 300},
      ),
    );
    // Return C, a cash refund of 108: returns arrive with plan 05.
    final session = (await db.openSession())!;
    final sale = await db.newSale();
    final ret = await db
        .into(db.salesInvoice)
        .insert(
          SalesInvoiceCompanion.insert(
            name: const Value('ACC-SINV-RET-X'),
            docstatus: const Value(1),
            status: const Value('Return'),
            isReturn: const Value(1),
            postingDatetime: toStorage(DateTime.now()),
            posOpeningEntryId: session.id,
            setWarehouseId: sale.warehouseId,
            priceListId: sale.priceListId,
            grandTotal: const Value(-108),
          ),
        );
    await db
        .into(db.salesInvoicePayment)
        .insert(
          SalesInvoicePaymentCompanion.insert(
            salesInvoiceId: ret,
            modeOfPaymentId: cash,
            amount: -108,
          ),
        );
    final d = await db.closingDraft();
    expect(d.invoices, 3);
    expect(
      {for (final r in d.rows) r.mode: r.expected},
      {'Cash': 1401.80, 'Credit Card': 500},
    );
    final dir = await Directory.systemTemp.createTemp('pos-close');
    addTearDown(() => dir.delete(recursive: true));
    final result = await db.submitClosing({
      cash: 1400,
      card: 500,
    }, backupDir: dir);
    expect(result.backupError, isNull);
    expect(dir.listSync(), hasLength(1));
    final diff = await (db.select(
      db.posClosingEntryDetail,
    )..where((x) => x.modeOfPaymentId.equals(cash))).getSingle();
    expect(diff.difference, -1.80);
    expect(await db.openSession(), isNull);
    expect(await db.sessionOpen(), isFalse);
    // The latest closing can be cancelled, which reopens the session.
    await db.cancelLastClosing();
    expect((await db.openSession())?.id, session.id);
  });

  test('POS-A23 editing a tax template later leaves the sale alone', () async {
    final db = await register();
    final vat = await db.into(db.tax).insert(TaxCompanion.insert(name: 'VAT'));
    TaxRow row(double rate) =>
        TaxRow(chargeType: ChargeType.onNetTotal, taxId: vat, rate: rate);
    final template = await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion.insert(
        title: 'VAT 8%',
        isDefault: const Value(1),
      ),
      [row(8)],
    );
    final pen = await newItem(db, 'PEN');
    await move(db, receipt, pen, 3, rate: 5);
    final name = await db.submitSale(
      await paid(db, await cart(db, [(pen, 1, 699)])),
    );
    await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion(
        id: Value(template),
        title: const Value('VAT 8%'),
        isDefault: const Value(1),
      ),
      [row(12)],
    );
    final s = await invoice(db, name);
    expect((s.totalTaxesAndCharges, s.grandTotal), (55.92, 754.92));
    final tax = await db.select(db.salesInvoiceTax).getSingle();
    expect((tax.rate, tax.taxAmount), (8, 55.92));
  });

  test(
    'POS-A24 a held order completed later joins the later session',
    () async {
      final db = await register();
      final pen = await newItem(db, 'PEN');
      await move(db, receipt, pen, 3, rate: 5);
      final held = await cart(db, [(pen, 1, 10)]);
      await db.saveSale(held);
      final dir = await Directory.systemTemp.createTemp('pos-held');
      addTearDown(() => dir.delete(recursive: true));
      expect((await db.closingDraft()).heldOrders, 1);
      await db.submitClosing({}, backupDir: dir);
      final later = await db.openSessionWith({});
      final name = await db.submitSale(
        await paid(db, await db.loadSale(held.id!)),
      );
      expect((await invoice(db, name)).posOpeningEntryId, later);
      expect((await db.closingDraft()).invoices, 1);
    },
  );

  test(
    'POS-A25 a Delivered serial number cannot be sold; STK-R26 warranty',
    () async {
      final db = await register();
      final phone = await newItem(db, 'PHONE', serial: true);
      await (db.update(db.item)..where((i) => i.id.equals(phone))).write(
        const ItemCompanion(warrantyPeriod: Value(30)),
      );
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
      Future<Sale> sn1() async {
        final s = await cart(db, [(phone, 1, 200)]);
        s.lines.single.entries.add(SbEntry(serialNo: 'SN-1'));
        return paid(db, s);
      }

      await db.submitSale(await sn1());
      final sold = await (db.select(
        db.serialNo,
      )..where((s) => s.serialNo.equals('SN-1'))).getSingle();
      expect(sold.status, 'Delivered');
      final today = DateTime.parse(toStorage(DateTime.now()).substring(0, 10));
      expect(
        sold.warrantyExpiryDate,
        toStorage(today.add(const Duration(days: 30))).substring(0, 10),
      );
      await expectLater(
        db.submitSale(await sn1()),
        refused(Refusal.serialNotAvailable),
      );
      // STK-R27: a line left without entries is picked at Submit.
      await db.submitSale(await paid(db, await cart(db, [(phone, 1, 200)])));
      final sn2 = await (db.select(
        db.serialNo,
      )..where((s) => s.serialNo.equals('SN-2'))).getSingle();
      expect(sn2.status, 'Delivered');
    },
  );

  test('STK-R22 an expired batch cannot be sold', () async {
    final db = await register();
    final milk = await newItem(db, 'MILK', batch: true);
    await db.saveBatch(
      BatchesCompanion.insert(
        batchId: 'OLD',
        itemId: milk,
        expiryDate: const Value('2026-01-01'),
      ),
    );
    await move(
      db,
      receipt,
      milk,
      2,
      rate: 10,
      entries: [SbEntry(batchNo: 'OLD', qty: 2)],
    );
    final sale = await paid(db, await cart(db, [(milk, 1, 20)]));
    sale.lines.single.entries.add(SbEntry(batchNo: 'OLD'));
    await expectLater(db.submitSale(sale), refused(Refusal.expiredBatch));
    // The refusal rolled back the draft; the same cart, with a good batch,
    // still completes.
    expect(sale.id, isNull);
    await move(
      db,
      receipt,
      milk,
      1,
      rate: 10,
      entries: [SbEntry(batchNo: 'NEW')],
    );
    sale.lines.single.entries
      ..clear()
      ..add(SbEntry(batchNo: 'NEW'));
    expect(await db.submitSale(sale), startsWith('ACC-SINV-'));
    // Auto pick skips it, so nothing is left to pick.
    await expectLater(
      db.submitSale(await paid(db, await cart(db, [(milk, 1, 20)]))),
      refused(Refusal.notEnoughEntries),
    );
  });

  test('STK-R11 a missing price is inserted once; a backdated receipt '
      'recosts the sale', () async {
    final db = await register();
    final list = (await db.newSale()).priceListId;
    final rice = await newItem(db, 'RICE');
    await move(db, receipt, rice, 10, rate: 100, day: '2026-11-10');
    await db.submitSale(await paid(db, await cart(db, [(rice, 2, 150)])));
    final prices = await (db.select(
      db.itemPrice,
    )..where((p) => p.itemId.equals(rice))).get();
    expect(
      [for (final p in prices) (p.priceListId, p.priceListRate)],
      [(list, 150.0)],
    );
    await db.submitSale(await paid(db, await cart(db, [(rice, 1, 170)])));
    expect(
      await (db.select(
        db.itemPrice,
      )..where((p) => p.itemId.equals(rice))).get(),
      hasLength(1),
    );
    // A cheaper receipt dated before the first one: FIFO now sells it first.
    await move(db, receipt, rice, 10, rate: 50, day: '2026-11-01');
    final costs = [
      for (final l in await db.select(db.salesInvoiceItem).get())
        l.incomingRate,
    ];
    expect(costs, [50, 50]);
  });
}

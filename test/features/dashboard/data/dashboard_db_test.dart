import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/numbers/format.dart';
import 'package:rx_merchant/features/dashboard/data/dashboard_db.dart';
import 'package:rx_merchant/features/dashboard/data/sales_reports.dart';
import 'package:rx_merchant/features/dashboard/logic/periods.dart';
import 'package:rx_merchant/features/pos/data/pos_db.dart';
import 'package:rx_merchant/features/setup/data/setup_queries.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';

import '../../pos/data/pos_db_test.dart'
    show cart, invoice, paid, receipt, register;
import '../../stock/data/stock_db_test.dart' show idOf, move, newItem;

// 04-sales-dashboard section 7: the fixture and acceptance checks.

const day1 = '2026-03-02';
const day2 = '2026-03-03';

Span days(String from, [String? to]) =>
    (from: parseDay(from), to: parseDay(to ?? from));

typedef Fixture = ({AppDatabase db, int a, int b, int invoice2});

Future<void> _post(AppDatabase db, int id, String at) =>
    (db.update(db.salesInvoice)..where((s) => s.id.equals(id))).write(
      SalesInvoiceCompanion(postingDatetime: Value(at)),
    );

Future<void> cancel(AppDatabase db, int id) =>
    (db.update(db.salesInvoice)..where((s) => s.id.equals(id))).write(
      const SalesInvoiceCompanion(
        docstatus: Value(2),
        status: Value('Cancelled'),
      ),
    );

/// VAT 8% On Net Total, the default template.
Future<void> vat8(AppDatabase db) async {
  final vat = await db.into(db.tax).insert(TaxCompanion.insert(name: 'VAT'));
  await db.saveSalesTaxesTemplate(
    SalesTaxesTemplateCompanion.insert(
      title: 'VAT 8%',
      isDefault: const Value(1),
    ),
    [TaxRow(chargeType: ChargeType.onNetTotal, taxId: vat, rate: 8)],
  );
}

/// A return of one unit of [of]'s first line, refunded in cash; returns
/// arrive with plan 05, so it is written directly. [cost] is the unit's
/// cost (0 for a price-only credit note).
Future<void> refund(
  AppDatabase db,
  SalesInvoiceData of, {
  required String at,
  required double net,
  required double tax,
  required double cost,
}) async {
  final line =
      await (db.select(db.salesInvoiceItem)
            ..where((l) => l.salesInvoiceId.equals(of.id))
            ..limit(1))
          .getSingle();
  final ret = await db
      .into(db.salesInvoice)
      .insert(
        SalesInvoiceCompanion.insert(
          name: Value('RET-${of.id}'),
          docstatus: const Value(1),
          status: const Value('Return'),
          isReturn: const Value(1),
          returnAgainstId: Value(of.id),
          postingDatetime: at,
          posOpeningEntryId: of.posOpeningEntryId,
          setWarehouseId: of.setWarehouseId,
          priceListId: of.priceListId,
          netTotal: Value(-net),
          totalTaxesAndCharges: Value(-tax),
          grandTotal: Value(-(net + tax)),
        ),
      );
  await db
      .into(db.salesInvoiceItem)
      .insert(
        SalesInvoiceItemCompanion.insert(
          salesInvoiceId: ret,
          idx: 1,
          itemId: line.itemId,
          itemName: line.itemName,
          qty: -1,
          uomId: line.uomId,
          stockQty: -1,
          rate: Value(net),
          amount: Value(-net),
          netRate: Value(net),
          netAmount: Value(-net),
          warehouseId: line.warehouseId,
          incomingRate: Value(cost),
          salesInvoiceItemId: Value(line.id),
        ),
      );
  await db
      .into(db.salesInvoicePayment)
      .insert(
        SalesInvoicePaymentCompanion.insert(
          salesInvoiceId: ret,
          modeOfPaymentId: await idOf(db, 'mode_of_payment', 'Cash'),
          amount: -(net + tax),
        ),
      );
}

/// Section 7: Invoices 1 and 2 on day 1, Return 3 on day 2, Draft 4 and
/// Cancelled 5; one item group, Products; VAT 8% On Net Total.
Future<Fixture> fixture() async {
  final db = await register();
  await vat8(db);
  final a = await newItem(db, 'A');
  final b = await newItem(db, 'B');
  await move(db, receipt, a, 10, rate: 60);
  await move(db, receipt, b, 10, rate: 350);
  final one = await invoice(
    db,
    await db.submitSale(await paid(db, await cart(db, [(a, 2, 100)]))),
  );
  final two = await invoice(
    db,
    await db.submitSale(
      await cart(db, [(b, 1, 500)], pay: {'Credit Card': 540}),
    ),
  );
  await _post(db, one.id, '$day1 10:00:00');
  await _post(db, two.id, '$day1 11:00:00');

  // Return 3, a cash refund of 108.
  await refund(db, one, at: '$day2 09:00:00', net: 100, tax: 8, cost: 60);

  // Draft 4 and Cancelled 5 never count.
  final draft = await db.saveSale(await cart(db, [(b, 3, 500)]));
  await _post(db, draft, '$day1 12:00:00');
  final five = await invoice(
    db,
    await db.submitSale(await paid(db, await cart(db, [(a, 1, 999)]))),
  );
  await _post(db, five.id, '$day1 13:00:00');
  await cancel(db, five.id);
  return (db: db, a: a, b: b, invoice2: two.id);
}

void main() {
  test('DSH-A1 to A8 the figures of days 1 to 2', () async {
    final f = await fixture();
    final x = await f.db.figures(days(day1, day2));
    expect(x.netSales, closeTo(600, 1e-9));
    expect(x.taxes, closeTo(48, 1e-9));
    expect(x.totalSales, closeTo(648, 1e-9));
    expect((x.invoices, x.returns, x.returned), (2, 1, 108));
    expect(x.averageSale, closeTo(378, 1e-9));
    expect(x.itemsSold, 2);
    expect(x.cost, closeTo(410, 1e-9));
    expect(x.grossProfit, closeTo(190, 1e-9));
    expect(x.grossProfitPercent.toStringAsFixed(1), '31.7');
  });

  test('DSH-A9 payment modes: payments less refunds', () async {
    final f = await fixture();
    final modes = await f.db.paymentModes(days(day1, day2));
    expect(
      {for (final m in modes) m.label: m.value},
      {'Cash': 108, 'Credit Card': 540},
    );
  });

  test('DSH-R6 change comes off the cash mode it was given from', () async {
    final db = await register();
    final a = await newItem(db, 'A');
    await move(db, receipt, a, 10, rate: 60);
    await db.submitSale(
      await cart(db, [(a, 1, 75)], pay: {'Credit Card': 50, 'Cash': 100}),
    );
    final today = dayOf(DateTime.now());
    final modes = await db.paymentModes((from: today, to: today));
    expect(
      {for (final m in modes) m.label: m.value},
      {'Cash': 25, 'Credit Card': 50},
    );
  });

  test('DSH-A10 day 1 only', () async {
    final f = await fixture();
    expect((await f.db.figures(days(day1))).netSales, closeTo(700, 1e-9));
  });

  test('DSH-A11 to A12 the sales goal', () async {
    final f = await fixture();
    final month = await f.db.monthlySales(DateTime(2026, 3, 20));
    expect(month, closeTo(648, 1e-9));
    expect(achievement(month, 1296), closeTo(50, 1e-9));
    expect(achievement(13949, 100000), closeTo(13.949, 1e-9));
    expect(achievement(500, 0), 0);
    expect(await f.db.monthlySales(DateTime(2026, 4, 1)), 0);
  });

  test('DSH-R6 trend, groups and top items', () async {
    final f = await fixture();
    final span = days(day1, day2);
    final buckets = bucketsOf(span, trendRange(span), 'Monday');
    expect(await f.db.trend(span, buckets), [700, -100]);
    expect(await f.db.trend(span, buckets, qty: true), [3, -1]);
    expect(
      [for (final g in await f.db.salesByGroup(span)) (g.label, g.value)],
      [('Products', 600)],
    );
    expect(
      [for (final i in await f.db.topItems(span)) (i.label, i.value)],
      [('B', 500), ('A', 100)],
    );
  });

  test('DSH-A14 Sales Analytics by Item, Value, Daily', () async {
    final f = await fixture();
    final r = await f.db.salesAnalytics(
      SalesFilters(span: days(day1, day2), range: Range.daily),
      'Monday',
    );
    expect(r.buckets, hasLength(2));
    expect(r.rows, [
      ['A', 200, -100, 100, f.a, 0],
      ['B', 500, 0, 500, f.b, 0],
    ]);
  });

  test('DSH-A15 Sales Analytics by Item Group', () async {
    final f = await fixture();
    final r = await f.db.salesAnalytics(
      SalesFilters(span: days(day1, day2), range: Range.daily, byGroup: true),
      'Monday',
    );
    expect(
      [for (final row in r.rows) row.take(4).toList()],
      [
        ['All Item Groups', 700, -100, 600],
        ['   Products', 700, -100, 600],
      ],
    );
  });

  test('DSH-A16 Item-wise Sales totals', () async {
    final f = await fixture();
    final rows = await f.db.itemWiseSales(SalesFilters(span: days(day1, day2)));
    expect(rows, hasLength(3));
    double sum(int c) => rows.fold(0.0, (s, r) => s + (r[c] as double));
    expect(sum(8), closeTo(600, 1e-9));
    expect(sum(9), closeTo(48, 1e-9));
    expect(sum(10), closeTo(648, 1e-9));
    // Filtered to Item B.
    final b = await f.db.itemWiseSales(
      SalesFilters(span: days(day1, day2), itemId: f.b),
    );
    expect(
      [for (final r in b) (r[2], r[8], r[9], r[10])],
      [('B', 500, 40, 540)],
    );
  });

  test('DSH-A17 Gross Profit by Item', () async {
    final f = await fixture();
    final rows = await f.db.grossProfit(SalesFilters(span: days(day1, day2)));
    expect(
      [for (final r in rows) r.take(5).toList()],
      [
        ['A', 1, 100, 60, 40],
        ['B', 1, 500, 350, 150],
      ],
    );
    // Average Selling Rate, Valuation Rate, no cost missing.
    expect(rows.first.skip(6).toList(), [100, 60, false]);
    final groups = await f.db.grossProfit(
      SalesFilters(span: days(day1, day2), groupBy: ProfitBy.itemGroup),
    );
    expect(
      [for (final r in groups) r.take(5).toList()],
      [
        ['Products', 2, 600, 410, 190],
      ],
    );
  });

  test('DSH-R9 a stock item sold at no cost is flagged; a price-only '
      'credit note is not', () async {
    final db = await register();
    final free = await newItem(db, 'FREE', allowNegative: true);
    final a = await newItem(db, 'A');
    await move(db, receipt, a, 10, rate: 60);
    await db.submitSale(await paid(db, await cart(db, [(free, 1, 10)])));
    final sold = await invoice(
      db,
      await db.submitSale(await paid(db, await cart(db, [(a, 1, 100)]))),
    );
    await refund(
      db,
      sold,
      at: toStorage(DateTime.now()),
      net: 20,
      tax: 0,
      cost: 0,
    );
    final today = dayOf(DateTime.now());
    final rows = await db.grossProfit(
      SalesFilters(span: (from: today, to: today)),
    );
    expect({for (final r in rows) r.first: r.last}, {'A': false, 'FREE': true});
  });

  test(
    'DSH-R8 each line carries its own tax from the item-wise detail',
    () async {
      final db = await register();
      await vat8(db);
      final c = await newItem(db, 'C');
      final d = await newItem(db, 'D');
      await move(db, receipt, c, 5, rate: 10);
      await move(db, receipt, d, 5, rate: 10);
      await db.submitSale(
        await paid(db, await cart(db, [(c, 1, 100), (d, 1, 50)])),
      );
      final today = dayOf(DateTime.now());
      final rows = await db.itemWiseSales(
        SalesFilters(span: (from: today, to: today)),
      );
      expect(
        [for (final r in rows) (r[2], r[9], r[10])],
        [('C', 8, 108), ('D', 4, 54)],
      );
    },
  );

  test('DSH-R6 the top 8 item groups, then Other', () async {
    final db = await register();
    final root = await idOf(db, 'item_group', 'All Item Groups');
    for (var i = 1; i <= 9; i++) {
      final group = await db
          .into(db.itemGroup)
          .insert(
            ItemGroupCompanion.insert(name: 'G$i', parentId: Value(root)),
          );
      final item = await newItem(db, 'I$i');
      await (db.update(db.item)..where((x) => x.id.equals(item))).write(
        ItemCompanion(itemGroupId: Value(group)),
      );
      await move(db, receipt, item, 1, rate: 1);
      await db.submitSale(
        await paid(db, await cart(db, [(item, 1, i * 10.0)])),
      );
    }
    final today = dayOf(DateTime.now());
    final bars = await db.salesByGroup((from: today, to: today));
    expect([for (final b in bars) b.label].take(8), [
      for (var i = 9; i >= 2; i--) 'G$i',
    ]);
    expect((bars.length, bars.last.id, bars.last.value), (9, null, 10));
  });

  test('DSH-A19 cancelling Invoice 2 takes away its amounts only', () async {
    final f = await fixture();
    await cancel(f.db, f.invoice2);
    final x = await f.db.figures(days(day1, day2));
    expect((x.netSales, x.taxes, x.totalSales), (100, 8, 108));
    expect((x.invoices, x.returns, x.averageSale), (1, 1, 216));
    expect((x.itemsSold, x.cost, x.grossProfit), (1, 60, 40));
    expect(
      [for (final m in await f.db.paymentModes(days(day1, day2))) m.label],
      ['Cash'],
    );
    final span = days(day1, day2);
    final groups = await f.db.salesByGroup(span);
    expect([for (final g in groups) (g.label, g.value)], [('Products', 100)]);
    expect(await f.db.trend(span, bucketsOf(span, Range.daily, 'Monday')), [
      200,
      -100,
    ]);
  });

  test('DSH-R12 no sale yet; stock value as of now', () async {
    final db = await register();
    expect(await db.hasAnySale(), isFalse);
    final a = await newItem(db, 'A');
    await move(db, receipt, a, 10, rate: 60);
    expect(await db.stockValue(), 600);
    await db.submitSale(await paid(db, await cart(db, [(a, 1, 75)])));
    expect(await db.hasAnySale(), isTrue);
    expect(await db.stockValue(), 540);
  });

  test('Section 3 ceiling: 20,000 invoices stay quick', () async {
    final db = await register();
    final a = await newItem(db, 'A');
    final ids = await db
        .customSelect(
          "SELECT (SELECT id FROM pos_opening_entry) AS s, "
          "(SELECT id FROM warehouse WHERE name = 'Stores') AS w, "
          "(SELECT id FROM price_list WHERE name = 'Standard Selling') AS p, "
          "(SELECT id FROM uom WHERE name = 'Nos') AS u, "
          "(SELECT id FROM mode_of_payment WHERE name = 'Cash') AS m",
        )
        .getSingle();
    int id(String k) => ids.read<int>(k);
    await db.customStatement(
      'WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM c '
      'WHERE x < 20000) INSERT INTO sales_invoice (name, docstatus, status, '
      'posting_datetime, pos_opening_entry_id, set_warehouse_id, '
      'price_list_id, net_total, total_taxes_and_charges, grand_total) '
      "SELECT 'X-' || x, 1, 'Paid', date('2026-01-01', '+' || (x % 300) || "
      "' days') || ' 10:00:00', ?, ?, ?, 100, 8, 108 FROM c",
      [id('s'), id('w'), id('p')],
    );
    await db.customStatement(
      'INSERT INTO sales_invoice_item (sales_invoice_id, idx, item_id, '
      'item_name, qty, uom_id, stock_qty, warehouse_id, net_amount, '
      "incoming_rate) SELECT id, 1, ?, 'A', 1, ?, 1, ?, 100, 60 "
      "FROM sales_invoice WHERE name LIKE 'X-%'",
      [a, id('u'), id('w')],
    );
    await db.customStatement(
      'INSERT INTO sales_invoice_payment (sales_invoice_id, '
      "mode_of_payment_id, amount) SELECT id, ?, 108 FROM sales_invoice "
      "WHERE name LIKE 'X-%'",
      [id('m')],
    );
    final year = days('2026-01-01', '2026-12-31');
    final watch = Stopwatch()..start();
    final x = await db.figures(year);
    await db.trend(year, bucketsOf(year, trendRange(year), 'Monday'));
    await db.salesByGroup(year);
    await db.topItems(year);
    await db.paymentModes(year);
    final dashboard = watch.elapsedMilliseconds;
    final f = SalesFilters(span: year);
    await db.salesAnalytics(f, 'Monday');
    await db.grossProfit(f);
    final lines = await db.itemWiseSales(f);
    final reports = watch.elapsedMilliseconds - dashboard;
    expect((x.invoices, lines.length), (20000, 20000));
    expect(dashboard, lessThan(500));
    expect(reports, lessThan(2000));
  });
}

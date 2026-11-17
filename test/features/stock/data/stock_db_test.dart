import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/singles.dart';
import 'package:rx_merchant/features/setup/data/setup_queries.dart';
import 'package:rx_merchant/features/setup/data/refusal.dart';
import 'package:rx_merchant/features/stock/data/stock_entry_db.dart';
import 'package:rx_merchant/features/stock/data/stock_ledger.dart';
import 'package:rx_merchant/features/stock/data/stock_masters.dart';
import 'package:rx_merchant/features/stock/data/stock_reconciliation_db.dart';
import 'package:rx_merchant/features/stock/data/stock_reports.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';
import 'package:rx_merchant/features/stock/logic/variants.dart';

import '../../setup/data/setup_db_test.dart' show refused, seeded;

const ItemTables noTables = (
  barcodes: [],
  uoms: [],
  reorder: [],
  taxes: [],
  attributes: [],
);

Future<int> idOf(AppDatabase db, String table, String name) async =>
    (await db
            .customSelect(
              'SELECT id FROM $table WHERE name = ?',
              variables: [Variable(name)],
            )
            .getSingle())
        .read<int>('id');

/// An item in Products, counted in Nos.
Future<int> newItem(
  AppDatabase db,
  String code, {
  bool allowNegative = false,
  bool batch = false,
  bool serial = false,
  String? method,
}) async => db.saveItem(
  ItemCompanion.insert(
    itemCode: code,
    itemName: code,
    itemGroupId: await idOf(db, 'item_group', 'Products'),
    stockUomId: await idOf(db, 'uom', 'Nos'),
    allowNegativeStock: Value(allowNegative ? 1 : 0),
    hasBatchNo: Value(batch ? 1 : 0),
    createNewBatch: Value(batch ? 1 : 0),
    batchNumberSeries: Value(batch ? '5x1SCR' : null),
    hasSerialNo: Value(serial ? 1 : 0),
    valuationMethod: Value(method),
  ),
  noTables,
);

/// Saves and submits one stock entry; returns its id.
Future<int> move(
  AppDatabase db,
  StockPurpose purpose,
  int itemId,
  double qty, {
  double rate = 0,
  String day = '2026-11-10',
  int? from,
  int? to,
  List<SbEntry> entries = const [],
  List<(String, double)> costs = const [],
}) async {
  final stores = await idOf(db, 'warehouse', 'Stores');
  final id = await db.saveStockEntry(
    StockEntryCompanion.insert(purpose: purpose.value, postingDatetime: ''),
    [
      EntryLine(
        itemId: itemId,
        sWarehouseId: purpose.hasSource ? from ?? stores : null,
        tWarehouseId: purpose.hasTarget ? to ?? stores : null,
        qty: qty,
        uomId: await idOf(db, 'uom', 'Nos'),
        basicRate: rate,
        entries: [...entries],
      ),
    ],
    costs,
    posting: '$day 10:00:00',
  );
  await db.submitStockEntry(id);
  return id;
}

Future<BinData> binOf(
  AppDatabase db,
  int itemId, [
  String wh = 'Stores',
]) async {
  final w = await idOf(db, 'warehouse', wh);
  return (db.select(db.bin)
        ..where((b) => b.itemId.equals(itemId) & b.warehouseId.equals(w)))
      .getSingle();
}

Future<double> issueCost(AppDatabase db, int entryId) async =>
    (await (db.select(
      db.stockEntry,
    )..where((e) => e.id.equals(entryId))).getSingle()).totalOutgoingValue;

void main() {
  const receipt = StockPurpose.materialReceipt;
  const issue = StockPurpose.materialIssue;
  const transfer = StockPurpose.materialTransfer;

  test('a receipt and an issue post FIFO costs and name the entry', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final r = await move(db, receipt, apple, 10, rate: 100);
    await move(db, receipt, apple, 10, rate: 120, day: '2026-11-11');
    final i = await move(db, issue, apple, 15, day: '2026-11-12');
    expect(await issueCost(db, i), 1600);
    final b = await binOf(db, apple);
    expect(b.actualQty, 5);
    expect(b.stockValue, 600);
    expect(b.stockQueue, '[[5.0,120.0]]');
    final e = await (db.select(
      db.stockEntry,
    )..where((x) => x.id.equals(r))).getSingle();
    expect(e.name, 'MAT-STE-2026-00001');
    expect(e.docstatus, 1);
  });

  test(
    'STK-A16 issuing 5 with 3 on hand is refused; nothing written',
    () async {
      final db = await seeded();
      final apple = await newItem(db, 'APPLE');
      await move(db, receipt, apple, 3, rate: 10);
      await expectLater(
        move(db, issue, apple, 5, day: '2026-11-11'),
        refused(Refusal.negativeStock),
      );
      expect((await binOf(db, apple)).actualQty, 3);
      final ledger = await db.select(db.stockLedgerEntry).get();
      expect(ledger, hasLength(1));
    },
  );

  test('STK-A17 allowed with Allow negative stock on the item', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE', allowNegative: true);
    await move(db, receipt, apple, 3, rate: 10);
    await move(db, issue, apple, 5, day: '2026-11-11');
    expect((await binOf(db, apple)).actualQty, -2);
  });

  test('STK-A18 a batch item never goes negative', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {
      'allow_negative_stock': true,
      'enable_serial_and_batch_no_for_item': true,
    });
    final pills = await newItem(db, 'PILLS', batch: true);
    await move(db, receipt, pills, 3, rate: 10);
    final batch = await (db.select(db.batches)).getSingle();
    expect(batch.batchId, '5x1SCR00001', reason: 'STK-A12');
    await expectLater(
      move(
        db,
        issue,
        pills,
        5,
        day: '2026-11-11',
        entries: [SbEntry(batchNo: batch.batchId, qty: 5)],
      ),
      refused(Refusal.negativeStock),
    );
    // With stock enough for the item, one batch still cannot go below zero.
    await move(db, receipt, pills, 3, rate: 10);
    await expectLater(
      move(
        db,
        issue,
        pills,
        5,
        day: '2026-11-11',
        entries: [SbEntry(batchNo: batch.batchId, qty: 5)],
      ),
      refused(Refusal.negativeBatch),
    );
  });

  test('STK-A19 an issue dated before the receipt is refused', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 10, rate: 10, day: '2026-11-02');
    await expectLater(
      move(db, issue, apple, 5, day: '2026-11-01'),
      refused(Refusal.negativeStock),
    );
  });

  test('STK-A20 a backdated receipt recosts a later issue', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 10, rate: 100, day: '2026-11-01');
    await move(db, receipt, apple, 10, rate: 120, day: '2026-11-03');
    final i = await move(db, issue, apple, 15, day: '2026-11-04');
    expect(await issueCost(db, i), 1600);
    await move(db, receipt, apple, 10, rate: 90, day: '2026-11-02');
    expect(await issueCost(db, i), 1450);
  });

  test('STK-A21 cancelling a receipt the issue needs is refused', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final first = await move(
      db,
      receipt,
      apple,
      10,
      rate: 100,
      day: '2026-11-01',
    );
    await move(db, receipt, apple, 10, rate: 120, day: '2026-11-03');
    await move(db, issue, apple, 15, day: '2026-11-04');
    await expectLater(
      db.cancelStockEntry(first),
      throwsA(
        isA<RefusedException>()
            .having((e) => e.reason, 'reason', Refusal.negativeStock)
            .having((e) => e.args[5], 'voucher', 'MAT-STE-2026-00003'),
      ),
    );
  });

  test('cancel reverses, amend names the copy -1', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final r = await move(db, receipt, apple, 10, rate: 100);
    await db.cancelStockEntry(r);
    expect((await binOf(db, apple)).actualQty, 0);
    final copy = await db.amendStockEntry(r);
    await db.submitStockEntry(copy);
    final e = await (db.select(
      db.stockEntry,
    )..where((x) => x.id.equals(copy))).getSingle();
    expect(e.name, 'MAT-STE-2026-00001-1');
    expect((await binOf(db, apple)).actualQty, 10);
  });

  test('STK-A22 reconciliation sets 8 @ 105 over 10 @ 100', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 10, rate: 100);
    final stores = await idOf(db, 'warehouse', 'Stores');
    final id = await db.saveStockReconciliation(
      StockReconciliationCompanion.insert(
        purpose: 'Stock Reconciliation',
        postingDatetime: '',
      ),
      [
        ReconciliationLine(
          itemId: apple,
          warehouseId: stores,
          qty: 8,
          rate: 105,
        ),
      ],
      posting: '2026-11-11 10:00:00',
    );
    final row = await (db.select(db.stockReconciliationItem)).getSingle();
    expect(row.quantityDifference, -2);
    expect(row.amountDifference, -160);
    await db.submitStockReconciliation(id);
    final b = await binOf(db, apple);
    expect(b.actualQty, 8);
    expect(b.stockValue, 840);
  });

  test('STK-A23 a transfer writes two entries; value unchanged', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final back = await db.saveWarehouse(
      WarehouseCompanion.insert(
        name: 'Back Room',
        parentId: Value(await idOf(db, 'warehouse', 'All Warehouses')),
      ),
    );
    final r = await move(db, receipt, apple, 10, rate: 50);
    final t = await move(db, transfer, apple, 4, day: '2026-11-11', to: back);
    final sle = await (db.select(
      db.stockLedgerEntry,
    )..where((s) => s.voucherId.equals(t))).get();
    expect(sle, hasLength(2));
    expect(
      (await binOf(db, apple)).stockValue +
          (await binOf(db, apple, 'Back Room')).stockValue,
      500,
    );
    expect((await binOf(db, apple, 'Back Room')).valuationRate, 50);
    expect(r, isNot(t));
  });

  test('STK-A24 a receipt whose serial was sold cannot be cancelled', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {
      'enable_serial_and_batch_no_for_item': true,
    });
    final laptop = await newItem(db, 'LAPTOP', serial: true);
    final r1 = await move(
      db,
      receipt,
      laptop,
      1,
      rate: 50000,
      entries: [SbEntry(serialNo: 'LAP-001')],
    );
    await move(
      db,
      receipt,
      laptop,
      1,
      rate: 55000,
      entries: [SbEntry(serialNo: 'LAP-002')],
    );
    final i = await move(
      db,
      issue,
      laptop,
      1,
      day: '2026-11-11',
      entries: [SbEntry(serialNo: 'LAP-002')],
    );
    expect(await issueCost(db, i), 55000, reason: 'STK-A5 at db level');
    expect((await binOf(db, laptop)).stockValue, 50000);
    await db.cancelStockEntry(r1);
    final r2 = (await db.select(db.stockEntry).get())[1].id;
    await expectLater(
      db.cancelStockEntry(r2),
      refused(Refusal.serialMovedSince),
    );
  });

  test(
    'STK-A25 an expired batch cannot be transferred, but can be issued',
    () async {
      final db = await seeded();
      await db.writeSingle(StockSettings.doctype, {
        'enable_serial_and_batch_no_for_item': true,
      });
      final milk = await newItem(db, 'MILK', batch: true);
      await move(db, receipt, milk, 5, rate: 2, day: '2026-01-01');
      final batch = await db.select(db.batches).getSingle();
      await db.saveBatch(
        batch
            .toCompanion(false)
            .copyWith(expiryDate: const Value('2026-02-01')),
      );
      final back = await db.saveWarehouse(
        WarehouseCompanion.insert(
          name: 'Back Room',
          parentId: Value(await idOf(db, 'warehouse', 'All Warehouses')),
        ),
      );
      await expectLater(
        move(
          db,
          transfer,
          milk,
          1,
          day: '2026-03-01',
          to: back,
          entries: [SbEntry(batchNo: batch.batchId, qty: 1)],
        ),
        refused(Refusal.expiredBatch),
      );
      // Auto Fetch takes the expired batch for a write-off.
      await move(db, issue, milk, 5, day: '2026-03-01');
      expect((await binOf(db, milk)).actualQty, 0);
    },
  );

  test('STK-A26 rebuilding bin from the ledger gives the same bins', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final pear = await newItem(db, 'PEAR', method: 'Moving Average');
    await move(db, receipt, apple, 10, rate: 100, day: '2026-11-01');
    await move(db, receipt, pear, 10, rate: 100, day: '2026-11-01');
    await move(db, receipt, pear, 20, rate: 120, day: '2026-11-02');
    await move(db, issue, pear, 15, day: '2026-11-03');
    await move(db, issue, apple, 4, day: '2026-11-03');
    await move(db, receipt, apple, 2, rate: 80, day: '2026-11-02');
    final before = await db.select(db.bin).get();
    expect(
      before.firstWhere((b) => b.itemId == pear).stockValue,
      1700,
      reason: 'STK-A4 at db level',
    );
    await db.rebuildBins();
    expect(await db.select(db.bin).get(), before);
  });

  test(
    'STK-A27 submitting on or before Stock Frozen Upto is refused',
    () async {
      final db = await seeded();
      final apple = await newItem(db, 'APPLE');
      await db.writeSingle(StockSettings.doctype, {
        'stock_frozen_upto': '2026-11-10',
      });
      await expectLater(
        move(db, receipt, apple, 1, rate: 1, day: '2026-11-10'),
        refused(Refusal.stockFrozen),
      );
      await move(db, receipt, apple, 1, rate: 1, day: '2026-11-11');
    },
  );

  test('STK-A8 additional costs raise the receipt valuation', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 6, rate: 100, costs: [('Freight', 30)]);
    expect((await binOf(db, apple)).stockValue, 630);
  });

  test('opening stock and price from a new item (STK-R5)', () async {
    final db = await seeded();
    final id = await db.saveItem(
      ItemCompanion.insert(
        itemCode: 'SOAP',
        itemName: 'Soap',
        itemGroupId: await idOf(db, 'item_group', 'Products'),
        stockUomId: await idOf(db, 'uom', 'Nos'),
        standardRate: const Value(25),
      ),
      noTables,
      opening: (qty: 12, rate: 15),
    );
    expect((await binOf(db, id)).stockValue, 180);
    final price = await db.select(db.itemPrice).getSingle();
    expect(price.priceListRate, 25);
    final entry = await db.select(db.stockEntry).getSingle();
    expect(entry.isOpening, 1);
  });

  test('STK-R7 frozen fields; STK-R9 a used unit stays', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await move(db, receipt, apple, 1, rate: 1);
    final it = await (db.select(
      db.item,
    )..where((i) => i.id.equals(apple))).getSingle();
    await expectLater(
      db.saveItem(
        it.toCompanion(false).copyWith(isStockItem: const Value(0)),
        noTables,
      ),
      refused(Refusal.frozenField),
    );
    final box = await idOf(db, 'uom', 'Box');
    final withBox = (
      barcodes: <ItemBarcodeCompanion>[],
      uoms: [
        ItemUomCompanion.insert(
          itemId: apple,
          uomId: box,
          conversionFactor: 10,
        ),
      ],
      reorder: <ItemReorderCompanion>[],
      taxes: <ItemTaxCompanion>[],
      attributes: <int>[],
    );
    await db.saveItem(it.toCompanion(false), withBox);
    final stores = await idOf(db, 'warehouse', 'Stores');
    final e = await db.saveStockEntry(
      StockEntryCompanion.insert(purpose: receipt.value, postingDatetime: ''),
      [
        EntryLine(
          itemId: apple,
          tWarehouseId: stores,
          qty: 3,
          uomId: box,
          factor: 10,
          basicRate: 1,
        ),
      ],
      const [],
    );
    expect(
      (await (db.select(
        db.stockEntryItem,
      )..where((i) => i.stockEntryId.equals(e))).getSingle()).transferQty,
      30,
      reason: 'STK-A6',
    );
    await expectLater(
      db.saveItem(it.toCompanion(false), noTables),
      refused(Refusal.unitInUse),
    );
  });

  test('STK-A7 a fraction of a whole-number unit is refused', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    await expectLater(
      move(db, receipt, apple, 1.5, rate: 1),
      throwsA(
        isA<RefusedException>().having((e) => e.args, 'args', [
          1,
          LineProblem.fraction,
        ]),
      ),
    );
  });

  test(
    'STK-R1 the Default Warehouse stays usable and follows a rename',
    () async {
      final db = await seeded();
      final stores = await (db.select(
        db.warehouse,
      )..where((w) => w.name.equals('Stores'))).getSingle();
      await expectLater(
        db.saveWarehouse(
          stores.toCompanion(false).copyWith(disabled: const Value(1)),
        ),
        refused(Refusal.defaultWarehouse),
      );
      await expectLater(
        db.deleteWarehouse(stores.id),
        refused(Refusal.defaultWarehouse),
      );
      await db.saveWarehouse(
        stores.toCompanion(false).copyWith(name: const Value('Shop Floor')),
      );
      expect(
        StockSettings(await db.readSingle(StockSettings.doctype))
            .defaultWarehouse,
        'Shop Floor',
      );
    },
  );

  test('STK-A10 variants: 6 created, a second run creates none', () async {
    final db = await seeded();
    final shirt = await db.saveItem(
      ItemCompanion.insert(
        itemCode: 'TSHIRT',
        itemName: 'T-Shirt',
        itemGroupId: await idOf(db, 'item_group', 'Products'),
        stockUomId: await idOf(db, 'uom', 'Nos'),
        hasVariants: const Value(1),
      ),
      noTables,
    );
    final color = await db.saveItemAttribute(
      ItemAttributeCompanion.insert(name: 'Color'),
      [
        ItemAttributeValueCompanion.insert(
          attributeId: 0,
          attributeValue: 'Red',
          abbr: 'RED',
        ),
        ItemAttributeValueCompanion.insert(
          attributeId: 0,
          attributeValue: 'Green',
          abbr: 'GRN',
        ),
      ],
    );
    final size = await db.saveItemAttribute(
      ItemAttributeCompanion.insert(name: 'Size'),
      [
        for (final (v, a) in [('Small', 'S'), ('Medium', 'M'), ('Large', 'L')])
          ItemAttributeValueCompanion.insert(
            attributeId: 0,
            attributeValue: v,
            abbr: a,
          ),
      ],
    );
    final combos = combinations([
      [
        (attributeId: color, value: 'Red', abbr: 'RED'),
        (attributeId: color, value: 'Green', abbr: 'GRN'),
      ],
      [
        for (final (v, a) in [('Small', 'S'), ('Medium', 'M'), ('Large', 'L')])
          (attributeId: size, value: v, abbr: a),
      ],
    ]);
    expect(await db.createVariants(shirt, combos), 6);
    expect(await db.createVariants(shirt, combos), 0);
    final codes = await (db.select(
      db.item,
    )..where((i) => i.variantOfId.equals(shirt))).map((i) => i.itemCode).get();
    expect(codes, contains('TSHIRT-RED-S'));
    await expectLater(
      move(db, receipt, shirt, 1, rate: 1),
      throwsA(
        isA<RefusedException>().having((e) => e.args, 'args', [
          1,
          LineProblem.itemTemplate,
        ]),
      ),
    );
  });

  test('STK-R25 serial series, and a range of 50 (STK-B13)', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {
      'enable_serial_and_batch_no_for_item': true,
    });
    final id = await newItem(db, 'PHONE', serial: true);
    await db.saveItem(
      (await (db.select(db.item)..where((i) => i.id.equals(id))).getSingle())
          .toCompanion(false)
          .copyWith(serialNoSeries: const Value('PB2L.#####')),
      noTables,
    );
    await move(db, receipt, id, 2, rate: 10);
    final serials = await db.select(db.serialNo).map((s) => s.serialNo).get();
    expect(serials, ['PB2L00001', 'PB2L00002']);
    await move(
      db,
      receipt,
      id,
      50,
      rate: 10,
      entries: [
        for (var n = 1; n <= 50; n++)
          SbEntry(serialNo: 'SN-${'$n'.padLeft(2, '0')}'),
      ],
    );
    expect((await binOf(db, id)).actualQty, 52);
  });

  test(
    'STK-R43 Stock Ledger, Stock Balance and Low Stock read the ledger',
    () async {
      final db = await seeded();
      final apple = await newItem(db, 'APPLE');
      await move(db, receipt, apple, 10, rate: 100, day: '2026-11-01');
      final cancelled = await move(
        db,
        receipt,
        apple,
        5,
        rate: 100,
        day: '2026-11-02',
      );
      await db.cancelStockEntry(cancelled);
      await move(db, issue, apple, 4, day: '2026-11-05');

      final ledger = await db.stockLedgerReport(StockFilters());
      expect(ledger, hasLength(2), reason: 'cancelled entries are left out');
      expect(ledger.last[4], 4, reason: 'Out Qty');
      expect(ledger.last[5], 6, reason: 'Balance Qty');

      final balance = await db.stockBalanceReport(
        StockFilters(from: '2026-11-03', to: '2026-11-30'),
      );
      expect(balance.single.sublist(4, 12), [10, 1000, 0, 0, 4, 400, 6, 600]);
      expect(balance.single[12], 100);

      final stores = await idOf(db, 'warehouse', 'Stores');
      await db
          .into(db.itemReorder)
          .insert(
            ItemReorderCompanion.insert(
              itemId: apple,
              warehouseId: stores,
              warehouseReorderLevel: const Value(6),
              warehouseReorderQty: const Value(20),
            ),
          );
      final low = await db.lowStockReport(StockFilters());
      expect(low.single[0], 'APPLE');
      expect(low.single[6], 0, reason: 'shortage');
      expect(await db.watchLowStockCount().first, 1);
    },
  );

  test('STK-R23 a serial number listed twice is refused', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {
      'enable_serial_and_batch_no_for_item': true,
    });
    final phone = await newItem(db, 'PHONE', serial: true);
    await expectLater(
      move(
        db,
        receipt,
        phone,
        2,
        rate: 1,
        entries: [
          SbEntry(serialNo: 'X-1'),
          SbEntry(serialNo: 'X-1'),
        ],
      ),
      throwsA(
        isA<RefusedException>().having((e) => e.args, 'args', [
          1,
          LineProblem.duplicateSerial,
        ]),
      ),
    );
  });

  test('STK-R36 an old negative entry does not block later postings', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {'allow_negative_stock': true});
    final apple = await newItem(db, 'APPLE');
    await move(db, issue, apple, 2, day: '2026-11-01');
    await db.writeSingle(StockSettings.doctype, {
      'allow_negative_stock': false,
    });
    await move(db, receipt, apple, 5, rate: 10, day: '2026-11-02');
    expect((await binOf(db, apple)).actualQty, 3);
  });

  test('STK-R10 step 3 and STK-R13 lookups', () async {
    final db = await seeded();
    final apple = await newItem(db, 'APPLE');
    final nos = await idOf(db, 'uom', 'Nos');
    final standard = await idOf(db, 'price_list', 'Standard Selling');
    await db.saveItemPrice(
      ItemPriceCompanion.insert(
        itemId: apple,
        priceListId: standard,
        priceListRate: 12,
      ),
    );
    final wholesale = await db.savePriceList(
      PriceListCompanion.insert(name: 'Wholesale'),
    );
    expect(
      await db.priceFor(apple, nos, '2026-11-17', priceListId: wholesale),
      isNull,
    );
    await db.writeSingle(SellingSettings.doctype, {
      'fallback_to_default_price_list': true,
    });
    expect(
      (await db.priceFor(
        apple,
        nos,
        '2026-11-17',
        priceListId: wholesale,
      ))!.rate,
      12,
    );

    final template = await db.saveItemTaxTemplate(
      ItemTaxTemplateCompanion.insert(title: 'Zero'),
      const [],
    );
    final all = await idOf(db, 'item_group', 'All Item Groups');
    await (db.update(db.itemGroup)..where((g) => g.id.equals(all))).write(
      ItemGroupCompanion(itemTaxTemplateId: Value(template)),
    );
    expect(await db.itemTaxTemplateOf(apple, '2026-11-17'), template);
  });

  test('STK-R19 an expiring batch needs an expiry date', () async {
    final db = await seeded();
    await db.writeSingle(StockSettings.doctype, {
      'enable_serial_and_batch_no_for_item': true,
    });
    final milk = await newItem(db, 'MILK', batch: true);
    final it = await (db.select(
      db.item,
    )..where((i) => i.id.equals(milk))).getSingle();
    await db.saveItem(
      it.toCompanion(false).copyWith(hasExpiryDate: const Value(1)),
      noTables,
    );
    await expectLater(
      db.saveBatch(BatchesCompanion.insert(batchId: 'M1', itemId: milk)),
      refused(Refusal.expiryRequired),
    );
    await db.saveItem(
      it
          .toCompanion(false)
          .copyWith(
            hasExpiryDate: const Value(1),
            shelfLifeInDays: const Value(10),
          ),
      noTables,
    );
    await db.saveBatch(
      BatchesCompanion.insert(
        batchId: 'M2',
        itemId: milk,
        manufacturingDate: const Value('2026-11-01'),
      ),
    );
    final b = await (db.select(
      db.batches,
    )..where((x) => x.batchId.equals('M2'))).getSingle();
    expect(b.expiryDate, '2026-11-11');
  });
}

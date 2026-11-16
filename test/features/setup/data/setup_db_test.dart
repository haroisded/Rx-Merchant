import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/singles.dart';
import 'package:rx_merchant/core/naming/naming_series.dart';
import 'package:rx_merchant/features/setup/data/country_info.dart';
import 'package:rx_merchant/features/setup/data/refusal.dart';
import 'package:rx_merchant/features/setup/data/seed.dart';
import 'package:rx_merchant/features/setup/data/setup_queries.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';

final philippines = CountryInfo.fromJson({
  'name': 'Philippines',
  'code': 'PH',
  'currency': 'PHP',
  'symbol': '₱',
  'fraction': 'Centavo',
  'fraction_units': 100,
  'smallest_currency_fraction_value': 0.01,
  'date_format': 'mm-dd-yyyy',
  'number_format': '#,###.##',
});

/// A fresh in-memory database that has been through the wizard.
Future<AppDatabase> seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db.completeSetup(
    language: 'en',
    country: philippines,
    currencyOf: philippines,
    storeName: 'Rx Corner Store',
    abbr: 'RCS',
  );
  return db;
}

Matcher refused(Refusal r) =>
    throwsA(isA<RefusedException>().having((e) => e.reason, 'reason', r));

void main() {
  test('SET-A12 the wizard seeds every SET-R3 record in one go', () async {
    final db = await seeded();
    Future<List<String>> names(String table, [String column = 'name']) async =>
        [
          for (final r
              in await db
                  .customSelect('SELECT $column FROM $table ORDER BY rowid')
                  .get())
            r.read<String>(column),
        ];

    expect(await names('currency', 'code'), ['PHP']);
    expect(await names('warehouse'), ['All Warehouses', 'Stores']);
    expect(await names('item_group'), [
      'All Item Groups',
      'Products',
      'Services',
      'Consumable',
    ]);
    expect(await names('uom'), hasLength(13));
    expect(await names('price_list'), ['Standard Selling']);
    expect(await names('mode_of_payment'), [
      'Cash',
      'Credit Card',
      'Wire Transfer',
    ]);
    expect(await names('pos_profile'), ['Main Counter']);
    expect(
      await names('naming_series_option', 'pattern'),
      contains('ACC-SINV-.YYYY.-'),
    );
    expect(await names('letter_head'), ['Rx Corner Store']);

    final payment = await db.select(db.posProfilePayment).getSingle();
    expect((payment.isDefault, payment.allowInReturns), (1, 1));
    final dozen = await (db.select(
      db.uom,
    )..where((u) => u.name.equals('Dozen'))).getSingle();
    expect(dozen.mustBeWholeNumber, 1);

    final system = SystemSettings(await db.readSingle(SystemSettings.doctype));
    expect(system.setupComplete, isTrue);
    expect(system.dateFormat, 'mm-dd-yyyy');
    final store = StoreProfile(await db.readSingle(StoreProfile.doctype));
    expect(
      (store.storeName, store.abbr, store.defaultCurrency),
      ('Rx Corner Store', 'RCS', 'PHP'),
    );
    final stock = StockSettings(await db.readSingle(StockSettings.doctype));
    expect(
      (stock.itemGroup, stock.stockUom, stock.defaultWarehouse),
      ('Products', 'Nos', 'Stores'),
    );
  });

  test('a failed wizard writes nothing (SET-R1)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.priceList)
        .insert(PriceListCompanion.insert(name: 'Standard Selling'));
    await expectLater(
      db.completeSetup(
        language: 'en',
        country: philippines,
        currencyOf: philippines,
        storeName: 'X',
        abbr: 'X',
      ),
      throwsA(anything),
    );
    expect(await db.select(db.warehouse).get(), isEmpty);
    expect(
      SystemSettings(await db.readSingle(SystemSettings.doctype)).setupComplete,
      isFalse,
    );
  });

  test('SET-A13 a submitted document locks currency decisions', () async {
    final db = await seeded();
    expect(await db.anySubmittedDocument(), isFalse);
    await db.customStatement(
      "INSERT INTO stock_entry (purpose, posting_datetime, docstatus) "
      "VALUES ('Material Receipt', '2026-11-16 10:00:00', 1)",
    );
    expect(await db.anySubmittedDocument(), isTrue);
  });

  test(
    'SET-A14 the only enabled Price List cannot be disabled or deleted',
    () async {
      final db = await seeded();
      final list = await db.select(db.priceList).getSingle();
      await expectLater(
        db.savePriceList(
          list.toCompanion(true).copyWith(enabled: const Value(0)),
        ),
        refused(Refusal.lastEnabledPriceList),
      );
      expect((await db.select(db.priceList).getSingle()).enabled, 1);

      final second = await db.savePriceList(
        PriceListCompanion.insert(name: 'Promo'),
      );
      await db.savePriceList(
        list.toCompanion(true).copyWith(enabled: const Value(0)),
      );
      expect(second, greaterThan(list.id));
    },
  );

  test('SET-A15 a new default template clears the old default', () async {
    final db = await seeded();
    final vat = await db.saveTax(TaxCompanion.insert(name: 'VAT'));
    final rows = [
      TaxRow(chargeType: ChargeType.onNetTotal, taxId: vat, rate: 12),
    ];
    final a = await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion.insert(title: 'A', isDefault: const Value(1)),
      rows,
    );
    final b = await db.saveSalesTaxesTemplate(
      SalesTaxesTemplateCompanion.insert(title: 'B', isDefault: const Value(1)),
      rows,
    );
    final defaults = await (db.select(
      db.salesTaxesTemplate,
    )..where((t) => t.isDefault.equals(1))).get();
    expect(defaults.map((t) => t.id), [b]);
    expect(await db.salesTaxesTemplateRows(a), hasLength(1));
    expect((await db.salesTaxesTemplateRows(a)).single.rate, 12);
  });

  test('a used master can be disabled but not deleted (SET-R8)', () async {
    final db = await seeded();
    final cash = await (db.select(
      db.modeOfPayment,
    )..where((m) => m.name.equals('Cash'))).getSingle();
    await expectLater(
      db.deleteMaster(db.modeOfPayment, cash.id),
      refused(Refusal.referenced),
    );
    final wire = await (db.select(
      db.modeOfPayment,
    )..where((m) => m.name.equals('Wire Transfer'))).getSingle();
    await db.deleteMaster(db.modeOfPayment, wire.id);
    await expectLater(
      db.saveModeOfPayment(ModeOfPaymentCompanion.insert(name: 'Cash')),
      refused(Refusal.duplicateName),
    );
  });

  group('POS Profile (SET-R14)', () {
    late AppDatabase db;
    late PosProfileData main;
    late List<PosProfilePaymentCompanion> payments;
    setUp(() async {
      db = await seeded();
      main = await db.select(db.posProfile).getSingle();
      payments = [
        for (final p in await db.select(db.posProfilePayment).get())
          p.toCompanion(true),
      ];
    });

    test('SET-A16 editing during an open session is refused', () async {
      await db.customStatement(
        "INSERT INTO pos_opening_entry (docstatus, status, pos_profile_id, period_start_datetime) "
        "VALUES (1, 'Open', ${main.id}, '2026-11-16 08:00:00')",
      );
      await expectLater(
        db.savePosProfile(main.toCompanion(true), payments, {}),
        refused(Refusal.profileSessionOpen),
      );
      await expectLater(
        db.deletePosProfile(main.id),
        refused(Refusal.profileSessionOpen),
      );
    });

    test('a second profile can be made default; one default stays', () async {
      final second = await db.savePosProfile(
        PosProfileCompanion.insert(
          name: 'Back Counter',
          warehouseId: main.warehouseId,
          priceListId: main.priceListId,
          isDefault: const Value(1),
        ),
        [],
        {},
      );
      final defaults = await (db.select(
        db.posProfile,
      )..where((p) => p.isDefault.equals(1))).get();
      expect(defaults.map((p) => p.id), [second]);
      await expectLater(
        db.savePosProfile(
          (await (db.select(
                db.posProfile,
              )..where((p) => p.id.equals(second))).getSingle())
              .toCompanion(true)
              .copyWith(isDefault: const Value(0)),
          [],
          {},
        ),
        refused(Refusal.oneDefaultProfile),
      );
    });

    test(
      'group warehouse, payment defaults and disabled choices are refused',
      () async {
        final group = await (db.select(
          db.warehouse,
        )..where((w) => w.isGroup.equals(1))).getSingle();
        await expectLater(
          db.savePosProfile(
            main.toCompanion(true).copyWith(warehouseId: Value(group.id)),
            payments,
            {},
          ),
          refused(Refusal.groupWarehouse),
        );
        await expectLater(
          db.savePosProfile(main.toCompanion(true), [
            payments.single.copyWith(isDefault: const Value(0)),
          ], {}),
          refused(Refusal.oneDefaultPayment),
        );
        await db.saveModeOfPayment(
          (await db.select(db.modeOfPayment).get()).first
              .toCompanion(true)
              .copyWith(enabled: const Value(0)),
        );
        await expectLater(
          db.savePosProfile(main.toCompanion(true), payments, {}),
          refused(Refusal.disabledChoice),
        );
      },
    );
  });

  group('Naming Series (SET-R6, R7)', () {
    test('Update Series below a number already used is refused', () async {
      final db = await seeded();
      await db.customStatement(
        "INSERT INTO stock_entry (name, purpose, posting_datetime, docstatus) "
        "VALUES ('MAT-STE-2026-00007', 'Material Receipt', '2026-11-16 10:00:00', 1)",
      );
      expect(await db.highestUsedNumber('MAT-STE-2026-'), 7);
      expect(await db.highestUsedNumber('MAT_STE-2026-'), 0);
      await expectLater(
        db.updateSeries('MAT-STE-2026-', 6),
        throwsA(isA<RefusedException>().having((e) => e.detail, 'detail', '7')),
      );
      await db.updateSeries('MAT-STE-2026-', 10);
      // SET-B4: the next document takes the new current + 1.
      expect(
        await db.nextName('MAT-STE-.YYYY.-', DateTime(2026, 11, 16)),
        'MAT-STE-2026-00011',
      );
      final row = await db.select(db.series).getSingle();
      expect((row.name, row.current), ('MAT-STE-2026-', 11));
    });

    test('patterns are saved in order; the first is the default', () async {
      final db = await seeded();
      await db.saveNamingSeries('Sales Invoice', [
        'SINV-.YY.-',
        'ACC-SINV-.YYYY.-',
      ]);
      final rows =
          await (db.select(db.namingSeriesOption)
                ..where((o) => o.doctype.equals('Sales Invoice'))
                ..orderBy([(o) => OrderingTerm(expression: o.idx)]))
              .get();
      expect(rows.map((r) => r.pattern), ['SINV-.YY.-', 'ACC-SINV-.YYYY.-']);
      await expectLater(
        db.saveNamingSeries('Item', ['A-', 'A-']),
        refused(Refusal.duplicateName),
      );
    });
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/singles.dart';
import 'package:rx_merchant/features/setup/data/backup.dart';
import 'package:rx_merchant/features/setup/data/data_import_db.dart';
import 'package:rx_merchant/features/setup/data/refusal.dart';
import 'package:rx_merchant/features/setup/logic/data_import.dart';
import 'package:sqlite3/sqlite3.dart';

import 'setup_db_test.dart' show seeded;

void main() {
  group('Data Import (SET-R16)', () {
    test('200 items from a CSV, each with a price and a barcode', () async {
      final db = await seeded();
      final rows = [
        for (var i = 1; i <= 200; i++)
          {
            Col.itemCode: 'ITEM-$i',
            Col.itemGroup: 'Products',
            Col.stockUom: 'Nos',
            Col.standardRate: '${i * 2}',
            Col.barcode: 'BC$i',
          },
      ];
      expect(
        validateImport(
          ImportRecordType.item,
          ImportType.insert,
          rows,
          await db.importLookups(),
        ),
        isEmpty,
      );
      final log = await db.runImport(
        ImportRecordType.item,
        ImportType.insert,
        rows,
      );
      expect(log, hasLength(200));
      expect(log.first, (row: 2, name: 'ITEM-1', created: true));

      Future<int> count(String table) async =>
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n');
      expect(await count('item'), 200);
      expect(await count('item_price'), 200);
      expect(await count('item_barcode'), 200);
      final first = await (db.select(
        db.item,
      )..where((t) => t.itemCode.equals('ITEM-1'))).getSingle();
      expect(first.itemName, 'ITEM-1');

      // Export, then update one name through the same columns.
      final exported = await db.exportRows(ImportRecordType.item);
      expect(exported.first, [
        for (final c in ImportRecordType.item.columns) c.label,
      ]);
      expect(exported[1].take(4), ['ITEM-1', 'ITEM-1', 'Products', 'Nos']);
      expect(exported[1][6], '2');

      await db.runImport(ImportRecordType.item, ImportType.update, [
        {Col.itemCode: 'ITEM-1', Col.itemName: 'Paracetamol 500mg'},
      ]);
      final updated = await (db.select(
        db.item,
      )..where((t) => t.itemCode.equals('ITEM-1'))).getSingle();
      expect(
        (updated.itemName, updated.standardRate),
        ('Paracetamol 500mg', 2),
      );
    });

    test('SET-A17 an unknown Item Group blocks the whole file', () async {
      final db = await seeded();
      final rows = [
        {Col.itemCode: 'A', Col.itemGroup: 'Products', Col.stockUom: 'Nos'},
        {Col.itemCode: 'B', Col.itemGroup: 'Toys', Col.stockUom: 'Nos'},
      ];
      final problems = validateImport(
        ImportRecordType.item,
        ImportType.insert,
        rows,
        await db.importLookups(),
      );
      expect(problems.single.row, 3);
      expect(problems.single.column, Col.itemGroup);
      // The page only calls runImport when there are no problems.
      expect(await db.select(db.item).get(), isEmpty);
    });

    test('Item Price and Item Barcode import, then update', () async {
      final db = await seeded();
      await db.runImport(ImportRecordType.item, ImportType.insert, [
        {Col.itemCode: 'PEN', Col.itemGroup: 'Products', Col.stockUom: 'Nos'},
      ]);
      await db.runImport(ImportRecordType.itemPrice, ImportType.insert, [
        {
          Col.itemCode: 'PEN',
          Col.priceList: 'Standard Selling',
          Col.uom: 'Box',
          Col.rate: '120',
        },
      ]);
      await db.runImport(ImportRecordType.itemPrice, ImportType.update, [
        {
          Col.itemCode: 'PEN',
          Col.priceList: 'Standard Selling',
          Col.uom: 'Box',
          Col.rate: '125',
        },
      ]);
      expect((await db.select(db.itemPrice).getSingle()).priceListRate, 125);

      await db.runImport(ImportRecordType.itemBarcode, ImportType.insert, [
        {
          Col.itemCode: 'PEN',
          Col.barcode: '4006381333931',
          Col.barcodeType: 'EAN',
        },
      ]);
      final lookups = await db.importLookups();
      expect(lookups.barcodes, {'4006381333931': 'PEN'});
      expect(lookups.prices.values.single, [(from: null, upto: null)]);
      expect(await db.exportRows(ImportRecordType.itemBarcode), [
        [Col.itemCode, Col.barcode, Col.barcodeType, Col.uom],
        ['PEN', '4006381333931', 'EAN', ''],
      ]);
    });
  });

  group('Backup (SET-R17, R18)', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('rx_backup_');
      addTearDown(() => dir.deleteSync(recursive: true));
    });

    test(
      'SET-A18 five backups with Number of Backups = 3 keep the newest three',
      () async {
        final db = await seeded();
        final times = [
          for (var s = 0; s < 5; s++) DateTime(2026, 11, 16, 9, 0, s),
        ];
        for (final t in times) {
          await db.takeBackup(dir: dir, now: t);
        }
        final kept = listBackups(dir);
        expect(kept.map((b) => b.taken), times.reversed.take(3));
        expect(
          kept.first.file.path,
          endsWith('RCS-backup-20261116-090004.sqlite'),
        );
        expect(checkRestorable(kept.first.file.path, db.schemaVersion), isNull);

        // The copy holds the data.
        final copy = sqlite3.open(
          kept.first.file.path,
          mode: OpenMode.readOnly,
        );
        addTearDown(copy.close);
        expect(
          copy
              .select("SELECT value FROM singles WHERE field = 'store_name'")
              .single['value'],
          'Rx Corner Store',
        );
      },
    );

    test('SET-A19 a file that is not a POS backup is refused', () async {
      final text = File('${dir.path}/notes.sqlite')..writeAsStringSync('hello');
      expect(checkRestorable(text.path, 1), Refusal.notABackup);

      final other = sqlite3.open('${dir.path}/other.sqlite')
        ..execute('CREATE TABLE t (x)');
      other.close();
      expect(
        checkRestorable('${dir.path}/other.sqlite', 1),
        Refusal.notABackup,
      );

      final newer = sqlite3.open('${dir.path}/newer.sqlite')
        ..execute('CREATE TABLE singles (doctype, field, value)')
        ..userVersion = 2;
      newer.close();
      expect(
        checkRestorable('${dir.path}/newer.sqlite', 1),
        Refusal.backupTooNew,
      );
    });

    test(
      'restore onto a fresh install keeps no copy of the empty store',
      () async {
        final source = await (await seeded()).takeBackup(dir: dir);
        final backups = Directory('${dir.path}/safety')..createSync();
        final target = '${dir.path}/restored.sqlite';

        final fresh = AppDatabase(NativeDatabase.memory());
        addTearDown(fresh.close);
        await restoreDatabase(
          fresh,
          source.path,
          target: target,
          backupDir: backups,
        );
        expect(listBackups(backups), isEmpty);

        final restored = sqlite3.open(target, mode: OpenMode.readOnly);
        addTearDown(restored.close);
        expect(
          restored
              .select(
                "SELECT value FROM singles WHERE field = 'setup_complete'",
              )
              .single['value'],
          '1',
        );

        // A store that finished setup is backed up before it is replaced.
        await restoreDatabase(
          await seeded(),
          source.path,
          target: '${dir.path}/restored-2.sqlite',
          backupDir: backups,
        );
        expect(listBackups(backups), hasLength(1));
      },
    );

    test('number_of_backups below 1 still keeps the newest', () async {
      final db = await seeded();
      await db.writeSingle(SystemSettings.doctype, {'number_of_backups': 0});
      await db.takeBackup(dir: dir, now: DateTime(2026, 1, 1));
      await db.takeBackup(dir: dir, now: DateTime(2026, 1, 2));
      expect(listBackups(dir).single.taken, DateTime(2026, 1, 2));
    });
  });
}

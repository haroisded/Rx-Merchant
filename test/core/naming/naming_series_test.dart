import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/naming/naming_series.dart';

void main() {
  group('parseSeries', () {
    test('date parts come from the posting date; no hashes means 5 digits', () {
      expect(parseSeries('ACC-SINV-.YYYY.-', DateTime(2026, 5, 1)), (
        key: 'ACC-SINV-2026-',
        digits: 5,
        suffix: '',
      ));
    });

    test('a run of hashes is the counter and sets the digit count', () {
      expect(parseSeries('INV12.####', DateTime(2026)), (
        key: 'INV12',
        digits: 4,
        suffix: '',
      ));
    });

    test('hashes need no dot before them', () {
      expect(parseSeries('INV12####', DateTime(2026)), (
        key: 'INV12',
        digits: 4,
        suffix: '',
      ));
    });

    test('YY, MM and DD are two digits', () {
      expect(parseSeries('PRE-.YY.-.MM.-.DD.-', DateTime(2026, 3, 7)), (
        key: 'PRE-26-03-07-',
        digits: 5,
        suffix: '',
      ));
    });

    test('text after the counter is kept as a suffix', () {
      expect(parseSeries('A-.###.-X', DateTime(2026)), (
        key: 'A-',
        digits: 3,
        suffix: '-X',
      ));
    });
  });

  group('nextName', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    const pattern = 'ACC-SINV-.YYYY.-';
    final in2026 = DateTime(2026, 11, 15);

    test('SET-A5 counts up within a year', () async {
      expect(await db.nextName(pattern, in2026), 'ACC-SINV-2026-00001');
      expect(await db.nextName(pattern, in2026), 'ACC-SINV-2026-00002');
      expect(await db.nextName(pattern, in2026), 'ACC-SINV-2026-00003');
    });

    test('SET-A6 a new year starts a new series at 1', () async {
      await db.nextName(pattern, in2026);
      expect(
        await db.nextName(pattern, DateTime(2027, 1, 1)),
        'ACC-SINV-2027-00001',
      );
    });

    test('SET-A7 the hash count sets the padding', () async {
      expect(await db.nextName('INV12.####', in2026), 'INV120001');
    });

    test('a suffix follows the counter', () async {
      expect(await db.nextName('A-.###.-X', in2026), 'A-001-X');
    });

    test('a counter past its digit count grows, it is never cut', () async {
      await db.customStatement(
        'INSERT INTO series (name, "current") '
        "VALUES ('ACC-SINV-2026-', 99999)",
      );
      expect(await db.nextName(pattern, in2026), 'ACC-SINV-2026-100000');
    });

    test('a failed transaction does not burn a number', () async {
      await expectLater(
        db.transaction(() async {
          await db.nextName(pattern, in2026);
          throw StateError('submit failed');
        }),
        throwsStateError,
      );
      expect(await db.nextName(pattern, in2026), 'ACC-SINV-2026-00001');
    });
  });
}

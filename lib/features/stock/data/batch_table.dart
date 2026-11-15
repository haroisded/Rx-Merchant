import 'package:drift/drift.dart';

/// The `batch` table of 02-stock.md, section 3.
///
/// Declared in Dart rather than in `stock.drift` for one reason: a drift-file
/// table named `batch` generates a database getter called `batch`, which
/// collides with drift's own `GeneratedDatabase.batch()`. Here the getter is
/// `batches`; the SQL table is still `batch`, with the same columns.
@DataClassName('BatchRow')
class Batches extends Table {
  @override
  String get tableName => 'batch';

  IntColumn get id => integer()();
  TextColumn get createdAt => text().withDefault(
    const CustomExpression("(strftime('%Y-%m-%d %H:%M:%S','now','localtime'))"),
  )();
  TextColumn get modifiedAt => text().withDefault(
    const CustomExpression("(strftime('%Y-%m-%d %H:%M:%S','now','localtime'))"),
  )();
  TextColumn get batchId => text().unique()();
  IntColumn get itemId =>
      integer().customConstraint('NOT NULL REFERENCES item(id)')();
  TextColumn get manufacturingDate => text().nullable()();
  TextColumn get expiryDate => text().nullable()();
  IntColumn get disabled => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

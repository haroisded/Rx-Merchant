import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/stock/data/batch_table.dart';

part 'app_database.g.dart';

/// The app's only data store. Schema version 1 is every table in section 8 of
/// the overview plan; each table is defined once, in its feature's `.drift`
/// file.
@DriftDatabase(
  tables: [Batches],
  include: {
    '../../features/setup/data/setup.drift',
    '../../features/stock/data/stock.drift',
    '../../features/pos/data/pos.drift',
    '../../features/invoices/data/invoices.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'rx_merchant'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

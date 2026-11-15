import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'singles.dart';

/// The one database of the app. Tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// System Settings, re-emitted whenever a setting changes.
final systemSettingsProvider = StreamProvider<SystemSettings>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .watchSingle(SystemSettings.doctype)
      .map(SystemSettings.new),
);

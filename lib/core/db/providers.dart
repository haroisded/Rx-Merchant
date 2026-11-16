import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../numbers/formats.dart';
import 'app_database.dart';
import 'singles.dart';

/// The one database of the app. Tests override it with an in-memory database.
/// A restore invalidates it, which closes the old connection and opens the
/// restored file (SET-R18).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The stored fields of one settings page, re-emitted on every change.
final singleProvider = StreamProvider.family<Map<String, String>, String>(
  (ref, doctype) => ref.watch(appDatabaseProvider).watchSingle(doctype),
);

/// System Settings, re-emitted whenever a setting changes.
final systemSettingsProvider = StreamProvider<SystemSettings>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .watchSingle(SystemSettings.doctype)
      .map(SystemSettings.new),
);

/// The Currency record of the store's Default Currency.
final storeCurrencyProvider = StreamProvider<CurrencyData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final code = StoreProfile(
    ref.watch(singleProvider(StoreProfile.doctype)).value ?? const {},
  ).defaultCurrency;
  if (code == null) return Stream.value(null);
  return (db.select(
    db.currency,
  )..where((c) => c.code.equals(code))).watchSingleOrNull();
});

/// The formats in force; defaults while the settings load.
final formatsProvider = Provider<Formats>(
  (ref) => Formats(
    system: ref.watch(systemSettingsProvider).value ?? const SystemSettings({}),
    defaults: GlobalDefaults(
      ref.watch(singleProvider(GlobalDefaults.doctype)).value ?? const {},
    ),
    currency: ref.watch(storeCurrencyProvider).value,
  ),
);

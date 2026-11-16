import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import 'refusal.dart';
import 'setup_queries.dart';

/// The database file: drift_flutter's default for `driftDatabase(name:
/// 'rx_merchant')` (`AppDatabase`).
Future<String> databasePath() async =>
    '${(await getApplicationDocumentsDirectory()).path}/rx_merchant.sqlite';

/// The app's backup folder (SET-R17).
Future<Directory> backupDirectory() async =>
    Directory('${(await getApplicationDocumentsDirectory()).path}/backups')
        .create(recursive: true);

final _stamp = RegExp(r'-backup-(\d{8}-\d{6})\.sqlite$');
final _stampFormat = DateFormat('yyyyMMdd-HHmmss', 'en_US');

/// Backups in [dir], newest first, with the time in their name.
List<({File file, DateTime taken})> listBackups(Directory dir) {
  final out = [
    for (final f in dir.listSync().whereType<File>())
      if (_stamp.firstMatch(f.path) case final m?)
        (file: f, taken: DateTime.parse(m[1]!.replaceFirst('-', 'T'))),
  ];
  return out..sort((a, b) => b.taken.compareTo(a.taken));
}

extension Backups on AppDatabase {
  /// SET-R17: one consistent file made with `VACUUM INTO` while the app runs,
  /// named `{abbr}-backup-{YYYYMMDD-HHMMSS}.sqlite`. Only the newest Number of
  /// Backups files are kept.
  Future<File> takeBackup({Directory? dir, DateTime? now}) async {
    final folder = dir ?? await backupDirectory();
    final abbr = StoreProfile(await readSingle(StoreProfile.doctype)).abbr
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final keep = SystemSettings(await readSingle(SystemSettings.doctype))
        .numberOfBackups;
    final file = File(
      '${folder.path}/$abbr-backup-${_stampFormat.format(now ?? DateTime.now())}.sqlite',
    );
    // Two backups in the same second: the later one replaces the first.
    if (file.existsSync()) file.deleteSync();
    await customStatement('VACUUM INTO ?', [file.path]);
    for (final old in listBackups(folder).skip(keep < 1 ? 1 : keep)) {
      old.file.deleteSync();
    }
    return file;
  }
}

/// SET-R18 checks: [path] must be a SQLite database holding `singles`, from
/// a schema version no newer than [schemaVersion]. Null when it can be
/// restored.
Refusal? checkRestorable(String path, int schemaVersion) {
  try {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final hasSingles = db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'singles'",
          )
          .isNotEmpty;
      if (!hasSingles) return Refusal.notABackup;
      return db.userVersion > schemaVersion ? Refusal.backupTooNew : null;
    } finally {
      db.close();
    }
  } on SqliteException {
    return Refusal.notABackup;
  }
}

/// SET-R18: replaces the database with the backup at [source]. Refused while
/// a POS session is open or when [checkRestorable] fails; the current data is
/// backed up first, unless setup was never finished (a fresh install, restored
/// from the wizard), which holds nothing to keep. [db] is closed afterwards:
/// the caller reopens the database, which runs any pending migration.
/// [target] and [backupDir] default to the app's own; tests pass others.
Future<void> restoreDatabase(
  AppDatabase db,
  String source, {
  String? target,
  Directory? backupDir,
}) async {
  if (await db.sessionOpen()) {
    throw const RefusedException(Refusal.sessionOpen);
  }
  if (checkRestorable(source, db.schemaVersion) case final reason?) {
    throw RefusedException(reason);
  }
  if (SystemSettings(await db.readSingle(SystemSettings.doctype))
      .setupComplete) {
    await db.takeBackup(dir: backupDir);
  }
  target ??= await databasePath();
  await db.close();
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final stale = File('$target$suffix');
    if (stale.existsSync()) stale.deleteSync();
  }
  await File(source).copy(target);
}

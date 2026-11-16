// drift_flutter runs SQLite on a background isolate, which re-throws
// SQLite errors wrapped in DriftRemoteException.
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:sqlite3/sqlite3.dart';

/// Why a save, delete or restore was refused. The UI turns each into a
/// translated message (`refusalText`), so the data layer stays free of text.
enum Refusal {
  /// A record with this name already exists.
  duplicateName,

  /// Referenced by another record: it can be disabled but not deleted
  /// (00-overview 6.2, SET-R8).
  referenced,

  /// SET-R13: at least one Price List stays enabled.
  lastEnabledPriceList,

  /// SET-R7: [RefusedException.detail] is the highest number already used.
  seriesBelowUsed,

  /// SET-R14: the profile has an open POS Opening Entry.
  profileSessionOpen,

  /// SET-R14: a group warehouse holds no stock.
  groupWarehouse,

  /// SET-R14: with payment rows, exactly one is the default.
  oneDefaultPayment,

  /// SET-R14: exactly one enabled profile is the default.
  oneDefaultProfile,

  /// A disabled Mode of Payment, Price List or template was chosen.
  disabledChoice,

  /// SET-R18: the file is not a backup of this app.
  notABackup,

  /// SET-R18: the backup comes from a newer version of the app.
  backupTooNew,

  /// SET-R18: restore is refused while a POS session is open.
  sessionOpen,
}

class RefusedException implements Exception {
  const RefusedException(this.reason, [this.detail]);

  final Refusal reason;
  final String? detail;

  @override
  String toString() => 'RefusedException(${reason.name}, $detail)';
}

// SQLite extended result codes.
const _foreignKey = 787;
const _primaryKey = 1555;
const _unique = 2067;

/// Runs [write] and turns a broken UNIQUE or FOREIGN KEY constraint into a
/// [RefusedException]. The database enforces both, so no write needs its own
/// "is this name taken / is this record used" query.
Future<T> refuseOnConstraint<T>(Future<T> Function() write) async {
  try {
    return await write();
  } catch (e) {
    final code = switch (e) {
      SqliteException(:final extendedResultCode) => extendedResultCode,
      DriftRemoteException(
        remoteCause: SqliteException(:final extendedResultCode),
      ) =>
        extendedResultCode,
      _ => null,
    };
    if (code == _unique || code == _primaryKey) {
      throw const RefusedException(Refusal.duplicateName);
    }
    if (code == _foreignKey) throw const RefusedException(Refusal.referenced);
    rethrow;
  }
}

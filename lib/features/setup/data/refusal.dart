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

  /// SET-R13: the Default Price List of Selling Settings is the Cash
  /// Register's; it must exist and stay enabled.
  defaultPriceList,

  /// SET-R7: [RefusedException.detail] is the highest number already used.
  seriesBelowUsed,

  /// SET-R18: the file is not a backup of this app.
  notABackup,

  /// SET-R18: the backup comes from a newer version of the app.
  backupTooNew,

  /// SET-R18: restore is refused while a POS session is open.
  sessionOpen,

  // ---- Stock (02-stock.md) ----

  /// STK-R34, R35, R36: args are item code, warehouse, quantity available,
  /// quantity needed, posting date-time and voucher.
  negativeStock,

  /// STK-R34: no batch can go negative; args are batch, item code,
  /// warehouse, posting date-time and voucher.
  negativeBatch,

  /// STK-R37: [RefusedException.detail] is Stock Frozen Upto.
  stockFrozen,

  /// STK-R7: Maintain Stock, Has Batch No, Has Serial No, Valuation Method
  /// and Default Unit of Measure are read-only once the item has stock.
  frozenField,

  /// STK-R14: Has Variants cannot change once the item has variants or stock.
  hasVariantsLocked,

  /// STK-R14: a template has no price and is never transacted. Detail: code.
  template,

  /// STK-R9: detail is the unit used on a document.
  unitInUse,

  /// STK-R8: detail is the item that owns the barcode.
  barcodeTaken,

  /// STK-R8: detail is the barcode.
  badBarcode,

  /// STK-R10: another Item Price with the same key overlaps in validity.
  overlappingPrice,

  /// STK-R1: the Default Warehouse of Stock Settings must exist, stay
  /// enabled and not be a group.
  defaultWarehouse,

  /// STK-R1: a warehouse with ledger entries cannot become a group.
  warehouseHasLedger,

  /// A document line problem: args are the row and a `LineProblem`.
  lineProblem,

  /// STK-R20: detail is the item; a batch must be entered.
  batchRequired,

  /// STK-R25: detail is the item; serial numbers must be entered.
  serialRequired,

  /// STK-R27: detail is the item; not enough serials or batches to pick.
  notEnoughEntries,

  /// STK-R22: detail is the batch.
  expiredBatch,

  /// Detail is the batch, which does not exist for this item.
  batchNotFound,

  /// STK-R19: detail is the batch; its item has Has Expiry Date and no
  /// Shelf Life In Days to default the expiry from.
  expiryRequired,

  /// STK-R24: detail is the serial number, which is not Available here.
  serialNotAvailable,

  /// STK-R25: detail is a serial number that already exists in stock.
  serialExists,

  /// STK-R41: detail is a serial number received by this entry and moved
  /// or sold since.
  serialMovedSince,

  /// The document is not in the state the action needs.
  docstatus,
}

class RefusedException implements Exception {
  const RefusedException(this.reason, [this.detail, this.args = const []]);

  final Refusal reason;
  final String? detail;

  /// Values the message is built from, formatted by the UI.
  final List<Object?> args;

  @override
  String toString() => 'RefusedException(${reason.name}, $detail, $args)';
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

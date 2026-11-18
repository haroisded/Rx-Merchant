import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/backup.dart';
import '../../setup/data/refusal.dart';
import 'pos_db.dart';

// POS Closing Entry (03-cash-register POS-R20): the session's totals and the
// cash-drawer reconciliation, per Mode of Payment.

const posClosingType = 'POS Closing Entry';

/// SQL for the Mode of Payment that sale `s`'s change comes out of: its
/// first Cash-type payment (D-43). Null when it has none.
const changeModeOf =
    '(SELECT p.mode_of_payment_id FROM sales_invoice_payment p '
    'JOIN mode_of_payment m ON m.id = p.mode_of_payment_id '
    "WHERE p.sales_invoice_id = s.id AND m.type = 'Cash' "
    'ORDER BY p.id LIMIT 1)';

/// One Payment Reconciliation row before the owner counts the drawer.
typedef ReconciliationRow = ({
  int modeId,
  String mode,
  double opening,
  double expected,
});

/// The closing entry of an open session, as it would be submitted now.
typedef ClosingDraft = ({
  PosOpeningEntryData session,
  int invoices,
  double totalQuantity,
  double netTotal,
  double totalTaxes,
  double grandTotal,
  List<ReconciliationRow> rows,
  int heldOrders,
});

extension PosClosingDb on AppDatabase {
  /// POS-R20 for the open session: its submitted sales and returns, their
  /// totals, and per payment mode on the opening entry or used in the
  /// session: Expected = opening + payments received − change given (change
  /// comes out of each sale's first Cash-type payment).
  Future<ClosingDraft> closingDraft() async {
    final session = await openSession();
    if (session == null) throw const RefusedException(Refusal.noOpenSession);
    final shown = await formats();
    final system = shown.system;
    double f(num v) => flt(v, system.currencyPrecision, shown.rounding);
    final totals = await customSelect(
      'SELECT COUNT(*) AS n, COALESCE(SUM(total_qty), 0) AS qty, '
      'COALESCE(SUM(net_total), 0) AS net, '
      'COALESCE(SUM(total_taxes_and_charges), 0) AS taxes, '
      'COALESCE(SUM(grand_total), 0) AS grand FROM sales_invoice '
      'WHERE pos_opening_entry_id = ? AND docstatus = 1',
      variables: [Variable(session.id)],
    ).getSingle();
    final opening = {
      for (final d in await (select(
        posOpeningEntryDetail,
      )..where((d) => d.posOpeningEntryId.equals(session.id))).get())
        d.modeOfPaymentId: d.openingAmount,
    };
    final received = <int, double>{};
    for (final r in await customSelect(
      'SELECT p.mode_of_payment_id AS mode, SUM(p.amount) AS amount '
      'FROM sales_invoice_payment p JOIN sales_invoice s '
      'ON s.id = p.sales_invoice_id WHERE s.pos_opening_entry_id = ? '
      'AND s.docstatus = 1 GROUP BY p.mode_of_payment_id',
      variables: [Variable(session.id)],
    ).get()) {
      received[r.read<int>('mode')] = r.read<double>('amount');
    }
    final change = <int, double>{};
    for (final r in await customSelect(
      'SELECT $changeModeOf AS mode, s.change_amount AS change '
      'FROM sales_invoice s WHERE s.pos_opening_entry_id = ? '
      'AND s.docstatus = 1 AND s.change_amount != 0',
      variables: [Variable(session.id)],
    ).get()) {
      final mode = r.read<int?>('mode');
      if (mode == null) continue;
      change[mode] = (change[mode] ?? 0) + r.read<double>('change');
    }
    final names = {
      for (final m in await select(modeOfPayment).get()) m.id: m.name,
    };
    final modes = {...opening.keys, ...received.keys}.toList()..sort();
    return (
      session: session,
      invoices: totals.read<int>('n'),
      totalQuantity: flt(
        totals.read<double>('qty'),
        system.floatPrecision,
        shown.rounding,
      ),
      netTotal: f(totals.read<double>('net')),
      totalTaxes: f(totals.read<double>('taxes')),
      grandTotal: f(totals.read<double>('grand')),
      rows: [
        for (final m in modes)
          (
            modeId: m,
            mode: names[m] ?? '',
            opening: opening[m] ?? 0,
            expected: f(
              (opening[m] ?? 0) + (received[m] ?? 0) - (change[m] ?? 0),
            ),
          ),
      ],
      heldOrders: await _heldOrders(),
    );
  }

  Future<int> _heldOrders() async => (await customSelect(
    'SELECT COUNT(*) AS n FROM sales_invoice WHERE docstatus = 0',
  ).getSingle()).read<int>('n');

  /// Submits the closing entry with the owner's counted [closing] amounts
  /// per mode: the session becomes Closed. Then a backup is taken (SET-R17)
  /// into [backupDir] (the app's backup folder by default); a failed backup
  /// is returned, not thrown, because the closing stands.
  Future<({int id, Object? backupError})> submitClosing(
    Map<int, double> closing, {
    String? remarks,
    Directory? backupDir,
  }) async {
    final id = await transaction(() async {
      final d = await closingDraft();
      final fm = await formats();
      final now = DateTime.now();
      final at = toStorage(now);
      final id = await into(posClosingEntry).insert(
        PosClosingEntryCompanion.insert(
          name: Value(await nextName(await defaultSeries(posClosingType), now)),
          docstatus: const Value(1),
          posOpeningEntryId: d.session.id,
          periodStartDatetime: d.session.periodStartDatetime,
          periodEndDatetime: at,
          postingDatetime: at,
          totalQuantity: Value(d.totalQuantity),
          netTotal: Value(d.netTotal),
          totalTaxesAndCharges: Value(d.totalTaxes),
          grandTotal: Value(d.grandTotal),
          remarks: Value(remarks),
        ),
      );
      for (final r in d.rows) {
        final counted = closing[r.modeId] ?? 0;
        await into(posClosingEntryDetail).insert(
          PosClosingEntryDetailCompanion.insert(
            posClosingEntryId: id,
            modeOfPaymentId: r.modeId,
            openingAmount: Value(r.opening),
            expectedAmount: Value(r.expected),
            closingAmount: Value(counted),
            difference: Value(
              flt(
                counted - r.expected,
                fm.system.currencyPrecision,
                fm.rounding,
              ),
            ),
          ),
        );
      }
      await (update(
        posOpeningEntry,
      )..where((s) => s.id.equals(d.session.id))).write(
        PosOpeningEntryCompanion(
          status: const Value('Closed'),
          periodEndDatetime: Value(at),
          modifiedAt: Value(at),
        ),
      );
      return id;
    });
    try {
      await takeBackup(dir: backupDir);
      return (id: id, backupError: null);
    } catch (e) {
      return (id: id, backupError: e);
    }
  }

  /// The latest submitted closing entry while no newer session exists: the
  /// one that can still be cancelled.
  Future<PosClosingEntryData?> cancellableClosing() async {
    final last =
        await (select(posClosingEntry)
              ..where((c) => c.docstatus.equals(1))
              ..orderBy([(c) => OrderingTerm.desc(c.id)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return null;
    final newer = await (select(
      posOpeningEntry,
    )..where((s) => s.id.isBiggerThanValue(last.posOpeningEntryId))).get();
    return newer.isEmpty ? last : null;
  }

  /// POS-R20: cancels the latest closing entry, which reopens its session.
  Future<void> cancelLastClosing() => transaction(() async {
    final last = await cancellableClosing();
    if (last == null || await openSession() != null) {
      throw const RefusedException(Refusal.notLatestClosing);
    }
    final at = toStorage(DateTime.now());
    await (update(posClosingEntry)..where((c) => c.id.equals(last.id))).write(
      PosClosingEntryCompanion(
        docstatus: const Value(2),
        modifiedAt: Value(at),
      ),
    );
    await (update(
      posOpeningEntry,
    )..where((s) => s.id.equals(last.posOpeningEntryId))).write(
      PosOpeningEntryCompanion(
        status: const Value('Open'),
        periodEndDatetime: const Value(null),
        modifiedAt: Value(at),
      ),
    );
  });
}

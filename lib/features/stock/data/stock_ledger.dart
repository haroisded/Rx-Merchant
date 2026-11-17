import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/refusal.dart';
import '../logic/valuation.dart';

/// One item in one warehouse: the unit the ledger is kept and replayed in.
typedef Chain = (int itemId, int warehouseId);

/// A posting time after every entry: nothing is checked from there.
const _never = '9999-12-31 23:59:59';

/// Each chain with the earliest posting time a change touched; entries from
/// then on must not go negative (STK-R36).
typedef Changes = Map<Chain, String>;

void _touch(Changes changes, Chain chain, String from) {
  final was = changes[chain];
  if (was == null || from.compareTo(was) < 0) changes[chain] = from;
}

/// The stock ledger engine (STK-R28 to R37). Documents insert their Stock
/// Ledger Entries with `actual_qty` (and `incoming_rate` for receipts); the
/// engine fills in every running column, refuses negative stock, and keeps
/// `bin` in step. Call it inside the document's Submit or Cancel transaction.
extension StockLedger on AppDatabase {
  /// Writes [rows] and recomputes their chains.
  Future<void> postLedger(List<StockLedgerEntryCompanion> rows) async {
    final changes = <Chain, String>{};
    for (final r in rows) {
      await into(stockLedgerEntry).insert(r);
      _touch(changes, (
        r.itemId.value,
        r.warehouseId.value,
      ), r.postingDatetime.value);
    }
    await repostChains(changes);
  }

  /// Marks the ledger entries of a voucher cancelled and recomputes their
  /// chains (STK-R36, R41).
  Future<void> cancelLedger(String voucherType, int voucherId) async {
    final rows =
        await (select(stockLedgerEntry)..where(
              (s) =>
                  s.voucherType.equals(voucherType) &
                  s.voucherId.equals(voucherId) &
                  s.isCancelled.equals(0),
            ))
            .get();
    await (update(stockLedgerEntry)..where(
          (s) =>
              s.voucherType.equals(voucherType) & s.voucherId.equals(voucherId),
        ))
        .write(const StockLedgerEntryCompanion(isCancelled: Value(1)));
    final changes = <Chain, String>{};
    for (final r in rows) {
      _touch(changes, (r.itemId, r.warehouseId), r.postingDatetime);
    }
    await repostChains(changes);
  }

  /// STK-R36: recomputes each chain from its first entry, refusing a
  /// negative balance only from the changed point on, so an old negative
  /// entry does not block what follows. A transfer's incoming rate is the
  /// rate it went out at, so recosting a source chain puts the target chain
  /// back on the list (its quantities do not change, so nothing is checked).
  // ponytail: replays the whole chain, linear in an item's history; start
  // from the changed entry if an item ever has hundreds of thousands.
  Future<void> repostChains(Changes changes) async {
    final stock = StockSettings(await readSingle(StockSettings.doctype));
    final system = SystemSettings(await readSingle(SystemSettings.doctype));
    final pending = {...changes};
    final recosted = <int>{};
    var passes = 0;
    while (pending.isNotEmpty) {
      if (++passes > 10000) throw StateError('Stock repost did not settle');
      final MapEntry(key: chain, value: from) = pending.entries.first;
      pending.remove(chain);
      for (final next in await _repost(chain, from, stock, system, recosted)) {
        _touch(pending, next, _never);
      }
    }
    for (final id in recosted) {
      await syncStockEntryValues(id);
    }
  }

  /// Replays one chain; returns the chains whose transfer-in rate changed.
  /// Stock Entries whose outgoing cost changed are added to [recosted].
  Future<Set<Chain>> _repost(
    Chain chain,
    String checkFrom,
    StockSettings stock,
    SystemSettings system,
    Set<int> recosted,
  ) async {
    final (itemId, warehouseId) = chain;
    final it = await (select(
      item,
    )..where((i) => i.id.equals(itemId))).getSingle();
    final method = it.hasSerialNo == 1
        ? ValuationMethod.serial
        : ValuationMethod.fromSetting(
            it.valuationMethod ?? stock.valuationMethod,
          );
    // STK-R34: batch and serial items never go negative.
    final strict = it.hasBatchNo == 1 || it.hasSerialNo == 1;
    final allowNegative =
        !strict && (stock.allowNegativeStock || it.allowNegativeStock == 1);
    final rounding = RoundingMethod.fromSetting(system.roundingMethod);
    final precision = system.currencyPrecision;
    final b = StockBalance(method, precision: precision, rounding: rounding);
    final batchQty = <int, double>{};
    // Stock Entry lines that went out here: (detail, batch) → rate.
    final outRates = <(int, int?), double>{};

    final rows =
        await (select(stockLedgerEntry)
              ..where(
                (s) =>
                    s.itemId.equals(itemId) &
                    s.warehouseId.equals(warehouseId) &
                    s.isCancelled.equals(0),
              )
              ..orderBy([
                (s) => OrderingTerm(expression: s.postingDatetime),
                (s) => OrderingTerm(expression: s.id),
              ]))
            .get();

    for (final r in rows) {
      final qtyBefore = b.qty;
      final valueBefore = b.value;
      var actual = r.actualQty;
      if (r.voucherType == 'Stock Reconciliation') {
        // The counted quantity and rate are kept on the entry itself.
        b.reset(r.qtyAfterTransaction, r.incomingRate);
        actual = flt(b.qty - qtyBefore, ratePrecision);
      } else if (actual > 0) {
        b.receive(
          actual,
          r.incomingRate,
          serialValue: method == ValuationMethod.serial
              ? await _serialValue(r)
              : null,
        );
      } else {
        b.issue(
          -actual,
          serialValue: method == ValuationMethod.serial
              ? await _serialValue(r)
              : null,
          fallbackRate: it.valuationRate,
        );
      }
      final checked = r.postingDatetime.compareTo(checkFrom) >= 0;
      if (checked && b.qty < -1e-9 && !allowNegative) {
        throw RefusedException(Refusal.negativeStock, null, [
          it.itemCode,
          await _warehouseName(warehouseId),
          qtyBefore,
          -actual,
          r.postingDatetime,
          r.voucherNo,
        ]);
      }
      if (r.batchId case final batch?) {
        final left = flt((batchQty[batch] ?? 0) + actual, ratePrecision);
        batchQty[batch] = left;
        if (checked && left < -1e-9) {
          final name = await (select(batches)..where((x) => x.id.equals(batch)))
              .map((x) => x.batchId)
              .getSingle();
          throw RefusedException(Refusal.negativeBatch, null, [
            name,
            it.itemCode,
            await _warehouseName(warehouseId),
            r.postingDatetime,
            r.voucherNo,
          ]);
        }
      }
      final difference = flt(b.value - valueBefore, precision, rounding);
      final outgoing = actual < 0
          ? flt(-difference / -actual, ratePrecision, rounding)
          : 0.0;
      if (actual < 0 && r.voucherType == 'Stock Entry') {
        outRates[(r.voucherDetailId, r.batchId)] = outgoing;
        if (difference != r.stockValueDifference) recosted.add(r.voucherId);
      }
      if (actual != r.actualQty ||
          b.qty != r.qtyAfterTransaction ||
          b.rate != r.valuationRate ||
          b.value != r.stockValue ||
          difference != r.stockValueDifference ||
          outgoing != r.outgoingRate) {
        await (update(stockLedgerEntry)..where((s) => s.id.equals(r.id))).write(
          StockLedgerEntryCompanion(
            actualQty: Value(actual),
            qtyAfterTransaction: Value(b.qty),
            valuationRate: Value(b.rate),
            stockValue: Value(b.value),
            stockValueDifference: Value(difference),
            outgoingRate: Value(outgoing),
          ),
        );
      }
    }

    await into(bin).insertOnConflictUpdate(
      BinCompanion.insert(
        itemId: itemId,
        warehouseId: warehouseId,
        actualQty: Value(b.qty),
        valuationRate: Value(b.rate),
        stockValue: Value(b.value),
        stockQueue: Value(jsonEncode(b.queue)),
      ),
    );
    return _passOnTransferRates(outRates);
  }

  /// A transfer's incoming rate is its outgoing rate plus its share of the
  /// additional costs (STK-R33, R39). Returns the target chains it changed.
  Future<Set<Chain>> _passOnTransferRates(
    Map<(int, int?), double> outRates,
  ) async {
    if (outRates.isEmpty) return const {};
    final details = {for (final (d, _) in outRates.keys) d};
    final ins = await customSelect(
      'SELECT s.id, s.item_id, s.warehouse_id, s.voucher_detail_id, '
      's.batch_id, s.incoming_rate, i.additional_cost, i.transfer_qty '
      'FROM stock_ledger_entry s JOIN stock_entry_item i '
      'ON i.id = s.voucher_detail_id '
      "WHERE s.voucher_type = 'Stock Entry' AND s.actual_qty > 0 "
      'AND s.is_cancelled = 0 '
      'AND s.voucher_detail_id IN (${details.join(',')})',
    ).get();
    final changed = <Chain>{};
    for (final r in ins) {
      final out =
          outRates[(
            r.read<int>('voucher_detail_id'),
            r.read<int?>('batch_id'),
          )];
      if (out == null) continue;
      final rate = flt(
        out +
            r.read<double>('additional_cost') / r.read<double>('transfer_qty'),
        ratePrecision,
      );
      if (rate == r.read<double>('incoming_rate')) continue;
      await (update(stockLedgerEntry)
            ..where((s) => s.id.equals(r.read<int>('id'))))
          .write(StockLedgerEntryCompanion(incomingRate: Value(rate)));
      changed.add((r.read<int>('item_id'), r.read<int>('warehouse_id')));
    }
    return changed;
  }

  /// STK-R32: the units on a serialised line, each at its own rate.
  Future<double> _serialValue(StockLedgerEntryData r) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(incoming_rate * qty), 0) AS v '
      'FROM serial_and_batch_entry WHERE voucher_type = ? '
      'AND voucher_detail_id = ? AND serial_no_id IS NOT NULL '
      'AND (?3 IS NULL OR batch_id = ?3)',
      variables: [
        Variable(r.voucherType),
        Variable(r.voucherDetailId),
        Variable(r.batchId),
      ],
    ).getSingle();
    return row.read<double>('v');
  }

  Future<String> _warehouseName(int id) => (select(
    warehouse,
  )..where((w) => w.id.equals(id))).map((w) => w.name).getSingle();

  /// Rewrites a submitted Stock Entry's outgoing rates and totals from its
  /// ledger entries, after a submit or a recost (STK-A20).
  Future<void> syncStockEntryValues(int entryId) async {
    final entry = await (select(
      stockEntry,
    )..where((e) => e.id.equals(entryId))).getSingle();
    if (entry.docstatus != 1) return;
    final precision = SystemSettings(await readSingle(SystemSettings.doctype))
        .currencyPrecision;
    final lines = await (select(
      stockEntryItem,
    )..where((i) => i.stockEntryId.equals(entryId))).get();
    var outgoing = 0.0, incoming = 0.0, total = 0.0;
    for (final l in lines) {
      var line = l;
      if (l.sWarehouseId != null) {
        final cost = flt(
          (await customSelect(
            'SELECT COALESCE(SUM(-stock_value_difference), 0) AS v '
            "FROM stock_ledger_entry WHERE voucher_type = 'Stock Entry' "
            'AND voucher_detail_id = ? AND actual_qty < 0 '
            'AND is_cancelled = 0',
            variables: [Variable(l.id)],
          ).getSingle()).read<double>('v'),
          precision,
        );
        final rate = flt(cost / l.transferQty, ratePrecision);
        line = l.copyWith(
          basicRate: rate,
          basicAmount: cost,
          valuationRate: flt(
            rate + l.additionalCost / l.transferQty,
            ratePrecision,
          ),
          amount: flt(cost + l.additionalCost, precision),
        );
        if (line != l) await update(stockEntryItem).replace(line);
        outgoing += line.basicAmount;
      }
      if (line.tWarehouseId != null) incoming += line.amount;
      total += line.amount;
    }
    final costs = await (select(
      stockEntryAdditionalCost,
    )..where((c) => c.stockEntryId.equals(entryId))).get();
    await (update(stockEntry)..where((e) => e.id.equals(entryId))).write(
      StockEntryCompanion(
        totalOutgoingValue: Value(flt(outgoing, precision)),
        totalIncomingValue: Value(flt(incoming, precision)),
        totalAdditionalCosts: Value(
          flt(costs.fold(0.0, (s, c) => s + c.amount), precision),
        ),
        totalAmount: Value(flt(total, precision)),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
    );
  }

  /// The balance of a chain as it stood at [posting], counting entries at
  /// that very moment (STK-R35, R42).
  Future<({double qty, double rate, double value})> balanceAt(
    int itemId,
    int warehouseId,
    String posting,
  ) async {
    final last =
        await (select(stockLedgerEntry)
              ..where(
                (s) =>
                    s.itemId.equals(itemId) &
                    s.warehouseId.equals(warehouseId) &
                    s.isCancelled.equals(0) &
                    s.postingDatetime.isSmallerOrEqualValue(posting),
              )
              ..orderBy([
                (s) => OrderingTerm.desc(s.postingDatetime),
                (s) => OrderingTerm.desc(s.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return (
      qty: last?.qtyAfterTransaction ?? 0,
      rate: last?.valuationRate ?? 0,
      value: last?.stockValue ?? 0,
    );
  }

  /// STK-R37: nothing on or before Stock Frozen Upto is submitted or
  /// cancelled.
  Future<void> checkNotFrozen(String posting) async {
    final upto = StockSettings(await readSingle(StockSettings.doctype))
        .stockFrozenUpto;
    if (upto != null &&
        upto.isNotEmpty &&
        posting.substring(0, 10).compareTo(upto) <= 0) {
      throw RefusedException(Refusal.stockFrozen, upto);
    }
  }

  /// STK-A26: recomputes every chain's `bin` from the ledger.
  Future<void> rebuildBins() async {
    final chains = await customSelect(
      'SELECT DISTINCT item_id, warehouse_id FROM stock_ledger_entry',
    ).get();
    await delete(bin).go();
    await repostChains({
      for (final c in chains)
        (c.read<int>('item_id'), c.read<int>('warehouse_id')): _never,
    });
  }
}

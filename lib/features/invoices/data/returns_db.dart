import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../pos/data/pos_db.dart';
import '../../pos/logic/sale.dart';
import '../../pos/logic/totals.dart';
import '../../setup/data/refusal.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/logic/tax_template.dart';
import '../../stock/data/stock_entry_db.dart';
import '../../stock/data/stock_ledger.dart';
import '../../stock/logic/stock_documents.dart';
import '../../stock/logic/stock_rules.dart';
import '../logic/returns.dart';

// Return / Credit Note and Cancel (05-invoices-and-receipts INV-R5 to R11).

const salesReturnType = 'Sales Invoice Return';

/// A return being made: the draft and what it was made from.
typedef ReturnDraft = ({
  Sale sale,
  ReturnBasis basis,

  /// Original line id -> quantity still returnable, in the line's unit.
  Map<int, double> left,

  /// Original line id -> serial numbers sold on it and not yet returned.
  Map<int, List<String>> serials,

  /// Original line id -> batches (stock units) still returnable.
  Map<int, List<SbEntry>> batches,

  /// Original line id -> its rate.
  Map<int, double> rates,
});

extension ReturnsDb on AppDatabase {
  /// INV-R5: a return of everything still returnable from sale [id]: each
  /// line at the original's rate, unit, discount, item tax and cost, the
  /// original's tax rows, Update Stock on into the original's warehouse.
  Future<ReturnDraft> returnDraft(int id) async {
    final h = await (select(
      salesInvoice,
    )..where((s) => s.id.equals(id))).getSingle();
    if (h.docstatus != 1 || h.isReturn == 1) {
      throw const RefusedException(Refusal.returnOriginal);
    }
    final f = await formats();
    final floats = f.system.floatPrecision;
    final taxes = await taxRowsOf(id);
    final sale = Sale(
      warehouseId: h.setWarehouseId,
      priceListId: h.priceListId,
      taxesTemplateId: h.taxesTemplateId,
      taxes: taxes,
      discountOnNetTotal: h.applyDiscountOn == 'Net Total',
      letterHeadId: h.letterHeadId,
      tcId: h.tcId,
      terms: h.terms,
    )..returnAgainstId = id;
    final left = await _returnable(id, floats);
    final serials = <int, List<String>>{};
    final batches = <int, List<SbEntry>>{};
    final rates = <int, double>{};
    for (final r
        in await (select(salesInvoiceItem)
              ..where((l) => l.salesInvoiceId.equals(id))
              ..orderBy([(l) => OrderingTerm(expression: l.idx)]))
            .get()) {
      rates[r.id] = r.rate;
      final qty = left[r.id] ?? 0;
      if (qty <= 0) continue;
      final (lineSerials, lineBatches) = await _stillOut(r.id);
      serials[r.id] = lineSerials;
      batches[r.id] = lineBatches;
      final stock = stockQty(qty, r.conversionFactor, floats);
      sale.lines.add(
        SaleLine(
            itemId: r.itemId,
            itemName: r.itemName,
            uomId: r.uomId,
            factor: r.conversionFactor,
            qty: -qty,
            priceListRate: r.priceListRate,
            discountPercentage: r.discountPercentage,
            discountAmount: r.discountAmount,
            rate: r.rate,
            itemTaxTemplateId: r.itemTaxTemplateId,
            itemTax: itemTaxFromJson(r.itemTaxRate),
            entries: lineSerials.isNotEmpty
                ? [for (final s in lineSerials) SbEntry(serialNo: s)]
                : takeBatches(lineBatches, stock),
          )
          ..againstLineId = r.id
          ..incomingRate = r.incomingRate,
      );
    }
    final basis = (
      total: h.total,
      discountPercentage: h.additionalDiscountPercentage,
      discountAmount: h.discountAmount,
      actual: [
        for (final t in taxes)
          t.chargeType == ChargeType.actual ? t.taxAmount : 0.0,
      ],
    );
    scaleReturn(
      sale,
      basis,
      precision: f.system.currencyPrecision,
      method: f.rounding,
    );
    return (
      sale: sale,
      basis: basis,
      left: left,
      serials: serials,
      batches: batches,
      rates: rates,
    );
  }

  /// Original line id -> quantity sold less what submitted returns took.
  Future<Map<int, double>> _returnable(int id, int floats) async => {
    for (final r in await customSelect(
      'SELECT o.id, o.qty + COALESCE((SELECT SUM(r.qty) FROM sales_invoice_item r '
      'JOIN sales_invoice s ON s.id = r.sales_invoice_id '
      'WHERE r.sales_invoice_item_id = o.id AND s.docstatus = 1), 0) AS left '
      'FROM sales_invoice_item o WHERE o.sales_invoice_id = ?',
      variables: [Variable(id)],
    ).get())
      r.read<int>('id'): flt(r.read<double>('left'), floats),
  };

  /// The serial numbers and batches sold on original line [lineId] that
  /// submitted returns have not brought back.
  Future<(List<String>, List<SbEntry>)> _stillOut(int lineId) async {
    final sold = await entriesOf(salesInvoiceType, lineId);
    final back = <SbEntry>[];
    for (final r in await customSelect(
      'SELECT r.id FROM sales_invoice_item r JOIN sales_invoice s '
      'ON s.id = r.sales_invoice_id WHERE r.sales_invoice_item_id = ? '
      'AND s.docstatus = 1',
      variables: [Variable(lineId)],
    ).get()) {
      back.addAll(await entriesOf(salesInvoiceType, r.read<int>('id')));
    }
    final returned = {for (final e in back) e.serialNo};
    final serials = [
      for (final e in sold)
        if (e.serialNo case final s? when !returned.contains(s)) s,
    ];
    final batches = <String, double>{};
    for (final e in sold) {
      if (e.serialNo != null || e.batchNo == null) continue;
      batches[e.batchNo!] = (batches[e.batchNo!] ?? 0) + e.qty;
    }
    for (final e in back) {
      if (e.serialNo != null || e.batchNo == null) continue;
      batches[e.batchNo!] = (batches[e.batchNo!] ?? 0) - e.qty;
    }
    return (
      serials,
      [
        for (final MapEntry(:key, :value) in batches.entries)
          if (value > 1e-9) SbEntry(batchNo: key, qty: value),
      ],
    );
  }

  /// INV-R8: every check a return must pass, all reported together.
  Future<List<RefusedException>> returnProblems(Sale ret) async {
    final out = <RefusedException>[];
    final id = ret.returnAgainstId!;
    if (await openSession() == null) {
      out.add(const RefusedException(Refusal.noOpenSession));
    }
    final h = await (select(
      salesInvoice,
    )..where((s) => s.id.equals(id))).getSingle();
    if (h.docstatus != 1 || h.isReturn == 1) {
      out.add(const RefusedException(Refusal.returnOriginal));
    }
    if (ret.lines.isEmpty) {
      out.add(const RefusedException(Refusal.nothingToReturn));
    }
    final f = await formats();
    final floats = f.system.floatPrecision;
    final left = await _returnable(id, floats);
    final facts = await itemFacts(ret.lines.map((l) => l.itemId));
    for (final (i, l) in ret.lines.indexed) {
      final row = i + 1;
      final original = l.againstLineId == null
          ? null
          : await (select(salesInvoiceItem)..where(
                  (x) =>
                      x.id.equals(l.againstLineId!) &
                      x.salesInvoiceId.equals(id),
                ))
                .getSingleOrNull();
      final can = left[l.againstLineId] ?? 0;
      if (original == null || l.qty >= 0 || -l.qty > can + 1e-9) {
        out.add(RefusedException(Refusal.returnTooMuch, null, [row, can]));
        continue;
      }
      // INV-R6: the original rate; lower only for a price-only credit.
      if (ret.updateStock ? l.rate != original.rate : l.rate > original.rate) {
        out.add(RefusedException(Refusal.returnRate, null, [row]));
      }
      final fact = facts[l.itemId];
      if (!ret.updateStock || fact == null || !fact.stockItem) continue;
      if (!(fact.hasSerial || fact.hasBatch)) continue;
      final stock = -stockQty(l.qty, l.factor, floats);
      final (serials, batches) = await _stillOut(original.id);
      final ok = fact.hasSerial
          ? l.entries.length == stock &&
                l.entries.every((e) => serials.contains(e.serialNo)) &&
                {for (final e in l.entries) e.serialNo}.length ==
                    l.entries.length
          : _batchesFit(l.entries, batches, stock);
      if (!ok) out.add(RefusedException(Refusal.returnEntries, null, [row]));
    }
    final t = totalsOf(ret, saleSettingsOf(f));
    final paid = flt(
      ret.payments.values.fold(0.0, (s, a) => s + a),
      f.system.currencyPrecision,
      f.rounding,
    );
    if (flt(paid - t.toPay, f.system.currencyPrecision, f.rounding) != 0) {
      out.add(
        RefusedException(Refusal.refundNotEqual, null, [-t.toPay, -paid]),
      );
    }
    final modes = {for (final m in await select(modeOfPayment).get()) m.id: m};
    for (final MapEntry(:key, :value) in ret.payments.entries) {
      if (value != 0 && modes[key]?.enabled != 1) {
        out.add(RefusedException(Refusal.modeDisabled, modes[key]?.name));
      }
    }
    return out;
  }

  bool _batchesFit(List<SbEntry> entries, List<SbEntry> left, double stock) {
    final can = {for (final e in left) e.batchNo: e.qty};
    var sum = 0.0;
    for (final e in entries) {
      if (e.batchNo == null || e.qty > (can[e.batchNo] ?? 0) + 1e-9) {
        return false;
      }
      sum += e.qty;
    }
    return (sum - stock).abs() < 1e-9;
  }

  /// INV-R8: saves and submits return [ret] in one transaction and returns
  /// its name. Every problem is reported together ([RefusedAll]).
  Future<String> submitReturn(Sale ret) => keepOnFailure(ret, _submitReturn);

  Future<String> _submitReturn(Sale ret) => transaction(() async {
    final problems = await returnProblems(ret);
    if (problems.isNotEmpty) throw RefusedAll(problems);
    final id = await writeSale(ret);
    final session = (await openSession())!;
    final now = DateTime.now();
    final posting = toStorage(now);
    await checkNotFrozen(posting);
    final name = await nextName(await defaultSeries(salesReturnType), now);
    if (ret.updateStock) {
      final lines = await (select(
        salesInvoiceItem,
      )..where((x) => x.salesInvoiceId.equals(id))).get();
      final facts = await itemFacts(lines.map((l) => l.itemId));
      // STK-R32: each serial number comes back at its own cost.
      await customUpdate(
        'UPDATE serial_and_batch_entry SET incoming_rate = COALESCE((SELECT '
        'incoming_rate FROM serial_no WHERE id = serial_no_id), 0) '
        'WHERE voucher_type = ?1 AND voucher_detail_id IN '
        '(SELECT id FROM sales_invoice_item WHERE sales_invoice_id = ?2)',
        variables: [Variable(salesInvoiceType), Variable(id)],
        updates: {serialAndBatchEntry},
      );
      final ledger = <StockLedgerEntryCompanion>[];
      for (final l in lines) {
        final fact = facts[l.itemId]!;
        if (!fact.stockItem) continue;
        final byBatch = <int?, double>{};
        if (fact.hasBatch) {
          for (final e
              in await (select(serialAndBatchEntry)..where(
                    (x) =>
                        x.voucherType.equals(salesInvoiceType) &
                        x.voucherDetailId.equals(l.id),
                  ))
                  .get()) {
            byBatch[e.batchId] = (byBatch[e.batchId] ?? 0) + e.qty;
          }
        } else {
          byBatch[null] = -l.stockQty;
        }
        for (final MapEntry(key: batch, value: qty) in byBatch.entries) {
          ledger.add(
            StockLedgerEntryCompanion.insert(
              itemId: l.itemId,
              warehouseId: l.warehouseId,
              postingDatetime: posting,
              voucherType: salesInvoiceType,
              voucherId: id,
              voucherNo: name,
              voucherDetailId: l.id,
              actualQty: qty,
              qtyAfterTransaction: 0,
              // STK-R33: back at the cost it went out at (D-64).
              // ponytail: the cost at the moment of the return; if a later
              // backdated receipt recosts the sale, re-read it in
              // _syncSaleCosts for return lines too.
              incomingRate: Value(l.incomingRate),
              batchId: Value(batch),
            ),
          );
        }
      }
      await postLedger(ledger);
      await _serialsAvailable(id, ret.warehouseId, posting);
    }
    await (update(salesInvoice)..where((x) => x.id.equals(id))).write(
      SalesInvoiceCompanion(
        name: Value(name),
        docstatus: const Value(1),
        status: const Value('Return'),
        postingDatetime: Value(posting),
        posOpeningEntryId: Value(session.id),
        modifiedAt: Value(posting),
      ),
    );
    await _setStatus(ret.returnAgainstId!, posting);
    return name;
  });

  /// The serial numbers on invoice [id]'s lines are Available in
  /// [warehouseId] again, with no warranty running.
  Future<void> _serialsAvailable(
    int id,
    int warehouseId,
    String at,
  ) => customUpdate(
    "UPDATE serial_no SET status = 'Available', warehouse_id = ?1, "
    'warranty_expiry_date = NULL, modified_at = ?2 WHERE id IN (SELECT '
    'e.serial_no_id FROM serial_and_batch_entry e JOIN sales_invoice_item l '
    'ON l.id = e.voucher_detail_id WHERE e.voucher_type = ?3 '
    'AND l.sales_invoice_id = ?4)',
    variables: [
      Variable(warehouseId),
      Variable(at),
      Variable(salesInvoiceType),
      Variable(id),
    ],
    updates: {serialNo},
  );

  /// A submitted return exists against sale [saleId].
  Future<bool> _returned(int saleId) => exists(
    'SELECT 1 FROM sales_invoice WHERE return_against_id = ? '
    'AND docstatus = 1',
    [saleId],
  );

  /// INV-R3: a sale is Credit Note Issued while a submitted return exists
  /// against it, otherwise Paid.
  Future<void> _setStatus(int saleId, String at) async {
    final returned = await _returned(saleId);
    await (update(salesInvoice)..where((x) => x.id.equals(saleId))).write(
      SalesInvoiceCompanion(
        status: Value(returned ? 'Credit Note Issued' : 'Paid'),
        modifiedAt: Value(at),
      ),
    );
  }

  /// INV-R10, R11: cancels sale or return [id] while its POS session is
  /// open. A sale with a submitted return is refused. Its ledger entries
  /// are cancelled and their chains recomputed, which refuses a return
  /// whose stock has since been sold; serial numbers go back where they
  /// were; a return's original gets its status back.
  Future<void> cancelInvoice(int id) => transaction(() async {
    final h = await (select(
      salesInvoice,
    )..where((s) => s.id.equals(id))).getSingle();
    if (h.docstatus != 1) throw const RefusedException(Refusal.docstatus);
    final session = await (select(
      posOpeningEntry,
    )..where((s) => s.id.equals(h.posOpeningEntryId))).getSingle();
    if (session.status != 'Open') {
      throw const RefusedException(Refusal.cancelSessionClosed);
    }
    if (h.isReturn == 0 && await _returned(id)) {
      throw const RefusedException(Refusal.cancelHasReturns);
    }
    final at = toStorage(DateTime.now());
    await checkNotFrozen(h.postingDatetime);
    await cancelLedger(salesInvoiceType, id);
    if (h.isReturn == 0) {
      await _serialsAvailable(id, h.setWarehouseId, at);
    } else if (h.updateStock == 1) {
      final original = await (select(
        salesInvoice,
      )..where((s) => s.id.equals(h.returnAgainstId!))).getSingle();
      await deliverSerials(id, original.postingDatetime, at);
    }
    await (update(salesInvoice)..where((x) => x.id.equals(id))).write(
      SalesInvoiceCompanion(
        docstatus: const Value(2),
        status: const Value('Cancelled'),
        modifiedAt: Value(at),
      ),
    );
    if (h.returnAgainstId case final original?) {
      await _setStatus(original, at);
    }
  });
}

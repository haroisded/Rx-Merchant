import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/refusal.dart';
import '../../setup/data/setup_queries.dart';
import '../logic/stock_documents.dart';
import '../logic/stock_rules.dart';
import '../logic/valuation.dart';
import 'stock_ledger.dart';

const stockEntryType = 'Stock Entry';

/// A serial number or batch that can leave a warehouse, by id and name.
typedef EntryRef = ({
  int? serialId,
  int? batchId,
  String? serialNo,
  String? batchNo,
});

/// Reads shared by the stock documents.
extension StockFacts on AppDatabase {
  /// What the line checks need to know about [ids] (`checkEntryLines`).
  Future<Map<int, ItemFacts>> itemFacts(Iterable<int> ids) async {
    if (ids.isEmpty) return {};
    final rows = await customSelect(
      'SELECT i.*, u.must_be_whole_number AS whole FROM item i '
      'JOIN uom u ON u.id = i.stock_uom_id WHERE i.id IN (${ids.toSet().join(',')})',
    ).get();
    return {
      for (final r in rows)
        r.read<int>('id'): (
          code: r.read<String>('item_code'),
          disabled: r.read<int>('disabled') == 1,
          endOfLife: r.read<String?>('end_of_life'),
          template: r.read<int>('has_variants') == 1,
          stockItem: r.read<int>('is_stock_item') == 1,
          hasBatch: r.read<int>('has_batch_no') == 1,
          hasSerial: r.read<int>('has_serial_no') == 1,
          stockUomWhole: r.read<int>('whole') == 1,
        ),
    };
  }

  /// Enabled warehouses that are not groups: the ones stock can be in.
  Future<Set<int>> usableWarehouses() =>
      (select(warehouse)
            ..where((w) => w.isGroup.equals(0) & w.disabled.equals(0)))
          .map((w) => w.id)
          .get()
          .then((ids) => ids.toSet());

  Future<Set<int>> wholeUoms() =>
      (select(uom)..where((u) => u.mustBeWholeNumber.equals(1)))
          .map((u) => u.id)
          .get()
          .then((ids) => ids.toSet());

  Future<int> floatPrecision() async =>
      SystemSettings(await readSingle(SystemSettings.doctype)).floatPrecision;

  Future<int> currencyPrecision() async =>
      SystemSettings(await readSingle(SystemSettings.doctype))
          .currencyPrecision;

  /// The name a submitted amendment of [table] row [fromId] takes: that
  /// cancelled document's name plus `-1`, or the next number when it was
  /// itself an amendment (00-overview 6.1).
  Future<String> amendedName(String table, int fromId) async {
    final from = await customSelect(
      'SELECT name, amended_from_id FROM $table WHERE id = ?',
      variables: [Variable(fromId)],
    ).getSingle();
    final name = from.read<String>('name');
    final m = RegExp(r'^(.*)-(\d+)$').firstMatch(name);
    return from.read<int?>('amended_from_id') != null && m != null
        ? '${m[1]}-${int.parse(m[2]!) + 1}'
        : '$name-1';
  }

  /// The moment a draft posts at: its own posting time when Edit Posting
  /// Date and Time was on, otherwise now (see [postingSetByHand]).
  String postingAt(String posting, String modified) =>
      postingSetByHand(posting, modified) ? posting : toStorage(DateTime.now());

  /// The first problem of [problems] as a refusal.
  void refuseFirst(List<(int, LineProblem)> problems) {
    if (problems.isEmpty) return;
    final (row, problem) = problems.first;
    throw RefusedException(Refusal.lineProblem, null, [row, problem]);
  }
}

/// Stock Entry: Material Receipt, Material Issue, Material Transfer
/// (STK-R38 to R41) with the serial numbers and batches of each line
/// (STK-R20 to R27).
extension StockEntryDb on AppDatabase {
  /// Saves a draft and returns its id. [posting] null means Edit Posting
  /// Date and Time is off: the posting time is the save time, and Submit
  /// moves it to the submit time. Typed batches and serial numbers of a
  /// receipt that do not exist yet are created now (STK-R20, R25).
  Future<int> saveStockEntry(
    StockEntryCompanion header,
    List<EntryLine> lines,
    List<(String, double)> costs, {
    String? posting,
  }) => transaction(() async {
    final purpose = StockPurpose.of(header.purpose.value);
    final now = toStorage(DateTime.now());
    final at = posting ?? now;
    if (header.id.present) {
      final old = await (select(
        stockEntry,
      )..where((e) => e.id.equals(header.id.value))).getSingle();
      if (old.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    }
    refuseFirst(
      checkEntryLines(
        purpose,
        lines,
        items: await itemFacts(lines.map((l) => l.itemId)),
        usableWarehouses: await usableWarehouses(),
        wholeUoms: await wholeUoms(),
        date: at.substring(0, 10),
        floatPrecision: await floatPrecision(),
      ),
    );
    final id = await upsert(
      stockEntry,
      header.copyWith(
        postingDatetime: Value(at),
        modifiedAt: Value(now),
        docstatus: const Value(0),
        fromWarehouseId: Value(
          purpose.hasSource ? header.fromWarehouseId.value : null,
        ),
        toWarehouseId: Value(
          purpose.hasTarget ? header.toWarehouseId.value : null,
        ),
      ),
      header.id,
    );
    await _clearLines(id);

    final precision = await currencyPrecision();
    final floats = await floatPrecision();
    final costTotal = purpose.hasTarget
        ? costs.fold(0.0, (s, c) => s + c.$2)
        : 0.0;
    final basics = [
      for (final l in lines)
        flt(stockQty(l.qty, l.factor, floats) * l.basicRate, precision),
    ];
    // STK-R39: costs are spread over the incoming lines.
    final shares = purpose.hasTarget
        ? spreadCosts(basics, costTotal, precision)
        : List.filled(lines.length, 0.0);
    var total = 0.0;
    for (final (i, l) in lines.indexed) {
      final qty = stockQty(l.qty, l.factor, floats);
      final amount = flt(basics[i] + shares[i], precision);
      total += amount;
      l.id = await into(stockEntryItem).insert(
        StockEntryItemCompanion.insert(
          stockEntryId: id,
          idx: i + 1,
          itemId: l.itemId,
          sWarehouseId: Value(purpose.hasSource ? l.sWarehouseId : null),
          tWarehouseId: Value(purpose.hasTarget ? l.tWarehouseId : null),
          qty: l.qty,
          uomId: l.uomId,
          conversionFactor: Value(l.factor),
          transferQty: qty,
          basicRate: Value(l.basicRate),
          basicAmount: Value(basics[i]),
          additionalCost: Value(shares[i]),
          amount: Value(amount),
          valuationRate: Value(
            flt(l.basicRate + (qty == 0 ? 0 : shares[i] / qty), ratePrecision),
          ),
          allowZeroValuationRate: Value(l.allowZero ? 1 : 0),
        ),
      );
      for (final e in l.entries) {
        await insertEntry(
          stockEntryType,
          l.id!,
          l.itemId,
          e,
          at,
          receipt: purpose == StockPurpose.materialReceipt,
        );
      }
    }
    for (final (description, amount) in costs) {
      if (!purpose.hasTarget) break;
      await into(stockEntryAdditionalCost).insert(
        StockEntryAdditionalCostCompanion.insert(
          stockEntryId: id,
          description: description,
          amount: amount,
        ),
      );
    }
    await (update(stockEntry)..where((e) => e.id.equals(id))).write(
      StockEntryCompanion(
        totalAdditionalCosts: Value(flt(costTotal, precision)),
        totalAmount: Value(flt(total, precision)),
      ),
    );
    return id;
  });

  /// Deletes a draft with its lines and their Serial / Batch Entries.
  Future<void> deleteStockEntry(int id) => transaction(() async {
    final e = await (select(
      stockEntry,
    )..where((x) => x.id.equals(id))).getSingle();
    if (e.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    await _clearLines(id);
    await (delete(stockEntry)..where((x) => x.id.equals(id))).go();
  });

  Future<void> _clearLines(int entryId) async {
    await customUpdate(
      'DELETE FROM serial_and_batch_entry WHERE voucher_type = ? AND '
      'voucher_detail_id IN (SELECT id FROM stock_entry_item WHERE stock_entry_id = ?)',
      variables: [Variable(stockEntryType), Variable(entryId)],
      updates: {serialAndBatchEntry},
      updateKind: UpdateKind.delete,
    );
    await (delete(
      stockEntryItem,
    )..where((i) => i.stockEntryId.equals(entryId))).go();
    await (delete(
      stockEntryAdditionalCost,
    )..where((c) => c.stockEntryId.equals(entryId))).go();
  }

  /// Resolves one typed Serial / Batch Entry and stores it against line
  /// [detailId] of a [voucherType] document. Only a [receipt] creates new
  /// batches and serial numbers.
  Future<void> insertEntry(
    String voucherType,
    int detailId,
    int itemId,
    SbEntry e,
    String posting, {
    bool receipt = false,
  }) async {
    int? batchId;
    if (e.batchNo case final name? when name.isNotEmpty) {
      final found = await (select(
        batches,
      )..where((b) => b.batchId.equals(name))).getSingleOrNull();
      if (found != null && found.itemId != itemId ||
          found == null && !receipt) {
        throw RefusedException(Refusal.batchNotFound, name);
      }
      batchId = found?.id ?? await createBatch(itemId, name, posting);
    }
    int? serialId;
    if (e.serialNo case final name? when name.isNotEmpty) {
      final found = await (select(
        serialNo,
      )..where((s) => s.serialNo.equals(name))).getSingleOrNull();
      if (found != null && found.itemId != itemId ||
          found == null && !receipt) {
        throw RefusedException(Refusal.serialNotAvailable, name);
      }
      if (receipt && found != null && found.status != 'Inactive') {
        throw RefusedException(Refusal.serialExists, name);
      }
      serialId =
          found?.id ??
          await into(serialNo).insert(
            SerialNoCompanion.insert(
              serialNo: name,
              itemId: itemId,
              batchId: Value(batchId),
            ),
          );
      batchId ??= found?.batchId;
    }
    if (batchId == null && serialId == null) return;
    await into(serialAndBatchEntry).insert(
      SerialAndBatchEntryCompanion.insert(
        voucherType: voucherType,
        voucherDetailId: detailId,
        itemId: itemId,
        serialNoId: Value(serialId),
        batchId: Value(batchId),
        qty: serialId != null ? 1 : e.qty,
      ),
    );
  }

  /// STK-R19: with Has Expiry Date the expiry date is mandatory; left
  /// empty it defaults to the manufacturing date plus Shelf Life In Days.
  Future<int> saveBatch(BatchesCompanion row) async {
    final it = await (select(
      item,
    )..where((i) => i.id.equals(row.itemId.value))).getSingle();
    var expiry = row.expiryDate.present ? row.expiryDate.value : null;
    if (it.hasExpiryDate == 1) {
      expiry ??= defaultExpiry(
        row.manufacturingDate.present ? row.manufacturingDate.value : null,
        it.shelfLifeInDays,
      );
      if (expiry == null) {
        throw RefusedException(Refusal.expiryRequired, row.batchId.value);
      }
    }
    return upsert(
      batches,
      row.copyWith(
        expiryDate: Value(expiry),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
      row.id,
    );
  }

  /// Creates batch [name] of [itemId], made on the receipt date.
  Future<int> createBatch(int itemId, String name, String fromDate) =>
      saveBatch(
        BatchesCompanion.insert(
          batchId: name,
          itemId: itemId,
          manufacturingDate: Value(fromDate.substring(0, 10)),
        ),
      );

  /// The lines of entry [id] with their Serial / Batch Entries by name.
  Future<List<EntryLine>> stockEntryLines(int id) async {
    final rows =
        await (select(stockEntryItem)
              ..where((i) => i.stockEntryId.equals(id))
              ..orderBy([(i) => OrderingTerm(expression: i.idx)]))
            .get();
    return [
      for (final r in rows)
        EntryLine(
          id: r.id,
          itemId: r.itemId,
          sWarehouseId: r.sWarehouseId,
          tWarehouseId: r.tWarehouseId,
          qty: r.qty,
          uomId: r.uomId,
          factor: r.conversionFactor,
          basicRate: r.basicRate,
          allowZero: r.allowZeroValuationRate == 1,
          entries: await entriesOf(stockEntryType, r.id),
        ),
    ];
  }

  /// The Serial / Batch Entries of one document line, by name.
  Future<List<SbEntry>> entriesOf(String voucherType, int detailId) async {
    final rows = await customSelect(
      'SELECT s.serial_no, b.batch_id, e.qty FROM serial_and_batch_entry e '
      'LEFT JOIN serial_no s ON s.id = e.serial_no_id '
      'LEFT JOIN batch b ON b.id = e.batch_id '
      'WHERE e.voucher_type = ? AND e.voucher_detail_id = ? ORDER BY e.id',
      variables: [Variable(voucherType), Variable(detailId)],
    ).get();
    return [
      for (final r in rows)
        SbEntry(
          serialNo: r.read<String?>('serial_no'),
          batchNo: r.read<String?>('batch_id'),
          qty: r.read<double>('qty'),
        ),
    ];
  }

  /// Submits draft [id] (STK-R28): names it, fills empty Serial / Batch
  /// Entries, writes the ledger and moves serial numbers, in one
  /// transaction.
  Future<void> submitStockEntry(int id) => transaction(() async {
    final e = await (select(
      stockEntry,
    )..where((x) => x.id.equals(id))).getSingle();
    if (e.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    final purpose = StockPurpose.of(e.purpose);
    final posting = postingAt(e.postingDatetime, e.modifiedAt);
    await checkNotFrozen(posting);
    final lines = await stockEntryLines(id);
    final facts = await itemFacts(lines.map((l) => l.itemId));
    refuseFirst(
      checkEntryLines(
        purpose,
        lines,
        items: facts,
        usableWarehouses: await usableWarehouses(),
        wholeUoms: await wholeUoms(),
        date: posting.substring(0, 10),
        floatPrecision: await floatPrecision(),
      ),
    );
    final name = switch (e.amendedFromId) {
      final from? => await amendedName('stock_entry', from),
      null => await nextName(
        await defaultSeries(stockEntryType),
        DateTime.parse(posting),
      ),
    };

    final ledger = <StockLedgerEntryCompanion>[];
    for (final row in await (select(
      stockEntryItem,
    )..where((i) => i.stockEntryId.equals(id))).get()) {
      final fact = facts[row.itemId]!;
      if (fact.hasBatch || fact.hasSerial) {
        await _fillEntries(purpose, row, fact, posting);
      }
      final entries =
          await (select(serialAndBatchEntry)..where(
                (x) =>
                    x.voucherType.equals(stockEntryType) &
                    x.voucherDetailId.equals(row.id),
              ))
              .get();
      await _checkEntries(purpose, row, entries, posting);

      final byBatch = <int?, double>{};
      if (fact.hasBatch) {
        for (final x in entries) {
          byBatch[x.batchId] = (byBatch[x.batchId] ?? 0) + x.qty;
        }
      } else {
        byBatch[null] = row.transferQty;
      }
      StockLedgerEntryCompanion sle(int wh, int? batch, double qty) =>
          StockLedgerEntryCompanion.insert(
            itemId: row.itemId,
            warehouseId: wh,
            postingDatetime: posting,
            voucherType: stockEntryType,
            voucherId: id,
            voucherNo: name,
            voucherDetailId: row.id,
            actualQty: qty,
            qtyAfterTransaction: 0,
            // A receipt's rate is its own; a transfer's comes from the
            // source chain (stock_ledger.dart).
            incomingRate: Value(
              qty > 0 && purpose == StockPurpose.materialReceipt
                  ? row.valuationRate
                  : 0,
            ),
            batchId: Value(batch),
          );
      for (final MapEntry(key: batch, value: qty) in byBatch.entries) {
        if (row.sWarehouseId case final s?) ledger.add(sle(s, batch, -qty));
        if (row.tWarehouseId case final t?) ledger.add(sle(t, batch, qty));
      }
    }
    await (update(stockEntry)..where((x) => x.id.equals(id))).write(
      StockEntryCompanion(
        name: Value(name),
        docstatus: const Value(1),
        postingDatetime: Value(posting),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
    );
    await _setEntryRates(id, purpose);
    await postLedger(ledger);
    await _moveSerials(id, purpose, cancel: false);
    await syncStockEntryValues(id);
  });

  /// STK-R20, R25, R27: a line of a batch or serial item submitted without
  /// entries. A receipt creates them from the item's series; an outgoing
  /// line picks them by Pick Serial / Batch Based On when Auto Create Serial
  /// and Batch Bundle For Outward is on.
  Future<void> _fillEntries(
    StockPurpose purpose,
    StockEntryItemData row,
    ItemFacts fact,
    String posting,
  ) async {
    final has =
        await (select(serialAndBatchEntry)..where(
              (x) =>
                  x.voucherType.equals(stockEntryType) &
                  x.voucherDetailId.equals(row.id),
            ))
            .get();
    if (has.isNotEmpty) return;
    final it = await (select(
      item,
    )..where((i) => i.id.equals(row.itemId))).getSingle();
    Future<void> add(int? serial, int? batch, double qty) =>
        into(serialAndBatchEntry).insert(
          SerialAndBatchEntryCompanion.insert(
            voucherType: stockEntryType,
            voucherDetailId: row.id,
            itemId: row.itemId,
            serialNoId: Value(serial),
            batchId: Value(batch),
            qty: qty,
          ),
        );
    final date = DateTime.parse(posting);

    if (purpose == StockPurpose.materialReceipt) {
      int? batch;
      if (fact.hasBatch) {
        if (it.createNewBatch != 1) {
          throw RefusedException(Refusal.batchRequired, fact.code);
        }
        batch = await createBatch(
          row.itemId,
          await nextName(it.batchNumberSeries ?? '${it.itemCode}-.#####', date),
          posting,
        );
      }
      if (!fact.hasSerial) return add(null, batch, row.transferQty);
      final series = it.serialNoSeries;
      if (series == null || series.isEmpty) {
        throw RefusedException(Refusal.serialRequired, fact.code);
      }
      for (var n = 0; n < row.transferQty; n++) {
        final serial = await refuseOnConstraint(
          () async => into(serialNo).insert(
            SerialNoCompanion.insert(
              serialNo: await nextName(series, date),
              itemId: row.itemId,
              batchId: Value(batch),
            ),
          ),
        );
        await add(serial, batch, 1);
      }
      return;
    }

    await fillOutwardEntries(
      stockEntryType,
      row.id,
      fact,
      row.itemId,
      row.sWarehouseId!,
      row.transferQty,
      posting,
      allowExpired: purpose == StockPurpose.materialIssue,
    );
  }

  /// STK-R27: an outgoing line of a batch or serial item left without
  /// entries takes them by Pick Serial / Batch Based On when Auto Create
  /// Serial and Batch Bundle For Outward is on; otherwise it is refused.
  Future<void> fillOutwardEntries(
    String voucherType,
    int detailId,
    ItemFacts fact,
    int itemId,
    int warehouseId,
    double qty,
    String posting, {
    required bool allowExpired,
  }) async {
    final settings = StockSettings(await readSingle(StockSettings.doctype));
    if (!settings.autoCreateSerialAndBatchBundleForOutward) {
      throw RefusedException(Refusal.notEnoughEntries, fact.code);
    }
    final picks = await availableEntries(
      itemId,
      warehouseId,
      posting,
      serials: fact.hasSerial,
      allowExpired: allowExpired,
    );
    final taken = autoPick(picks, qty, settings.pickSerialAndBatchBasedOn);
    if ((taken.fold(0.0, (s, t) => s + t.$2) - qty).abs() > 1e-9) {
      throw RefusedException(Refusal.notEnoughEntries, fact.code);
    }
    for (final (e, q) in taken) {
      await into(serialAndBatchEntry).insert(
        SerialAndBatchEntryCompanion.insert(
          voucherType: voucherType,
          voucherDetailId: detailId,
          itemId: itemId,
          serialNoId: Value(e.serialId),
          batchId: Value(e.batchId),
          qty: q,
        ),
      );
    }
  }

  /// What can leave [warehouseId] at [posting]: Available serial numbers,
  /// or batches with a balance, for Auto Fetch (STK-R21, R27). Expired
  /// batches only when [allowExpired] (a Material Issue, STK-R22).
  Future<List<Pickable<EntryRef>>> availableEntries(
    int itemId,
    int warehouseId,
    String posting, {
    required bool serials,
    required bool allowExpired,
  }) async {
    final today = posting.substring(0, 10);
    final rows = serials
        ? await customSelect(
            // FIFO is by when the unit came into this warehouse.
            'SELECT s.id AS serial, s.serial_no, s.batch_id AS batch, '
            'b.batch_id AS batch_no, 1.0 AS qty, COALESCE((SELECT '
            'MAX(l.posting_datetime) FROM serial_and_batch_entry e JOIN '
            'stock_ledger_entry l ON l.voucher_type = e.voucher_type AND '
            'l.voucher_detail_id = e.voucher_detail_id AND l.actual_qty > 0 '
            'AND l.is_cancelled = 0 AND l.warehouse_id = s.warehouse_id '
            'WHERE e.serial_no_id = s.id), s.created_at) AS received, '
            'b.expiry_date AS expiry '
            'FROM serial_no s LEFT JOIN batch b ON b.id = s.batch_id '
            "WHERE s.item_id = ? AND s.status = 'Available' AND s.warehouse_id = ?",
            variables: [Variable(itemId), Variable(warehouseId)],
          ).get()
        : await customSelect(
            'SELECT NULL AS serial, NULL AS serial_no, b.id AS batch, '
            'b.batch_id AS batch_no, SUM(l.actual_qty) AS qty, '
            'b.created_at AS received, b.expiry_date AS expiry '
            'FROM stock_ledger_entry l JOIN batch b ON b.id = l.batch_id '
            'WHERE l.item_id = ? AND l.warehouse_id = ? AND l.is_cancelled = 0 '
            'AND l.posting_datetime <= ? GROUP BY b.id HAVING SUM(l.actual_qty) > 0',
            variables: [
              Variable(itemId),
              Variable(warehouseId),
              Variable(posting),
            ],
          ).get();
    return [
      for (final r in rows)
        if (allowExpired ||
            batchStatus(r.read<String?>('expiry'), today) !=
                BatchStatus.expired)
          (
            id: (
              serialId: r.read<int?>('serial'),
              batchId: r.read<int?>('batch'),
              serialNo: r.read<String?>('serial_no'),
              batchNo: r.read<String?>('batch_no'),
            ),
            qty: r.read<double>('qty'),
            received: r.read<String>('received'),
            expiry: r.read<String?>('expiry'),
          ),
    ];
  }

  /// STK-R22, R24, R25: serial numbers must be where the line takes them
  /// from; a receipt's must be new; an expired batch leaves only by issue.
  Future<void> _checkEntries(
    StockPurpose purpose,
    StockEntryItemData row,
    List<SerialAndBatchEntryData> entries,
    String posting,
  ) async {
    for (final x in entries) {
      if (x.serialNoId case final id?) {
        final s = await (select(
          serialNo,
        )..where((s) => s.id.equals(id))).getSingle();
        final ok = purpose == StockPurpose.materialReceipt
            ? s.status == 'Inactive'
            : s.status == 'Available' && s.warehouseId == row.sWarehouseId;
        if (!ok) {
          throw RefusedException(
            purpose == StockPurpose.materialReceipt
                ? Refusal.serialExists
                : Refusal.serialNotAvailable,
            s.serialNo,
          );
        }
      }
      if (purpose == StockPurpose.materialTransfer && x.batchId != null) {
        final b = await (select(
          batches,
        )..where((b) => b.id.equals(x.batchId!))).getSingle();
        if (batchStatus(b.expiryDate, posting.substring(0, 10)) ==
            BatchStatus.expired) {
          throw RefusedException(Refusal.expiredBatch, b.batchId);
        }
      }
    }
  }

  /// STK-R24: Submit moves serial numbers in, out or across; Cancel moves
  /// them back.
  Future<void> _moveSerials(
    int entryId,
    StockPurpose purpose, {
    required bool cancel,
  }) async {
    final rows = await customSelect(
      'SELECT e.serial_no_id, i.s_warehouse_id, i.t_warehouse_id, '
      'i.valuation_rate FROM serial_and_batch_entry e '
      'JOIN stock_entry_item i ON i.id = e.voucher_detail_id '
      'WHERE e.voucher_type = ? AND i.stock_entry_id = ? '
      'AND e.serial_no_id IS NOT NULL',
      variables: [Variable(stockEntryType), Variable(entryId)],
    ).get();
    for (final r in rows) {
      final id = r.read<int>('serial_no_id');
      final s = r.read<int?>('s_warehouse_id');
      final t = r.read<int?>('t_warehouse_id');
      final rate = r.read<double>('valuation_rate');
      final change = switch ((purpose, cancel)) {
        (StockPurpose.materialReceipt, false) => SerialNoCompanion(
          status: const Value('Available'),
          warehouseId: Value(t),
          incomingRate: Value(rate),
        ),
        (StockPurpose.materialReceipt, true) => const SerialNoCompanion(
          status: Value('Inactive'),
          warehouseId: Value(null),
        ),
        (StockPurpose.materialIssue, false) => const SerialNoCompanion(
          status: Value('Delivered'),
          warehouseId: Value(null),
        ),
        (StockPurpose.materialIssue, true) => SerialNoCompanion(
          status: const Value('Available'),
          warehouseId: Value(s),
        ),
        (StockPurpose.materialTransfer, _) => SerialNoCompanion(
          warehouseId: Value(cancel ? s : t),
        ),
      };
      await (update(serialNo)..where((x) => x.id.equals(id))).write(
        change.copyWith(modifiedAt: Value(toStorage(DateTime.now()))),
      );
    }
  }

  /// STK-R32: each serial number goes in at its line's valuation rate and
  /// out at its own rate; the ledger engine reads these.
  Future<void> _setEntryRates(
    int entryId,
    StockPurpose purpose,
  ) => customUpdate(
    purpose == StockPurpose.materialReceipt
        ? 'UPDATE serial_and_batch_entry SET incoming_rate = (SELECT '
              'valuation_rate FROM stock_entry_item WHERE id = voucher_detail_id) '
              'WHERE voucher_type = ?1 AND voucher_detail_id IN '
              '(SELECT id FROM stock_entry_item WHERE stock_entry_id = ?2)'
        : 'UPDATE serial_and_batch_entry SET incoming_rate = COALESCE((SELECT '
              'incoming_rate FROM serial_no WHERE id = serial_no_id), 0) '
              'WHERE voucher_type = ?1 AND voucher_detail_id IN '
              '(SELECT id FROM stock_entry_item WHERE stock_entry_id = ?2)',
    variables: [Variable(stockEntryType), Variable(entryId)],
    updates: {serialAndBatchEntry},
  );

  /// Cancels submitted entry [id] (STK-R41): its ledger entries are reversed
  /// under STK-R36 and its serial numbers move back. A receipt whose serial
  /// numbers have moved since is refused.
  Future<void> cancelStockEntry(int id) => transaction(() async {
    final e = await (select(
      stockEntry,
    )..where((x) => x.id.equals(id))).getSingle();
    if (e.docstatus != 1) throw const RefusedException(Refusal.docstatus);
    await checkNotFrozen(e.postingDatetime);
    final purpose = StockPurpose.of(e.purpose);
    final serials = await customSelect(
      'SELECT s.serial_no, s.status, s.warehouse_id, i.t_warehouse_id '
      'FROM serial_and_batch_entry x JOIN serial_no s ON s.id = x.serial_no_id '
      'JOIN stock_entry_item i ON i.id = x.voucher_detail_id '
      'WHERE x.voucher_type = ? AND i.stock_entry_id = ?',
      variables: [Variable(stockEntryType), Variable(id)],
    ).get();
    for (final s in serials) {
      final where = s.read<int?>('warehouse_id');
      final ok = purpose == StockPurpose.materialIssue
          ? s.read<String>('status') == 'Delivered'
          : s.read<String>('status') == 'Available' &&
                where == s.read<int?>('t_warehouse_id');
      if (!ok) {
        throw RefusedException(
          Refusal.serialMovedSince,
          s.read<String>('serial_no'),
        );
      }
    }
    await (update(stockEntry)..where((x) => x.id.equals(id))).write(
      StockEntryCompanion(
        docstatus: const Value(2),
        modifiedAt: Value(toStorage(DateTime.now())),
      ),
    );
    await cancelLedger(stockEntryType, id);
    await _moveSerials(id, purpose, cancel: true);
  });

  /// Amend: a cancelled entry copied into a new draft (00-overview 6.1).
  Future<int> amendStockEntry(int id) async {
    final e = await (select(
      stockEntry,
    )..where((x) => x.id.equals(id))).getSingle();
    if (e.docstatus != 2) throw const RefusedException(Refusal.docstatus);
    final costs = await (select(
      stockEntryAdditionalCost,
    )..where((c) => c.stockEntryId.equals(id))).get();
    return saveStockEntry(
      StockEntryCompanion.insert(
        purpose: e.purpose,
        postingDatetime: e.postingDatetime,
        fromWarehouseId: Value(e.fromWarehouseId),
        toWarehouseId: Value(e.toWarehouseId),
        isOpening: Value(e.isOpening),
        remarks: Value(e.remarks),
        amendedFromId: Value(id),
      ),
      [for (final l in await stockEntryLines(id)) l..id = null],
      [for (final c in costs) (c.description, c.amount)],
      posting: e.postingDatetime,
    );
  }
}

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/numbers/format.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/numbers/in_words.dart';
import '../../setup/data/refusal.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/logic/tax_template.dart';
import '../../stock/data/stock_entry_db.dart';
import '../../stock/data/stock_ledger.dart';
import '../../stock/data/stock_masters.dart';
import '../../stock/logic/stock_documents.dart';
import '../../stock/logic/stock_rules.dart';
import '../logic/sale.dart';
import '../logic/totals.dart';

// The Cash Register's records (03-cash-register): sessions, the sale being
// built, held orders and Submit.

const salesInvoiceType = 'Sales Invoice';
const posOpeningType = 'POS Opening Entry';

/// One item in the register's selector (POS-R3): its stock in the sale's
/// warehouse and its Stock UOM price in the sale's price list.
typedef RegisterItem = ({
  int id,
  String code,
  String name,
  int groupId,
  double qty,
  double? price,
  String barcodes,
  bool hasImage,
  bool stockItem,
  bool allowNegative,
  bool hasBatch,
  bool hasSerial,
  double maxDiscount,
});

/// The settings the totals engine reads (POS-R12 to R14).
SaleSettings saleSettingsOf(Formats f) => (
  precision: f.system.currencyPrecision,
  method: f.rounding,
  fraction: f.currency?.smallestCurrencyFractionValue ?? 0,
  disableRoundedTotal: f.defaults.disableRoundedTotal,
);

extension PosDb on AppDatabase {
  // ---- Sessions (POS-R1, R2) ---------------------------------------------

  Stream<PosOpeningEntryData?> watchOpenSession() => (select(
    posOpeningEntry,
  )..where((s) => s.status.equals('Open'))).watchSingleOrNull();

  Future<PosOpeningEntryData?> openSession() => (select(
    posOpeningEntry,
  )..where((s) => s.status.equals('Open'))).getSingleOrNull();

  /// POS-R2: a submitted POS Opening Entry with one Opening Amount per
  /// enabled Mode of Payment in [amounts].
  Future<int> openSessionWith(Map<int, double> amounts) => transaction(
    () async {
      if (await openSession() != null) {
        throw const RefusedException(Refusal.anotherSessionOpen);
      }
      final now = DateTime.now();
      final at = toStorage(now);
      final id = await into(posOpeningEntry).insert(
        PosOpeningEntryCompanion.insert(
          name: Value(await nextName(await defaultSeries(posOpeningType), now)),
          docstatus: const Value(1),
          status: const Value('Open'),
          periodStartDatetime: at,
        ),
      );
      for (final MapEntry(:key, :value) in amounts.entries) {
        await into(posOpeningEntryDetail).insert(
          PosOpeningEntryDetailCompanion.insert(
            posOpeningEntryId: id,
            modeOfPaymentId: key,
            openingAmount: Value(value),
          ),
        );
      }
      return id;
    },
  );

  // ---- The sale ------------------------------------------------------------

  /// The formats and rounding in force, as the screens see them.
  Future<Formats> formats() async {
    final store = StoreProfile(await readSingle(StoreProfile.doctype));
    return Formats(
      system: SystemSettings(await readSingle(SystemSettings.doctype)),
      defaults: GlobalDefaults(await readSingle(GlobalDefaults.doctype)),
      currency: store.defaultCurrency == null
          ? null
          : await (select(currency)
                  ..where((c) => c.code.equals(store.defaultCurrency!)))
                .getSingleOrNull(),
    );
  }

  /// POS-R2a: a new sale with the store's register defaults: Stock
  /// Settings' warehouse, Selling Settings' price list, the default Sales
  /// Taxes and Charges Template (not if disabled), Apply Discount On, the
  /// default Letter Head, and POS Settings' Print Heading and Terms.
  Future<Sale> newSale() async {
    final stock = StockSettings(await readSingle(StockSettings.doctype));
    final selling = SellingSettings(await readSingle(SellingSettings.doctype));
    final pos = PosSettings(await readSingle(PosSettings.doctype));
    final template =
        await (select(salesTaxesTemplate)
              ..where((t) => t.isDefault.equals(1) & t.disabled.equals(0)))
            .getSingleOrNull();
    final head =
        await (select(letterHead)
              ..where((h) => h.isDefault.equals(1) & h.disabled.equals(0)))
            .getSingleOrNull();
    final heading = pos.selectPrintHeading == null
        ? null
        : await (select(printHeading)
                ..where((h) => h.name.equals(pos.selectPrintHeading!)))
              .getSingleOrNull();
    final tc = pos.tcName == null
        ? null
        : await (select(termsAndConditions)..where(
                (t) => t.title.equals(pos.tcName!) & t.disabled.equals(0),
              ))
              .getSingleOrNull();
    return Sale(
      warehouseId:
          await (select(warehouse)
                ..where((w) => w.name.equals(stock.defaultWarehouse)))
              .map((w) => w.id)
              .getSingle(),
      priceListId:
          await (select(priceList)
                ..where((p) => p.name.equals(selling.sellingPriceList)))
              .map((p) => p.id)
              .getSingle(),
      taxesTemplateId: template?.id,
      taxes: template == null
          ? const []
          : await salesTaxesTemplateRows(template.id),
      discountOnNetTotal: pos.applyDiscountOn == 'Net Total',
      letterHeadId: head?.id,
      printHeadingId: heading?.id,
      tcId: tc?.id,
      terms: tc?.terms,
    );
  }

  /// POS-R3: the items the register sells, with the stock in [warehouseId]
  /// and the price in [priceListId] valid on [date].
  Stream<List<RegisterItem>> watchRegisterItems(
    int warehouseId,
    int priceListId,
    String date,
  ) =>
      customSelect(
        'SELECT i.id, i.item_code, i.item_name, i.item_group_id, i.is_stock_item, '
        'i.allow_negative_stock, i.has_batch_no, i.has_serial_no, i.max_discount, '
        'i.image IS NOT NULL AS has_image, '
        'COALESCE((SELECT actual_qty FROM bin WHERE item_id = i.id AND '
        'warehouse_id = ?1), 0) AS qty, '
        '(SELECT ip.price_list_rate FROM item_price ip WHERE ip.item_id = i.id '
        'AND ip.price_list_id = ?2 AND ip.batch_id IS NULL '
        'AND (ip.uom_id IS NULL OR ip.uom_id = i.stock_uom_id) '
        'AND (ip.valid_from IS NULL OR ip.valid_from <= ?3) '
        'AND (ip.valid_upto IS NULL OR ip.valid_upto >= ?3) '
        'ORDER BY ip.valid_from DESC LIMIT 1) AS price, '
        "(SELECT group_concat(barcode, ' ') FROM item_barcode WHERE item_id = i.id) AS barcodes "
        'FROM item i WHERE i.disabled = 0 AND i.is_sales_item = 1 '
        'AND i.has_variants = 0 AND (i.end_of_life IS NULL OR i.end_of_life >= ?3) '
        'ORDER BY i.item_name',
        variables: [
          Variable(warehouseId),
          Variable(priceListId),
          Variable(date),
        ],
        readsFrom: {item, bin, itemPrice, itemBarcode},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (
              id: r.read<int>('id'),
              code: r.read<String>('item_code'),
              name: r.read<String>('item_name'),
              groupId: r.read<int>('item_group_id'),
              qty: r.read<double>('qty'),
              price: r.read<double?>('price'),
              barcodes: r.read<String?>('barcodes') ?? '',
              hasImage: r.read<int>('has_image') == 1,
              stockItem: r.read<int>('is_stock_item') == 1,
              allowNegative: r.read<int>('allow_negative_stock') == 1,
              hasBatch: r.read<int>('has_batch_no') == 1,
              hasSerial: r.read<int>('has_serial_no') == 1,
              maxDiscount: r.read<double>('max_discount'),
            ),
        ],
      );

  /// A new cart line for [itemId] (POS-R5, R6, R11): in [uomId], else the
  /// Default Sales Unit of Measure, else the Stock UOM; priced from the
  /// sale's price list; with the item's tax rates in force.
  Future<SaleLine> newLine(Sale sale, int itemId, {int? uomId}) async {
    final it = await (select(
      item,
    )..where((i) => i.id.equals(itemId))).getSingle();
    final today = toStorage(DateTime.now()).substring(0, 10);
    final line = SaleLine(
      itemId: itemId,
      itemName: it.itemName,
      uomId: it.stockUomId,
    );
    await setUnit(sale, line, uomId ?? it.salesUomId ?? it.stockUomId);
    final template = await itemTaxTemplateOf(itemId, today);
    line
      ..itemTaxTemplateId = template
      ..itemTax = template == null
          ? {}
          : {
              for (final r in await itemTaxTemplateRows(template))
                r.taxId: (rate: r.taxRate, notApplicable: r.notApplicable == 1),
            };
    return line;
  }

  /// POS-R5, R6: [line] in unit [uomId] (one of the item's units, else its
  /// Stock UOM), its price looked up again with the discount % kept.
  Future<void> setUnit(Sale sale, SaleLine line, int uomId) async {
    final it = await (select(
      item,
    )..where((i) => i.id.equals(line.itemId))).getSingle();
    final unit = uomId == it.stockUomId
        ? null
        : await (select(itemUom)..where(
                (u) => u.itemId.equals(line.itemId) & u.uomId.equals(uomId),
              ))
              .getSingleOrNull();
    line
      ..uomId = unit?.uomId ?? it.stockUomId
      ..factor = unit?.conversionFactor ?? 1;
    await reprice(sale, line);
  }

  /// STK-R10 for [line]'s unit today; with no price the rate stays as typed.
  Future<void> reprice(Sale sale, SaleLine line) async {
    final price = await priceFor(
      line.itemId,
      line.uomId,
      toStorage(DateTime.now()).substring(0, 10),
      priceListId: sale.priceListId,
      batchId: await _batchIdOf(line.batchNo),
    );
    if (price == null) return;
    final p = linePrice(
      price.rate,
      percentage: line.discountPercentage,
      precision: (await formats()).system.currencyPrecision,
    );
    line
      ..priceListRate = price.rate
      ..rate = p.rate
      ..discountAmount = p.discountAmount;
  }

  Future<int?> _batchIdOf(String? name) async => name == null
      ? null
      : await (select(batches)..where((b) => b.batchId.equals(name)))
            .map((b) => b.id)
            .getSingleOrNull();

  /// POS-R21: the Available serial number [code] in [warehouseId], with
  /// its item and batch.
  Future<({int itemId, SbEntry entry})?> availableSerial(
    String code,
    int warehouseId,
  ) async {
    final row = await customSelect(
      'SELECT s.item_id, s.serial_no, b.batch_id FROM serial_no s '
      'LEFT JOIN batch b ON b.id = s.batch_id WHERE s.serial_no = ? '
      "AND s.status = 'Available' AND s.warehouse_id = ?",
      variables: [Variable(code.trim()), Variable(warehouseId)],
    ).getSingleOrNull();
    if (row == null) return null;
    return (
      itemId: row.read<int>('item_id'),
      entry: SbEntry(
        serialNo: row.read<String>('serial_no'),
        batchNo: row.read<String?>('batch_id'),
      ),
    );
  }

  // ---- Held orders (POS-R18) ------------------------------------------------

  /// Saves [sale] as a draft (no name, no stock effect) in the open session
  /// and returns its id.
  Future<int> saveSale(Sale sale) => _keepOnFailure(sale, _saveSale);

  /// Runs [write] on [sale]; when it fails the transaction rolls back, so
  /// the cart forgets the draft id and line ids the write gave it.
  Future<T> _keepOnFailure<T>(Sale sale, Future<T> Function(Sale) write) async {
    final id = sale.id;
    final dirty = sale.dirty;
    try {
      return await write(sale);
    } catch (_) {
      sale
        ..id = id
        ..dirty = dirty;
      rethrow;
    }
  }

  Future<int> _saveSale(Sale sale) => transaction(() async {
    final session = await openSession();
    if (session == null) throw const RefusedException(Refusal.noOpenSession);
    final f = await formats();
    final t = totalsOf(sale, saleSettingsOf(f));
    final paid = settle(
      t.toPay,
      await _tenders(sale),
      precision: f.system.currencyPrecision,
      method: f.rounding,
    );
    final posting = toStorage(DateTime.now());
    final header = SalesInvoiceCompanion.insert(
      postingDatetime: posting,
      posOpeningEntryId: session.id,
      setWarehouseId: sale.warehouseId,
      priceListId: sale.priceListId,
      taxesTemplateId: Value(sale.taxesTemplateId),
      totalQty: Value(flt(t.totalQty, f.system.floatPrecision, f.rounding)),
      total: Value(t.total),
      netTotal: Value(t.netTotal),
      applyDiscountOn: Value(
        sale.discountOnNetTotal ? 'Net Total' : 'Grand Total',
      ),
      additionalDiscountPercentage: Value(sale.additionalDiscountPercentage),
      discountAmount: Value(t.discountAmount),
      totalTaxesAndCharges: Value(t.totalTaxes),
      grandTotal: Value(t.grandTotal),
      roundingAdjustment: Value(t.roundingAdjustment),
      roundedTotal: Value(t.roundedTotal),
      inWords: Value(_inWords(t.toPay, f)),
      paidAmount: Value(paid.paid),
      changeAmount: Value(paid.change),
      letterHeadId: Value(sale.letterHeadId),
      printHeadingId: Value(sale.printHeadingId),
      tcId: Value(sale.tcId),
      terms: Value(sale.terms),
      modifiedAt: Value(posting),
    );
    final id = sale.id;
    if (id == null) {
      sale.id = await into(salesInvoice).insert(header);
    } else {
      final count = await (update(
        salesInvoice,
      )..where((x) => x.id.equals(id) & x.docstatus.equals(0))).write(header);
      if (count == 0) throw const RefusedException(Refusal.docstatus);
      await _clearChildren(id);
    }
    final invoiceId = sale.id!;
    for (final (i, l) in sale.lines.indexed) {
      final lt = t.lines[i];
      l.id = await into(salesInvoiceItem).insert(
        SalesInvoiceItemCompanion.insert(
          salesInvoiceId: invoiceId,
          idx: i + 1,
          itemId: l.itemId,
          itemName: l.itemName,
          qty: l.qty,
          uomId: l.uomId,
          conversionFactor: Value(l.factor),
          stockQty: stockQty(l.qty, l.factor, f.system.floatPrecision),
          priceListRate: Value(l.priceListRate),
          discountPercentage: Value(l.discountPercentage),
          discountAmount: Value(l.discountAmount),
          rate: Value(l.rate),
          amount: Value(lt.amount),
          netRate: Value(lt.netRate),
          netAmount: Value(lt.netAmount),
          itemTaxTemplateId: Value(l.itemTaxTemplateId),
          itemTaxRate: Value(itemTaxJson(l.itemTax)),
          warehouseId: sale.warehouseId,
        ),
      );
      for (final e in l.entries) {
        await insertEntry(salesInvoiceType, l.id!, l.itemId, e, posting);
      }
    }
    for (final (k, row) in sale.taxes.indexed) {
      final x = t.taxes[k];
      await into(salesInvoiceTax).insert(
        SalesInvoiceTaxCompanion.insert(
          salesInvoiceId: invoiceId,
          idx: k + 1,
          chargeType: row.chargeType.value,
          taxId: row.taxId!,
          description: Value(row.description),
          rate: Value(row.rate),
          rowId: Value(row.rowId),
          includedInPrintRate: Value(row.included ? 1 : 0),
          taxAmount: Value(x.taxAmount),
          taxAmountAfterDiscountAmount: Value(x.taxAmountAfterDiscount),
          total: Value(x.total),
          // Item row id -> [rate, amount]; "NA" for Not Applicable.
          itemWiseTaxDetail: Value(
            jsonEncode({
              for (final MapEntry(key: i, value: (rate, amount))
                  in x.itemWise.entries)
                '${sale.lines[i].id}': [rate ?? 'NA', amount],
            }),
          ),
        ),
      );
    }
    for (final MapEntry(:key, :value) in sale.payments.entries) {
      if (value == 0) continue;
      await into(salesInvoicePayment).insert(
        SalesInvoicePaymentCompanion.insert(
          salesInvoiceId: invoiceId,
          modeOfPaymentId: key,
          amount: value,
        ),
      );
    }
    sale.dirty = false;
    return invoiceId;
  });

  Future<void> _clearChildren(int invoiceId) async {
    await customUpdate(
      'DELETE FROM serial_and_batch_entry WHERE voucher_type = ? AND '
      'voucher_detail_id IN (SELECT id FROM sales_invoice_item '
      'WHERE sales_invoice_id = ?)',
      variables: [Variable(salesInvoiceType), Variable(invoiceId)],
      updates: {serialAndBatchEntry},
      updateKind: UpdateKind.delete,
    );
    await (delete(
      salesInvoiceItem,
    )..where((x) => x.salesInvoiceId.equals(invoiceId))).go();
    await (delete(
      salesInvoiceTax,
    )..where((x) => x.salesInvoiceId.equals(invoiceId))).go();
    await (delete(
      salesInvoicePayment,
    )..where((p) => p.salesInvoiceId.equals(invoiceId))).go();
  }

  /// Deletes held order [id] with its Serial / Batch Entries (POS-R19).
  Future<void> deleteSale(int id) => transaction(() async {
    final row = await (select(
      salesInvoice,
    )..where((x) => x.id.equals(id))).getSingle();
    if (row.docstatus != 0) throw const RefusedException(Refusal.docstatus);
    await _clearChildren(id);
    await (delete(salesInvoice)..where((x) => x.id.equals(id))).go();
  });

  /// Held order [id] as a cart, its prices looked up again (POS-R18).
  Future<Sale> loadSale(int id) async {
    final h = await (select(
      salesInvoice,
    )..where((x) => x.id.equals(id))).getSingle();
    final taxes =
        await (select(salesInvoiceTax)
              ..where((x) => x.salesInvoiceId.equals(id))
              ..orderBy([(x) => OrderingTerm(expression: x.idx)]))
            .get();
    final sale =
        Sale(
            id: id,
            warehouseId: h.setWarehouseId,
            priceListId: h.priceListId,
            taxesTemplateId: h.taxesTemplateId,
            taxes: [
              for (final x in taxes)
                TaxRow(
                  chargeType: ChargeType.of(x.chargeType),
                  taxId: x.taxId,
                  description: x.description,
                  rate: x.rate,
                  // An Actual row keeps its fixed amount.
                  taxAmount: x.taxAmount,
                  rowId: x.rowId,
                  included: x.includedInPrintRate == 1,
                ),
            ],
            discountOnNetTotal: h.applyDiscountOn == 'Net Total',
            letterHeadId: h.letterHeadId,
            printHeadingId: h.printHeadingId,
            tcId: h.tcId,
            terms: h.terms,
          )
          ..additionalDiscountPercentage = h.additionalDiscountPercentage
          ..discountAmount = h.discountAmount;
    for (final r
        in await (select(salesInvoiceItem)
              ..where((x) => x.salesInvoiceId.equals(id))
              ..orderBy([(x) => OrderingTerm(expression: x.idx)]))
            .get()) {
      final line = SaleLine(
        id: r.id,
        itemId: r.itemId,
        itemName: r.itemName,
        uomId: r.uomId,
        factor: r.conversionFactor,
        qty: r.qty,
        priceListRate: r.priceListRate,
        discountPercentage: r.discountPercentage,
        discountAmount: r.discountAmount,
        rate: r.rate,
        itemTaxTemplateId: r.itemTaxTemplateId,
        itemTax: itemTaxFromJson(r.itemTaxRate),
        entries: await entriesOf(salesInvoiceType, r.id),
      );
      await reprice(sale, line);
      sale.lines.add(line);
    }
    for (final p in await (select(
      salesInvoicePayment,
    )..where((x) => x.salesInvoiceId.equals(id))).get()) {
      sale.payments[p.modeOfPaymentId] = p.amount;
    }
    return sale;
  }

  /// The register's invoices, newest first (POS-R19).
  Stream<List<SalesInvoiceData>> watchRecentOrders() =>
      (select(salesInvoice)
            ..orderBy([(x) => OrderingTerm.desc(x.id)])
            ..limit(200))
          .watch();

  // ---- Submit (POS-R16, R17) -------------------------------------------------

  Future<List<Tender>> _tenders(Sale sale) async {
    final cash = {
      for (final m in await select(modeOfPayment).get()) m.id: m.type == 'Cash',
    };
    return [
      for (final MapEntry(:key, :value) in sale.payments.entries)
        (amount: value, cash: cash[key] ?? false),
    ];
  }

  String? _inWords(double amount, Formats f) {
    if (f.defaults.disableInWords) return null;
    final c = f.currency;
    if (c == null) return null;
    return moneyInWords(
      amount,
      code: c.code ?? '',
      fraction: c.fraction ?? 'Cent',
      precision: f.system.currencyPrecision,
    );
  }

  /// POS-R16: every check a sale must pass, all reported together. With
  /// [stockOnly], only the stock check (Validate Stock on Save).
  Future<List<RefusedException>> saleProblems(
    Sale sale, {
    bool stockOnly = false,
  }) async {
    final out = <RefusedException>[];
    final posting = toStorage(DateTime.now());
    final f = await formats();
    final floats = f.system.floatPrecision;
    if (!stockOnly) {
      if (await openSession() == null) {
        out.add(const RefusedException(Refusal.noOpenSession));
      }
      if (sale.lines.isEmpty) {
        out.add(const RefusedException(Refusal.emptyCart));
      }
    }
    final facts = await itemFacts(sale.lines.map((l) => l.itemId));
    final items = {
      for (final it in await (select(
        item,
      )..where((i) => i.id.isIn(facts.keys))).get())
        it.id: it,
    };
    final selling = SellingSettings(await readSingle(SellingSettings.doctype));
    final stock = StockSettings(await readSingle(StockSettings.doctype));
    if (!stockOnly) {
      // STK-R3, R6, R14, R23, R27 as for any outgoing line; a sale may also
      // sell items that keep no stock.
      final lines = [
        for (final l in sale.lines)
          EntryLine(
            itemId: l.itemId,
            sWarehouseId: sale.warehouseId,
            qty: l.qty,
            uomId: l.uomId,
            factor: l.factor,
            entries: l.entries,
          ),
      ];
      for (final (row, p) in checkEntryLines(
        StockPurpose.materialIssue,
        lines,
        items: facts,
        usableWarehouses: await usableWarehouses(),
        wholeUoms: await wholeUoms(),
        date: posting.substring(0, 10),
        floatPrecision: floats,
      )) {
        if (p != LineProblem.itemNotStock) out.add(_lineRefusal(row, p));
      }
      final t = totalsOf(sale, saleSettingsOf(f));
      for (final (i, l) in sale.lines.indexed) {
        final it = items[l.itemId];
        if (it == null) continue;
        if (it.isSalesItem != 1) {
          out.add(_lineRefusal(i + 1, LineProblem.notSalesItem));
        }
        if (it.maxDiscount > 0 && l.discountPercentage > it.maxDiscount) {
          out.add(_lineRefusal(i + 1, LineProblem.discountAboveMax));
        }
        if (selling.validateSellingPrice && it.isStockItem == 1) {
          final cost = await balanceAt(l.itemId, sale.warehouseId, posting);
          final perUnit = l.factor == 0 ? 0 : t.lines[i].netRate / l.factor;
          if (perUnit <
              flt(cost.rate, f.system.currencyPrecision, f.rounding)) {
            out.add(_lineRefusal(i + 1, LineProblem.belowValuationRate));
          }
        }
      }
      final paid = settle(
        t.toPay,
        await _tenders(sale),
        precision: f.system.currencyPrecision,
        method: f.rounding,
      );
      if (paid.short) {
        out.add(
          RefusedException(Refusal.paymentShort, null, [t.toPay, paid.paid]),
        );
      }
      if (paid.nonCashOver) {
        out.add(const RefusedException(Refusal.nonCashOverpaid));
      }
    }
    // POS-R16 check 7, STK-R34, R35: enough of each stock item in the sale's
    // warehouse at the posting time.
    final need = <int, double>{};
    for (final l in sale.lines) {
      if (facts[l.itemId]?.stockItem != true) continue;
      need[l.itemId] =
          (need[l.itemId] ?? 0) + stockQty(l.qty, l.factor, floats);
    }
    final wh = await (select(
      warehouse,
    )..where((w) => w.id.equals(sale.warehouseId))).getSingle();
    for (final MapEntry(key: id, value: qty) in need.entries) {
      final fact = facts[id]!;
      final strict = fact.hasBatch || fact.hasSerial;
      if (!strict &&
          (stock.allowNegativeStock || items[id]!.allowNegativeStock == 1)) {
        continue;
      }
      final have = (await balanceAt(id, sale.warehouseId, posting)).qty;
      if (have + 1e-9 < qty) {
        out.add(
          RefusedException(Refusal.itemUnavailable, null, [
            fact.code,
            wh.name,
            have,
            qty,
          ]),
        );
      }
    }
    return out;
  }

  RefusedException _lineRefusal(int row, LineProblem p) =>
      RefusedException(Refusal.lineProblem, null, [row, p]);

  /// POS-R17: saves and submits [sale] in one transaction, and returns its
  /// name. Every POS-R16 problem is reported together ([RefusedAll]).
  Future<String> submitSale(Sale sale) => _keepOnFailure(sale, _submitSale);

  Future<String> _submitSale(Sale sale) => transaction(() async {
    final problems = await saleProblems(sale);
    if (problems.isNotEmpty) throw RefusedAll(problems);
    final id = await _saveSale(sale);
    final session = (await openSession())!;
    final now = DateTime.now();
    final posting = toStorage(now);
    await checkNotFrozen(posting);
    final name = await nextName(await defaultSeries(salesInvoiceType), now);
    final f = await formats();
    final lines =
        await (select(salesInvoiceItem)
              ..where((x) => x.salesInvoiceId.equals(id))
              ..orderBy([(x) => OrderingTerm(expression: x.idx)]))
            .get();
    final facts = await itemFacts(lines.map((l) => l.itemId));
    final ledger = <StockLedgerEntryCompanion>[];
    for (final l in lines) {
      final fact = facts[l.itemId]!;
      if (!fact.stockItem) continue;
      final byBatch = <int?, double>{};
      if (fact.hasBatch || fact.hasSerial) {
        var entries = await _entriesOf(l.id);
        if (entries.isEmpty) {
          // STK-R27: picked now when the setting allows; expired batches
          // are never picked for a sale (STK-R22).
          await fillOutwardEntries(
            salesInvoiceType,
            l.id,
            fact,
            l.itemId,
            l.warehouseId,
            l.stockQty,
            posting,
            allowExpired: false,
          );
          entries = await _entriesOf(l.id);
        }
        await _checkSaleEntries(l, entries, posting);
        if (fact.hasBatch) {
          for (final e in entries) {
            byBatch[e.batchId] = (byBatch[e.batchId] ?? 0) + e.qty;
          }
        }
      }
      if (!fact.hasBatch) byBatch[null] = l.stockQty;
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
            actualQty: -qty,
            qtyAfterTransaction: 0,
            batchId: Value(batch),
          ),
        );
      }
    }
    await (update(salesInvoice)..where((x) => x.id.equals(id))).write(
      SalesInvoiceCompanion(
        name: Value(name),
        docstatus: const Value(1),
        status: const Value('Paid'),
        postingDatetime: Value(posting),
        posOpeningEntryId: Value(session.id),
        modifiedAt: Value(posting),
      ),
    );
    // STK-R32: each serial number goes out at its own cost.
    await customUpdate(
      'UPDATE serial_and_batch_entry SET incoming_rate = COALESCE((SELECT '
      'incoming_rate FROM serial_no WHERE id = serial_no_id), 0) '
      'WHERE voucher_type = ?1 AND voucher_detail_id IN '
      '(SELECT id FROM sales_invoice_item WHERE sales_invoice_id = ?2)',
      variables: [Variable(salesInvoiceType), Variable(id)],
      updates: {serialAndBatchEntry},
    );
    // The ledger engine also writes each line's incoming_rate.
    await postLedger(ledger);
    await _deliverSerials(id, posting);
    await _insertMissingPrices(sale, lines, f);
    return name;
  });

  Future<List<SerialAndBatchEntryData>> _entriesOf(int lineId) =>
      (select(serialAndBatchEntry)..where(
            (x) =>
                x.voucherType.equals(salesInvoiceType) &
                x.voucherDetailId.equals(lineId),
          ))
          .get();

  /// STK-R22, R24: only Available serial numbers in the sale's warehouse,
  /// and no expired batch, can be sold.
  Future<void> _checkSaleEntries(
    SalesInvoiceItemData line,
    List<SerialAndBatchEntryData> entries,
    String posting,
  ) async {
    for (final x in entries) {
      if (x.serialNoId case final id?) {
        final s = await (select(
          serialNo,
        )..where((s) => s.id.equals(id))).getSingle();
        if (s.status != 'Available' || s.warehouseId != line.warehouseId) {
          throw RefusedException(Refusal.serialNotAvailable, s.serialNo);
        }
      }
      if (x.batchId case final id?) {
        final b = await (select(
          batches,
        )..where((b) => b.id.equals(id))).getSingle();
        if (batchStatus(b.expiryDate, posting.substring(0, 10)) ==
            BatchStatus.expired) {
          throw RefusedException(Refusal.expiredBatch, b.batchId);
        }
      }
    }
  }

  /// STK-R24, R26: sold serial numbers are Delivered, with their warranty
  /// running from the sale date.
  Future<void> _deliverSerials(int invoiceId, String posting) async {
    final rows = await customSelect(
      'SELECT e.serial_no_id, i.warranty_period FROM serial_and_batch_entry e '
      'JOIN sales_invoice_item l ON l.id = e.voucher_detail_id '
      'JOIN item i ON i.id = l.item_id '
      'WHERE e.voucher_type = ? AND l.sales_invoice_id = ? '
      'AND e.serial_no_id IS NOT NULL',
      variables: [Variable(salesInvoiceType), Variable(invoiceId)],
    ).get();
    final date = DateTime.parse(posting.substring(0, 10));
    for (final r in rows) {
      final days = r.read<int?>('warranty_period') ?? 0;
      await (update(
        serialNo,
      )..where((s) => s.id.equals(r.read<int>('serial_no_id')))).write(
        SerialNoCompanion(
          status: const Value('Delivered'),
          warehouseId: const Value(null),
          warrantyExpiryDate: Value(
            days > 0
                ? toStorage(date.add(Duration(days: days))).substring(0, 10)
                : null,
          ),
          modifiedAt: Value(posting),
        ),
      );
    }
  }

  /// STK-R11: with Auto insert Price List rate if missing, an item sold with
  /// no Item Price in the sale's list gets one from the rate used, per Stock
  /// UOM, once.
  Future<void> _insertMissingPrices(
    Sale sale,
    List<SalesInvoiceItemData> lines,
    Formats f,
  ) async {
    final stock = StockSettings(await readSingle(StockSettings.doctype));
    if (!stock.autoInsertPriceListRateIfMissing) return;
    for (final l in lines) {
      if (l.rate <= 0) continue;
      final has = await exists(
        'SELECT 1 FROM item_price WHERE item_id = ? AND price_list_id = ?',
        [l.itemId, sale.priceListId],
      );
      if (has) continue;
      final it = await (select(
        item,
      )..where((i) => i.id.equals(l.itemId))).getSingle();
      await saveItemPrice(
        ItemPriceCompanion.insert(
          itemId: l.itemId,
          priceListId: sale.priceListId,
          uomId: Value(it.stockUomId),
          priceListRate: flt(
            l.rate / l.conversionFactor,
            f.system.currencyPrecision,
            f.rounding,
          ),
        ),
      );
    }
  }
}

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../logic/tax_template.dart';
import 'country_info.dart';
import 'refusal.dart';

/// Reads and writes of the Setup pages. Every write runs in one transaction
/// and states its rule; constraint failures become [RefusedException]s.
extension SetupQueries on AppDatabase {
  // ---- Locks -------------------------------------------------------------

  /// SET-R2: true once any document has been submitted.
  Future<bool> anySubmittedDocument() => exists(
    'SELECT 1 FROM sales_invoice WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM stock_entry WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM stock_reconciliation WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM pos_opening_entry WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM pos_closing_entry WHERE docstatus = 1',
  );

  /// True while a POS session is open.
  Future<bool> sessionOpen() =>
      exists("SELECT 1 FROM pos_opening_entry WHERE status = 'Open'");

  /// True when [query], with its `?` [args], returns a row.
  Future<bool> exists(String query, [List<Object> args = const []]) async {
    final row = await customSelect(
      'SELECT EXISTS ($query) AS found',
      variables: [for (final a in args) Variable(a)],
    ).getSingle();
    return row.read<int>('found') == 1;
  }

  // ---- Shared ------------------------------------------------------------

  /// Text for `modified_at` (00-overview 6.6).
  Value<String> get _now => Value(toStorage(DateTime.now()));

  /// Inserts [row], or updates it when its [id] is present, and returns the
  /// id. (An upsert that updates leaves SQLite's last insert rowid stale, so
  /// the known id is returned in that case.)
  Future<int> upsert<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row, [
    Value<int> id = const Value.absent(),
  ]) async {
    final rowid = await refuseOnConstraint(
      () => into(table).insertOnConflictUpdate(row),
    );
    return id.present ? id.value : rowid;
  }

  /// Deletes a master. A referenced one is refused by its foreign keys
  /// ("can be disabled but not deleted", 00-overview 6.2).
  Future<void> deleteMaster(TableInfo table, int id) => transaction(
    () => refuseOnConstraint(() async {
      await customUpdate(
        'DELETE FROM ${table.actualTableName} WHERE id = ?',
        variables: [Variable(id)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      if (table.actualTableName == priceList.actualTableName) {
        await _checkPriceLists();
      }
    }),
  );

  // ---- Currency, Mode of Payment, Tax, Price List --------------------------

  Future<void> saveCurrency(CurrencyCompanion row) =>
      upsert(currency, row.copyWith(modifiedAt: _now));

  /// Adds the Currency record of [country]'s currency unless it exists,
  /// for a Default Currency chosen on Store Profile.
  Future<void> addCurrency(CountryInfo country) =>
      into(currency)
          .insert(country.toCurrency(), mode: InsertMode.insertOrIgnore);

  Future<int> saveModeOfPayment(ModeOfPaymentCompanion row) =>
      upsert(modeOfPayment, row.copyWith(modifiedAt: _now), row.id);

  Future<int> saveTax(TaxCompanion row) =>
      upsert(tax, row.copyWith(modifiedAt: _now), row.id);

  /// SET-R13. Renaming the Default Price List renames it in Selling
  /// Settings too, which keeps it by name.
  Future<int> savePriceList(PriceListCompanion row) => transaction(() async {
    final defaultName = await _defaultPriceListName();
    final old = row.id.present
        ? await (select(
            priceList,
          )..where((p) => p.id.equals(row.id.value))).getSingleOrNull()
        : null;
    final id = await upsert(priceList, row.copyWith(modifiedAt: _now), row.id);
    if (old?.name == defaultName && row.name.present) {
      await writeSingle(SellingSettings.doctype, {
        'selling_price_list': row.name.value,
      });
    }
    await _checkPriceLists();
    return id;
  });

  Future<String> _defaultPriceListName() async =>
      SellingSettings(await readSingle(SellingSettings.doctype))
          .sellingPriceList;

  /// SET-R13: the Default Price List is the Cash Register's, so it exists and
  /// stays enabled (which also keeps at least one list enabled).
  Future<void> _checkPriceLists() async {
    final name = await _defaultPriceListName();
    final list = await (select(
      priceList,
    )..where((p) => p.name.equals(name))).getSingleOrNull();
    if (list?.enabled != 1) {
      throw const RefusedException(Refusal.defaultPriceList);
    }
  }

  // ---- Tax templates -----------------------------------------------------

  /// Saves a Sales Taxes and Charges Template with its rows in `idx` order.
  /// The rows must have passed `validateTaxRows`. Making it the default
  /// clears the old default (SET-R9).
  Future<int> saveSalesTaxesTemplate(
    SalesTaxesTemplateCompanion template,
    List<TaxRow> rows,
  ) => transaction(() async {
    final id = await upsert(
      salesTaxesTemplate,
      template.copyWith(modifiedAt: _now),
      template.id,
    );
    if (template.isDefault.value == 1) {
      await (update(
        salesTaxesTemplate,
      )..where((t) => t.id.equals(id).not())).write(
        SalesTaxesTemplateCompanion(
          isDefault: const Value(0),
          modifiedAt: _now,
        ),
      );
    }
    await (delete(
      salesTaxesTemplateRow,
    )..where((r) => r.templateId.equals(id))).go();
    for (final (i, r) in rows.indexed) {
      await into(salesTaxesTemplateRow).insert(
        SalesTaxesTemplateRowCompanion.insert(
          templateId: id,
          idx: i + 1,
          chargeType: r.chargeType.value,
          taxId: r.taxId!,
          description: Value(r.description),
          rate: Value(r.rate),
          taxAmount: Value(r.taxAmount),
          rowId: Value(r.chargeType.isPreviousRow ? r.rowId : null),
          includedInPrintRate: Value(r.included ? 1 : 0),
        ),
      );
    }
    return id;
  });

  Future<List<TaxRow>> salesTaxesTemplateRows(int templateId) async {
    final rows =
        await (select(salesTaxesTemplateRow)
              ..where((r) => r.templateId.equals(templateId))
              ..orderBy([(r) => OrderingTerm(expression: r.idx)]))
            .get();
    return [
      for (final r in rows)
        TaxRow(
          chargeType: ChargeType.of(r.chargeType),
          taxId: r.taxId,
          description: r.description,
          rate: r.rate,
          taxAmount: r.taxAmount,
          rowId: r.rowId,
          included: r.includedInPrintRate == 1,
        ),
    ];
  }

  Future<List<ItemTaxTemplateRowData>> itemTaxTemplateRows(int templateId) =>
      (select(itemTaxTemplateRow)
            ..where((r) => r.templateId.equals(templateId))
            ..orderBy([(r) => OrderingTerm(expression: r.id)]))
          .get();

  /// Saves an Item Tax Template with its rows (SET-R12).
  Future<int> saveItemTaxTemplate(
    ItemTaxTemplateCompanion template,
    List<ItemTaxTemplateRowCompanion> rows,
  ) => transaction(() async {
    final id = await upsert(
      itemTaxTemplate,
      template.copyWith(modifiedAt: _now),
      template.id,
    );
    await (delete(
      itemTaxTemplateRow,
    )..where((r) => r.templateId.equals(id))).go();
    for (final r in rows) {
      await refuseOnConstraint(
        () => into(
          itemTaxTemplateRow,
        ).insert(r.copyWith(id: const Value.absent(), templateId: Value(id))),
      );
    }
    return id;
  });

  // ---- Naming Series -----------------------------------------------------

  /// Replaces the patterns of [doctype]; the first is the default (SET-R7).
  Future<void> saveNamingSeries(String doctype, List<String> patterns) =>
      transaction(() async {
        await (delete(
          namingSeriesOption,
        )..where((o) => o.doctype.equals(doctype))).go();
        for (final (i, pattern) in patterns.indexed) {
          await refuseOnConstraint(
            () => into(namingSeriesOption).insert(
              NamingSeriesOptionCompanion.insert(
                doctype: doctype,
                pattern: pattern,
                idx: i + 1,
              ),
            ),
          );
        }
      });

  /// The highest counter any document or item name already uses under the
  /// series [key], or 0.
  Future<int> highestUsedNumber(String key) async {
    final like =
        '${key.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
    final names = await customSelect(
      [
        for (final (column, table) in const [
          ('name', 'sales_invoice'),
          ('name', 'stock_entry'),
          ('name', 'stock_reconciliation'),
          ('name', 'pos_opening_entry'),
          ('name', 'pos_closing_entry'),
          ('item_code', 'item'),
        ])
          "SELECT $column AS n FROM $table WHERE $column LIKE ?1 ESCAPE '\\'",
      ].join(' UNION ALL '),
      variables: [Variable(like)],
    ).get();
    var highest = 0;
    for (final row in names) {
      final digits = RegExp(r'^\d+')
          .stringMatch(row.read<String>('n').substring(key.length));
      if (digits != null && int.parse(digits) > highest) {
        highest = int.parse(digits);
      }
    }
    return highest;
  }

  /// "Update Series": the next document under [key] takes [current] + 1.
  /// Setting it below a number already used is refused, because the next
  /// name would collide (SET-R7).
  Future<void> updateSeries(String key, int current) => transaction(() async {
    final used = await highestUsedNumber(key);
    if (current < used) {
      throw RefusedException(Refusal.seriesBelowUsed, '$used');
    }
    await into(series).insertOnConflictUpdate(
      SeriesCompanion.insert(name: Value(key), current: Value(current)),
    );
  });
}

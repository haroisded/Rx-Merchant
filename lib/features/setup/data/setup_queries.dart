import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/numbers/format.dart';
import '../logic/tax_template.dart';
import 'country_info.dart';
import 'refusal.dart';

/// Reads and writes of the Setup pages. Every write runs in one transaction
/// and states its rule; constraint failures become [RefusedException]s.
extension SetupQueries on AppDatabase {
  // ---- Locks -------------------------------------------------------------

  /// SET-R2: true once any document has been submitted.
  Future<bool> anySubmittedDocument() => _exists(
    'SELECT 1 FROM sales_invoice WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM stock_entry WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM stock_reconciliation WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM pos_opening_entry WHERE docstatus = 1 '
    'UNION ALL SELECT 1 FROM pos_closing_entry WHERE docstatus = 1',
  );

  /// An open POS session, for [profileId] or for any profile.
  Future<bool> sessionOpen({int? profileId}) => _exists(
    "SELECT 1 FROM pos_opening_entry WHERE status = 'Open'"
    '${profileId == null ? '' : ' AND pos_profile_id = ?'}',
    [?profileId],
  );

  Future<bool> _exists(String query, [List<Object> args = const []]) async {
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
      await _checkPriceLists();
      await _checkDefaultProfile();
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

  /// SET-R13: at least one list stays enabled.
  Future<int> savePriceList(PriceListCompanion row) => transaction(() async {
    final id = await upsert(priceList, row.copyWith(modifiedAt: _now), row.id);
    await _checkPriceLists();
    return id;
  });

  Future<void> _checkPriceLists() async {
    final enabled = await (select(
      priceList,
    )..where((p) => p.enabled.equals(1))).get();
    final any = await select(priceList).get();
    if (any.isNotEmpty && enabled.isEmpty) {
      throw const RefusedException(Refusal.lastEnabledPriceList);
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

  // ---- POS Profile -------------------------------------------------------

  /// The payment methods and item group ids of POS Profile [id].
  Future<({List<PosProfilePaymentData> payments, Set<int> itemGroupIds})>
  posProfileLines(int id) async => (
    payments: await (select(
      posProfilePayment,
    )..where((p) => p.posProfileId.equals(id))).get(),
    itemGroupIds: {
      for (final g in await (select(
        posProfileItemGroup,
      )..where((g) => g.posProfileId.equals(id))).get())
        g.itemGroupId,
    },
  );

  /// Saves a POS Profile with its payment methods and item groups (SET-R14).
  Future<int> savePosProfile(
    PosProfileCompanion profile,
    List<PosProfilePaymentCompanion> payments,
    Set<int> itemGroupIds,
  ) => transaction(() async {
    if (profile.id case Value(present: true, :final value)
        when await sessionOpen(profileId: value)) {
      throw const RefusedException(Refusal.profileSessionOpen);
    }
    final store = await (select(
      warehouse,
    )..where((w) => w.id.equals(profile.warehouseId.value))).getSingle();
    if (store.isGroup == 1) {
      throw const RefusedException(Refusal.groupWarehouse);
    }
    if (payments.isNotEmpty &&
        payments.where((p) => p.isDefault.value == 1).length != 1) {
      throw const RefusedException(Refusal.oneDefaultPayment);
    }
    await _refuseDisabled(profile, payments);

    final id = await upsert(
      posProfile,
      profile.copyWith(modifiedAt: _now),
      profile.id,
    );
    if (profile.isDefault.value == 1) {
      await (update(posProfile)..where((p) => p.id.equals(id).not())).write(
        PosProfileCompanion(isDefault: const Value(0), modifiedAt: _now),
      );
    }
    await (delete(
      posProfilePayment,
    )..where((p) => p.posProfileId.equals(id))).go();
    for (final p in payments) {
      await refuseOnConstraint(
        () => into(
          posProfilePayment,
        ).insert(p.copyWith(id: const Value.absent(), posProfileId: Value(id))),
      );
    }
    await (delete(
      posProfileItemGroup,
    )..where((g) => g.posProfileId.equals(id))).go();
    for (final groupId in itemGroupIds) {
      await into(posProfileItemGroup).insert(
        PosProfileItemGroupCompanion.insert(
          posProfileId: id,
          itemGroupId: groupId,
        ),
      );
    }
    await _checkDefaultProfile();
    return id;
  });

  /// SET-R8, R13, R9: disabled masters cannot be chosen.
  Future<void> _refuseDisabled(
    PosProfileCompanion profile,
    List<PosProfilePaymentCompanion> payments,
  ) async {
    final list = await (select(
      priceList,
    )..where((p) => p.id.equals(profile.priceListId.value))).getSingle();
    final templateId = profile.taxesTemplateId.present
        ? profile.taxesTemplateId.value
        : null;
    final template = templateId == null
        ? null
        : await (select(
            salesTaxesTemplate,
          )..where((t) => t.id.equals(templateId))).getSingle();
    final modes =
        await (select(modeOfPayment)..where(
              (m) => m.id.isIn(payments.map((p) => p.modeOfPaymentId.value)),
            ))
            .get();
    if (list.enabled == 0 ||
        template?.disabled == 1 ||
        modes.any((m) => m.enabled == 0)) {
      throw const RefusedException(Refusal.disabledChoice);
    }
  }

  /// SET-R14: while any profile is enabled, exactly one enabled profile is
  /// the default.
  Future<void> _checkDefaultProfile() async {
    final enabled = await (select(
      posProfile,
    )..where((p) => p.disabled.equals(0))).get();
    if (enabled.isNotEmpty &&
        enabled.where((p) => p.isDefault == 1).length != 1) {
      throw const RefusedException(Refusal.oneDefaultProfile);
    }
  }

  /// Deleting a profile is refused while its session is open.
  Future<void> deletePosProfile(int id) async {
    if (await sessionOpen(profileId: id)) {
      throw const RefusedException(Refusal.profileSessionOpen);
    }
    await deleteMaster(posProfile, id);
  }

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

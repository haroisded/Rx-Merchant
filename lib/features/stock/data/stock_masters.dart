import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/refusal.dart';
import '../../setup/data/setup_queries.dart';
import '../logic/barcode.dart';
import '../logic/stock_documents.dart';
import '../logic/stock_rules.dart';
import '../logic/variants.dart';
import 'stock_entry_db.dart';

/// The child tables of an item form (02-stock section 5, Item form).
typedef ItemTables = ({
  List<ItemBarcodeCompanion> barcodes,
  List<ItemUomCompanion> uoms,
  List<ItemReorderCompanion> reorder,
  List<ItemTaxCompanion> taxes,

  /// A template's attributes, in order (STK-R15).
  List<int> attributes,
});

/// What a new item's form adds: Opening Stock at Valuation Rate (STK-R5).
typedef OpeningStock = ({double qty, double rate});

/// Reads and writes of the stock masters (STK-R1 to R19).
extension StockMasters on AppDatabase {
  Value<String> get _now => Value(toStorage(DateTime.now()));

  Future<bool> hasLedger(int itemId) =>
      exists('SELECT 1 FROM stock_ledger_entry WHERE item_id = ?', [itemId]);

  // ---- Warehouse (STK-R1) ------------------------------------------------

  Future<String> _defaultWarehouseName() async =>
      StockSettings(await readSingle(StockSettings.doctype)).defaultWarehouse;

  /// STK-R1: a warehouse with ledger entries cannot become a group; the
  /// Default Warehouse stays an enabled non-group, and a rename of it is
  /// written into Stock Settings.
  Future<int> saveWarehouse(WarehouseCompanion row) => transaction(() async {
    final old = row.id.present
        ? await (select(
            warehouse,
          )..where((w) => w.id.equals(row.id.value))).getSingle()
        : null;
    if (old != null &&
        old.isGroup == 0 &&
        row.isGroup.value == 1 &&
        await exists(
          'SELECT 1 FROM stock_ledger_entry WHERE warehouse_id = ?',
          [old.id],
        )) {
      throw const RefusedException(Refusal.warehouseHasLedger);
    }
    final id = await upsert(warehouse, row.copyWith(modifiedAt: _now), row.id);
    if (old != null &&
        old.name == await _defaultWarehouseName() &&
        row.name.present) {
      await writeSingle(StockSettings.doctype, {
        'default_warehouse': row.name.value,
      });
    }
    await _checkDefaultWarehouse();
    return id;
  });

  Future<void> deleteWarehouse(int id) => transaction(() async {
    await deleteMaster(warehouse, id);
    await _checkDefaultWarehouse();
  });

  Future<void> _checkDefaultWarehouse() async {
    final name = await _defaultWarehouseName();
    final w = await (select(
      warehouse,
    )..where((w) => w.name.equals(name))).getSingleOrNull();
    if (w == null || w.isGroup == 1 || w.disabled == 1) {
      throw const RefusedException(Refusal.defaultWarehouse);
    }
  }

  // ---- Simple masters ----------------------------------------------------

  Future<int> saveItemGroup(ItemGroupCompanion row) =>
      upsert(itemGroup, row.copyWith(modifiedAt: _now), row.id);

  Future<int> saveUom(UomCompanion row) =>
      upsert(uom, row.copyWith(modifiedAt: _now), row.id);

  Future<int> saveBrand(BrandCompanion row) =>
      upsert(brand, row.copyWith(modifiedAt: _now), row.id);

  /// STK-R15: an attribute with its text values, or a numeric range.
  Future<int> saveItemAttribute(
    ItemAttributeCompanion row,
    List<ItemAttributeValueCompanion> values,
  ) => transaction(() async {
    final id = await upsert(
      itemAttribute,
      row.copyWith(modifiedAt: _now),
      row.id,
    );
    await (delete(
      itemAttributeValue,
    )..where((v) => v.attributeId.equals(id))).go();
    for (final v in values) {
      await refuseOnConstraint(
        () => into(
          itemAttributeValue,
        ).insert(v.copyWith(id: const Value.absent(), attributeId: Value(id))),
      );
    }
    return id;
  });

  /// A serial number made by hand is Inactive until stock brings it in
  /// (STK-R24); only its warranty and batch are edited here.
  Future<int> saveSerialNo(SerialNoCompanion row) => upsert(
    serialNo,
    row.copyWith(
      modifiedAt: _now,
      status: const Value.absent(),
      warehouseId: const Value.absent(),
    ),
    row.id,
  );

  // ---- Item --------------------------------------------------------------

  /// Saves an item with its child tables (STK-R4 to R9, R14, R17). A new
  /// item's Standard Selling Rate becomes an Item Price and its Opening
  /// Stock a submitted Material Receipt (STK-R5), in the same transaction.
  Future<int> saveItem(
    ItemCompanion row,
    ItemTables tables, {
    OpeningStock? opening,
  }) => transaction(() async {
    final settings = StockSettings(await readSingle(StockSettings.doctype));
    var data = row.copyWith(modifiedAt: _now);
    final old = row.id.present
        ? await (select(
            item,
          )..where((i) => i.id.equals(row.id.value))).getSingle()
        : null;

    // STK-R4: with Naming Series the code is generated on save.
    if (old == null &&
        settings.itemNamingBy == 'Naming Series' &&
        (!row.itemCode.present || row.itemCode.value.isEmpty)) {
      data = data.copyWith(
        itemCode: Value(
          await nextName(await defaultSeries('Item'), DateTime.now()),
        ),
      );
    }

    if (old != null) await _checkItemChange(old, data, tables);
    await _checkBarcodes(old?.id, tables.barcodes);
    final id = await upsert(item, data, row.id);
    await _writeTables(id, tables, keepUsedUnits: false);

    if (old == null) {
      await _openItem(id, data, settings, opening);
    } else if (data.hasVariants.present
        ? data.hasVariants.value == 1
        : old.hasVariants == 1) {
      await _updateVariants(id, tables);
    }
    return id;
  });

  /// STK-R7, R9, R14 on an existing item.
  Future<void> _checkItemChange(
    ItemData old,
    ItemCompanion data,
    ItemTables tables,
  ) async {
    final stocked = await hasLedger(old.id);
    bool changed<T>(Value<T> v, T was) => v.present && v.value != was;
    if (stocked &&
        (changed(data.isStockItem, old.isStockItem) ||
            changed(data.hasBatchNo, old.hasBatchNo) ||
            changed(data.hasSerialNo, old.hasSerialNo) ||
            changed(data.valuationMethod, old.valuationMethod) ||
            changed(data.stockUomId, old.stockUomId))) {
      throw const RefusedException(Refusal.frozenField);
    }
    if (changed(data.hasVariants, old.hasVariants) &&
        (stocked ||
            await exists('SELECT 1 FROM item WHERE variant_of_id = ?', [
              old.id,
            ]))) {
      throw const RefusedException(Refusal.hasVariantsLocked);
    }
    // STK-R9: a unit on any document keeps its factor and stays.
    final used = await customSelect(
      'SELECT u.id, u.name, iu.conversion_factor FROM uom u '
      'JOIN item_uom iu ON iu.uom_id = u.id AND iu.item_id = ?1 '
      'WHERE u.id IN (SELECT uom_id FROM stock_entry_item WHERE item_id = ?1 '
      'UNION SELECT uom_id FROM sales_invoice_item WHERE item_id = ?1)',
      variables: [Variable(old.id)],
    ).get();
    for (final u in used) {
      final kept = tables.uoms.any(
        (n) =>
            n.uomId.value == u.read<int>('id') &&
            n.conversionFactor.value == u.read<double>('conversion_factor'),
      );
      if (!kept) {
        throw RefusedException(Refusal.unitInUse, u.read<String>('name'));
      }
    }
  }

  /// STK-R8: valid for its type, and owned by no other item.
  Future<void> _checkBarcodes(
    int? itemId,
    List<ItemBarcodeCompanion> barcodes,
  ) async {
    for (final b in barcodes) {
      final code = b.barcode.value;
      if (!validBarcode(b.barcodeType.value, code)) {
        throw RefusedException(Refusal.badBarcode, code);
      }
      final owner = await customSelect(
        'SELECT i.item_code FROM item_barcode b JOIN item i ON i.id = b.item_id '
        'WHERE b.barcode = ? AND b.item_id IS NOT ?',
        variables: [Variable(code), Variable(itemId)],
      ).getSingleOrNull();
      if (owner != null) {
        throw RefusedException(
          Refusal.barcodeTaken,
          owner.read<String>('item_code'),
        );
      }
    }
  }

  /// Replaces the child tables of item [id]. On a variant updated from its
  /// template, units already used on its documents are kept.
  Future<void> _writeTables(
    int id,
    ItemTables t, {
    required bool keepUsedUnits,
  }) async {
    Future<void> replace<T extends Table, D>(
      TableInfo<T, D> table,
      List<Insertable<D>> rows,
    ) async {
      await customUpdate(
        'DELETE FROM ${table.actualTableName} WHERE item_id = ?'
        '${keepUsedUnits && table.actualTableName == 'item_uom' ? ' AND uom_id NOT IN (SELECT uom_id FROM stock_entry_item WHERE item_id = ?1 UNION SELECT uom_id FROM sales_invoice_item WHERE item_id = ?1)' : ''}',
        variables: [Variable(id)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      for (final r in rows) {
        await refuseOnConstraint(
          () => into(table).insert(r, mode: InsertMode.insertOrIgnore),
        );
      }
    }

    if (!keepUsedUnits) {
      await replace(itemBarcode, [
        for (final b in t.barcodes)
          b.copyWith(id: const Value.absent(), itemId: Value(id)),
      ]);
      await replace(itemReorder, [
        for (final r in t.reorder)
          r.copyWith(id: const Value.absent(), itemId: Value(id)),
      ]);
    }
    await replace(itemUom, [
      for (final u in t.uoms) u.copyWith(itemId: Value(id)),
    ]);
    await replace(itemTax, [
      for (final x in t.taxes)
        x.copyWith(id: const Value.absent(), itemId: Value(id)),
    ]);
    if (!keepUsedUnits) {
      final values = {
        for (final v in await (select(
          itemVariantAttribute,
        )..where((v) => v.itemId.equals(id))).get())
          v.attributeId: v.attributeValue,
      };
      await replace(itemVariantAttribute, [
        for (final a in t.attributes)
          ItemVariantAttributeCompanion.insert(
            itemId: id,
            attributeId: a,
            attributeValue: Value(values[a]),
          ),
      ]);
    }
  }

  /// STK-R5 for a new item.
  Future<void> _openItem(
    int id,
    ItemCompanion data,
    StockSettings settings,
    OpeningStock? opening,
  ) async {
    final it = await (select(item)..where((i) => i.id.equals(id))).getSingle();
    if (it.standardRate > 0 && it.hasVariants == 0) {
      final selling = SellingSettings(
        await readSingle(SellingSettings.doctype),
      );
      final list =
          await (select(priceList)
                ..where((p) => p.name.equals(selling.sellingPriceList)))
              .getSingleOrNull();
      if (list != null) {
        await into(itemPrice).insert(
          ItemPriceCompanion.insert(
            itemId: id,
            priceListId: list.id,
            priceListRate: it.standardRate,
          ),
        );
      }
    }
    if (opening == null ||
        opening.qty == 0 ||
        it.isStockItem == 0 ||
        it.hasBatchNo == 1 ||
        it.hasSerialNo == 1 ||
        it.hasVariants == 1) {
      return;
    }
    final warehouseId =
        it.defaultWarehouseId ??
        await (select(warehouse)
              ..where((w) => w.name.equals(settings.defaultWarehouse)))
            .map((w) => w.id)
            .getSingle();
    final now = toStorage(DateTime.now());
    final entry = await saveStockEntry(
      StockEntryCompanion.insert(
        purpose: StockPurpose.materialReceipt.value,
        postingDatetime: now,
        toWarehouseId: Value(warehouseId),
        isOpening: const Value(1),
      ),
      [
        EntryLine(
          itemId: id,
          tWarehouseId: warehouseId,
          qty: opening.qty,
          uomId: it.stockUomId,
          basicRate: opening.rate,
        ),
      ],
      const [],
    );
    await submitStockEntry(entry);
  }

  // ---- Variants (STK-R14 to R17) -----------------------------------------

  /// STK-R17: saving a template copies its shared fields, units and taxes to
  /// every variant; frozen fields are skipped on variants with stock.
  Future<void> _updateVariants(int templateId, ItemTables tables) async {
    final t = await (select(
      item,
    )..where((i) => i.id.equals(templateId))).getSingle();
    final variants = await (select(
      item,
    )..where((i) => i.variantOfId.equals(templateId))).get();
    for (final v in variants) {
      final stocked = await hasLedger(v.id);
      await (update(item)..where((i) => i.id.equals(v.id))).write(
        ItemCompanion(
          itemGroupId: Value(t.itemGroupId),
          brandId: Value(t.brandId),
          description: Value(t.description),
          isSalesItem: Value(t.isSalesItem),
          salesUomId: Value(t.salesUomId),
          maxDiscount: Value(t.maxDiscount),
          modifiedAt: _now,
          stockUomId: stocked ? const Value.absent() : Value(t.stockUomId),
          isStockItem: stocked ? const Value.absent() : Value(t.isStockItem),
          valuationMethod: stocked
              ? const Value.absent()
              : Value(t.valuationMethod),
          hasBatchNo: stocked ? const Value.absent() : Value(t.hasBatchNo),
          hasSerialNo: stocked ? const Value.absent() : Value(t.hasSerialNo),
        ),
      );
      await _writeTables(v.id, tables, keepUsedUnits: true);
    }
  }

  /// STK-R16: creates one variant of [templateId] per combination, skipping
  /// those that exist. Returns how many were created.
  Future<int> createVariants(
    int templateId,
    List<List<AttributeValue>> combos,
  ) => transaction(() async {
    final t = await (select(
      item,
    )..where((i) => i.id.equals(templateId))).getSingle();
    String key(Iterable<(int, String)> pairs) =>
        (pairs.map((p) => '${p.$1}=${p.$2}').toList()..sort()).join('|');
    final existing = <String>{};
    final rows = await customSelect(
      'SELECT a.item_id, a.attribute_id, a.attribute_value '
      'FROM item_variant_attribute a JOIN item i ON i.id = a.item_id '
      'WHERE i.variant_of_id = ?',
      variables: [Variable(templateId)],
    ).get();
    final byItem = <int, List<(int, String)>>{};
    for (final r in rows) {
      (byItem[r.read<int>('item_id')] ??= []).add((
        r.read<int>('attribute_id'),
        r.read<String?>('attribute_value') ?? '',
      ));
    }
    existing.addAll(byItem.values.map(key));
    final uoms = await (select(
      itemUom,
    )..where((u) => u.itemId.equals(templateId))).get();
    final taxes = await (select(
      itemTax,
    )..where((x) => x.itemId.equals(templateId))).get();

    var created = 0;
    for (final combo in combos) {
      if (!existing.add(key(combo.map((v) => (v.attributeId, v.value))))) {
        continue;
      }
      final id = await refuseOnConstraint(
        () => into(item).insert(
          t
              .toCompanion(false)
              .copyWith(
                id: const Value.absent(),
                createdAt: const Value.absent(),
                modifiedAt: _now,
                itemCode: Value(variantCode(t.itemCode, combo)),
                itemName: Value(variantCode(t.itemName, combo)),
                hasVariants: const Value(0),
                variantOfId: Value(templateId),
                image: const Value(null),
              ),
        ),
      );
      for (final v in combo) {
        await into(itemVariantAttribute).insert(
          ItemVariantAttributeCompanion.insert(
            itemId: id,
            attributeId: v.attributeId,
            attributeValue: Value(v.value),
          ),
        );
      }
      for (final u in uoms) {
        await into(itemUom).insert(u.copyWith(itemId: id));
      }
      for (final x in taxes) {
        await into(itemTax).insert(
          x
              .toCompanion(false)
              .copyWith(id: const Value.absent(), itemId: Value(id)),
        );
      }
      created++;
    }
    return created;
  });

  // ---- Item Price (STK-R10) ----------------------------------------------

  /// A template has no price (STK-R14); prices with the same item, price
  /// list, unit and batch must not overlap in validity. A price for the
  /// Stock UOM is stored with no unit.
  Future<int> saveItemPrice(ItemPriceCompanion row) => transaction(() async {
    final it = await (select(
      item,
    )..where((i) => i.id.equals(row.itemId.value))).getSingle();
    if (it.hasVariants == 1) {
      throw RefusedException(Refusal.template, it.itemCode);
    }
    final unit = row.uomId.value == it.stockUomId ? null : row.uomId.value;
    final data = row.copyWith(uomId: Value(unit), modifiedAt: _now);
    final others =
        await (select(itemPrice)..where(
              (p) =>
                  p.itemId.equals(it.id) &
                  p.priceListId.equals(row.priceListId.value) &
                  (unit == null ? p.uomId.isNull() : p.uomId.equals(unit)) &
                  (row.batchId.value == null
                      ? p.batchId.isNull()
                      : p.batchId.equals(row.batchId.value!)) &
                  (row.id.present
                      ? p.id.equals(row.id.value).not()
                      : const Constant(true)),
            ))
            .get();
    if (others.any(
      (p) => validityOverlaps(
        p.validFrom,
        p.validUpto,
        data.validFrom.value,
        data.validUpto.value,
      ),
    )) {
      throw const RefusedException(Refusal.overlappingPrice);
    }
    return upsert(itemPrice, data, row.id);
  });

  // ---- Lookups the Cash Register uses ------------------------------------

  /// STK-R10: the price of [itemId] in [uomId] on [date] (`YYYY-MM-DD`) from
  /// [priceListId] (default: Selling Settings' Default Price List), and the
  /// unit it was stored for. With "Use prices from Default Price List as
  /// fallback" on, a list without a price falls back to the default list.
  Future<({double rate, int storedUomId})?> priceFor(
    int itemId,
    int uomId,
    String date, {
    int? priceListId,
    int? batchId,
  }) async {
    final selling = SellingSettings(await readSingle(SellingSettings.doctype));
    final fallback = await (select(
      priceList,
    )..where((p) => p.name.equals(selling.sellingPriceList))).getSingleOrNull();
    final list = priceListId == null
        ? fallback
        : await (select(
            priceList,
          )..where((p) => p.id.equals(priceListId))).getSingleOrNull();
    final it = await (select(
      item,
    )..where((i) => i.id.equals(itemId))).getSingle();
    final factor = uomId == it.stockUomId
        ? 1.0
        : (await (select(itemUom)..where(
                        (u) => u.itemId.equals(itemId) & u.uomId.equals(uomId),
                      ))
                      .getSingleOrNull())
                  ?.conversionFactor ??
              1.0;
    Future<({double rate, int storedUomId})?> on(PriceListData? l) async {
      if (l == null) return null;
      final rows =
          await (select(itemPrice)..where(
                (p) => p.itemId.equals(itemId) & p.priceListId.equals(l.id),
              ))
              .get();
      return pickPrice(
        [
          for (final p in rows)
            (
              uomId: p.uomId,
              rate: p.priceListRate,
              validFrom: p.validFrom,
              validUpto: p.validUpto,
              batchId: p.batchId,
            ),
        ],
        uomId: uomId,
        stockUomId: it.stockUomId,
        factor: factor,
        priceNotUomDependent: l.priceNotUomDependent == 1,
        date: date,
        batchId: batchId,
      );
    }

    return await on(list) ??
        (selling.fallbackToDefaultPriceList && fallback?.id != list?.id
            ? await on(fallback)
            : null);
  }

  /// STK-R13: the Item Tax Template of [itemId] on [date]: the item's own,
  /// else its Item Group's, else up the group tree.
  Future<int?> itemTaxTemplateOf(int itemId, String date) async {
    final it = await (select(
      item,
    )..where((i) => i.id.equals(itemId))).getSingle();
    final rows = await (select(
      itemTax,
    )..where((x) => x.itemId.equals(itemId))).get();
    final groups = <int?>[];
    for (int? g = it.itemGroupId; g != null;) {
      final group = await (select(
        itemGroup,
      )..where((x) => x.id.equals(g!))).getSingle();
      groups.add(group.itemTaxTemplateId);
      g = group.parentId;
    }
    return itemTaxTemplateFor(
      [
        for (final r in rows)
          (templateId: r.itemTaxTemplateId, validFrom: r.validFrom),
      ],
      groups,
      date,
    );
  }
}

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../logic/data_import.dart';

/// One line of the import log: the spreadsheet row and the record it wrote.
typedef ImportLogLine = ({int row, String name, bool created});

extension DataImportDb on AppDatabase {
  Future<Set<String>> _names(String table, String column) async => {
    for (final r in await customSelect('SELECT $column AS n FROM $table').get())
      r.read<String>('n'),
  };

  Future<Map<String, int>> _ids(String table, String column) async => {
    for (final r in await customSelect(
      'SELECT $column AS n, id FROM $table',
    ).get())
      r.read<String>('n'): r.read<int>('id'),
  };

  /// The names an import is validated against (SET-R16).
  Future<ImportLookups> importLookups() async => ImportLookups(
    items: await _names('item', 'item_code'),
    itemGroups: await _names('item_group', 'name'),
    uoms: await _names('uom', 'name'),
    brands: await _names('brand', 'name'),
    priceLists: await _names('price_list', 'name'),
    itemTaxTemplates: await _names('item_tax_template', 'title'),
    barcodes: {
      for (final r in await customSelect(
        'SELECT b.barcode, i.item_code FROM item_barcode b '
        'JOIN item i ON i.id = b.item_id',
      ).get())
        r.read<String>('barcode'): r.read<String>('item_code'),
    },
    prices: await _prices(),
  );

  Future<Map<String, List<({String? from, String? upto})>>> _prices() async {
    final out = <String, List<({String? from, String? upto})>>{};
    final rows = await customSelect(
      "SELECT i.item_code, p.name AS price_list, COALESCE(u.name, '') AS uom, "
      'ip.valid_from, ip.valid_upto FROM item_price ip '
      'JOIN item i ON i.id = ip.item_id '
      'JOIN price_list p ON p.id = ip.price_list_id '
      'LEFT JOIN uom u ON u.id = ip.uom_id',
    ).get();
    for (final r in rows) {
      final key = priceKey(
        r.read<String>('item_code'),
        r.read<String>('price_list'),
        r.read<String>('uom'),
      );
      (out[key] ??= []).add((
        from: r.read<String?>('valid_from'),
        upto: r.read<String?>('valid_upto'),
      ));
    }
    return out;
  }

  /// Writes [rows], which passed `validateImport`, in one transaction
  /// (SET-R16 step 5) and lists what was created or updated.
  Future<List<ImportLogLine>> runImport(
    ImportRecordType type,
    ImportType importType,
    List<Map<String, String>> rows,
  ) => transaction(() async {
    final items = await _ids('item', 'item_code');
    final groups = await _ids('item_group', 'name');
    final uoms = await _ids('uom', 'name');
    final brands = await _ids('brand', 'name');
    final lists = await _ids('price_list', 'name');
    final templates = await _ids('item_tax_template', 'title');
    final selling = SellingSettings(await readSingle(SellingSettings.doctype));
    final now = Value(toStorage(DateTime.now()));
    final insert = importType == ImportType.insert;
    final log = <ImportLogLine>[];

    for (final (i, r) in rows.indexed) {
      String? cell(String c) => (r[c]?.isEmpty ?? true) ? null : r[c];
      Value<double> number(String c) =>
          Value.absentIfNull(cell(c) == null ? null : double.parse(cell(c)!));
      Value<int> flag(String c) =>
          Value.absentIfNull(cell(c) == null ? null : int.parse(cell(c)!));
      Value<int?> link(Map<String, int> ids, String c) =>
          cell(c) == null ? const Value.absent() : Value(ids[cell(c)]);

      switch (type) {
        case ImportRecordType.item:
          final code = cell(Col.itemCode)!;
          final fields = ItemCompanion(
            itemName: Value.absentIfNull(
              cell(Col.itemName) ?? (insert ? code : null),
            ),
            itemGroupId: Value.absentIfNull(groups[cell(Col.itemGroup)]),
            stockUomId: Value.absentIfNull(uoms[cell(Col.stockUom)]),
            isStockItem: flag(Col.maintainStock),
            isSalesItem: flag(Col.isSalesItem),
            standardRate: number(Col.standardRate),
            valuationRate: number(Col.valuationRate),
            brandId: link(brands, Col.brand),
            description: Value.absentIfNull(cell(Col.description)),
            maxDiscount: number(Col.maxDiscount),
            modifiedAt: now,
          );
          final int id;
          if (insert) {
            id = await into(item)
                .insert(fields.copyWith(itemCode: Value(code)));
            items[code] = id;
            // STK-R5: a Standard Selling Rate given on create becomes an
            // Item Price in the default price list.
            final rate = fields.standardRate.present
                ? fields.standardRate.value
                : 0.0;
            final listId = lists[selling.sellingPriceList];
            if (rate > 0 && listId != null) {
              await into(itemPrice).insert(
                ItemPriceCompanion.insert(
                  itemId: id,
                  priceListId: listId,
                  priceListRate: rate,
                ),
              );
            }
          } else {
            id = items[code]!;
            await (update(item)..where((t) => t.id.equals(id))).write(fields);
          }
          if (cell(Col.barcode) case final barcode?) {
            await into(itemBarcode).insert(
              ItemBarcodeCompanion.insert(itemId: id, barcode: barcode),
              mode: InsertMode.insertOrIgnore,
            );
          }
          if (cell(Col.itemTaxTemplate) case final title?) {
            await (delete(
              itemTax,
            )..where((t) => t.itemId.equals(id) & t.validFrom.isNull())).go();
            await into(itemTax).insert(
              ItemTaxCompanion.insert(
                itemId: id,
                itemTaxTemplateId: templates[title]!,
              ),
            );
          }
          log.add((row: i + 2, name: code, created: insert));

        case ImportRecordType.itemPrice:
          final itemId = items[cell(Col.itemCode)]!;
          final listId = lists[cell(Col.priceList)]!;
          final uomId = uoms[cell(Col.uom)];
          final from = cell(Col.validFrom);
          final fields = ItemPriceCompanion(
            uomId: Value(uomId),
            priceListRate: number(Col.rate),
            validFrom: Value(from),
            validUpto: Value(cell(Col.validUpto)),
            modifiedAt: now,
          );
          if (insert) {
            await into(itemPrice).insert(
              fields.copyWith(
                itemId: Value(itemId),
                priceListId: Value(listId),
              ),
            );
          } else {
            await (update(itemPrice)..where(
                  (p) =>
                      p.itemId.equals(itemId) &
                      p.priceListId.equals(listId) &
                      (uomId == null
                          ? p.uomId.isNull()
                          : p.uomId.equals(uomId)) &
                      (from == null
                          ? p.validFrom.isNull()
                          : p.validFrom.equals(from)),
                ))
                .write(fields);
          }
          log.add((row: i + 2, name: cell(Col.itemCode)!, created: insert));

        case ImportRecordType.itemBarcode:
          final barcode = cell(Col.barcode)!;
          final fields = ItemBarcodeCompanion(
            itemId: Value(items[cell(Col.itemCode)]!),
            barcodeType: Value(cell(Col.barcodeType)),
            uomId: Value(uoms[cell(Col.uom)]),
          );
          if (insert) {
            await into(itemBarcode)
                .insert(fields.copyWith(barcode: Value(barcode)));
          } else {
            await (update(
              itemBarcode,
            )..where((b) => b.barcode.equals(barcode))).write(fields);
          }
          log.add((row: i + 2, name: barcode, created: insert));
      }
    }
    return log;
  });

  /// Data Export: the template header and one row per record, so an export
  /// can be edited and imported back with Update Existing Records.
  Future<List<List<String>>> exportRows(ImportRecordType type) async {
    // One expression per template column, in column order.
    final (columns, from) = switch (type) {
      ImportRecordType.item => (
        [
          'i.item_code',
          'i.item_name',
          'g.name',
          'u.name',
          'i.is_stock_item', //
          'i.is_sales_item', 'i.standard_rate', 'i.valuation_rate',
          '(SELECT barcode FROM item_barcode WHERE item_id = i.id ORDER BY id LIMIT 1)',
          'b.name', 'i.description', 'i.max_discount',
          '(SELECT t.title FROM item_tax x JOIN item_tax_template t '
              'ON t.id = x.item_tax_template_id WHERE x.item_id = i.id '
              'ORDER BY x.valid_from DESC LIMIT 1)',
        ],
        'item i JOIN item_group g ON g.id = i.item_group_id '
            'JOIN uom u ON u.id = i.stock_uom_id '
            'LEFT JOIN brand b ON b.id = i.brand_id ORDER BY i.item_code',
      ),
      ImportRecordType.itemPrice => (
        [
          'i.item_code', 'p.name', 'u.name', 'ip.price_list_rate', //
          'ip.valid_from', 'ip.valid_upto',
        ],
        'item_price ip JOIN item i ON i.id = ip.item_id '
            'JOIN price_list p ON p.id = ip.price_list_id '
            'LEFT JOIN uom u ON u.id = ip.uom_id ORDER BY i.item_code, ip.id',
      ),
      ImportRecordType.itemBarcode => (
        ['i.item_code', 'b.barcode', 'b.barcode_type', 'u.name'],
        'item_barcode b JOIN item i ON i.id = b.item_id '
            'LEFT JOIN uom u ON u.id = b.uom_id ORDER BY i.item_code, b.id',
      ),
    };
    final selected = [for (final (i, c) in columns.indexed) '$c AS c$i']
        .join(', ');
    final rows = await customSelect('SELECT $selected FROM $from').get();
    return [
      [for (final c in type.columns) c.label],
      for (final r in rows)
        [for (var i = 0; i < columns.length; i++) _cell(r.data['c$i'])],
    ];
  }
}

/// 10.0 is written as 10, so an exported file reads like a typed one.
String _cell(Object? v) => switch (v) {
  null => '',
  final double d when d == d.truncateToDouble() => '${d.toInt()}',
  _ => '$v',
};

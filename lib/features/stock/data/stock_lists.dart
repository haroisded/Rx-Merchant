import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

// The lists the stock screens show (00-overview 5: queries live in data/).

/// One line of the Item list: no image bytes, total stock and the selling
/// price of the Stock UOM on the Default Price List today.
typedef ItemRow = ({
  int id,
  String code,
  String name,
  int groupId,
  int stockUomId,
  int? variantOf,
  bool disabled,
  bool template,
  bool stockItem,
  bool hasBatch,
  bool hasSerial,
  bool hasImage,
  double qty,
  double? price,
  String barcodes,
});

typedef PriceRow = ({
  ItemPriceData price,
  String item,
  String list,
  String uom,
});
typedef BatchListRow = ({BatchRow batch, String item});
typedef SerialListRow = ({SerialNoData serial, String item, String? warehouse});

/// A chip above the item form: stock in a warehouse, or an Item Price.
typedef StripChip = ({bool stock, int? priceId, String label, double value});

extension StockLists on AppDatabase {
  /// Every item, with [listName]'s price valid on [today].
  Stream<List<ItemRow>> watchItemRows(String listName, String today) =>
      customSelect(
        'SELECT i.id, i.item_code, i.item_name, i.item_group_id, i.stock_uom_id, '
        'i.variant_of_id, i.disabled, i.has_variants, i.is_stock_item, '
        'i.has_batch_no, i.has_serial_no, i.image IS NOT NULL AS has_image, '
        '(SELECT COALESCE(SUM(actual_qty), 0) FROM bin WHERE item_id = i.id) AS qty, '
        '(SELECT ip.price_list_rate FROM item_price ip JOIN price_list p '
        'ON p.id = ip.price_list_id WHERE ip.item_id = i.id AND p.name = ?1 '
        'AND ip.uom_id IS NULL AND ip.batch_id IS NULL '
        'AND (ip.valid_from IS NULL OR ip.valid_from <= ?2) '
        'AND (ip.valid_upto IS NULL OR ip.valid_upto >= ?2) '
        'ORDER BY ip.valid_from DESC LIMIT 1) AS price, '
        "(SELECT group_concat(barcode, ' ') FROM item_barcode WHERE item_id = i.id) AS barcodes "
        'FROM item i ORDER BY i.item_name',
        variables: [Variable(listName), Variable(today)],
        readsFrom: {item, bin, itemPrice, itemBarcode, priceList},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (
              id: r.read<int>('id'),
              code: r.read<String>('item_code'),
              name: r.read<String>('item_name'),
              groupId: r.read<int>('item_group_id'),
              stockUomId: r.read<int>('stock_uom_id'),
              variantOf: r.read<int?>('variant_of_id'),
              disabled: r.read<int>('disabled') == 1,
              template: r.read<int>('has_variants') == 1,
              stockItem: r.read<int>('is_stock_item') == 1,
              hasBatch: r.read<int>('has_batch_no') == 1,
              hasSerial: r.read<int>('has_serial_no') == 1,
              hasImage: r.read<int>('has_image') == 1,
              qty: r.read<double>('qty'),
              price: r.read<double?>('price'),
              barcodes: r.read<String?>('barcodes') ?? '',
            ),
        ],
      );

  Stream<List<PriceRow>> watchItemPrices() =>
      customSelect(
        'SELECT ip.*, i.item_code AS item, p.name AS list, '
        'COALESCE(u.name, su.name) AS unit FROM item_price ip '
        'JOIN item i ON i.id = ip.item_id JOIN price_list p ON p.id = ip.price_list_id '
        'LEFT JOIN uom u ON u.id = ip.uom_id JOIN uom su ON su.id = i.stock_uom_id '
        'ORDER BY i.item_code, p.name',
        readsFrom: {itemPrice, item, priceList, uom},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (
              price: itemPrice.map(r.data),
              item: r.read<String>('item'),
              list: r.read<String>('list'),
              uom: r.read<String>('unit'),
            ),
        ],
      );

  Stream<List<BatchListRow>> watchBatchList() =>
      customSelect(
        'SELECT b.*, i.item_code AS item FROM batch b JOIN item i ON i.id = b.item_id '
        'ORDER BY b.batch_id',
        readsFrom: {batches, item},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (batch: batches.map(r.data), item: r.read<String>('item')),
        ],
      );

  Stream<List<SerialListRow>> watchSerialList() =>
      customSelect(
        'SELECT s.*, i.item_code AS item, w.name AS wh FROM serial_no s '
        'JOIN item i ON i.id = s.item_id LEFT JOIN warehouse w ON w.id = s.warehouse_id '
        'ORDER BY s.serial_no',
        readsFrom: {serialNo, item, warehouse},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (
              serial: serialNo.map(r.data),
              item: r.read<String>('item'),
              warehouse: r.read<String?>('wh'),
            ),
        ],
      );

  /// The quantity of one batch per warehouse.
  Future<List<(String, double)>> batchStock(int batchId) async => [
    for (final r in await customSelect(
      'SELECT w.name, SUM(l.actual_qty) AS qty FROM stock_ledger_entry l '
      'JOIN warehouse w ON w.id = l.warehouse_id WHERE l.batch_id = ? '
      'AND l.is_cancelled = 0 GROUP BY w.id HAVING SUM(l.actual_qty) != 0',
      variables: [Variable(batchId)],
    ).get())
      (r.read<String>('name'), r.read<double>('qty')),
  ];

  /// The Default Valuation Method cannot change once an item that follows
  /// it has stock, as in ERPNext.
  Future<bool> valuationMethodLocked() async =>
      (await customSelect(
        'SELECT EXISTS (SELECT 1 FROM stock_ledger_entry l JOIN item i '
        'ON i.id = l.item_id WHERE i.valuation_method IS NULL '
        'AND i.has_serial_no = 0) AS found',
      ).getSingle()).read<int>('found') ==
      1;

  /// Stock Levels and Item Prices of one item.
  Stream<List<StripChip>> watchItemStrip(int itemId) =>
      customSelect(
        "SELECT 1 AS stock, NULL AS id, w.name AS label, b.actual_qty AS v "
        'FROM bin b JOIN warehouse w ON w.id = b.warehouse_id '
        'WHERE b.item_id = ?1 AND b.actual_qty != 0 UNION ALL '
        "SELECT 0, ip.id, p.name || ' · ' || COALESCE(u.name, su.name), "
        'ip.price_list_rate FROM item_price ip JOIN price_list p ON p.id = ip.price_list_id '
        'JOIN item i ON i.id = ip.item_id JOIN uom su ON su.id = i.stock_uom_id '
        'LEFT JOIN uom u ON u.id = ip.uom_id WHERE ip.item_id = ?1',
        variables: [Variable(itemId)],
        readsFrom: {bin, itemPrice},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            (
              stock: r.read<int>('stock') == 1,
              priceId: r.read<int?>('id'),
              label: r.read<String>('label'),
              value: r.read<double>('v'),
            ),
        ],
      );

  /// The id of the [table] row called [name], or null.
  Future<int?> idByName(String table, String name) async => (await customSelect(
    'SELECT id FROM $table WHERE name = ?',
    variables: [Variable(name)],
  ).getSingleOrNull())?.read<int>('id');
}

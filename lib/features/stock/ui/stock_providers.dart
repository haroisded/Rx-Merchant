import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../data/stock_lists.dart';
import '../data/stock_reports.dart';

export '../data/stock_lists.dart' show ItemRow, StripChip;

// Streams the stock screens share. Each re-emits when its table changes.

final warehousesProvider = StreamProvider<List<WarehouseData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.warehouse).watch();
});

final itemGroupsProvider = StreamProvider<List<ItemGroupData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.itemGroup).watch();
});

final uomsProvider = StreamProvider<List<UomData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.uom).watch();
});

final brandsProvider = StreamProvider<List<BrandData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.brand).watch();
});

final itemAttributesProvider = StreamProvider<List<ItemAttributeData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.itemAttribute).watch();
});

final stockSettingsProvider = Provider<StockSettings>(
  (ref) => StockSettings(
    ref.watch(singleProvider(StockSettings.doctype)).value ?? const {},
  ),
);

final lowStockCountProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).watchLowStockCount(),
);

/// Enabled, non-group warehouses: where stock can be (STK-R1).
List<WarehouseData> usable(List<WarehouseData> all) => [
  for (final w in all)
    if (w.isGroup == 0 && w.disabled == 0) w,
];

final itemRowsProvider = StreamProvider<List<ItemRow>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final list = SellingSettings(
    ref.watch(singleProvider(SellingSettings.doctype)).value ?? const {},
  ).sellingPriceList;
  return db.watchItemRows(list, toStorage(DateTime.now()).substring(0, 10));
});

/// The Stock Levels and Item Prices above an item's form.
final itemStripProvider = StreamProvider.family<List<StripChip>, int>(
  (ref, itemId) => ref.watch(appDatabaseProvider).watchItemStrip(itemId),
);

final itemImageProvider = FutureProvider.family<Uint8List?, int>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.item,
  )..where((i) => i.id.equals(id))).map((i) => i.image).getSingleOrNull();
});

/// Items matching [query] by code, name or barcode, for link fields. With
/// [stockOnly], only items that can be moved (STK-R6, R14).
Future<List<ItemRow>> searchItems(
  List<ItemRow> rows,
  String query, {
  bool stockOnly = false,
}) async {
  final q = query.toLowerCase();
  return [
    for (final r in rows)
      if ((!stockOnly || (!r.disabled && !r.template && r.stockItem)) &&
          ('${r.code} ${r.name} ${r.barcodes}').toLowerCase().contains(q))
        r,
  ].take(50).toList();
}

/// The item with exactly this barcode, and the unit the barcode names
/// (STK-R8).
Future<({int itemId, int? uomId})?> itemByBarcode(
  AppDatabase db,
  String code,
) async {
  final b = await (db.select(
    db.itemBarcode,
  )..where((b) => b.barcode.equals(code.trim()))).getSingleOrNull();
  if (b != null) return (itemId: b.itemId, uomId: b.uomId);
  final i = await (db.select(
    db.item,
  )..where((i) => i.itemCode.equals(code.trim()))).getSingleOrNull();
  return i == null ? null : (itemId: i.id, uomId: null);
}

/// The units an item can be moved in: its Stock UOM (factor 1) and its UoM
/// table (STK-R9).
Future<List<({int uomId, double factor})>> unitsOf(
  AppDatabase db,
  int itemId,
) async {
  final it = await (db.select(
    db.item,
  )..where((i) => i.id.equals(itemId))).getSingle();
  final more = await (db.select(
    db.itemUom,
  )..where((u) => u.itemId.equals(itemId))).get();
  return [
    (uomId: it.stockUomId, factor: 1.0),
    for (final u in more)
      if (u.uomId != it.stockUomId)
        (uomId: u.uomId, factor: u.conversionFactor),
  ];
}

/// The units [itemId] can be moved in (STK-R9).
final itemUnitsProvider =
    FutureProvider.family<List<({int uomId, double factor})>, int>(
      (ref, itemId) => unitsOf(ref.watch(appDatabaseProvider), itemId),
    );

/// The batches of one item.
final itemBatchesProvider = StreamProvider.family<List<BatchRow>, int>((
  ref,
  itemId,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.batches)..where((b) => b.itemId.equals(itemId))).watch();
});

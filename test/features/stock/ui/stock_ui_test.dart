import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/providers.dart';
import 'package:rx_merchant/features/setup/data/seed.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';

import '../data/stock_db_test.dart' show move, newItem;

import '../../setup/data/setup_db_test.dart' show philippines;

/// The app on a store that went through the wizard, opened on Stock.
Future<AppDatabase> pumpStock(
  WidgetTester tester, {
  double width = 400,
  double height = 900,
  Future<void> Function(AppDatabase db)? before,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  await tester.runAsync(
    () => db.completeSetup(
      language: 'en',
      country: philippines,
      currencyOf: philippines,
      storeName: 'Rx Corner Store',
      abbr: 'RCS',
    ),
  );
  if (before != null) await tester.runAsync(() => before(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stock').last);
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('Stock home groups; an empty Item list offers add and import', (
    tester,
  ) async {
    await pumpStock(tester);
    expect(find.text('Items and Pricing'), findsOneWidget);
    expect(find.text('Stock Transactions'), findsOneWidget);
    // Serial No and Batch appear only once Stock Settings enables them.
    expect(find.text('Serial No and Batch'), findsNothing);

    await tester.tap(find.text('Item'));
    await tester.pumpAndSettle();
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Import items'), findsOneWidget);
  });

  testWidgets('a new item saves with its name pre-filled from the code', (
    tester,
  ) async {
    final db = await pumpStock(tester);
    await tester.tap(find.text('Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item Code *'),
      'SOAP',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final item = await tester.runAsync(() => db.select(db.item).getSingle());
    expect(item!.itemCode, 'SOAP');
    expect(item.itemName, 'SOAP');
  });

  testWidgets('a new item: bad numbers stop Save; Back asks before '
      'discarding (P-10)', (tester) async {
    final db = await pumpStock(tester);
    await tester.tap(find.text('Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item Code *'),
      'SOAP',
    );
    final opening = find.widgetWithText(TextFormField, 'Opening Stock');
    Future<void> saveAndExpect(String message) async {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining(message), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(opening, 'abc-5');
    await saveAndExpect('Some fields need attention.');
    // Still refused from another tab: the Details tab stays built.
    await tester.ensureVisible(find.text('Sales'));
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    await saveAndExpect('Some fields need attention.');
    await tester.ensureVisible(find.text('Details'));
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.enterText(opening, '5');
    await saveAndExpect('Opening Stock needs a Valuation Rate above zero.');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valuation Rate'),
      '2',
    );
    await tester.ensureVisible(find.text('Sales'));
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Max Discount (%)'),
      '500',
    );
    await saveAndExpect('Max Discount (%) must be between 0 and 100.');
    expect(await tester.runAsync(() => db.select(db.item).get()), isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Discard Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Add Item'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.item).get()), isEmpty);
  });

  testWidgets('a settings page that stays after Save leaves without asking', (
    tester,
  ) async {
    await pumpStock(tester);
    await tester.tap(find.text('Setup').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Store Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Rx Corner Shop');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.text('Store Profile'), findsOneWidget);
  });

  testWidgets('STK-R12 the Stock destination shows the low-stock count', (
    tester,
  ) async {
    await pumpStock(
      tester,
      before: (db) async {
        final group = await (db.select(
          db.itemGroup,
        )..where((g) => g.name.equals('Products'))).getSingle();
        final nos = await (db.select(
          db.uom,
        )..where((u) => u.name.equals('Nos'))).getSingle();
        final stores = await (db.select(
          db.warehouse,
        )..where((w) => w.name.equals('Stores'))).getSingle();
        final id = await db
            .into(db.item)
            .insert(
              ItemCompanion.insert(
                itemCode: 'GAUZE',
                itemName: 'Gauze',
                itemGroupId: group.id,
                stockUomId: nos.id,
              ),
            );
        await db
            .into(db.itemReorder)
            .insert(
              ItemReorderCompanion.insert(
                itemId: id,
                warehouseId: stores.id,
                warehouseReorderLevel: const Value(5),
              ),
            );
      },
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Badge),
      ),
      findsOneWidget,
    );
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('Stock Ledger lists an entry under a totals row', (tester) async {
    await pumpStock(
      tester,
      height: 2000,
      before: (db) async {
        final apple = await newItem(db, 'APPLE');
        await move(
          db,
          StockPurpose.materialReceipt,
          apple,
          10,
          rate: 2,
          day: '2026-11-16',
        );
      },
    );
    await tester.tap(find.text('Stock Ledger'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('APPLE'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });
}

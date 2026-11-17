import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/providers.dart';
import 'package:rx_merchant/features/setup/data/seed.dart';
import 'package:rx_merchant/features/stock/data/stock_masters.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';

import '../../setup/data/setup_db_test.dart' show philippines;
import '../../stock/data/stock_db_test.dart' show idOf, move, newItem;

/// pumpAndSettle that fails after 10 s instead of hanging the run.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);

/// The app on a store with SOAP (barcode 4800, 20 in stock at 25.00),
/// opened on the Cash Register.
Future<AppDatabase> pumpPos(
  WidgetTester tester, {
  double width = 400,
  double height = 900,
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
  await tester.runAsync(() async {
    await db.completeSetup(
      language: 'en',
      country: philippines,
      currencyOf: philippines,
      storeName: 'Rx Corner Store',
      abbr: 'RCS',
    );
    final soap = await newItem(db, 'SOAP');
    await db
        .into(db.itemBarcode)
        .insert(ItemBarcodeCompanion.insert(itemId: soap, barcode: '4800'));
    await db.saveItemPrice(
      ItemPriceCompanion.insert(
        itemId: soap,
        priceListId: await idOf(db, 'price_list', 'Standard Selling'),
        priceListRate: 25,
      ),
    );
    await move(db, StockPurpose.materialReceipt, soap, 20, rate: 10);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  await settle(tester);
  return db;
}

void main() {
  testWidgets('POS-R1 the register asks for a session, then sells on a '
      'phone: scan, checkout, complete', (tester) async {
    final db = await pumpPos(tester);
    expect(find.text('POS Opening Entry'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await settle(tester);

    expect(find.text('0 items'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), '4800');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Grand Total: ₱ 25.00'), findsOneWidget);

    await tester.tap(find.text('1 item'));
    await settle(tester);
    await tester.tap(find.text('Checkout'));
    await settle(tester);
    // Set Grand Total to Default Payment Method: Cash starts at 25.00.
    expect(find.text('Complete Order'), findsOneWidget);
    await tester.tap(find.text('Complete Order'));
    await settle(tester);

    final year = DateTime.now().year;
    expect(find.text('ACC-SINV-$year-00001'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
    final sold = await tester.runAsync(
      () => db.select(db.salesInvoice).getSingle(),
    );
    expect((sold!.status, sold.grandTotal), ('Paid', 25));
  });

  testWidgets('a tablet shows selector, cart and number pad side by side', (
    tester,
  ) async {
    await pumpPos(tester, width: 1280, height: 800);
    await tester.tap(find.text('Open'));
    await settle(tester);
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('Scan or tap an item to start a sale.'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);

    await tester.tap(find.text('SOAP'));
    await settle(tester);
    expect(find.text('₱ 25.00'), findsWidgets);
  });

  testWidgets('Medium: the item detail opens over the selector, not the cart', (
    tester,
  ) async {
    await pumpPos(tester, width: 700, height: 900);
    await tester.tap(find.text('Open'));
    await settle(tester);
    await tester.tap(find.text('SOAP'));
    await settle(tester);
    final cartLine = find.text('1.000 × ₱ 25.00');
    final cartLeft = tester.getTopLeft(cartLine).dx;
    await tester.tap(cartLine);
    await settle(tester);
    expect(find.text('Available Qty'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Available Qty')).dx,
      lessThan(cartLeft),
    );
  });
}

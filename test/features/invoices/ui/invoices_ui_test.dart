import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/features/pos/data/pos_db.dart';

import '../../pos/data/pos_db_test.dart' show cart, paid;
import '../../pos/ui/pos_ui_test.dart' show pumpPos, settle;
import '../../stock/data/stock_db_test.dart' show idOf;

// 05-invoices-and-receipts section 5: the Invoices destination, the return
// form and Setup > Printing.

/// A session and one sale of 3 SOAP at 25.00; its name. Written away from
/// the register, whose live queries would hold the database in the test's
/// fake clock.
Future<String> _sale(WidgetTester tester, AppDatabase db) async {
  late String name;
  await tester.runAsync(() async {
    await db.openSessionWith({await idOf(db, 'mode_of_payment', 'Cash'): 0});
    final soap = await (db.select(
      db.item,
    )..where((i) => i.itemCode.equals('SOAP'))).map((i) => i.id).getSingle();
    name = await db.submitSale(await paid(db, await cart(db, [(soap, 3, 25)])));
  });
  return name;
}

Future<void> _openInvoices(WidgetTester tester) async {
  await tester.tap(find.text('Invoices').last);
  await settle(tester);
}

void main() {
  testWidgets('INV-R1, R2 on a phone: the list, then the invoice', (
    tester,
  ) async {
    final db = await pumpPos(tester);
    await _openInvoices(tester);
    expect(
      find.text('Sales you complete at the Cash Register appear here.'),
      findsOneWidget,
    );
    final name = await _sale(tester, db);
    await settle(tester);
    expect(find.text(name), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    await tester.tap(find.text(name));
    await settle(tester);
    expect(find.text('Net Total'), findsOneWidget);
    expect(find.text('₱ 75.00'), findsWidgets);
    expect(find.byTooltip('Print'), findsOneWidget);
  });

  testWidgets('a tablet shows the invoice beside the list', (tester) async {
    final db = await pumpPos(tester, width: 1280, height: 800);
    await _openInvoices(tester);
    final name = await _sale(tester, db);
    await settle(tester);
    await tester.tap(find.text(name));
    await settle(tester);
    // The list stays on the left; the detail's item table on the right.
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
  });

  testWidgets('INV-R5 to R8 a partial return from the invoice', (tester) async {
    final db = await pumpPos(tester, height: 1400);
    await _openInvoices(tester);
    final name = await _sale(tester, db);
    await settle(tester);
    await tester.tap(find.text(name));
    await settle(tester);
    await tester.tap(find.text('Create'));
    await settle(tester);
    await tester.tap(find.text('Return / Credit Note'));
    await settle(tester);
    expect(find.text('Still returnable: 3.000'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await settle(tester);
    // Two come back: 50.00 refunded in Cash, the default mode.
    expect(find.text('₱ -50.00'), findsWidgets);
    await tester.tap(find.text('Submit'));
    await settle(tester);
    await tester.tap(find.text('Submit').last);
    await settle(tester);
    expect(find.text('Return'), findsWidgets);
    expect(find.text('New Order'), findsOneWidget);
    final ret = await tester.runAsync(
      () => (db.select(
        db.salesInvoice,
      )..where((s) => s.isReturn.equals(1))).getSingle(),
    );
    expect((ret!.status, ret.grandTotal), ('Return', -50));
  });

  testWidgets('Setup > Printing opens its pages', (tester) async {
    await pumpPos(tester);
    await tester.tap(find.text('Setup').last);
    await settle(tester);
    // Past the Printing group, so its links clear the navigation bar.
    await tester.scrollUntilVisible(find.text('Backups'), 200);
    await tester.tap(find.text('Letter Head'));
    await settle(tester);
    // The wizard's letter head, the Default.
    expect(find.text('Rx Corner Store'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
  });
}

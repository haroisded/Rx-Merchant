import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/providers.dart';
import 'package:rx_merchant/core/db/singles.dart';
import 'package:rx_merchant/features/dashboard/ui/dashboard_screen.dart';
import 'package:rx_merchant/features/dashboard/ui/sales_report_pages.dart';
import 'package:rx_merchant/features/pos/data/pos_db.dart';
import 'package:rx_merchant/features/setup/data/seed.dart';
import 'package:rx_merchant/l10n/app_localizations.dart';

import '../../pos/data/pos_db_test.dart' show cart, paid, receipt;
import '../../pos/ui/pos_ui_test.dart' show settle;
import '../../setup/data/setup_db_test.dart' show philippines;
import '../../stock/data/stock_db_test.dart' show idOf, move, newItem;

// 04-sales-dashboard section 5: the Dashboard screen.

/// The Dashboard on a store with SOAP in stock; [sell] completes one sale
/// of 2 × 25.00 first.
Future<AppDatabase> pumpDashboard(
  WidgetTester tester, {
  double width = 400,
  bool sell = true,
  double target = 0,
  Widget home = const DashboardScreen(),
}) async {
  tester.view.physicalSize = Size(width, 1600);
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
    await db.writeSingle(StoreProfile.doctype, {
      'monthly_sales_target': target,
    });
    final soap = await newItem(db, 'SOAP');
    await move(db, receipt, soap, 20, rate: 10);
    if (sell) {
      await db.openSessionWith({await idOf(db, 'mode_of_payment', 'Cash'): 0});
      await db.submitSale(await paid(db, await cart(db, [(soap, 2, 25)])));
    }
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await settle(tester);
  return db;
}

void main() {
  testWidgets('no sale yet: one card pointing to the Cash Register', (
    tester,
  ) async {
    await pumpDashboard(tester, sell: false);
    expect(
      find.text('Complete your first sale to see your dashboard'),
      findsOneWidget,
    );
    expect(find.text('Open Cash Register'), findsOneWidget);
  });

  testWidgets('phone: cards 2 per row; no target, a link to set one', (
    tester,
  ) async {
    await pumpDashboard(tester);
    expect(find.text('₱ 50.00'), findsWidgets);
    final net = tester.getTopLeft(find.text('Net Sales'));
    final invoices = tester.getTopLeft(find.text('Invoices'));
    final average = tester.getTopLeft(find.text('Average Sale'));
    expect(invoices.dy, net.dy);
    expect(average.dy, greaterThan(net.dy));
    // DSH-A13: target 0, no goal card.
    expect(find.text('Set a monthly sales target'), findsOneWidget);
    expect(find.text('Achievement'), findsNothing);
    expect(find.text('Sales Trend'), findsOneWidget);
  });

  testWidgets('tablet: cards 4 per row; the goal card with its progress', (
    tester,
  ) async {
    await pumpDashboard(tester, width: 1280, target: 200);
    final net = tester.getTopLeft(find.text('Net Sales'));
    expect(tester.getTopLeft(find.text('Items Sold')).dy, net.dy);
    expect(
      tester.getTopLeft(find.text('Gross Profit').first).dy,
      greaterThan(net.dy),
    );
    // DSH-A11 shape: 50 of 200 is 25.0%.
    expect(find.text('Achievement'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('DSH-R12 a new sale shows without a refresh', (tester) async {
    final db = await pumpDashboard(tester);
    expect(find.text('₱ 100.00'), findsNothing);
    await tester.runAsync(() async {
      final soap = (await db.select(db.item).getSingle()).id;
      await db.submitSale(await paid(db, await cart(db, [(soap, 2, 25)])));
    });
    await settle(tester);
    expect(find.text('₱ 100.00'), findsWidgets);
  });

  testWidgets('DSH-R7 on a phone Sales Analytics shows the Total first; '
      'Gross Profit adds its check column', (tester) async {
    await pumpDashboard(
      tester,
      home: salesReportPage('sales-analytics', const {})!,
    );
    // The header's Total is the second column (the first is 160 wide).
    final item = tester.getTopLeft(find.text('Item'));
    final total = find
        .text('Total')
        .evaluate()
        .map((e) => tester.getTopLeft(find.byWidget(e.widget)))
        .firstWhere((o) => o.dy == item.dy);
    expect(total.dx, inInclusiveRange(item.dx + 160, item.dx + 160 + 128));
    expect(find.text('● SOAP'), findsOneWidget);
    expect(find.text('₱ 50.00'), findsWidgets);

    await pumpDashboard(
      tester,
      width: 1280,
      home: salesReportPage('gross-profit', const {})!,
    );
    expect(find.text('Average Selling Rate'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    // 50 sold at a cost of 20: 60.0%, in the row and the totals row.
    expect(find.text('60.0%'), findsNWidgets(2));
  });
}

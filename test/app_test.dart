import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/providers.dart';
import 'package:rx_merchant/core/db/singles.dart';

/// Starts the app on an in-memory database in a window [width] dp wide.
Future<void> pumpApp(
  WidgetTester tester, {
  required double width,
  bool setupComplete = true,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  if (setupComplete) {
    await tester.runAsync(
      () => db.writeSingle(SystemSettings.doctype, {'setup_complete': true}),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('wizard gate (SET-R1)', () {
    testWidgets('a fresh install shows only the wizard', (tester) async {
      await pumpApp(tester, width: 400, setupComplete: false);

      expect(find.text('Step 1 of 4'), findsOneWidget);
      // A new device can restore instead of setting up (SET-R18).
      expect(find.text('Restore from backup'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets(
      'SET-B1 Language, Region, Store, Done lands on the Cash Register',
      (tester) async {
        await pumpApp(tester, width: 400, setupComplete: false);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        // Region: the device's country (en_US in tests) is preselected.
        expect(find.text('United States'), findsOneWidget);
        expect(find.textContaining('USD'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Rx Corner Store');
        await tester.pumpAndSettle();
        expect(find.text('RCS'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Cash Register'));
        await tester.pumpAndSettle();

        expect(find.text('Step 4 of 4'), findsNothing);
        expect(find.widgetWithText(AppBar, 'Cash Register'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets('a set-up store never sees the wizard', (tester) async {
      await pumpApp(tester, width: 400);

      expect(find.text('Step 1 of 4'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Cash Register'), findsOneWidget);
    });
  });

  group('Setup destination', () {
    Future<void> openSetup(WidgetTester tester) async {
      await tester.tap(find.text('Setup').last);
      await tester.pumpAndSettle();
    }

    testWidgets('compact: the workspace, then a pushed page', (tester) async {
      await pumpApp(tester, width: 400);
      await openSetup(tester);
      expect(find.text('Store Profile'), findsOneWidget);
      // Every plan's pages are reachable, Printing's too (05-invoices).
      await tester.scrollUntilVisible(find.text('Print Settings'), 200);
      for (final page in ['Stock Settings', 'Print Settings']) {
        expect(
          tester.widget<ListTile>(find.widgetWithText(ListTile, page)).enabled,
          isTrue,
        );
      }

      await tester.scrollUntilVisible(find.text('Mode of Payment'), -200);
      await tester.tap(find.text('Mode of Payment'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mode of Payment'), findsOneWidget);
      expect(find.text('Store Profile'), findsNothing);
    });

    testWidgets('expanded: the workspace stays beside the page', (
      tester,
    ) async {
      await pumpApp(tester, width: 1280);
      await openSetup(tester);
      await tester.tap(find.text('Tax'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Tax'), findsOneWidget);
      expect(find.text('Store Profile'), findsOneWidget);
    });

    testWidgets('a settings page saves to singles', (tester) async {
      await pumpApp(tester, width: 400);
      await openSetup(tester);
      await tester.tap(find.text('Global Defaults'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hide Currency Symbol'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      final db = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(appDatabaseProvider);
      final stored = await tester.runAsync(
        () => db.readSingle(GlobalDefaults.doctype),
      );
      expect(GlobalDefaults(stored!).hideCurrencySymbol, isTrue);
    });

    testWidgets('POS Settings does not save back a mode no longer offered', (
      tester,
    ) async {
      await pumpApp(tester, width: 400);
      final db = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(appDatabaseProvider);
      // No Mode of Payment exists, so the stored default is not offered.
      await tester.runAsync(
        () => db.writeSingle(PosSettings.doctype, {
          'default_mode_of_payment': 'GCash',
        }),
      );
      await openSetup(tester);
      await tester.tap(find.text('POS Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      final stored = await tester.runAsync(
        () => db.readSingle(PosSettings.doctype),
      );
      expect(stored!['default_mode_of_payment'], '');
      expect(PosSettings(stored).defaultModeOfPayment, 'Cash');
    });
  });

  group('adaptive shell', () {
    testWidgets(
      'compact: a NavigationBar with the five destinations in order',
      (tester) async {
        await pumpApp(tester, width: 400);

        final labels = tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label);
        // "Register", not "Cash Register": the long form wraps on a 360dp bar.
        expect(labels, ['Register', 'Invoices', 'Stock', 'Dashboard', 'Setup']);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets('599dp is still compact', (tester) async {
      await pumpApp(tester, width: 599);

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    for (final width in [600.0, 839.0]) {
      testWidgets('${width.toInt()}dp is medium: a rail without labels', (
        tester,
      ) async {
        await pumpApp(tester, width: width);

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.labelType, NavigationRailLabelType.none);
        expect(rail.destinations, hasLength(5));
        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets('840dp is expanded: a rail with labels', (tester) async {
      await pumpApp(tester, width: 840);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.labelType, NavigationRailLabelType.all);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('tapping a destination switches the screen', (tester) async {
      await pumpApp(tester, width: 400);

      await tester.tap(find.text('Stock'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Stock'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Cash Register'), findsNothing);
    });

    testWidgets('rotating a tablet moves between rail layouts', (tester) async {
      await pumpApp(tester, width: 800);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).labelType,
        NavigationRailLabelType.none,
      );

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).labelType,
        NavigationRailLabelType.all,
      );
    });
  });
}

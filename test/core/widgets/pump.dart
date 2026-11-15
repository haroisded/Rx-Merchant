import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/l10n/app_localizations.dart';

/// Pumps [child] with the app's theme and localisation in a window [width] dp
/// wide.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

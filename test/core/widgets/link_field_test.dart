import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/core/widgets/link_field.dart';

import 'pump.dart';

void main() {
  const groups = ['Products', 'Services', 'Consumable'];
  Future<Iterable<String>> search(String query) async =>
      groups.where((g) => g.toLowerCase().contains(query.toLowerCase()));

  String? picked;
  var created = false;
  var cleared = false;
  setUp(() {
    picked = null;
    created = false;
    cleared = false;
  });

  Widget field({String? value, bool mandatory = false, String? errorText}) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: LinkField<String>(
          label: 'Item Group',
          value: value,
          mandatory: mandatory,
          errorText: errorText,
          search: search,
          labelOf: (g) => g,
          onChanged: (g) {
            picked = g;
            cleared = g == null;
          },
          onCreateNew: () => created = true,
        ),
      );

  testWidgets('shows its label and the current value', (tester) async {
    await pumpInApp(tester, field(value: 'Products'));

    expect(find.text('Item Group'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('a mandatory field marks its label and shows its error', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      field(mandatory: true, errorText: 'Item Group is required'),
    );

    expect(find.text('Item Group *'), findsOneWidget);
    expect(find.text('Item Group is required'), findsOneWidget);
  });

  testWidgets('opening lists every match and a Create new entry', (
    tester,
  ) async {
    await pumpInApp(tester, field());

    await tester.tap(find.text('Item Group'));
    await tester.pumpAndSettle();

    for (final group in groups) {
      expect(find.text(group), findsOneWidget);
    }
    expect(find.text('Create new'), findsOneWidget);
  });

  testWidgets('typing narrows the matches; picking one reports it', (
    tester,
  ) async {
    await pumpInApp(tester, field());
    await tester.tap(find.text('Item Group'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'serv');
    await tester.pumpAndSettle();
    expect(find.text('Products'), findsNothing);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    expect(picked, 'Services');
  });

  testWidgets('Create new calls back without picking anything', (tester) async {
    await pumpInApp(tester, field());
    await tester.tap(find.text('Item Group'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create new'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(picked, isNull);
  });

  testWidgets('an optional field with a value can be cleared', (tester) async {
    await pumpInApp(tester, field(value: 'Products'));

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });

  testWidgets('a mandatory field offers no clear button', (tester) async {
    await pumpInApp(tester, field(value: 'Products', mandatory: true));

    expect(find.byIcon(Icons.clear), findsNothing);
  });
}

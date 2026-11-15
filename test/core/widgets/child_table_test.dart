import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/core/widgets/child_table.dart';

import 'pump.dart';

void main() {
  Widget table({bool readOnly = false}) => ChildTable<String>(
    rows: const ['Row A', 'Row B'],
    readOnly: readOnly,
    rowBuilder: (context, row) => ListTile(title: Text(row)),
    editorBuilder: (context, row) => SizedBox.expand(
      key: const Key('editor'),
      child: Text(row == null ? 'EDITING NEW' : 'EDITING $row'),
    ),
  );

  testWidgets('lists every row', (tester) async {
    await pumpInApp(tester, table());

    expect(find.text('Row A'), findsOneWidget);
    expect(find.text('Row B'), findsOneWidget);
  });

  testWidgets('compact: tapping a row opens its editor in a bottom sheet', (
    tester,
  ) async {
    await pumpInApp(tester, table());

    await tester.tap(find.text('Row B'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('EDITING Row B'), findsOneWidget);
  });

  testWidgets('wider: tapping a row opens its editor in a side sheet', (
    tester,
  ) async {
    await pumpInApp(tester, table(), width: 900);

    await tester.tap(find.text('Row A'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('EDITING Row A'), findsOneWidget);
    final sheet = tester.getRect(find.byKey(const Key('editor')));
    expect(sheet.right, 900, reason: 'the sheet sits on the trailing edge');
    expect(sheet.width, lessThanOrEqualTo(400));
  });

  testWidgets('Add Row opens the editor with no row', (tester) async {
    await pumpInApp(tester, table());

    await tester.tap(find.text('Add Row'));
    await tester.pumpAndSettle();

    expect(find.text('EDITING NEW'), findsOneWidget);
  });

  testWidgets('read-only hides Add Row but rows still open', (tester) async {
    await pumpInApp(tester, table(readOnly: true));

    expect(find.text('Add Row'), findsNothing);

    await tester.tap(find.text('Row A'));
    await tester.pumpAndSettle();
    expect(find.text('EDITING Row A'), findsOneWidget);
  });
}

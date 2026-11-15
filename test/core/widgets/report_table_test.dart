import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/core/widgets/report_table.dart';

import 'pump.dart';

void main() {
  group('toCsv', () {
    test('writes a header line, then one line per row', () {
      expect(
        toCsv(
          ['Item', 'Qty'],
          [
            ['Paracetamol', 2],
            ['Bandage', 10.5],
          ],
        ).split(RegExp(r'\r?\n')).where((line) => line.isNotEmpty),
        ['Item,Qty', 'Paracetamol,2', 'Bandage,10.5'],
      );
    });

    test('quotes a cell holding a comma or a quote', () {
      expect(
        toCsv(
          ['Item', 'Qty'],
          [
            ['A, "x"', 2],
          ],
        ),
        contains('"A, ""x""",2'),
      );
    });

    test('an empty cell stays empty', () {
      expect(
        toCsv(
          ['Item', 'Batch', 'Qty'],
          [
            ['A', null, 1],
          ],
        ),
        contains('A,,1'),
      );
    });
  });

  group('ReportTable', () {
    Widget report() => ReportTable(
      columns: const ['Item', 'Qty'],
      rows: const [
        ['Paracetamol', 2],
        ['Bandage', 10.5],
      ],
      filters: const Text('FILTERS'),
      exportName: 'stock-balance',
    );

    testWidgets('shows filters, headers, cells and a CSV export action', (
      tester,
    ) async {
      await pumpInApp(tester, report());

      expect(find.text('FILTERS'), findsOneWidget);
      expect(find.text('Item'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('10.5'), findsOneWidget);
      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    testWidgets('the table scrolls sideways on a narrow window', (
      tester,
    ) async {
      await pumpInApp(tester, report());

      final horizontal = find.ancestor(
        of: find.byType(DataTable),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(horizontal, findsOneWidget);
    });
  });
}

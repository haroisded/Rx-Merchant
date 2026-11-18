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

    test('DSH-R11 the filters are written above the header', () {
      expect(
        toCsv(
          ['Item', 'Qty'],
          [
            ['A', 1],
          ],
          [
            ['From Date', '2026-03-01'],
            ['To Date', '2026-03-31'],
          ],
        ).split(RegExp(r'\r?\n')).where((line) => line.isNotEmpty),
        ['From Date,2026-03-01', 'To Date,2026-03-31', 'Item,Qty', 'A,1'],
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

    testWidgets('the first column stays put while the rest scroll sideways', (
      tester,
    ) async {
      await pumpInApp(tester, report());

      Finder sideways(String text) => find.ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(sideways('Qty'), findsOneWidget);
      expect(sideways('Item'), findsNothing);
    });

    testWidgets('rows beyond the columns are hidden; a totals row; row tap', (
      tester,
    ) async {
      List<Object?>? tapped;
      await pumpInApp(
        tester,
        ReportTable(
          columns: const ['Item', 'Qty'],
          rows: const [
            ['Paracetamol', 2, 'hidden'],
          ],
          totals: const ['Total', 2],
          cell: (c, v) => c == 1 && v is num ? '$v pcs' : '${v ?? ''}',
          exportName: 'x',
          onRowTap: (row) => tapped = row,
        ),
      );
      expect(find.text('hidden'), findsNothing);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('2 pcs'), findsNWidgets(2));
      await tester.tap(find.text('Paracetamol'));
      expect(tapped, ['Paracetamol', 2, 'hidden']);
    });
  });
}

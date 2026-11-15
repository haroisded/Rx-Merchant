import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/core/widgets/list_detail_pane.dart';

import 'pump.dart';

void main() {
  const list = Text('LIST');
  const detail = Text('DETAIL');

  testWidgets('expanded shows the list and the detail side by side', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const ListDetailPane(list: list, detail: detail),
      width: 840,
    );

    expect(find.text('LIST'), findsOneWidget);
    expect(find.text('DETAIL'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('LIST')).dx,
      lessThan(tester.getTopLeft(find.text('DETAIL')).dx),
    );
  });

  testWidgets('expanded with nothing selected still shows the list', (
    tester,
  ) async {
    await pumpInApp(tester, const ListDetailPane(list: list), width: 1000);

    expect(find.text('LIST'), findsOneWidget);
  });

  for (final width in [400.0, 839.0]) {
    testWidgets(
      '${width.toInt()}dp shows one pane: the detail when there is one',
      (tester) async {
        await pumpInApp(
          tester,
          const ListDetailPane(list: list, detail: detail),
          width: width,
        );

        expect(find.text('DETAIL'), findsOneWidget);
        expect(find.text('LIST'), findsNothing);
      },
    );
  }

  testWidgets('compact with nothing selected shows the list', (tester) async {
    await pumpInApp(tester, const ListDetailPane(list: list));

    expect(find.text('LIST'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rx_merchant/app.dart';
import 'package:rx_merchant/core/widgets/status_chip.dart';

import 'pump.dart';

void main() {
  final scheme = AppTheme.light.colorScheme;

  // 00-overview, section 7.1, "Status indicator".
  final expected = {
    'Draft': scheme.secondaryContainer,
    'Submitted': scheme.primaryContainer,
    'Paid': scheme.primaryContainer,
    'Return': scheme.surfaceContainerHighest,
    'Credit Note Issued': scheme.surfaceContainerHighest,
    'Cancelled': scheme.errorContainer,
  };

  for (final MapEntry(key: status, value: color) in expected.entries) {
    testWidgets('$status uses its colour role and shows its name', (
      tester,
    ) async {
      await pumpInApp(tester, Center(child: StatusChip(status)));

      expect(tester.widget<Chip>(find.byType(Chip)).backgroundColor, color);
      expect(find.text(status), findsOneWidget);
    });
  }

  testWidgets('an unlisted status still shows, in the neutral role', (
    tester,
  ) async {
    await pumpInApp(tester, const Center(child: StatusChip('Open')));

    expect(
      tester.widget<Chip>(find.byType(Chip)).backgroundColor,
      scheme.surfaceContainerHighest,
    );
    expect(find.text('Open'), findsOneWidget);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/child_table.dart';
import '../../../l10n/app_localizations.dart';

/// STK-R8: scans one barcode with the camera and returns its text, or null
/// when dismissed. The scanning model ships inside the app, so it works with
/// no network. A Bluetooth or USB scanner needs none of this: it types into
/// the focused field.
Future<String?> scanBarcode(BuildContext context) =>
    showRowEditor<String>(context, (context) => const _ScanSheet());

class _ScanSheet extends StatefulWidget {
  const _ScanSheet();

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context).scanBarcode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final code = capture.barcodes
                    .map((b) => b.rawValue)
                    .nonNulls
                    .firstOrNull;
                if (code == null || _done) return;
                _done = true;
                Navigator.pop(context, code);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A scan button for a search or barcode field.
class ScanButton extends StatelessWidget {
  const ScanButton({super.key, required this.onScanned});

  final ValueChanged<String> onScanned;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).scanBarcode,
    icon: const Icon(Icons.qr_code_scanner),
    onPressed: () async {
      final code = await scanBarcode(context);
      if (code != null) onScanned(code);
    },
  );
}

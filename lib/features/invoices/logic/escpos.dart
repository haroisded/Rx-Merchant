import 'dart:convert';

import 'receipt_text.dart';

// Raw printing (05-invoices-and-receipts INV-R22): the POS Receipt as
// ESC/POS commands, the thermal printer's own language. Pure Dart.

const escInit = [0x1B, 0x40];
const _feed = [0x1B, 0x64, 0x03];

/// GS V 66 0: feed to the cutter, then cut.
const escCut = [0x1D, 0x56, 0x42, 0x00];

/// ESC p 0: a pulse on drawer pin 2 opens the cash drawer.
const escDrawer = [0x1B, 0x70, 0x00, 0x19, 0xFA];

List<int> _align(bool center) => [0x1B, 0x61, center ? 1 : 0];
List<int> _bold(bool on) => [0x1B, 0x45, on ? 1 : 0];

/// D-68: what the printer's basic character set can print. The currency
/// [symbol] becomes the currency [code], `×` becomes `x`; any other
/// character outside printable ASCII becomes `?`.
String printable(String text, {String? symbol, String? code}) {
  var s = text.replaceAll('×', 'x');
  if (symbol != null && symbol.isNotEmpty && code != null && !_ascii(symbol)) {
    s = s.replaceAll(symbol, code);
  }
  return String.fromCharCodes([
    for (final c in s.runes) c >= 0x20 && c < 0x7F ? c : 0x3F,
  ]);
}

bool _ascii(String s) => s.runes.every((c) => c >= 0x20 && c < 0x7F);

/// [lines] as one print job: initialise, the lines (centred and bold as
/// marked), the [barcode] as Code 128 (INV-R23), a feed, then the drawer
/// kick when [drawer] and the cut when [cut].
List<int> escPosJob(
  List<ReceiptLine> lines, {
  String? barcode,
  bool cut = true,
  bool drawer = false,
}) {
  final out = <int>[...escInit];
  for (final l in lines) {
    out
      ..addAll(_align(l.center))
      ..addAll(_bold(l.bold))
      ..addAll(ascii.encode(printable(l.text)))
      ..add(0x0A);
  }
  out.addAll(_bold(false));
  if (barcode case final code? when code.isNotEmpty) {
    final data = ascii.encode('{B${printable(code)}');
    out
      ..addAll(_align(true))
      ..addAll([0x1D, 0x68, 80]) // height
      ..addAll([0x1D, 0x77, 2]) // module width
      ..addAll([0x1D, 0x48, 2]) // the name printed under it
      ..addAll([0x1D, 0x6B, 73, data.length, ...data])
      ..add(0x0A);
  }
  out
    ..addAll(_align(false))
    ..addAll(_feed);
  if (drawer) out.addAll(escDrawer);
  if (cut) out.addAll(escCut);
  return out;
}

/// INV-R22's Test print: a ruler of the configured [width], so the
/// characters per line can be checked.
List<ReceiptLine> rulerLines(int width) => [
  (
    text: List.generate(width, (i) => '${(i + 1) % 10}').join(),
    center: false,
    bold: false,
  ),
  (text: '-' * width, center: false, bold: false),
];

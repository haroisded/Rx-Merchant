import 'print_layout.dart';

// The POS Receipt as lines of fixed-width text (05-invoices-and-receipts
// INV-R22): wrapped to Characters per line, amounts right-aligned. The raw
// printer prints these; pure Dart.

typedef ReceiptLine = ({String text, bool center, bool bold});

/// [doc] as receipt lines of at most [width] characters. [clean] maps every
/// text first, such as to what the printer can encode.
List<ReceiptLine> receiptLines(
  PrintDoc doc,
  int width, {
  String Function(String) clean = _same,
}) {
  final out = <ReceiptLine>[];
  void center(String text, {bool bold = false}) {
    for (final l in wrap(clean(text), width)) {
      out.add((text: l, center: true, bold: bold));
    }
  }

  void left(String text) {
    for (final l in wrap(clean(text), width)) {
      out.add((text: l, center: false, bold: false));
    }
  }

  void pair(String label, String value, {bool bold = false}) {
    for (final l in pairLines(clean(label), clean(value), width)) {
      out.add((text: l, center: false, bold: bold));
    }
  }

  final rule = '-' * width;
  for (final (i, l) in doc.header.indexed) {
    center(l, bold: i == 0);
  }
  center(doc.heading, bold: true);
  for (final r in doc.meta) {
    pair(r.label, r.value);
  }
  left(rule);
  for (final it in doc.items) {
    left(it.name);
    pair('  ${it.qtyRate}', it.amount);
    if (it.discount case final d?) left('  $d');
    for (final n in it.notes) {
      left('  $n');
    }
  }
  left(rule);
  for (final r in doc.totals) {
    pair(r.label, r.value, bold: r.strong);
  }
  if (doc.inWords case final w?) left(w);
  left(rule);
  for (final r in doc.payments) {
    pair(r.label, r.value);
  }
  if (doc.terms case final t?) {
    left(rule);
    for (final l in t.split('\n')) {
      left(l);
    }
  }
  for (final l in doc.footer) {
    center(l);
  }
  return out;
}

String _same(String s) => s;

/// [text] broken at spaces into lines of at most [width], each keeping its
/// leading indent; a word longer than a line is cut.
List<String> wrap(String text, int width) {
  final rest = text.trimLeft();
  final indent = text.substring(0, text.length - rest.length);
  if (indent.isNotEmpty && indent.length < width) {
    return [for (final l in wrap(rest, width - indent.length)) '$indent$l'];
  }
  final out = <String>[];
  var line = '';
  for (var word in rest.split(' ')) {
    if (word.isEmpty) continue;
    while (word.length > width) {
      if (line.isNotEmpty) out.add(line);
      out.add(word.substring(0, width));
      word = word.substring(width);
      line = '';
    }
    if (line.isEmpty) {
      line = word;
    } else if (line.length + 1 + word.length <= width) {
      line = '$line $word';
    } else {
      out.add(line);
      line = word;
    }
  }
  if (line.isNotEmpty || out.isEmpty) out.add(line);
  return out;
}

/// [label] on the left and [value] right-aligned on its last line, or on a
/// line of its own when they do not fit together.
List<String> pairLines(String label, String value, int width) {
  final lines = wrap(label, width);
  final last = lines.removeLast();
  if (last.length + 1 + value.length <= width) {
    return [...lines, last + value.padLeft(width - last.length)];
  }
  return [...lines, last, value.padLeft(width)];
}

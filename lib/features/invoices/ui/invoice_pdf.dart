import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/print_layout.dart';

// The two built-in Print Formats as PDF (05-invoices-and-receipts INV-R12,
// R14, R21, R23), both from the same PrintDoc.

/// POS Settings' `print_format` values.
enum PrintFormat {
  standard('Standard'),
  posReceipt('POS Receipt');

  const PrintFormat(this.value);

  final String value;

  static PrintFormat of(String value) =>
      value == 'Standard' ? standard : posReceipt;
}

/// Roboto, bundled (D-67), and the characters it can draw.
typedef PdfFonts = ({pw.Font regular, pw.Font bold, Set<int> runes});

Future<PdfFonts> loadPdfFonts() async {
  final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  return (
    regular: pw.Font.ttf(regular),
    bold: pw.Font.ttf(bold),
    runes: TtfParser(regular).charToGlyphIndexMap.keys.toSet(),
  );
}

/// Print Settings' PDF Page Size.
PdfPageFormat pageFormatOf(String size) => switch (size) {
  'A5' => PdfPageFormat.a5,
  'Letter' => PdfPageFormat.letter,
  _ => PdfPageFormat.a4,
};

/// [d] as a PDF document. Standard: on [pageSize], the letter head and
/// footer on every page when [repeatHeader], otherwise on the first and
/// last. POS Receipt: a roll [rollMm] wide (58 or 80), ending with the
/// barcode.
pw.Document invoiceDocument(
  PrintDoc d, {
  required PrintFormat format,
  required PdfFonts fonts,
  PdfPageFormat pageSize = PdfPageFormat.a4,
  bool repeatHeader = true,
  int rollMm = 80,
}) {
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );
  final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  pw.Widget pair(PrintRow r, {double size = 10}) => pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(
          r.label,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: r.strong ? pw.FontWeight.bold : null,
          ),
        ),
      ),
      pw.Text(
        r.value,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: r.strong ? pw.FontWeight.bold : null,
        ),
      ),
    ],
  );
  pw.Widget? logo(double height) =>
      d.logo == null ? null : pw.Image(pw.MemoryImage(d.logo!), height: height);

  if (format == PrintFormat.posReceipt) {
    const size = 8.0;
    final roll = rollMm < 70 ? PdfPageFormat.roll57 : PdfPageFormat.roll80;
    doc.addPage(
      pw.Page(
        pageFormat: roll.copyWith(
          marginLeft: 3 * PdfPageFormat.mm,
          marginRight: 3 * PdfPageFormat.mm,
          marginTop: 3 * PdfPageFormat.mm,
          marginBottom: 6 * PdfPageFormat.mm,
        ),
        build: (_) => pw.DefaultTextStyle(
          style: const pw.TextStyle(fontSize: size),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              ?logo(40),
              for (final (i, l) in d.header.indexed)
                pw.Text(
                  l,
                  textAlign: pw.TextAlign.center,
                  style: i == 0 ? bold : null,
                ),
              pw.SizedBox(height: 4),
              pw.Text(d.heading, textAlign: pw.TextAlign.center, style: bold),
              for (final r in d.meta) pair(r, size: size),
              pw.Divider(height: 6),
              for (final it in d.items) ...[
                pw.Text(it.name),
                pair((
                  label: '  ${it.qtyRate}',
                  value: it.amount,
                  strong: false,
                ), size: size),
                if (it.discount case final t?) pw.Text('  $t'),
                for (final n in it.notes) pw.Text('  $n'),
              ],
              pw.Divider(height: 6),
              for (final r in d.totals) pair(r, size: size),
              if (d.inWords case final w?) pw.Text(w),
              pw.Divider(height: 6),
              for (final r in d.payments) pair(r, size: size),
              if (d.terms case final t?) ...[pw.Divider(height: 6), pw.Text(t)],
              for (final l in d.footer)
                pw.Text(l, textAlign: pw.TextAlign.center),
              if (d.barcode case final code?) ...[
                pw.SizedBox(height: 6),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: code,
                  height: 36,
                  textStyle: const pw.TextStyle(fontSize: size),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return doc;
  }

  final header = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      ?logo(48),
      for (final (i, l) in d.header.indexed)
        pw.Text(l, style: i == 0 ? bold.copyWith(fontSize: 14) : null),
      pw.SizedBox(height: 8),
    ],
  );
  final footer = pw.Column(
    children: [
      for (final l in d.footer)
        pw.Text(
          l,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9),
        ),
    ],
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: pageSize,
      header: (ctx) =>
          repeatHeader || ctx.pageNumber == 1 ? header : pw.SizedBox(),
      footer: (ctx) => repeatHeader || ctx.pageNumber == ctx.pagesCount
          ? footer
          : pw.SizedBox(),
      build: (_) => [
        pw.Text(d.heading, style: bold.copyWith(fontSize: 18)),
        pw.SizedBox(height: 6),
        for (final r in d.meta) pair(r),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: d.columns,
          data: d.rows,
          headerStyle: bold.copyWith(fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          // Quantities and amounts on the right (INV-R17's columns).
          cellAlignments: {
            for (final c in d.numeric) c: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 260,
            // INV-R18: totals, In Words, then payments and change.
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final r in d.totals) pair(r),
                if (d.inWords case final w?) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(w, style: const pw.TextStyle(fontSize: 9)),
                ],
                pw.Divider(height: 8),
                for (final r in d.payments) pair(r),
              ],
            ),
          ),
        ),
        if (d.terms case final t?) ...[
          pw.SizedBox(height: 12),
          pw.Text(t, style: const pw.TextStyle(fontSize: 9)),
        ],
      ],
    ),
  );
  return doc;
}

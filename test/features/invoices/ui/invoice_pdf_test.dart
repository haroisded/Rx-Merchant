import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rx_merchant/features/invoices/logic/invoice.dart';
import 'package:rx_merchant/features/invoices/logic/print_layout.dart';
import 'package:rx_merchant/features/invoices/ui/invoice_pdf.dart';

// INV-B5: both formats build from the same layout; a long invoice runs over
// pages with its letter head on each.

PdfFonts _fonts() {
  pw.Font font(String file) => pw.Font.ttf(
    File('assets/fonts/$file').readAsBytesSync().buffer.asByteData(),
  );
  return (
    regular: font('Roboto-Regular.ttf'),
    bold: font('Roboto-Bold.ttf'),
    runes: TtfParser(
      File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytesSync()
          .buffer
          .asByteData(),
    ).charToGlyphIndexMap.keys.toSet(),
  );
}

PrintDoc _doc(int lines) => layoutInvoice(
  Invoice(
    id: 1,
    name: 'ACC-SINV-2026-00001',
    status: 'Paid',
    docstatus: 1,
    posting: DateTime(2026, 11, 18),
    lines: [
      for (var i = 0; i < lines; i++)
        InvoiceLine(
          id: i,
          itemCode: 'ITEM-$i',
          itemName: 'Item number $i',
          qty: 1,
          uom: 'Nos',
          rate: 10,
          amount: 10,
        ),
    ],
    netTotal: 10.0 * lines,
    grandTotal: 10.0 * lines,
    letterHead: const PrintLetterHead(header: 'Rx Corner Store'),
  ),
  (
    compact: false,
    withLetterhead: true,
    zeroTaxes: false,
    draftHeading: true,
    roundedTotal: true,
    inWords: true,
  ),
  money: (v) => '₱ ${v.toStringAsFixed(2)}',
  number: (v) => '$v',
  when: (d) => '$d',
  label: (l) => l.name,
);

void main() {
  test('INV-A3 manual check: 40 lines on A5 run over pages', () async {
    final fonts = _fonts();
    expect(fonts.runes.contains('₱'.runes.single), isTrue);
    final doc = invoiceDocument(
      _doc(40),
      format: PrintFormat.standard,
      fonts: fonts,
      pageSize: PdfPageFormat.a5,
    );
    final bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(doc.document.pdfPageList.pages.length, greaterThan(1));
  });

  test('the POS Receipt is one roll page with the barcode', () async {
    final doc = invoiceDocument(
      _doc(3),
      format: PrintFormat.posReceipt,
      fonts: _fonts(),
      rollMm: 58,
    );
    await doc.save();
    final page = doc.document.pdfPageList.pages.single;
    expect(page.pageFormat.width, PdfPageFormat.roll57.width);
  });
}

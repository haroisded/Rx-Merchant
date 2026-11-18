import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/invoices/logic/escpos.dart';
import 'package:rx_merchant/features/invoices/logic/invoice.dart';
import 'package:rx_merchant/features/invoices/logic/print_layout.dart';
import 'package:rx_merchant/features/invoices/logic/receipt_text.dart';

// 05-invoices-and-receipts section 7: unit tests of the print layout and
// raw printing.

const _options = (
  compact: true,
  withLetterhead: true,
  zeroTaxes: false,
  draftHeading: true,
  roundedTotal: true,
  inWords: true,
);

Invoice _invoice({
  String status = 'Paid',
  String itemName = 'Paracetamol 500mg',
  List<InvoiceTax> taxes = const [
    InvoiceTax(description: 'VAT', amount: 8),
    InvoiceTax(description: 'Levy', amount: 0),
  ],
}) => Invoice(
  id: 1,
  name: status == 'Draft' ? null : 'ACC-SINV-2026-00001',
  status: status,
  docstatus: status == 'Draft' ? 0 : 1,
  posting: DateTime(2026, 11, 18, 9, 30),
  lines: [
    InvoiceLine(
      id: 1,
      itemCode: 'PARA500',
      itemName: itemName,
      qty: 2,
      uom: 'Nos',
      rate: 50,
      amount: 100,
    ),
  ],
  taxes: taxes,
  payments: const [(mode: 'Cash', amount: 120)],
  netTotal: 100,
  grandTotal: 108,
  roundingAdjustment: 0.5,
  roundedTotal: 108.5,
  changeAmount: 11.5,
  inWords: 'PHP One Hundred And Eight and Fifty Centavo only.',
  letterHead: const PrintLetterHead(header: 'Rx Corner Store\nMain Street'),
);

PrintDoc _layout(Invoice inv, [PrintOptions o = _options]) => layoutInvoice(
  inv,
  o,
  money: (v) => '₱ ${v.toStringAsFixed(2)}',
  number: (v) => '$v',
  when: (d) => '$d',
  label: (l) => switch (l) {
    PrintLabel.draft => 'DRAFT',
    PrintLabel.salesInvoice => 'Sales Invoice',
    _ => l.name,
  },
);

void main() {
  test('INV-A3 Compact Item Print on / off: 4 / 9 columns', () {
    expect(_layout(_invoice()).columns, hasLength(4));
    final full = _layout(_invoice(), (
      compact: false,
      withLetterhead: true,
      zeroTaxes: false,
      draftHeading: true,
      roundedTotal: true,
      inWords: true,
    ));
    expect(full.columns, hasLength(9));
    expect(full.rows.single, hasLength(9));
  });

  test('INV-A4 a zero tax row is left out unless asked for', () {
    List<String> labels(PrintDoc d) => [for (final r in d.totals) r.label];
    expect(labels(_layout(_invoice())), isNot(contains('Levy')));
    final on = _layout(_invoice(), (
      compact: true,
      withLetterhead: true,
      zeroTaxes: true,
      draftHeading: true,
      roundedTotal: true,
      inWords: true,
    ));
    expect(labels(on), contains('Levy'));
  });

  test('INV-A5 Disable Rounded Total: no rounding lines', () {
    final d = _layout(_invoice(), (
      compact: true,
      withLetterhead: true,
      zeroTaxes: false,
      draftHeading: true,
      roundedTotal: false,
      inWords: true,
    ));
    expect(
      [for (final r in d.totals) r.label],
      ['netTotal', 'VAT', 'grandTotal'],
    );
  });

  test('INV-A6 a receipt at 32 characters wraps a long name', () {
    final name = 'Paracetamol 500mg film-coated tablets, box of 100 pcs ABC';
    expect(name.length, greaterThan(55));
    final lines = receiptLines(_layout(_invoice(itemName: name)), 32);
    expect(lines.every((l) => l.text.length <= 32), isTrue);
    final amount = lines.firstWhere((l) => l.text.contains('×')).text;
    expect(amount.length, 32);
    expect(amount, endsWith('₱ 100.00'));
  });

  test('INV-A7 raw commands: initialise first, cut last, no drawer', () {
    final job = escPosJob(
      receiptLines(_layout(_invoice()), 48),
      barcode: 'ACC-SINV-2026-00001',
      cut: true,
      drawer: false,
    );
    expect(job.take(2), escInit);
    expect(job.skip(job.length - 4), escCut);
    bool has(List<int> part) {
      for (var i = 0; i + part.length <= job.length; i++) {
        var all = true;
        for (var k = 0; k < part.length && all; k++) {
          all = job[i + k] == part[k];
        }
        if (all) return true;
      }
      return false;
    }

    expect(has(escDrawer), isFalse);
    final kicked = escPosJob(const [], drawer: true, cut: true);
    expect(kicked.skip(kicked.length - 9).take(5), escDrawer);
  });

  test('INV-A8 a currency symbol the printer cannot print', () {
    expect(printable('₱ 12.00', symbol: '₱', code: 'PHP'), 'PHP 12.00');
    expect(printable('Café', symbol: '\$', code: 'USD'), 'Caf?');
    final lines = receiptLines(
      _layout(_invoice()),
      32,
      clean: (s) => printable(s, symbol: '₱', code: 'PHP'),
    );
    expect(lines.any((l) => l.text.contains('PHP 100.00')), isTrue);
    expect(lines.any((l) => l.text.contains('₱')), isFalse);
    // The item line's × prints as x, not ?.
    expect(lines.any((l) => l.text.contains('2.0 x PHP 50.00')), isTrue);
  });

  test('INV-A9, R13 a draft is marked; what may be printed', () {
    expect(_layout(_invoice(status: 'Draft')).heading, contains('DRAFT'));
    expect(_layout(_invoice()).heading, 'Sales Invoice');
    expect(
      mayPrint('Cancelled', allowDraft: true, allowCancelled: false),
      isFalse,
    );
    expect(mayPrint('Draft', allowDraft: false, allowCancelled: true), isFalse);
    expect(mayPrint('Paid', allowDraft: false, allowCancelled: false), isTrue);
  });

  test('INV-R14, R18 letter head, totals order, In Words, change', () {
    final d = _layout(_invoice());
    expect(d.header, ['Rx Corner Store', 'Main Street']);
    expect(
      [for (final r in d.totals) r.label],
      ['netTotal', 'VAT', 'grandTotal', 'roundingAdjustment', 'roundedTotal'],
    );
    expect(d.inWords, startsWith('PHP One Hundred'));
    expect(d.payments.last.label, 'changeAmount');
    final bare = _layout(_invoice(), (
      compact: true,
      withLetterhead: false,
      zeroTaxes: false,
      draftHeading: true,
      roundedTotal: true,
      inWords: false,
    ));
    expect(bare.header, isEmpty);
    expect(bare.inWords, isNull);
  });
}

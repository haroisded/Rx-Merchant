import 'dart:typed_data';

import 'invoice.dart';

// The one layout step both print formats are built from (05-invoices-and-
// receipts INV-R12 to R20): an invoice becomes print blocks of text. Pure
// Dart; the screen passes the formatters and the translated labels.

/// The words the print uses, translated by the screen.
enum PrintLabel {
  salesInvoice,
  creditNote,
  draft,
  cancelled,
  invoiceNo,
  date,
  returnAgainst,
  sr,
  itemCode,
  itemName,
  description,
  qty,
  uom,
  rate,
  discount,
  amount,
  netTotal,
  included,
  additionalDiscount,
  grandTotal,
  roundingAdjustment,
  roundedTotal,
  changeAmount,
}

typedef PrintRow = ({String label, String value, bool strong});

/// One line of the receipt's item list (INV-R17): the name, `qty × rate`
/// and the amount, then a discount and any serial or batch numbers.
typedef ReceiptItem = ({
  String name,
  String qtyRate,
  String amount,
  String? discount,
  List<String> notes,
});

/// What Print Settings and Global Defaults decide.
typedef PrintOptions = ({
  bool compact,
  bool withLetterhead,
  bool zeroTaxes,
  bool draftHeading,
  bool roundedTotal,
  bool inWords,
});

class PrintDoc {
  const PrintDoc({
    required this.heading,
    this.logo,
    this.header = const [],
    this.footer = const [],
    required this.meta,
    required this.columns,
    required this.numeric,
    required this.rows,
    required this.items,
    required this.totals,
    required this.payments,
    this.inWords,
    this.terms,
    this.barcode,
  });

  /// INV-R15, R13: the document's title, marked DRAFT or CANCELLED.
  final String heading;
  final Uint8List? logo;

  /// The letter head's lines (INV-R14).
  final List<String> header;
  final List<String> footer;
  final List<PrintRow> meta;

  /// The Standard format's item table: 4 columns compact, 9 otherwise.
  final List<String> columns;

  /// The columns of quantities and amounts, printed on the right.
  final Set<int> numeric;
  final List<List<String>> rows;

  /// The POS Receipt's item list, always compact.
  final List<ReceiptItem> items;
  final List<PrintRow> totals;
  final List<PrintRow> payments;
  final String? inWords;
  final String? terms;

  /// INV-R23: the invoice name, printed as Code 128 on the receipt.
  final String? barcode;
}

/// INV-R13: a draft prints only with Allow Print for Draft, a cancelled
/// invoice only with Allow Print for Cancelled.
bool mayPrint(
  String status, {
  required bool allowDraft,
  required bool allowCancelled,
}) => switch (status) {
  'Draft' => allowDraft,
  'Cancelled' => allowCancelled,
  _ => true,
};

/// INV-R14 to R20: invoice [inv] as print blocks. [money] and [number]
/// format amounts and quantities (INV-R20), [when] a date and time; [label]
/// gives the translated words.
PrintDoc layoutInvoice(
  Invoice inv,
  PrintOptions o, {
  required String Function(num) money,
  required String Function(num) number,
  required String Function(DateTime) when,
  required String Function(PrintLabel) label,
}) {
  PrintRow row(PrintLabel l, String value, {bool strong = false}) =>
      (label: label(l), value: value, strong: strong);
  var heading =
      inv.heading ??
      label(inv.isReturn ? PrintLabel.creditNote : PrintLabel.salesInvoice);
  if (inv.status == 'Draft' && o.draftHeading) {
    heading = '${label(PrintLabel.draft)} $heading';
  }
  if (inv.status == 'Cancelled') {
    heading = '${label(PrintLabel.cancelled)} $heading';
  }
  final head = o.withLetterhead ? inv.letterHead : null;
  List<String> lines(String? text) => [
    for (final l in (text ?? '').split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  String discountOf(InvoiceLine l) => l.discountAmount == 0
      ? ''
      : '${label(PrintLabel.discount)} ${number(l.discountPercentage)}% '
            '(${money(-l.discountAmount)})';
  final notes = [
    for (final l in inv.lines) [...l.batches, ...l.serials],
  ];
  final full = [
    PrintLabel.sr,
    PrintLabel.itemCode,
    PrintLabel.itemName,
    PrintLabel.description,
    PrintLabel.qty,
    PrintLabel.uom,
    PrintLabel.rate,
    PrintLabel.discount,
    PrintLabel.amount,
  ];
  final compact = [
    PrintLabel.description,
    PrintLabel.qty,
    PrintLabel.rate,
    PrintLabel.amount,
  ];

  final totals = <PrintRow>[
    row(PrintLabel.netTotal, money(inv.netTotal)),
    for (final t in inv.taxes)
      if (t.amount != 0 || o.zeroTaxes)
        (
          label: t.included
              ? '${t.description} (${label(PrintLabel.included)})'
              : t.description,
          value: money(t.amount),
          strong: false,
        ),
    if (inv.discountAmount != 0)
      row(PrintLabel.additionalDiscount, money(-inv.discountAmount)),
    row(PrintLabel.grandTotal, money(inv.grandTotal), strong: true),
    if (o.roundedTotal && inv.roundedTotal != 0) ...[
      row(PrintLabel.roundingAdjustment, money(inv.roundingAdjustment)),
      row(PrintLabel.roundedTotal, money(inv.roundedTotal), strong: true),
    ],
  ];

  return PrintDoc(
    heading: heading,
    logo: head?.image,
    header: lines(head?.header),
    footer: lines(head?.footer),
    meta: [
      row(PrintLabel.invoiceNo, inv.name ?? label(PrintLabel.draft)),
      row(PrintLabel.date, when(inv.posting)),
      if (inv.against case final a?) row(PrintLabel.returnAgainst, a.name),
    ],
    columns: [for (final c in o.compact ? compact : full) label(c)],
    numeric: o.compact ? const {1, 2, 3} : const {4, 6, 7, 8},
    rows: [
      for (final (i, l) in inv.lines.indexed)
        o.compact
            ? [
                [
                  l.itemName,
                  if (l.itemCode != l.itemName) l.itemCode,
                  ?l.description,
                  if (l.discountAmount != 0) discountOf(l),
                  ...notes[i],
                ].join('\n'),
                '${number(l.qty)} ${l.uom}',
                money(l.rate),
                money(l.amount),
              ]
            : [
                '${i + 1}',
                l.itemCode,
                l.itemName,
                [?l.description, ...notes[i]].join('\n'),
                number(l.qty),
                l.uom,
                money(l.rate),
                l.discountAmount == 0 ? '' : '${number(l.discountPercentage)}%',
                money(l.amount),
              ],
    ],
    items: [
      for (final (i, l) in inv.lines.indexed)
        (
          name: l.itemName,
          qtyRate: '${number(l.qty)} × ${money(l.rate)}',
          amount: money(l.amount),
          discount: l.discountAmount == 0 ? null : discountOf(l),
          notes: notes[i],
        ),
    ],
    totals: totals,
    payments: [
      for (final p in inv.payments)
        (label: p.mode, value: money(p.amount), strong: false),
      if (!inv.isReturn) row(PrintLabel.changeAmount, money(inv.changeAmount)),
    ],
    inWords: o.inWords ? inv.inWords : null,
    terms: inv.terms?.trim().isEmpty ?? true ? null : inv.terms!.trim(),
    barcode: inv.name,
  );
}

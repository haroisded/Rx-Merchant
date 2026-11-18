import 'dart:typed_data';

// A submitted (or draft, or cancelled) Sales Invoice as the detail screen and
// the print layout read it (05-invoices-and-receipts INV-R2). Plain Dart, so
// the layout stays testable without a database.

class InvoiceLine {
  const InvoiceLine({
    required this.id,
    required this.itemCode,
    required this.itemName,
    this.description,
    required this.qty,
    required this.uom,
    required this.rate,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    required this.amount,
    this.serials = const [],
    this.batches = const [],
  });

  final int id;
  final String itemCode;
  final String itemName;
  final String? description;

  /// Negative on a return.
  final double qty;
  final String uom;

  /// The rate the buyer was quoted (tax-inclusive when taxes are included).
  final double rate;
  final double discountPercentage;
  final double discountAmount;
  final double amount;
  final List<String> serials;
  final List<String> batches;
}

class InvoiceTax {
  const InvoiceTax({
    required this.description,
    required this.amount,
    this.included = false,
  });

  final String description;

  /// The amount in the Grand Total (after any additional discount).
  final double amount;

  /// Included in the rate (POS-R12): printed with "(included)".
  final bool included;
}

typedef InvoicePayment = ({String mode, double amount});
typedef InvoiceRef = ({int id, String name, String status});

class PrintLetterHead {
  const PrintLetterHead({this.image, this.header, this.footer});

  final Uint8List? image;
  final String? header;
  final String? footer;
}

class Invoice {
  const Invoice({
    required this.id,
    this.name,
    required this.status,
    required this.docstatus,
    this.isReturn = false,
    required this.posting,
    this.session,
    this.sessionOpen = false,
    this.updateStock = true,
    this.warehouse = '',
    this.against,
    this.returns = const [],
    this.lines = const [],
    this.taxes = const [],
    this.payments = const [],
    this.netTotal = 0,
    this.discountAmount = 0,
    this.grandTotal = 0,
    this.roundingAdjustment = 0,
    this.roundedTotal = 0,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.inWords,
    this.heading,
    this.terms,
    this.letterHead,
  });

  final int id;

  /// Null for a draft (INV-R4).
  final String? name;
  final String status;
  final int docstatus;
  final bool isReturn;
  final DateTime posting;
  final String? session;

  /// Its POS session is still open (INV-R10, R11).
  final bool sessionOpen;
  final bool updateStock;
  final String warehouse;

  /// The sale this return was made against.
  final InvoiceRef? against;

  /// The returns made against this sale.
  final List<InvoiceRef> returns;
  final List<InvoiceLine> lines;
  final List<InvoiceTax> taxes;
  final List<InvoicePayment> payments;
  final double netTotal;
  final double discountAmount;
  final double grandTotal;
  final double roundingAdjustment;

  /// 0 when Disable Rounded Total was on at the sale.
  final double roundedTotal;
  final double paidAmount;
  final double changeAmount;
  final String? inWords;

  /// The Print Heading chosen for the sale (INV-R15), if any.
  final String? heading;
  final String? terms;
  final PrintLetterHead? letterHead;
}

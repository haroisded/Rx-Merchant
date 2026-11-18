import 'dart:convert';

import '../../setup/logic/tax_template.dart';
import '../../stock/logic/stock_documents.dart';

// The sale being built at the Cash Register: a Sales Invoice before it is
// saved (03-cash-register section 3). No database or Flutter import.

/// A line's Item Tax Template rates: tax id -> rate, or Not Applicable
/// (SET-R12, POS-R11).
typedef ItemTaxRates = Map<int, ({double rate, bool notApplicable})>;

/// One cart line (`sales_invoice_item`).
class SaleLine {
  SaleLine({
    this.id,
    required this.itemId,
    required this.itemName,
    required this.uomId,
    this.factor = 1,
    this.qty = 1,
    this.priceListRate = 0,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.rate = 0,
    this.itemTaxTemplateId,
    ItemTaxRates? itemTax,
    List<SbEntry>? entries,
  }) : itemTax = itemTax ?? {},
       entries = entries ?? [];

  int? id;
  int itemId;
  String itemName;
  int uomId;

  /// Stock units in one [uomId] (POS-R5).
  double factor;
  double qty;
  double priceListRate;
  double discountPercentage;
  double discountAmount;
  double rate;
  int? itemTaxTemplateId;
  ItemTaxRates itemTax;

  /// Serial / Batch Entries (POS-R21).
  List<SbEntry> entries;

  /// On a return: the original line (INV-R5) and the cost per stock unit it
  /// went out at, which the goods come back in at (STK-R33).
  int? againstLineId;
  double incomingRate = 0;

  /// The batch of a line that holds one batch, for merging (POS-R4).
  String? get batchNo => entries.length == 1 && entries.first.serialNo == null
      ? entries.first.batchNo
      : null;
}

/// The sale's header and children (POS-R2a).
class Sale {
  Sale({
    this.id,
    required this.warehouseId,
    required this.priceListId,
    this.taxesTemplateId,
    this.taxes = const [],
    this.discountOnNetTotal = false,
    this.letterHeadId,
    this.printHeadingId,
    this.tcId,
    this.terms,
  });

  /// The draft's id once saved (POS-R18).
  int? id;
  int warehouseId;
  int priceListId;
  int? taxesTemplateId;

  /// Copied from the template when the sale starts (SET-R10).
  List<TaxRow> taxes;

  /// Apply Discount On: Net Total, else Grand Total (POS-R13).
  bool discountOnNetTotal;
  double additionalDiscountPercentage = 0;

  /// Typed when no percentage is given.
  double discountAmount = 0;
  int? letterHeadId;
  int? printHeadingId;
  int? tcId;
  String? terms;
  final lines = <SaleLine>[];

  /// Mode of payment id -> amount tendered (POS-R15); negative on a return.
  final payments = <int, double>{};

  /// A return (Credit Note) against this sale (INV-R5).
  int? returnAgainstId;

  /// INV-R6: off for a price-only credit, where no goods move.
  bool updateStock = true;

  /// Changed since it was last saved (Action on New Invoice, POS-R18).
  bool dirty = false;
}

/// A submitted sale and its name, for the order summary.
typedef Submitted = ({Sale sale, String name});

/// POS-R4, R21: [line] (one unit, with serial or batch [entry] if any) joins
/// the cart. A line with the same item, unit, rate and batch takes it; a
/// scanned serial joins a line whose units are all chosen, once.
void addToSale(Sale sale, SaleLine line, SbEntry? entry) {
  if (entry != null) line.entries.add(entry);
  final serial = entry?.serialNo;
  final same = sale.lines.where(
    (l) =>
        l.itemId == line.itemId &&
        l.uomId == line.uomId &&
        l.rate == line.rate &&
        (serial != null
            ? l.entries.length == l.qty &&
                  l.entries.every((e) => e.serialNo != null)
            : l.batchNo == line.batchNo),
  );
  final l = same.firstOrNull;
  if (l == null) return sale.lines.add(line);
  if (serial != null && l.entries.any((e) => e.serialNo == serial)) return;
  l.qty += 1;
  if (serial != null) {
    l.entries.add(entry!);
  } else if (entry != null) {
    l.entries.first.qty += 1;
  }
}

/// `sales_invoice_item.item_tax_rate`: tax id -> rate, "NA" for Not
/// Applicable (POS-A4).
String itemTaxJson(ItemTaxRates rates) => jsonEncode({
  for (final MapEntry(:key, :value) in rates.entries)
    '$key': value.notApplicable ? 'NA' : value.rate,
});

ItemTaxRates itemTaxFromJson(String json) => {
  for (final MapEntry(:key, :value)
      in (jsonDecode(json) as Map<String, dynamic>).entries)
    int.parse(key): value == 'NA'
        ? (rate: 0.0, notApplicable: true)
        : (rate: (value as num).toDouble(), notApplicable: false),
};

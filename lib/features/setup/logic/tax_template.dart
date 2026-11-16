import '../../../core/numbers/flt.dart';

/// The Type of a tax row (Types in Tax Template). [value] is what the
/// `charge_type` column stores.
enum ChargeType {
  actual('Actual'),
  onNetTotal('On Net Total'),
  onPreviousRowAmount('On Previous Row Amount'),
  onPreviousRowTotal('On Previous Row Total'),
  onItemQuantity('On Item Quantity');

  const ChargeType(this.value);
  final String value;

  static ChargeType of(String value) =>
      values.firstWhere((t) => t.value == value);

  /// Only these types take a Reference Row # (SET-R9).
  bool get isPreviousRow =>
      this == onPreviousRowAmount || this == onPreviousRowTotal;
}

/// One row of a Sales Taxes and Charges Template, as edited in its form.
class TaxRow {
  const TaxRow({
    required this.chargeType,
    this.taxId,
    this.description,
    this.rate = 0,
    this.taxAmount = 0,
    this.rowId,
    this.included = false,
  });

  final ChargeType chargeType;
  final int? taxId;
  final String? description;

  /// Percent; an amount per unit for On Item Quantity; ignored for Actual.
  final double rate;

  /// Used by Actual only.
  final double taxAmount;

  /// Reference Row #, 1-based.
  final int? rowId;

  /// Is this Tax included in Basic Rate?
  final bool included;
}

enum TaxRowProblem {
  missingTax,
  previousRowInFirstRow,
  missingReferenceRow,
  referenceRowNotEarlier,
  actualIncluded,
  includedReferenceNotIncluded,
}

/// The SET-R9 checks, as (row number, problem). Rows are in `idx` order.
List<(int, TaxRowProblem)> validateTaxRows(List<TaxRow> rows) {
  final problems = <(int, TaxRowProblem)>[];
  for (final (i, row) in rows.indexed) {
    final n = i + 1;
    if (row.taxId == null) problems.add((n, TaxRowProblem.missingTax));
    if (row.chargeType == ChargeType.actual && row.included) {
      problems.add((n, TaxRowProblem.actualIncluded));
    }
    if (!row.chargeType.isPreviousRow) continue;
    final ref = row.rowId;
    if (n == 1) {
      problems.add((n, TaxRowProblem.previousRowInFirstRow));
    } else if (ref == null) {
      problems.add((n, TaxRowProblem.missingReferenceRow));
    } else if (ref < 1 || ref >= n) {
      problems.add((n, TaxRowProblem.referenceRowNotEarlier));
    } else if (row.included && !rows[ref - 1].included) {
      problems.add((n, TaxRowProblem.includedReferenceNotIncluded));
    }
  }
  return problems;
}

/// The "Try it" panel: each row's Amount and running Total on a [net] amount
/// and a total quantity [qty], calculated in `idx` order (SET-R9). Rows must
/// have passed [validateTaxRows].
List<({double amount, double total})> tryTaxes(
  List<TaxRow> rows, {
  required double net,
  required double qty,
  required int precision,
  RoundingMethod method = RoundingMethod.bankers,
}) {
  final out = <({double amount, double total})>[];
  var total = flt(net, precision, method);
  for (final row in rows) {
    final raw = switch (row.chargeType) {
      ChargeType.actual => row.taxAmount,
      ChargeType.onNetTotal => net * row.rate / 100,
      ChargeType.onPreviousRowAmount =>
        out[row.rowId! - 1].amount * row.rate / 100,
      ChargeType.onPreviousRowTotal =>
        out[row.rowId! - 1].total * row.rate / 100,
      ChargeType.onItemQuantity => qty * row.rate,
    };
    final amount = flt(raw, precision, method);
    total = flt(total + amount, precision, method);
    out.add((amount: amount, total: total));
  }
  return out;
}

/// SET-R12: the rate a sale's tax [row] applies to an item, given the item's
/// Item Tax Template rows as `tax id → (tax_rate, not_applicable)`. Null means
/// the tax does not apply to the item at all (Not Applicable), which is not
/// the same as a rate of 0.
double? effectiveRate(
  TaxRow row,
  Map<int, ({double rate, bool notApplicable})> itemTemplate,
) {
  final override = itemTemplate[row.taxId];
  if (override == null) return row.rate;
  return override.notApplicable ? null : override.rate;
}

/// [rows] without row number [n] (1-based). References to later rows move
/// up by one so they keep pointing at the same row; a reference to the
/// removed row is cleared, which `validateTaxRows` then reports.
List<TaxRow> removeTaxRow(List<TaxRow> rows, int n) => [
  for (final (i, r) in rows.indexed)
    if (i != n - 1)
      switch (r.rowId) {
        final ref? when ref >= n => TaxRow(
          chargeType: r.chargeType,
          taxId: r.taxId,
          description: r.description,
          rate: r.rate,
          taxAmount: r.taxAmount,
          rowId: ref == n ? null : ref - 1,
          included: r.included,
        ),
        _ => r,
      },
];

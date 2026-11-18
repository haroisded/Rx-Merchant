import '../../../core/numbers/flt.dart';
import '../../pos/logic/sale.dart';
import '../../setup/logic/tax_template.dart';
import '../../stock/logic/stock_documents.dart';

// A Return / Credit Note (05-invoices-and-receipts INV-R5 to R7), pure Dart.

/// What a return is scaled by: the original sale's Total, its additional
/// discount (a percentage, or an amount when the percentage is 0) and the
/// fixed amount of each Actual tax row.
typedef ReturnBasis = ({
  double total,
  double discountPercentage,
  double discountAmount,
  List<double> actual,
});

/// INV-R7 (D-62): a return refunds the original's additional discount and
/// fixed (Actual) charges in proportion to the line amounts it returns, so
/// a full return refunds exactly what was paid. A percentage discount is
/// proportional by itself.
void scaleReturn(
  Sale ret,
  ReturnBasis basis, {
  required int precision,
  RoundingMethod method = RoundingMethod.bankers,
}) {
  double f(num v) => flt(v, precision, method);
  final returned = f(ret.lines.fold(0.0, (s, l) => s + f(l.rate * l.qty)));
  // Negative: −1 on a full return.
  final share = basis.total == 0 ? 0.0 : returned / basis.total;
  ret
    ..additionalDiscountPercentage = basis.discountPercentage
    ..discountAmount = basis.discountPercentage != 0
        ? 0
        : f(basis.discountAmount * share)
    ..taxes = [
      for (final (k, t) in ret.taxes.indexed)
        t.chargeType != ChargeType.actual
            ? t
            : TaxRow(
                chargeType: t.chargeType,
                taxId: t.taxId,
                description: t.description,
                rate: t.rate,
                taxAmount: f(basis.actual[k] * share),
                rowId: t.rowId,
                included: t.included,
              ),
    ];
}

/// INV-R6, D-65: [qty] stock units of a batch line taken from the batches
/// still returnable ([left], in the order they were sold).
List<SbEntry> takeBatches(List<SbEntry> left, double qty) {
  final out = <SbEntry>[];
  var need = qty;
  for (final e in left) {
    if (need <= 1e-9) break;
    final take = e.qty < need ? e.qty : need;
    out.add(SbEntry(batchNo: e.batchNo, qty: take));
    need -= take;
  }
  return out;
}

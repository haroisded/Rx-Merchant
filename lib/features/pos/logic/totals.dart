import 'dart:math' as math;

import '../../../core/numbers/flt.dart';
import '../../setup/logic/tax_template.dart';
import 'sale.dart';

// The totals engine (03-cash-register POS-R7 to R15). One pure function
// recalculates the whole sale after every change, in the order of ERPNext's
// taxes_and_totals: item values, taxes included in the rate worked back,
// net total, taxes, additional discount, grand and rounded total.

/// Each line's values after the calculation.
typedef LineTotals = ({double amount, double netRate, double netAmount});

/// One tax row after the calculation. [itemWise] is, per line index, the
/// rate in force (null for Not Applicable) and the line's amount.
typedef TaxTotals = ({
  double taxAmount,
  double taxAmountAfterDiscount,
  double total,
  Map<int, (double?, double)> itemWise,
});

class Totals {
  const Totals({
    required this.lines,
    required this.taxes,
    required this.totalQty,
    required this.total,
    required this.netTotal,
    required this.discountAmount,
    required this.totalTaxes,
    required this.grandTotal,
    required this.roundingAdjustment,
    required this.roundedTotal,
    required this.rounded,
  });

  final List<LineTotals> lines;
  final List<TaxTotals> taxes;
  final double totalQty;

  /// Σ amount, before any additional discount.
  final double total;
  final double netTotal;
  final double discountAmount;
  final double totalTaxes;
  final double grandTotal;
  final double roundingAdjustment;

  /// 0 when Disable Rounded Total is on ([rounded] false).
  final double roundedTotal;
  final bool rounded;

  /// POS-R14: Rounded Total when it exists, otherwise Grand Total.
  double get toPay => rounded ? roundedTotal : grandTotal;
}

/// POS-R9 to R14 for [lines] and the sale's [taxes] (in `idx` order, valid
/// under SET-R9). The additional discount is [discountPercentage] of the
/// base, or [discountAmount] when no percentage is given, on Net Total or
/// Grand Total.
Totals computeTotals(
  List<SaleLine> lines,
  List<TaxRow> taxes, {
  double discountPercentage = 0,
  double discountAmount = 0,
  bool discountOnNetTotal = false,
  required int precision,
  RoundingMethod method = RoundingMethod.bankers,
  double smallestFraction = 0,
  bool disableRoundedTotal = false,
}) {
  final c = _Calc(lines, taxes, precision, method);
  final amount = [for (final l in lines) c.f(l.rate * l.qty)];
  final total = c.f(amount.fold(0.0, (s, a) => s + a));
  final net = [...amount];
  final netRate = [for (final l in lines) l.rate];
  c.workBackIncluded(amount, net, netRate);

  final first = c.taxes(net, total);
  var result = first;

  // POS-R13: the additional discount, spread over the lines' net amounts.
  final netTotal = first.netTotal;
  final discount = discountPercentage != 0
      ? c.f(
          (discountOnNetTotal ? netTotal : first.grandTotal) *
              discountPercentage /
              100,
        )
      : c.f(discountAmount);
  // On Grand Total, fixed charges are not discounted.
  final over = discountOnNetTotal
      ? netTotal
      : c.f(first.grandTotal - c.fixedTaxes(first.taxes));
  if (discount != 0 && over != 0) {
    var sum = 0.0;
    for (final (i, l) in lines.indexed) {
      net[i] = c.f(net[i] - discount * net[i] / over);
      sum += net[i];
      if (i == lines.length - 1 &&
          (discountOnNetTotal || taxes.isEmpty || over == netTotal)) {
        net[i] = c.f(net[i] + c.f(netTotal - sum - discount));
      }
      netRate[i] = l.qty == 0 ? 0 : c.f(net[i] / l.qty);
    }
    result = c.taxes(
      net,
      total,
      discount: discount,
      // On Grand Total each row keeps its Amount before the discount.
      keepAmounts: discountOnNetTotal ? null : first.taxes,
    );
    // On Grand Total the new Grand Total is the old one minus the
    // discount; the rounding remainder goes to the last tax row, so Net
    // Total + taxes still equals it (POS-R13, R14).
    final loss = discountOnNetTotal || taxes.isEmpty
        ? 0.0
        : c.f(first.grandTotal - discount - result.taxes.last.total);
    if (loss != 0) result = c.addToLastRow(result, loss, discounted: true);
  }

  final grandTotal = result.grandTotal;
  final roundedTotal = disableRoundedTotal
      ? 0.0
      : roundToFraction(grandTotal, smallestFraction, precision, method);
  return Totals(
    lines: [
      for (var i = 0; i < lines.length; i++)
        (amount: amount[i], netRate: netRate[i], netAmount: net[i]),
    ],
    taxes: result.taxes,
    totalQty: lines.fold(0.0, (s, l) => s + l.qty),
    total: total,
    netTotal: result.netTotal,
    discountAmount: discount != 0 && over != 0 ? discount : 0,
    totalTaxes: c.f(grandTotal - result.netTotal),
    grandTotal: grandTotal,
    roundingAdjustment: disableRoundedTotal
        ? 0
        : c.f(roundedTotal - grandTotal),
    roundedTotal: roundedTotal,
    rounded: !disableRoundedTotal,
  );
}

/// What the engine takes from the settings: Currency Precision, Rounding
/// Method, the Smallest Currency Fraction Value and Disable Rounded Total.
typedef SaleSettings = ({
  int precision,
  RoundingMethod method,
  double fraction,
  bool disableRoundedTotal,
});

/// [computeTotals] for a whole [sale].
Totals totalsOf(Sale sale, SaleSettings s) => computeTotals(
  sale.lines,
  sale.taxes,
  discountPercentage: sale.additionalDiscountPercentage,
  discountAmount: sale.discountAmount,
  discountOnNetTotal: sale.discountOnNetTotal,
  precision: s.precision,
  method: s.method,
  smallestFraction: s.fraction,
  disableRoundedTotal: s.disableRoundedTotal,
);

/// POS-R14: [value] to the nearest [fraction] (the currency's Smallest
/// Currency Fraction Value), up only when the remainder is more than half
/// of it; to a whole unit when no fraction is set.
double roundToFraction(
  double value,
  double fraction,
  int precision,
  RoundingMethod method,
) {
  if (fraction <= 0) return flt(value, 0, method);
  final scale = math.pow(10, precision);
  final units = (value * scale).round();
  final step = (fraction * scale).round();
  final rest = units % step;
  final out = rest * 2 > step ? units + step - rest : units - rest;
  return flt(out / scale, precision, method);
}

/// POS-R7, R8: a line's Rate and discount from its Price List Rate and one
/// of a discount [percentage], a discount [amount] or a typed [rate]. A rate
/// above the Price List Rate leaves the discount at zero.
({double rate, double discountPercentage, double discountAmount}) linePrice(
  double priceListRate, {
  double? percentage,
  double? amount,
  double? rate,
  required int precision,
  RoundingMethod method = RoundingMethod.bankers,
}) {
  double f(num v) => flt(v, precision, method);
  double pctOf(double off) =>
      priceListRate == 0 ? 0 : flt(off / priceListRate * 100, 9, method);
  if (rate != null) {
    final off = rate < priceListRate ? f(priceListRate - rate) : 0.0;
    return (rate: f(rate), discountPercentage: pctOf(off), discountAmount: off);
  }
  if (amount != null) {
    return (
      rate: f(priceListRate - amount),
      discountPercentage: pctOf(amount),
      discountAmount: f(amount),
    );
  }
  final p = percentage ?? 0;
  final off = f(priceListRate * p / 100);
  return (
    rate: f(priceListRate - off),
    discountPercentage: p,
    discountAmount: off,
  );
}

/// One payment: its amount and whether its Mode of Payment is of Type Cash.
typedef Tender = ({double amount, bool cash});

/// POS-R15: paid amount and change. The sale is [short] until payments
/// cover [toPay]; change comes out of cash, so a card or bank amount above
/// what is due is refused ([nonCashOver]).
({double paid, double change, bool short, bool nonCashOver}) settle(
  double toPay,
  Iterable<Tender> tenders, {
  required int precision,
  RoundingMethod method = RoundingMethod.bankers,
}) {
  double f(num v) => flt(v, precision, method);
  final paid = f(tenders.fold(0.0, (s, t) => s + t.amount));
  final nonCash = f(
    tenders.where((t) => !t.cash).fold(0.0, (s, t) => s + t.amount),
  );
  return (
    paid: paid,
    change: math.max(0, f(paid - toPay)),
    short: f(toPay - paid) > 0,
    nonCashOver: f(nonCash - toPay) > 0,
  );
}

class _Calc {
  _Calc(this.lines, this.rows, this.precision, this.method);

  final List<SaleLine> lines;
  final List<TaxRow> rows;
  final int precision;
  final RoundingMethod method;

  double f(num v) => flt(v, precision, method);

  double? rateOf(int i, TaxRow t) => effectiveRate(t, lines[i].itemTax);

  /// POS-R12: for rows included in the rate, the line's net amount is
  /// worked back: (amount − per-unit charges × qty) ÷ (1 + Σ fractions).
  void workBackIncluded(
    List<double> amount,
    List<double> net,
    List<double> netRate,
  ) {
    if (!rows.any((t) => t.included)) return;
    for (final (i, l) in lines.indexed) {
      final fraction = <double>[];
      final grandFraction = <double>[];
      var cumulated = 0.0;
      var perQty = 0.0;
      for (final (k, t) in rows.indexed) {
        var fr = 0.0;
        if (t.included) {
          final r = (rateOf(i, t) ?? 0) / 100;
          switch (t.chargeType) {
            case ChargeType.onNetTotal:
              fr = r;
            case ChargeType.onPreviousRowAmount:
              fr = r * fraction[t.rowId! - 1];
            case ChargeType.onPreviousRowTotal:
              fr = r * grandFraction[t.rowId! - 1];
            case ChargeType.onItemQuantity:
              perQty += (rateOf(i, t) ?? 0) * l.qty;
            case ChargeType.actual:
          }
        }
        fraction.add(fr);
        grandFraction.add((k == 0 ? 1 : grandFraction[k - 1]) + fr);
        cumulated += fr;
      }
      if (l.qty != 0 && (cumulated != 0 || perQty != 0)) {
        net[i] = f((amount[i] - perQty) / (1 + cumulated));
        netRate[i] = f(net[i] / l.qty);
      }
    }
  }

  /// POS-R10, R11: the tax rows on the lines' [net] amounts. An Actual
  /// charge is shared by net amount, the last line taking the remainder.
  /// With rows included in the rate, a remainder of up to five of the
  /// smallest units goes to the last row, so the Grand Total equals what
  /// was entered (POS-R12, A16).
  ({double netTotal, double grandTotal, List<TaxTotals> taxes}) taxes(
    List<double> net,
    double total, {
    double discount = 0,
    List<TaxTotals>? keepAmounts,
  }) {
    final netTotal = f(net.fold(0.0, (s, a) => s + a));
    final amount = List.filled(rows.length, 0.0);
    final after = List.filled(rows.length, 0.0);
    final itemWise = [for (final _ in rows) <int, (double?, double)>{}];
    final actualLeft = [for (final t in rows) f(t.taxAmount)];
    for (final (i, l) in lines.indexed) {
      final current = <double>[];
      final grand = <double>[];
      for (final (k, t) in rows.indexed) {
        final r = rateOf(i, t);
        var cur = switch (t.chargeType) {
          ChargeType.actual =>
            netTotal == 0 ? 0.0 : net[i] * f(t.taxAmount) / netTotal,
          ChargeType.onNetTotal => (r ?? 0) / 100 * net[i],
          ChargeType.onPreviousRowAmount =>
            (r ?? 0) / 100 * current[t.rowId! - 1],
          ChargeType.onPreviousRowTotal => (r ?? 0) / 100 * grand[t.rowId! - 1],
          ChargeType.onItemQuantity => (r ?? 0) * l.qty,
        };
        if (t.chargeType == ChargeType.actual) {
          actualLeft[k] -= cur;
          if (i == lines.length - 1) cur += actualLeft[k];
        } else {
          amount[k] += cur;
        }
        after[k] += cur;
        current.add(cur);
        grand.add((k == 0 ? net[i] : grand[k - 1]) + cur);
        itemWise[k][i] = (r, f(cur));
      }
    }
    final out = <TaxTotals>[];
    for (final (k, t) in rows.indexed) {
      final ad = f(after[k]);
      out.add((
        taxAmount:
            keepAmounts?[k].taxAmount ??
            f(t.chargeType == ChargeType.actual ? t.taxAmount : amount[k]),
        taxAmountAfterDiscount: ad,
        total: f((k == 0 ? netTotal : out[k - 1].total) + ad),
        itemWise: itemWise[k],
      ));
    }
    final result = (
      netTotal: netTotal,
      grandTotal: rows.isEmpty ? netTotal : out.last.total,
      taxes: out,
    );
    if (!rows.any((t) => t.included)) return result;
    final notIncluded = [
      for (final (k, t) in rows.indexed)
        if (!t.included) out[k].taxAmountAfterDiscount,
    ].fold(0.0, (s, a) => s + a);
    final diff = f(total + notIncluded - out.last.total - discount);
    return diff != 0 && diff.abs() <= 5 / math.pow(10, precision)
        ? addToLastRow(result, diff)
        : result;
  }

  /// [result] with [diff] added to its last tax row and Grand Total; with
  /// [discounted], only to the row's amount after the discount.
  ({double netTotal, double grandTotal, List<TaxTotals> taxes}) addToLastRow(
    ({double netTotal, double grandTotal, List<TaxTotals> taxes}) result,
    double diff, {
    bool discounted = false,
  }) {
    final x = result.taxes.last;
    final total = f(x.total + diff);
    return (
      netTotal: result.netTotal,
      grandTotal: total,
      taxes: [
        ...result.taxes.take(result.taxes.length - 1),
        (
          taxAmount: discounted ? x.taxAmount : f(x.taxAmount + diff),
          taxAmountAfterDiscount: f(x.taxAmountAfterDiscount + diff),
          total: total,
          itemWise: x.itemWise,
        ),
      ],
    );
  }

  /// The Actual and On Item Quantity charges, and rows built on them.
  double fixedTaxes(List<TaxTotals> done) {
    final fixed = <int, double>{};
    for (final (k, t) in rows.indexed) {
      if (t.chargeType == ChargeType.actual ||
          t.chargeType == ChargeType.onItemQuantity) {
        fixed[k] = done[k].taxAmount;
      } else if (t.rowId case final ref?
          when t.chargeType.isPreviousRow && fixed.containsKey(ref - 1)) {
        fixed[k] = fixed[ref - 1]! * t.rate / 100;
      }
    }
    return fixed.values.fold(0.0, (s, a) => s + a);
  }
}

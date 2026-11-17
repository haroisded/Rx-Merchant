import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/pos/logic/sale.dart';
import 'package:rx_merchant/features/pos/logic/totals.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';

// 03-cash-register section 7: unit tests on the totals engine.

const vat = 1;
const levy = 2;

SaleLine line(double rate, {double qty = 1, ItemTaxRates? tax}) =>
    SaleLine(itemId: 1, itemName: 'X', uomId: 1, qty: qty, rate: rate)
      ..itemTax = tax ?? {};

TaxRow onNet(double rate, {bool included = false, int tax = vat}) => TaxRow(
  chargeType: ChargeType.onNetTotal,
  taxId: tax,
  rate: rate,
  included: included,
);

Totals calc(
  List<SaleLine> lines,
  List<TaxRow> taxes, {
  double pct = 0,
  double amount = 0,
  bool onNet = false,
  double fraction = 0.01,
}) => computeTotals(
  lines,
  taxes,
  discountPercentage: pct,
  discountAmount: amount,
  discountOnNetTotal: onNet,
  precision: 2,
  smallestFraction: fraction,
);

void main() {
  test('POS-A1 one line 699, 8% On Net Total', () {
    final t = calc([line(699)], [onNet(8)]);
    expect(t.totalTaxes, 55.92);
    expect(t.grandTotal, 754.92);
  });

  test('POS-A2 rate 108 with 8% included in the basic rate', () {
    final t = calc([line(108)], [onNet(8, included: true)]);
    expect(t.lines.single.netAmount, 100);
    expect(t.lines.single.netRate, 100);
    expect(t.totalTaxes, 8);
    expect(t.grandTotal, 108);
  });

  test('POS-A3 item tax templates override the row rate', () {
    final t = calc(
      [
        line(699),
        line(149, tax: {vat: (rate: 4, notApplicable: false)}),
        line(99, tax: {vat: (rate: 0, notApplicable: false)}),
      ],
      [onNet(8)],
    );
    expect(t.totalTaxes, 61.88);
    expect(t.netTotal, 947);
    expect(t.grandTotal, 1008.88);
  });

  test('POS-A4 Not Applicable: no tax on the line, stored as "NA"', () {
    final tax = <int, ({double rate, bool notApplicable})>{
      vat: (rate: 0, notApplicable: true),
    };
    final t = calc([line(100, tax: tax)], [onNet(8)]);
    expect(t.totalTaxes, 0);
    expect(t.taxes.single.itemWise[0], (null, 0.0));
    expect(itemTaxJson(tax), '{"1":"NA"}');
    expect(itemTaxJson({vat: (rate: 0, notApplicable: false)}), '{"1":0.0}');
    expect(itemTaxFromJson('{"1":"NA"}')[vat]!.notApplicable, isTrue);
  });

  test('POS-A5 / A6 previous row amount and previous row total', () {
    TaxRow second(ChargeType type) =>
        TaxRow(chargeType: type, taxId: levy, rate: 2, rowId: 1);
    final a = calc(
      [line(1000)],
      [onNet(8), second(ChargeType.onPreviousRowAmount)],
    );
    expect([for (final x in a.taxes) x.taxAmount], [80, 1.6]);
    expect(a.grandTotal, 1081.6);
    final b = calc(
      [line(1000)],
      [onNet(8), second(ChargeType.onPreviousRowTotal)],
    );
    expect([for (final x in b.taxes) x.taxAmount], [80, 21.6]);
    expect(b.grandTotal, 1101.6);
  });

  test('POS-A7 Actual 25 on a net of 1,000, shared by net amount', () {
    final t = calc(
      [line(600), line(400)],
      [const TaxRow(chargeType: ChargeType.actual, taxId: levy, taxAmount: 25)],
    );
    expect(t.grandTotal, 1025);
    expect(t.taxes.single.itemWise, {0: (0.0, 15.0), 1: (0.0, 10.0)});
  });

  test('POS-A8 On Item Quantity: rate 2, total quantity 5', () {
    final t = calc(
      [line(10, qty: 2), line(10, qty: 3)],
      [
        const TaxRow(
          chargeType: ChargeType.onItemQuantity,
          taxId: levy,
          rate: 2,
        ),
      ],
    );
    expect(t.totalTaxes, 10);
  });

  test('POS-A9 price list rate 200, discount 10%, quantity 2', () {
    final p = linePrice(200, percentage: 10, precision: 2);
    expect(p.rate, 180);
    expect(p.discountAmount, 20);
    final t = calc([line(p.rate, qty: 2)], []);
    expect(t.lines.single.amount, 360);
    // POS-R7: a typed rate below the list rate becomes a discount.
    final typed = linePrice(200, rate: 150, precision: 2);
    expect(typed.discountPercentage, 25);
    expect(linePrice(200, rate: 250, precision: 2).discountAmount, 0);
  });

  test('POS-A11 additional discount on Net Total and on Grand Total', () {
    Totals d({double pct = 0, double amount = 0, required bool net}) =>
        calc([line(1000)], [onNet(8)], pct: pct, amount: amount, onNet: net);
    final cells = [
      d(pct: 10, net: true),
      d(pct: 10, net: false),
      d(amount: 50, net: true),
      d(amount: 50, net: false),
    ];
    expect(
      [
        for (final t in cells)
          [t.netTotal, t.totalTaxes, t.grandTotal, t.discountAmount],
      ],
      [
        [900, 72, 972, 100],
        [900, 72, 972, 108],
        [950, 76, 1026, 50],
        [953.7, 76.3, 1030, 50],
      ],
    );
  });

  test('POS-A12 / A13 rounded total by the smallest fraction', () {
    Totals r(double rate, double fraction) =>
        calc([line(rate)], [], fraction: fraction);
    expect(r(754.92, 0.01).roundedTotal, 754.92);
    expect(r(754.92, 0.05).roundedTotal, 754.90);
    expect(r(754.92, 0.05).roundingAdjustment, -0.02);
    expect(r(754.92, 0).roundedTotal, 755);
    expect(r(754.92, 0).roundingAdjustment, 0.08);
    expect(r(754.93, 0.05).roundedTotal, 754.95);
    final off = computeTotals(
      [line(754.92)],
      [],
      precision: 2,
      smallestFraction: 0.05,
      disableRoundedTotal: true,
    );
    expect((off.roundedTotal, off.toPay), (0, 754.92));
  });

  test('POS-A14 change on cash, split payment, refused card overpayment', () {
    ({double paid, double change, bool short, bool nonCashOver}) s(
      List<Tender> t,
    ) => settle(754.90, t, precision: 2);
    expect(s([(amount: 1000, cash: true)]).change, 245.10);
    final split = s([(amount: 500, cash: false), (amount: 300, cash: true)]);
    expect((split.change, split.nonCashOver), (45.10, false));
    expect(s([(amount: 800, cash: false)]).nonCashOver, isTrue);
    expect(s([(amount: 700, cash: true)]).short, isTrue);
  });

  test('POS-A16 two lines at 54 with 8% included: exactly 108.00', () {
    final t = calc([line(54), line(54)], [onNet(8, included: true)]);
    expect(t.grandTotal, 108);
    expect(t.netTotal, 100);
    // Three at 33.33 incl. 8%: the rounding remainder goes to the tax row.
    final odd = calc(
      [line(33.33), line(33.33), line(33.33)],
      [onNet(8, included: true)],
    );
    expect(odd.grandTotal, 99.99);
  });

  test('a Grand Total discount remainder goes to the last tax row', () {
    // 3 × 100 with 8%: Grand Total 324; amount 10 off. Net 290.73, the
    // remainder of 0.01 makes tax 23.27 and Grand Total exactly 314.00.
    final t = calc([line(100), line(100), line(100)], [onNet(8)], amount: 10);
    expect(t.netTotal, 290.73);
    expect(t.grandTotal, 314);
    expect(t.totalTaxes, 23.27);
    expect(t.taxes.single.taxAmountAfterDiscount, 23.27);
  });
}

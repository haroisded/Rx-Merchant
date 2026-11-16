import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/numbers/flt.dart';
import 'package:rx_merchant/features/setup/logic/tax_template.dart';

const vat = 1;
TaxRow row(
  ChargeType type, {
  double rate = 0,
  double amount = 0,
  int? ref,
  bool included = false,
}) => TaxRow(
  chargeType: type,
  taxId: vat,
  rate: rate,
  taxAmount: amount,
  rowId: ref,
  included: included,
);

List<({double amount, double total})> run(
  List<TaxRow> rows, {
  double qty = 1,
}) => tryTaxes(rows, net: 1000, qty: qty, precision: 2);

void main() {
  group('validateTaxRows (SET-R9)', () {
    test('SET-A8 a previous-row type in row 1 is rejected', () {
      expect(validateTaxRows([row(ChargeType.onPreviousRowAmount, ref: 1)]), [
        (1, TaxRowProblem.previousRowInFirstRow),
      ]);
    });

    test('SET-A9 Reference Row # pointing at a later row is rejected', () {
      final rows = [
        row(ChargeType.onNetTotal, rate: 8),
        row(ChargeType.onPreviousRowTotal, rate: 2, ref: 3),
        row(ChargeType.onNetTotal, rate: 1),
      ];
      expect(validateTaxRows(rows), [
        (2, TaxRowProblem.referenceRowNotEarlier),
      ]);
    });

    test('SET-A10 an Actual row marked as included is rejected', () {
      expect(
        validateTaxRows([row(ChargeType.actual, amount: 25, included: true)]),
        [(1, TaxRowProblem.actualIncluded)],
      );
    });

    test('an included previous-row row needs an included reference', () {
      final rows = [
        row(ChargeType.onNetTotal, rate: 8),
        row(ChargeType.onPreviousRowAmount, rate: 2, ref: 1, included: true),
      ];
      expect(validateTaxRows(rows), [
        (2, TaxRowProblem.includedReferenceNotIncluded),
      ]);
    });

    test('a valid compound template and a row without a tax', () {
      expect(
        validateTaxRows([
          row(ChargeType.onNetTotal, rate: 8, included: true),
          row(ChargeType.onPreviousRowAmount, rate: 2, ref: 1, included: true),
        ]),
        isEmpty,
      );
      expect(
        validateTaxRows([const TaxRow(chargeType: ChargeType.onNetTotal)]),
        [(1, TaxRowProblem.missingTax)],
      );
    });
  });

  group('SET-A11 "Try it" reproduces Types in Tax Template on 1,000', () {
    test('Actual 25', () {
      expect(run([row(ChargeType.actual, amount: 25)]).single, (
        amount: 25.0,
        total: 1025.0,
      ));
    });

    test('8% On Net Total', () {
      expect(run([row(ChargeType.onNetTotal, rate: 8)]).single, (
        amount: 80.0,
        total: 1080.0,
      ));
    });

    test('2% On Previous Row Amount', () {
      final r = run([
        row(ChargeType.onNetTotal, rate: 8),
        row(ChargeType.onPreviousRowAmount, rate: 2, ref: 1),
      ]);
      expect(r.last, (amount: 1.6, total: 1081.6));
    });

    test('2% On Previous Row Total', () {
      final r = run([
        row(ChargeType.onNetTotal, rate: 8),
        row(ChargeType.onPreviousRowTotal, rate: 2, ref: 1),
      ]);
      expect(r.last, (amount: 21.6, total: 1101.6));
    });

    test('On Item Quantity, rate 2, quantity 5', () {
      expect(
        run([row(ChargeType.onItemQuantity, rate: 2)], qty: 5).single.amount,
        10,
      );
    });
  });

  test('SET-R12 worked example: item templates override the 8% row', () {
    final standard = row(ChargeType.onNetTotal, rate: 8);
    double tax(double net, Map<int, ({double rate, bool notApplicable})> t) =>
        net * effectiveRate(standard, t)! / 100;
    final total =
        flt(tax(699, {}), 2) +
        flt(tax(149, {vat: (rate: 4, notApplicable: false)}), 2) +
        flt(tax(99, {vat: (rate: 0, notApplicable: false)}), 2);
    expect(flt(total, 2), 61.88);
    expect(
      effectiveRate(standard, {vat: (rate: 4, notApplicable: true)}),
      isNull,
    );
  });

  test('removing a row keeps later references on the same row', () {
    final rows = [
      row(ChargeType.onNetTotal, rate: 1),
      row(ChargeType.onNetTotal, rate: 2),
      row(ChargeType.onPreviousRowAmount, rate: 3, ref: 2),
      row(ChargeType.onPreviousRowTotal, rate: 4, ref: 1),
    ];
    final left = removeTaxRow(rows, 1);
    expect(left.map((r) => r.rate), [2, 3, 4]);
    expect(left.map((r) => r.rowId), [null, 1, null]);
    expect(validateTaxRows(left), [(3, TaxRowProblem.missingReferenceRow)]);
  });

  test('ChargeType round-trips its stored value', () {
    for (final t in ChargeType.values) {
      expect(ChargeType.of(t.value), t);
    }
    expect(
      RoundingMethod.fromSetting('Commercial Rounding'),
      RoundingMethod.commercial,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/stock/logic/barcode.dart';
import 'package:rx_merchant/features/stock/logic/serials.dart';
import 'package:rx_merchant/features/stock/logic/stock_rules.dart';
import 'package:rx_merchant/features/stock/logic/valuation.dart';
import 'package:rx_merchant/features/stock/logic/variants.dart';

StockBalance balance(ValuationMethod m) => StockBalance(m, precision: 2);

/// Receives each (qty, rate), then issues [issue]; returns the cost of the
/// issue and the balance.
(double, StockBalance) run(
  ValuationMethod m,
  List<(double, double)> receipts,
  double issue,
) {
  final b = balance(m);
  for (final (q, r) in receipts) {
    b.receive(q, r);
  }
  final before = b.value;
  b.issue(issue);
  return (before - b.value, b);
}

void main() {
  test('STK-A1 FIFO: 10 @ 100, 10 @ 120, issue 15', () {
    final (cost, b) = run(ValuationMethod.fifo, [(10, 100), (10, 120)], 15);
    expect(cost, 1600);
    expect(b.queue, [
      [5, 120],
    ]);
    expect(b.value, 600);
    expect(b.rate, 120);
  });

  test('STK-A2 Moving Average: same movements', () {
    final (cost, b) = run(ValuationMethod.movingAverage, [
      (10, 100),
      (10, 120),
    ], 15);
    expect(b.rate, 110);
    expect(cost, 1650);
    expect(b.value, 550);
  });

  test('STK-A3 FIFO: 10 @ 100, 20 @ 120, issue 15', () {
    final (cost, b) = run(ValuationMethod.fifo, [(10, 100), (20, 120)], 15);
    expect(cost, 1600);
    expect(b.value, 1800);
  });

  test('STK-A4 Moving Average: 10 @ 100, 20 @ 120, issue 15', () {
    final (cost, b) = run(ValuationMethod.movingAverage, [
      (10, 100),
      (20, 120),
    ], 15);
    expect(b.rate, closeTo(113.333333333, 1e-9));
    expect(cost, 1700);
    expect(b.value, 1700);
  });

  test('STK-A5 serial: each unit leaves at its own cost', () {
    final b = balance(ValuationMethod.serial)
      ..receive(1, 50000)
      ..receive(1, 55000);
    b.issue(1, serialValue: 55000);
    expect(b.value, 50000);
    expect(b.qty, 1);
  });

  test('FIFO: a negative layer is settled by the next receipt', () {
    final b = balance(ValuationMethod.fifo)
      ..receive(3, 100)
      ..issue(5);
    expect(b.qty, -2);
    expect(b.queue, [
      [-2, 100],
    ]);
    b.receive(10, 120);
    expect(b.queue, [
      [8, 120],
    ]);
    expect(b.value, 960);
  });

  test('reconciliation resets to one layer', () {
    final b = balance(ValuationMethod.fifo)
      ..receive(10, 100)
      ..reset(8, 105);
    expect(b.queue, [
      [8, 105],
    ]);
    expect(b.value, 840);
  });

  test('STK-A6 3 Cartons at factor 10 is 30 in stock', () {
    expect(stockQty(3, 10, 3), 30);
  });

  test('STK-A7 1.5 is a fraction, 2 is not', () {
    expect(isWhole(1.5), isFalse);
    expect(isWhole(2), isTrue);
  });

  test('STK-A8 additional cost 50 over 600 and 400', () {
    expect(spreadCosts([600, 400], 50, 2), [30, 20]);
    expect(spreadCosts([1, 1, 1], 10, 2), [3.33, 3.33, 3.34]);
  });

  test('STK-A9 numeric attribute 1 to 5 by 1', () {
    expect(numericValues(1, 5, 1), ['1', '2', '3', '4', '5']);
    expect(numericValues(0.5, 1.5, 0.5), ['0.5', '1', '1.5']);
  });

  test('STK-A10 Red, Green x Small, Medium, Large is 6 variants', () {
    AttributeValue v(int a, String value, String abbr) =>
        (attributeId: a, value: value, abbr: abbr);
    final combos = combinations([
      [v(1, 'Red', 'RED'), v(1, 'Green', 'GRN')],
      [v(2, 'Small', 'S'), v(2, 'Medium', 'M'), v(2, 'Large', 'L')],
    ]);
    expect(combos, hasLength(6));
    expect(variantCode('TSHIRT', combos.first), 'TSHIRT-RED-S');
  });

  test('STK-A11 range SN-01::10', () {
    final r = serialRange('SN-01::10')!;
    expect(r, hasLength(10));
    expect(r.first, 'SN-01');
    expect(r.last, 'SN-10');
    expect(serialRange('SN-01'), isNull);
  });

  test('STK-A13 price of a Box from the Kilo price', () {
    const kilo = 1, box = 2;
    final prices = <PriceRow>[
      (uomId: null, rate: 10, validFrom: null, validUpto: null, batchId: null),
    ];
    double? priceOf(bool notUomDependent) => pickPrice(
      prices,
      uomId: box,
      stockUomId: kilo,
      factor: 10,
      priceNotUomDependent: notUomDependent,
      date: '2026-11-17',
    )?.rate;
    expect(priceOf(true), 100);
    expect(priceOf(false), 10);
  });

  test('STK-R10 validity and batch-specific prices', () {
    final prices = <PriceRow>[
      (
        uomId: 1,
        rate: 9,
        validFrom: null,
        validUpto: '2026-01-31',
        batchId: null,
      ),
      (
        uomId: 1,
        rate: 11,
        validFrom: '2026-02-01',
        validUpto: null,
        batchId: null,
      ),
      (uomId: 1, rate: 12, validFrom: null, validUpto: null, batchId: 7),
    ];
    double? on(String date, [int? batch]) => pickPrice(
      prices,
      uomId: 1,
      stockUomId: 1,
      factor: 1,
      priceNotUomDependent: false,
      date: date,
      batchId: batch,
    )?.rate;
    expect(on('2026-01-15'), 9);
    expect(on('2026-03-01'), 11);
    expect(on('2026-03-01', 7), 12);
    expect(validityOverlaps(null, '2026-01-31', '2026-02-01', null), isFalse);
    expect(validityOverlaps(null, null, '2026-02-01', null), isTrue);
  });

  test('STK-A14 EAN with a wrong check digit is rejected', () {
    expect(validBarcode('EAN', '4006381333931'), isTrue);
    expect(validBarcode('EAN', '4006381333932'), isFalse);
  });

  test('STK-A15 item tax: item row from 1 March, group otherwise', () {
    const itemTemplate = 5, groupTemplate = 9;
    final rows = [(templateId: itemTemplate, validFrom: '2026-03-01')];
    expect(
      itemTaxTemplateFor(rows, [null, groupTemplate], '2026-02-15'),
      groupTemplate,
    );
    expect(
      itemTaxTemplateFor(rows, [null, groupTemplate], '2026-03-15'),
      itemTemplate,
    );
  });

  test('STK-R19 batch status and default expiry', () {
    expect(batchStatus(null, '2026-11-17'), BatchStatus.notSet);
    expect(batchStatus('2026-11-17', '2026-11-17'), BatchStatus.notExpired);
    expect(batchStatus('2026-11-16', '2026-11-17'), BatchStatus.expired);
    expect(defaultExpiry('2026-11-17', 30), '2026-12-17');
  });

  test('STK-R27 auto pick by FIFO, LIFO and Expiry', () {
    final available = <Pickable<String>>[
      (id: 'A', qty: 5, received: '2026-01-01', expiry: '2026-12-31'),
      (id: 'B', qty: 5, received: '2026-02-01', expiry: '2026-06-30'),
    ];
    expect(autoPick(available, 7, 'FIFO'), [('A', 5.0), ('B', 2.0)]);
    expect(autoPick(available, 7, 'LIFO'), [('B', 5.0), ('A', 2.0)]);
    expect(autoPick(available, 3, 'Expiry'), [('B', 3.0)]);
  });
}

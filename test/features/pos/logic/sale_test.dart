import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/pos/logic/sale.dart';
import 'package:rx_merchant/features/stock/logic/stock_documents.dart';

SaleLine one(int item, {double rate = 10, int uom = 1}) =>
    SaleLine(itemId: item, itemName: 'X', uomId: uom, rate: rate);

void main() {
  test(
    'POS-R4 the same item, unit and rate merge; anything else is a line',
    () {
      final sale = Sale(warehouseId: 1, priceListId: 1);
      addToSale(sale, one(1), null);
      addToSale(sale, one(1), null);
      addToSale(sale, one(1, rate: 12), null);
      addToSale(sale, one(1, uom: 2), null);
      expect([for (final l in sale.lines) l.qty], [2, 1, 1]);
    },
  );

  test('POS-R21 a scanned serial joins its line once', () {
    final sale = Sale(warehouseId: 1, priceListId: 1);
    addToSale(sale, one(1), SbEntry(serialNo: 'A'));
    addToSale(sale, one(1), SbEntry(serialNo: 'B'));
    addToSale(sale, one(1), SbEntry(serialNo: 'B'));
    final line = sale.lines.single;
    expect(line.qty, 2);
    expect([for (final e in line.entries) e.serialNo], ['A', 'B']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/numbers/flt.dart';

void main() {
  const bankers = RoundingMethod.bankers;
  const commercial = RoundingMethod.commercial;

  group("Banker's Rounding", () {
    test('SET-A1 sends a midpoint to the nearest even digit', () {
      expect(flt(2.345, 2, bankers), 2.34);
      expect(flt(2.355, 2, bankers), 2.36);
    });

    test('is the default method', () {
      expect(flt(2.345, 2), 2.34);
    });

    test('whole-number midpoints go to the even neighbour', () {
      expect(flt(0.5, 0, bankers), 0);
      expect(flt(1.5, 0, bankers), 2);
      expect(flt(2.5, 0, bankers), 2);
    });

    test('a negative midpoint mirrors the positive one', () {
      expect(flt(-2.345, 2, bankers), -2.34);
      expect(flt(-2.355, 2, bankers), -2.36);
    });

    test('values off the midpoint round to nearest', () {
      expect(flt(2.3449, 2, bankers), 2.34);
      expect(flt(2.3451, 2, bankers), 2.35);
    });
  });

  group('Commercial Rounding', () {
    test('SET-A2 sends a midpoint away from zero', () {
      expect(flt(2.345, 2, commercial), 2.35);
    });

    test('SET-A3 survives the binary float trap', () {
      expect(flt(1.005, 2, commercial), 1.01);
    });

    test('whole-number midpoints go up', () {
      expect(flt(2.5, 0, commercial), 3);
    });

    test('a negative midpoint goes away from zero', () {
      expect(flt(-2.345, 2, commercial), -2.35);
    });
  });

  test('zero stays zero', () {
    expect(flt(0, 2), 0);
    expect(flt(0, 2, commercial), 0);
  });

  test('nine decimals keep a repeating valuation rate', () {
    expect(flt(113.333333333333, 9), 113.333333333);
  });

  test('integers pass through', () {
    expect(flt(1000, 2), 1000);
  });

  test('the Rounding Method setting maps to the enum', () {
    expect(RoundingMethod.fromSetting("Banker's Rounding"), bankers);
    expect(RoundingMethod.fromSetting('Commercial Rounding'), commercial);
  });
}

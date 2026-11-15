import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/numbers/format.dart';

void main() {
  group('formatNumber', () {
    test('SET-A4 the two formats named in SET-R5', () {
      expect(formatNumber(12345.67, '#,###.##', 2), '12,345.67');
      expect(formatNumber(12345.67, '#.###,##', 2), '12.345,67');
    });

    test('every Number Format option', () {
      const n = 1234567.891;
      expect(formatNumber(n, '#,###.##', 2), '1,234,567.89');
      expect(formatNumber(n, '#.###,##', 2), '1.234.567,89');
      expect(formatNumber(n, '# ###.##', 2), '1 234 567.89');
      expect(formatNumber(n, '#,##,###.##', 2), '12,34,567.89');
      expect(formatNumber(n, '#,###', 2), '1,234,568');
      expect(formatNumber(n, '#.###', 2), '1.234.568');
    });

    test('precision sets the decimals shown', () {
      expect(formatNumber(1.5, '#,###.##', 3), '1.500');
      expect(formatNumber(1234.5, '#,###.##', 0), '1,235');
    });

    test('small and zero values are padded, not grouped', () {
      expect(formatNumber(0, '#,###.##', 2), '0.00');
      expect(formatNumber(12.3, '#,###.##', 2), '12.30');
      expect(formatNumber(999, '#,##,###.##', 2), '999.00');
    });

    test('negative values keep their sign', () {
      expect(formatNumber(-1234.5, '#,###.##', 2), '-1,234.50');
      expect(formatNumber(-1234567.891, '#,##,###.##', 2), '-12,34,567.89');
    });

    test('a negative value that rounds to zero shows no sign', () {
      expect(formatNumber(-0.001, '#,###.##', 2), '0.00');
    });
  });

  group('formatCurrency', () {
    test('symbol on the left by default', () {
      expect(
        formatCurrency(
          12345.67,
          numberFormat: '#,###.##',
          precision: 2,
          symbol: r'$',
        ),
        r'$ 12,345.67',
      );
    });

    test('symbol on the right', () {
      expect(
        formatCurrency(
          12345.67,
          numberFormat: '#,###.##',
          precision: 2,
          symbol: r'$',
          symbolOnRight: true,
        ),
        r'12,345.67 $',
      );
    });

    test('Hide Currency Symbol, or no symbol, shows the number alone', () {
      expect(
        formatCurrency(
          12345.67,
          numberFormat: '#,###.##',
          precision: 2,
          symbol: r'$',
          hideSymbol: true,
        ),
        '12,345.67',
      );
      expect(
        formatCurrency(12345.67, numberFormat: '#,###.##', precision: 2),
        '12,345.67',
      );
    });

    test('a negative amount keeps the sign on the number', () {
      expect(
        formatCurrency(
          -5,
          numberFormat: '#,###.##',
          precision: 2,
          symbol: r'$',
        ),
        r'$ -5.00',
      );
    });
  });

  group('dates and times', () {
    final d = DateTime(2026, 11, 5, 14, 7, 9);

    test('every Date Format option', () {
      expect(formatDate(d, 'yyyy-mm-dd'), '2026-11-05');
      expect(formatDate(d, 'dd-mm-yyyy'), '05-11-2026');
      expect(formatDate(d, 'dd/mm/yyyy'), '05/11/2026');
      expect(formatDate(d, 'dd.mm.yyyy'), '05.11.2026');
      expect(formatDate(d, 'mm/dd/yyyy'), '11/05/2026');
      expect(formatDate(d, 'mm-dd-yyyy'), '11-05-2026');
    });

    test('both Time Format options', () {
      expect(formatTime(d, 'HH:mm:ss'), '14:07:09');
      expect(formatTime(d, 'HH:mm'), '14:07');
    });

    test('storage text is fixed and round-trips', () {
      expect(toStorage(d), '2026-11-05 14:07:09');
      expect(DateTime.parse(toStorage(d)), d);
    });
  });
}

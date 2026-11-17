import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/numbers/in_words.dart';

void main() {
  test('In Words, as Frappe writes it', () {
    String w(double v) =>
        moneyInWords(v, code: 'PHP', fraction: 'Centavo', precision: 2);
    expect(
      w(754.90),
      'PHP Seven Hundred And Fifty-Four and Ninety Centavo only.',
    );
    expect(w(1005), 'PHP One Thousand And Five only.');
    expect(
      w(1234567),
      'PHP One Million, Two Hundred And Thirty-Four Thousand, '
      'Five Hundred And Sixty-Seven only.',
    );
    expect(w(0.5), 'Fifty Centavo only.');
    expect(w(0), 'PHP Zero only.');
  });
}

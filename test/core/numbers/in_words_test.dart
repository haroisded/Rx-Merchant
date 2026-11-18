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

  test('INV-A1, A2 In Words in USD', () {
    String w(double v) =>
        moneyInWords(v, code: 'USD', fraction: 'Cent', precision: 2);
    expect(w(108), 'USD One Hundred And Eight only.');
    // Frappe's wording (D-66): "Fifty-Four", the Fraction name as stored.
    expect(w(754.90), 'USD Seven Hundred And Fifty-Four and Ninety Cent only.');
  });

  test('INV-R19 #,##,###.## counts in lakh and crore', () {
    String w(double v) => moneyInWords(
      v,
      code: 'INR',
      fraction: 'Paisa',
      precision: 2,
      indian: true,
    );
    expect(
      w(1234567),
      'INR Twelve Lakh, Thirty-Four Thousand, Five Hundred And Sixty-Seven only.',
    );
    expect(w(250000000), 'INR Twenty-Five Crore only.');
    expect(w(10000000005), 'INR One Thousand Crore And Five only.');
    expect(w(1005), 'INR One Thousand And Five only.');
  });
}

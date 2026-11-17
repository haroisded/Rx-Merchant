// In Words (03-cash-register POS-R14), as Frappe's `money_in_words` writes
// it: "PHP One Thousand And Fifty and Twenty-Five Centavo only."

final _ones =
    'zero one two three four five six seven eight nine ten eleven twelve '
            'thirteen fourteen fifteen sixteen seventeen eighteen nineteen'
        .split(' ');
final _tens = ' - twenty thirty forty fifty sixty seventy eighty ninety'.split(
  ' ',
);
const _scales = ['', 'thousand', 'million', 'billion', 'trillion'];

/// [amount] in words with the currency [code] and its [fraction] name
/// ("Cent"), the fraction having [precision] digits. A negative amount is
/// spelled as its size; the document shows the sign elsewhere.
// ponytail: international scale only; add lakh / crore if the Indian number
// format (#,##,###.##) is ever chosen.
String moneyInWords(
  double amount, {
  required String code,
  required String fraction,
  required int precision,
}) {
  final parts = amount.abs().toStringAsFixed(precision).split('.');
  final whole = int.parse(parts[0]);
  final cents = parts.length > 1 ? int.parse(parts[1]) : 0;
  if (whole == 0 && cents == 0) return '$code Zero only.';
  if (whole == 0) return '${_title(_words(cents))} $fraction only.';
  final out = '$code ${_title(_words(whole))}';
  return cents == 0
      ? '$out only.'
      : '$out and ${_title(_words(cents))} $fraction only.';
}

/// English words for [n], as num2words writes them ("one thousand and
/// five", "two hundred and thirty-four thousand, five hundred").
String _words(int n) {
  if (n == 0) return _ones[0];
  final groups = <int>[];
  for (var rest = n; rest > 0; rest ~/= 1000) {
    groups.add(rest % 1000);
  }
  final out = StringBuffer();
  for (var i = groups.length - 1; i >= 0; i--) {
    final g = groups[i];
    if (g == 0) continue;
    if (out.isNotEmpty) out.write(i == 0 && g < 100 ? ' and ' : ', ');
    out.write(_below1000(g));
    if (_scales[i].isNotEmpty) out.write(' ${_scales[i]}');
  }
  return '$out';
}

String _below1000(int n) {
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final tens = rest < 20
      ? _ones[rest]
      : '${_tens[rest ~/ 10]}${rest % 10 == 0 ? '' : '-${_ones[rest % 10]}'}';
  if (hundreds == 0) return tens;
  return '${_ones[hundreds]} hundred${rest == 0 ? '' : ' and $tens'}';
}

/// Python's str.title(): a capital after every non-letter.
String _title(String s) => s.replaceAllMapped(
  RegExp(r'(^|[^a-z])([a-z])'),
  (m) => '${m[1]}${m[2]!.toUpperCase()}',
);

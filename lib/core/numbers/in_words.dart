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
/// spelled as its size; the document shows the sign elsewhere. [indian]
/// counts in lakh and crore, for the Number Format `#,##,###.##`
/// (05-invoices-and-receipts INV-R19).
String moneyInWords(
  double amount, {
  required String code,
  required String fraction,
  required int precision,
  bool indian = false,
}) {
  String words(int n) => _title(_words(n, indian: indian));
  final parts = amount.abs().toStringAsFixed(precision).split('.');
  final whole = int.parse(parts[0]);
  final cents = parts.length > 1 ? int.parse(parts[1]) : 0;
  if (whole == 0 && cents == 0) return '$code Zero only.';
  if (whole == 0) return '${words(cents)} $fraction only.';
  final out = '$code ${words(whole)}';
  return cents == 0 ? '$out only.' : '$out and ${words(cents)} $fraction only.';
}

/// English words for [n], as num2words writes them ("one thousand and
/// five", "two hundred and thirty-four thousand, five hundred"); with
/// [indian], "twelve lakh, thirty-four thousand, …".
String _words(int n, {bool indian = false}) {
  if (n == 0) return _ones[0];
  // (count, scale), lowest first.
  final groups = <(int, String)>[];
  if (indian) {
    groups
      ..add((n % 1000, ''))
      ..add((n ~/ 1000 % 100, 'thousand'))
      ..add((n ~/ 100000 % 100, 'lakh'))
      ..add((n ~/ 10000000, 'crore'));
  } else {
    for (var rest = n, i = 0; rest > 0; rest ~/= 1000, i++) {
      groups.add((rest % 1000, _scales[i]));
    }
  }
  final out = StringBuffer();
  for (var i = groups.length - 1; i >= 0; i--) {
    final (g, scale) = groups[i];
    if (g == 0) continue;
    if (out.isNotEmpty) out.write(i == 0 && g < 100 ? ' and ' : ', ');
    // Crores can run past 999: "one thousand crore".
    out.write(g < 1000 ? _below1000(g) : _words(g, indian: true));
    if (scale.isNotEmpty) out.write(' $scale');
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

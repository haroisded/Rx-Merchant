import 'package:intl/intl.dart';

// Formats affect display only; stored values never change (SET-R5).

/// Shows [value] in a System Settings Number Format: `#,###.##`, `#.###,##`,
/// `# ###.##`, `#,##,###.##`, `#,###` or `#.###`. The last two have no decimal
/// part and show whole numbers whatever the [precision].
String formatNumber(num value, String numberFormat, int precision) {
  final decimalPart = RegExp(r'([.,])##$').firstMatch(numberFormat);
  final decimalSeparator = decimalPart?.group(1) ?? '';
  final groupSeparator = numberFormat.length > 1 ? numberFormat[1] : ',';
  // Indian grouping: the last three digits, then pairs.
  final indian = numberFormat.startsWith('#,##,');

  final fixed = value.abs().toStringAsFixed(
    decimalPart == null ? 0 : precision,
  );
  final dot = fixed.indexOf('.');
  var whole = dot < 0 ? fixed : fixed.substring(0, dot);
  final fraction = dot < 0 ? '' : decimalSeparator + fixed.substring(dot + 1);

  final groups = <String>[];
  var size = 3;
  while (whole.length > size) {
    groups.insert(0, whole.substring(whole.length - size));
    whole = whole.substring(0, whole.length - size);
    if (indian) size = 2;
  }
  groups.insert(0, whole);

  // No minus sign on a value that displays as zero.
  final sign = value < 0 && double.parse(fixed) != 0 ? '-' : '';
  return '$sign${groups.join(groupSeparator)}$fraction';
}

/// Reads a number typed in a Number Format (SET-R5: formats affect typing
/// too): `1.234,5` in `#.###,##` is 1234.5. A format without decimals takes
/// the other mark as its decimal point, so `7,5` in `#.###` is 7.5.
///
/// Groups after the first must have the format's size, so a mistyped
/// decimal mark is refused instead of read as a group separator: `7.5` in
/// `#.###` is null, not 75. Null too when the text is not a finite number.
double? parseNumber(String text, String numberFormat) {
  final groupSeparator = numberFormat.length > 1 ? numberFormat[1] : ',';
  final decimalSeparator =
      RegExp(r'([.,])##$').firstMatch(numberFormat)?[1] ??
      (groupSeparator == '.' ? ',' : '.');
  final indian = numberFormat.startsWith('#,##,');
  final t = text.trim();
  final cut = t.lastIndexOf(decimalSeparator);
  final groups = (cut < 0 ? t : t.substring(0, cut)).split(groupSeparator);
  for (var i = 1; i < groups.length; i++) {
    final size = indian && i < groups.length - 1 ? 2 : 3;
    if (groups[i].length != size) return null;
  }
  final fraction = cut < 0 ? '' : '.${t.substring(cut + 1)}';
  final value = double.tryParse('${groups.join()}$fraction');
  return value != null && value.isFinite ? value : null;
}

/// [formatNumber] with the currency symbol placed as the Currency record says.
/// [hideSymbol] is Global Defaults' "Hide Currency Symbol".
String formatCurrency(
  num value, {
  required String numberFormat,
  required int precision,
  String? symbol,
  bool symbolOnRight = false,
  bool hideSymbol = false,
}) {
  final number = formatNumber(value, numberFormat, precision);
  if (hideSymbol || symbol == null || symbol.isEmpty) return number;
  return symbolOnRight ? '$number $symbol' : '$symbol $number';
}

// The locale is pinned so digits are always ASCII, whatever the app language.
const _locale = 'en_US';

/// Shows the date of [d] in a System Settings Date Format, e.g. `dd-mm-yyyy`.
String formatDate(DateTime d, String dateFormat) =>
    DateFormat(dateFormat.replaceAll('mm', 'MM'), _locale).format(d);

/// Shows the time of [d] in a System Settings Time Format: `HH:mm:ss` or
/// `HH:mm`.
String formatTime(DateTime d, String timeFormat) =>
    DateFormat(timeFormat, _locale).format(d);

/// The text a `posting_datetime` column holds: `YYYY-MM-DD HH:MM:SS`, local
/// time (00-overview, section 6.4). `DateTime.parse` reads it back.
String toStorage(DateTime d) =>
    DateFormat('yyyy-MM-dd HH:mm:ss', _locale).format(d);

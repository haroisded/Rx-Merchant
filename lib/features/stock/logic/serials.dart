/// STK-R25 "Create Serial Nos from Range": `SN-01::10` gives SN-01 to SN-10.
/// The digits at the end of the first number are counted up to the number
/// after `::`, keeping their width. Null when [text] is not a range.
List<String>? serialRange(String text) {
  final m = RegExp(r'^(.*?)(\d+)::(\d+)$').firstMatch(text.trim());
  if (m == null) return null;
  final prefix = m[1]!;
  final width = m[2]!.length;
  final from = int.parse(m[2]!);
  final to = int.parse(m[3]!);
  if (to < from) return null;
  return [
    for (var n = from; n <= to; n++) '$prefix${'$n'.padLeft(width, '0')}',
  ];
}

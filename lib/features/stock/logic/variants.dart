import '../../../core/numbers/flt.dart';

// Item Variants (STK-R15, R16).

/// One value of an attribute, with the abbreviation used in variant codes.
typedef AttributeValue = ({int attributeId, String value, String abbr});

/// A number as typed: 1.0 is '1', 2.5 is '2.5'.
String plainNumber(double v) {
  final r = flt(v, 9);
  return r == r.truncateToDouble() ? '${r.toInt()}' : '$r';
}

/// STK-R15: a numeric attribute from 1 to 5 by 1 gives 1, 2, 3, 4, 5. A
/// numeric value is its own abbreviation.
List<String> numericValues(double from, double to, double increment) {
  if (increment <= 0 || to < from) return const [];
  return [
    for (var i = 0; flt(from + i * increment, 9) <= to; i++)
      plainNumber(from + i * increment),
  ];
}

/// STK-R16 "Create > Multiple Variants": every combination of the ticked
/// values, one list per attribute in the template's attribute order.
List<List<AttributeValue>> combinations(List<List<AttributeValue>> ticked) =>
    ticked.fold<List<List<AttributeValue>>>(
      [[]],
      (combos, values) => [
        for (final c in combos)
          for (final v in values) [...c, v],
      ],
    );

/// STK-R16: `TSHIRT` with Red and Small (abbreviations RED, S) is
/// `TSHIRT-RED-S`. The variant's Item Name is built the same way.
String variantCode(String template, List<AttributeValue> values) =>
    [template, for (final v in values) v.abbr].join('-');

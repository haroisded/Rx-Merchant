import 'dart:math' as math;

/// The Rounding Method of System Settings (SET-R4).
enum RoundingMethod {
  /// A midpoint goes to the nearest even digit: 2.345 to 2.34, 2.355 to 2.36.
  bankers("Banker's Rounding"),

  /// A midpoint goes away from zero: 2.345 to 2.35.
  commercial('Commercial Rounding');

  const RoundingMethod(this.setting);

  /// The value stored under `rounding_method` in System Settings.
  final String setting;

  static RoundingMethod fromSetting(String value) =>
      values.firstWhere((m) => m.setting == value, orElse: () => bankers);
}

/// 2^-52: the relative size of binary float error in a double.
const _relativeError = 2.220446049250313e-16;

/// Rounds [value] to [precision] decimals. Every calculated value goes through
/// this before it is stored (00-overview, section 6.3).
///
/// 2.345 is really 2.34499999999999997 in binary, so the scaled value is
/// compared against the midpoint with a tolerance of one float error before
/// the method decides which way to go. Same approach as Frappe's `flt`.
double flt(
  num value,
  int precision, [
  RoundingMethod method = RoundingMethod.bankers,
]) {
  final scale = math.pow(10, precision);
  final scaled = value.abs() * scale;
  final tolerance = scaled * _relativeError;
  final double rounded;
  switch (method) {
    case RoundingMethod.commercial:
      rounded = (scaled + tolerance).roundToDouble();
    case RoundingMethod.bankers:
      final floor = scaled.floorToDouble();
      final isMidpoint = (scaled - floor - 0.5).abs() < tolerance;
      rounded = !isMidpoint
          ? scaled.roundToDouble()
          : (floor % 2 == 0 ? floor : floor + 1);
  }
  return value.sign * rounded / scale;
}

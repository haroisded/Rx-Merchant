/// The spacing scale. Padding, margins and gaps use these steps, never
/// arbitrary numbers.
abstract final class AppSpacing {
  static const double unit = 4;

  static const double xs = unit; // 4
  static const double sm = unit * 2; // 8
  static const double md = unit * 4; // 16
  static const double lg = unit * 6; // 24
}

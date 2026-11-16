import '../db/app_database.dart';
import '../db/singles.dart';
import 'flt.dart';
import 'format.dart';

/// The display formats in force, from System Settings, Global Defaults and
/// the store's Currency (SET-R5). Screens format every number, amount and
/// date through this, so changing a setting changes every screen.
class Formats {
  const Formats({required this.system, required this.defaults, this.currency});

  final SystemSettings system;
  final GlobalDefaults defaults;
  final CurrencyData? currency;

  String number(num value, [int? precision]) => formatNumber(
    value,
    system.numberFormat,
    precision ?? system.floatPrecision,
  );

  String money(num value) => formatCurrency(
    value,
    numberFormat: system.numberFormat,
    precision: system.currencyPrecision,
    symbol: currency?.symbol,
    symbolOnRight: currency?.symbolOnRight == 1,
    hideSymbol: defaults.hideCurrencySymbol,
  );

  String date(DateTime d) => formatDate(d, system.dateFormat);
  String time(DateTime d) => formatTime(d, system.timeFormat);

  /// Reads a typed number in the Number Format.
  double? parse(String text) => parseNumber(text, system.numberFormat);

  RoundingMethod get rounding =>
      RoundingMethod.fromSetting(system.roundingMethod);
}

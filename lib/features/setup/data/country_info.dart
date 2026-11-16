import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';

/// One entry of the bundled `assets/country_info.json`: reference data the
/// wizard reads, kept out of the database (01-setup, section 2 "Country").
class CountryInfo {
  CountryInfo.fromJson(Map<String, dynamic> j)
    : name = j['name'] as String,
      code = j['code'] as String,
      currency = j['currency'] as String?,
      currencyName = j['currency_name'] as String?,
      symbol = j['symbol'] as String?,
      fraction = j['fraction'] as String?,
      fractionUnits = j['fraction_units'] as int,
      smallestFraction = (j['smallest_currency_fraction_value'] as num)
          .toDouble(),
      dateFormat = j['date_format'] as String,
      numberFormat = j['number_format'] as String;

  final String name;
  final String code;

  /// Null for a territory with no currency of its own.
  final String? currency;
  final String? currencyName;
  final String? symbol;
  final String? fraction;
  final int fractionUnits;
  final double smallestFraction;
  final String dateFormat;
  final String numberFormat;

  /// The Currency record of this country's currency (SET-R3).
  CurrencyCompanion toCurrency() => CurrencyCompanion.insert(
    code: Value(currency),
    fraction: Value(fraction),
    fractionUnits: Value(fractionUnits),
    smallestCurrencyFractionValue: Value(smallestFraction),
    symbol: Value(symbol),
  );

  /// Decimals the currency needs: none for the yen, three for the dinar.
  int get currencyPrecision => switch (fractionUnits) {
    0 || 1 => 0,
    1000 => 3,
    _ => 2,
  };
}

/// Decoded here, not with `rootBundle.loadString`, which hands files over
/// 50 KB to a background isolate for 57 KB of text.
Future<List<CountryInfo>> loadCountryInfo() async {
  final bytes = await rootBundle.load('assets/country_info.json');
  final text = utf8.decode(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  return [
    for (final j in jsonDecode(text) as List)
      CountryInfo.fromJson(j as Map<String, dynamic>),
  ];
}

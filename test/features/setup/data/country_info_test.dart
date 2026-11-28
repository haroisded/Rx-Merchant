import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('country data: one clean symbol per currency, no footnote marks', () {
    final countries = (jsonDecode(
      File('assets/country_info.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    for (final c in countries.where((c) => c['currency'] != null)) {
      final symbol = c['symbol'] as String?;
      expect(symbol, isNotNull, reason: '${c['name']} has no symbol');
      expect(symbol, isNot(contains(' or ')), reason: '${c['name']}');
      expect('${c['fraction']}', isNot(contains('[')), reason: '${c['name']}');
    }
    String format(String name) =>
        countries.firstWhere((c) => c['name'] == name)['number_format'];
    expect(format('Spain'), '#.###,##');
    expect(format('United States'), '#,###.##');
  });
}

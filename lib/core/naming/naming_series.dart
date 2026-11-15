import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Resolves a Naming Series [pattern] for a document posted on [postingDate]
/// (SET-R6). No database access.
///
/// The pattern is split on `.`; `YYYY`, `YY`, `MM` and `DD` become parts of
/// the posting date and everything else is literal. The first run of `#` is
/// the counter and its length is the digit count; without one, a five-digit
/// counter goes at the end. `key` is the text before the counter (the
/// `series.name` it counts under) and `suffix` the text after it.
///
/// `ACC-SINV-.YYYY.-` in 2026 gives key `ACC-SINV-2026-`, 5 digits.
({String key, int digits, String suffix}) parseSeries(
  String pattern,
  DateTime postingDate,
) {
  String two(int n) => n.toString().padLeft(2, '0');
  final resolved = pattern
      .split('.')
      .map(
        (part) => switch (part) {
          'YYYY' => '${postingDate.year}',
          'YY' => two(postingDate.year % 100),
          'MM' => two(postingDate.month),
          'DD' => two(postingDate.day),
          _ => part,
        },
      )
      .join();
  final counter = RegExp('#+').firstMatch(resolved);
  if (counter == null) return (key: resolved, digits: 5, suffix: '');
  return (
    key: resolved.substring(0, counter.start),
    digits: counter.end - counter.start,
    suffix: resolved.substring(counter.end),
  );
}

extension NamingSeries on AppDatabase {
  /// Takes the next number of the series [pattern] resolves to and returns
  /// the document name, e.g. `ACC-SINV-2026-00001`.
  ///
  /// Call it inside the document's Submit transaction: this transaction nests
  /// in that one, so a failed submit does not burn a number (SET-R6.4).
  Future<String> nextName(String pattern, DateTime postingDate) =>
      transaction(() async {
        final (:key, :digits, :suffix) = parseSeries(pattern, postingDate);
        final row = await (select(
          series,
        )..where((s) => s.name.equals(key))).getSingleOrNull();
        final next = (row?.current ?? 0) + 1;
        await into(series).insertOnConflictUpdate(
          SeriesCompanion.insert(name: Value(key), current: Value(next)),
        );
        return '$key${next.toString().padLeft(digits, '0')}$suffix';
      });
}

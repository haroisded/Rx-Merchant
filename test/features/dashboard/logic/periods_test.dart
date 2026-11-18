import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/dashboard/logic/periods.dart';

// 04-sales-dashboard DSH-R3, R6, R7.

String show(Span s) => '${ymd(s.from)}..${ymd(s.to)}';

void main() {
  final wednesday = DateTime(2026, 11, 18, 15, 30);

  test('DSH-A18 the week starts on the First Day of the Week', () {
    expect(
      show(spanOf(Period.thisWeek, wednesday, 'Sunday')),
      '2026-11-15..2026-11-18',
    );
    expect(
      show(spanOf(Period.thisWeek, wednesday, 'Monday')),
      '2026-11-16..2026-11-18',
    );
    // A week starting on the day itself.
    expect(
      show(spanOf(Period.thisWeek, wednesday, 'Wednesday')),
      '2026-11-18..2026-11-18',
    );
  });

  test('DSH-R3 periods run up to today', () {
    String of(Period p) => show(spanOf(p, wednesday, 'Monday'));
    expect(of(Period.today), '2026-11-18..2026-11-18');
    expect(of(Period.yesterday), '2026-11-17..2026-11-17');
    expect(of(Period.thisMonth), '2026-11-01..2026-11-18');
    expect(of(Period.thisYear), '2026-01-01..2026-11-18');
  });

  test('DSH-R3 the previous period covers the same days one unit back', () {
    Span at(Period p, DateTime now) => spanOf(p, now, 'Monday');
    String prev(Period p, DateTime now) => show(previousOf(p, at(p, now)));
    expect(prev(Period.today, wednesday), '2026-11-17..2026-11-17');
    expect(prev(Period.yesterday, wednesday), '2026-11-16..2026-11-16');
    expect(prev(Period.thisWeek, wednesday), '2026-11-09..2026-11-11');
    expect(prev(Period.thisMonth, wednesday), '2026-10-01..2026-10-18');
    // Cut to the shorter month; January goes back to December.
    expect(
      prev(Period.thisMonth, DateTime(2026, 3, 31)),
      '2026-02-01..2026-02-28',
    );
    expect(
      prev(Period.thisMonth, DateTime(2026, 1, 9)),
      '2025-12-01..2025-12-09',
    );
    expect(
      prev(Period.thisYear, DateTime(2028, 2, 29)),
      '2027-01-01..2027-02-28',
    );
    final custom = (
      from: DateTime.utc(2026, 11, 1),
      to: DateTime.utc(2026, 11, 10),
    );
    expect(show(previousOf(Period.custom, custom)), '2026-10-22..2026-10-31');
  });

  test('DSH-R6 trend buckets: days to 31 days, weeks to 26 weeks', () {
    Span days(int n) =>
        (from: DateTime.utc(2026), to: DateTime.utc(2026, 1, n));
    expect(trendRange(days(31)), Range.daily);
    expect(trendRange(days(32)), Range.weekly);
    expect(trendRange(days(182)), Range.weekly);
    expect(trendRange(days(183)), Range.monthly);
  });

  test('DSH-R7 a range is cut into its units, ends cut to the range', () {
    List<String> cut(Span s, Range r) => [
      for (final b in bucketsOf(s, r, 'Monday')) show(b),
    ];
    final november = (
      from: DateTime.utc(2026, 11, 1),
      to: DateTime.utc(2026, 11, 18),
    );
    expect(cut(november, Range.weekly), [
      '2026-11-01..2026-11-01',
      '2026-11-02..2026-11-08',
      '2026-11-09..2026-11-15',
      '2026-11-16..2026-11-18',
    ]);
    expect(cut(november, Range.daily), hasLength(18));
    expect(
      cut((
        from: DateTime.utc(2026, 2, 10),
        to: DateTime.utc(2026, 7, 1),
      ), Range.quarterly),
      [
        '2026-02-10..2026-03-31',
        '2026-04-01..2026-06-30',
        '2026-07-01..2026-07-01',
      ],
    );
    expect(
      cut((
        from: DateTime.utc(2025, 12, 30),
        to: DateTime.utc(2026, 1, 2),
      ), Range.yearly),
      ['2025-12-30..2025-12-31', '2026-01-01..2026-01-02'],
    );
    final index = dayIndex(bucketsOf(november, Range.weekly, 'Monday'));
    expect(
      (index['2026-11-01'], index['2026-11-08'], index['2026-11-18']),
      (0, 1, 3),
    );
  });
}

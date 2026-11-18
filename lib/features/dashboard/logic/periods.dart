// 04-sales-dashboard DSH-R3, R6, R7: the periods of the dashboard and the
// buckets a range is split into. Days are UTC midnights, so day arithmetic
// never meets a daylight-saving hour.

/// The fixed periods of the period bar, and a custom range.
enum Period { today, yesterday, thisWeek, thisMonth, thisYear, custom }

/// The bucket size of a trend or of Sales Analytics' columns.
enum Range { daily, weekly, monthly, quarterly, yearly }

/// Calendar days, both ends included.
typedef Span = ({DateTime from, DateTime to});

/// The calendar day of [d].
DateTime dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _plus(DateTime d, int days) =>
    DateTime.utc(d.year, d.month, d.day + days);

/// `YYYY-MM-DD`, as dates are stored and filtered.
String ymd(DateTime d) => d.toIso8601String().substring(0, 10);

/// The day a `YYYY-MM-DD` (or longer) text starts with.
DateTime parseDay(String text) => dayOf(DateTime.parse(text.substring(0, 10)));

/// The number of days in [s].
int lengthOf(Span s) => s.to.difference(s.from).inDays + 1;

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The first day of the week holding [d], weeks starting on
/// [firstDayOfWeek] (System Settings; Monday when not a weekday name).
DateTime weekStart(DateTime d, String firstDayOfWeek) {
  final first = _weekdays.indexOf(firstDayOfWeek) + 1;
  return _plus(d, -((d.weekday - (first == 0 ? 1 : first)) % 7));
}

/// [p] as of [now]: the fixed periods run up to today (DSH-R3).
Span spanOf(Period p, DateTime now, String firstDayOfWeek, {Span? custom}) {
  final today = dayOf(now);
  return switch (p) {
    Period.today => (from: today, to: today),
    Period.yesterday => (from: _plus(today, -1), to: _plus(today, -1)),
    Period.thisWeek => (from: weekStart(today, firstDayOfWeek), to: today),
    Period.thisMonth => (
      from: DateTime.utc(today.year, today.month),
      to: today,
    ),
    Period.thisYear => (from: DateTime.utc(today.year), to: today),
    Period.custom => custom ?? (from: today, to: today),
  };
}

/// What [s] of [p] is compared with: the same days one week, month or year
/// back (the 1st to the 18th of last month for This Month on the 18th); a
/// day or a custom range is compared with as many days just before it.
Span previousOf(Period p, Span s) {
  switch (p) {
    case Period.thisWeek:
      return (from: _plus(s.from, -7), to: _plus(s.to, -7));
    case Period.thisMonth:
      final from = DateTime.utc(s.from.year, s.from.month - 1);
      final last = DateTime.utc(s.from.year, s.from.month, 0).day;
      return (
        from: from,
        to: DateTime.utc(from.year, from.month, s.to.day.clamp(1, last)),
      );
    case Period.thisYear:
      final last = DateTime.utc(s.to.year - 1, s.to.month + 1, 0).day;
      return (
        from: DateTime.utc(s.from.year - 1),
        to: DateTime.utc(s.to.year - 1, s.to.month, s.to.day.clamp(1, last)),
      );
    case Period.today || Period.yesterday || Period.custom:
      final n = lengthOf(s);
      return (from: _plus(s.from, -n), to: _plus(s.to, -n));
  }
}

/// The Sales Trend's buckets for [s] (DSH-R6): days up to 31 days, weeks up
/// to 26 weeks, months beyond.
Range trendRange(Span s) => switch (lengthOf(s)) {
  <= 31 => Range.daily,
  <= 26 * 7 => Range.weekly,
  _ => Range.monthly,
};

/// [s] cut into [range]'s units; the first and last are cut to [s].
List<Span> bucketsOf(Span s, Range range, String firstDayOfWeek) {
  final out = <Span>[];
  var start = s.from;
  while (!start.isAfter(s.to)) {
    final next = switch (range) {
      Range.daily => _plus(start, 1),
      Range.weekly => _plus(weekStart(start, firstDayOfWeek), 7),
      Range.monthly => DateTime.utc(start.year, start.month + 1),
      Range.quarterly => DateTime.utc(
        start.year,
        (start.month - 1) ~/ 3 * 3 + 4,
      ),
      Range.yearly => DateTime.utc(start.year + 1),
    };
    final end = _plus(next, -1);
    out.add((from: start, to: end.isAfter(s.to) ? s.to : end));
    start = next;
  }
  return out;
}

/// The bucket index of each `YYYY-MM-DD` day in [buckets].
Map<String, int> dayIndex(List<Span> buckets) => {
  for (final (i, b) in buckets.indexed)
    for (var d = b.from; !d.isAfter(b.to); d = _plus(d, 1)) ymd(d): i,
};

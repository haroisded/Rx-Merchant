import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../data/dashboard_db.dart';
import '../logic/periods.dart';

const dashboardPath = '/dashboard';

/// The period bar's choice; [custom] holds a custom range (DSH-R3).
typedef PeriodChoice = ({Period period, Span? custom});

class PeriodNotifier extends Notifier<PeriodChoice> {
  @override
  PeriodChoice build() => (period: Period.today, custom: null);

  void choose(Period period, [Span? custom]) =>
      state = (period: period, custom: custom);
}

final periodProvider = NotifierProvider<PeriodNotifier, PeriodChoice>(
  PeriodNotifier.new,
);

/// The First Day of the Week in force (System Settings).
final firstDayOfWeekProvider = Provider<String>(
  (ref) => (ref.watch(systemSettingsProvider).value ?? const SystemSettings({}))
      .firstDayOfWeek,
);

/// Emits whenever a sale or the stock changes, so the dashboard shows a
/// completed sale without a refresh (DSH-R12).
final salesTickProvider = StreamProvider<Set<TableUpdate>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.salesInvoice,
      db.salesInvoiceItem,
      db.salesInvoicePayment,
      db.bin,
    ]),
  );
});

/// Everything the dashboard shows for the chosen period.
typedef Dashboard = ({
  bool anySale,
  Span span,
  Figures now,
  Figures before,
  double stockValue,
  double monthlySales,
  List<Span> buckets,
  List<double> trendValue,
  List<double> trendQty,
  List<Bar> groups,
  List<Bar> itemsByValue,
  List<Bar> itemsByQty,
  List<Bar> modes,
});

final dashboardProvider = FutureProvider<Dashboard>((ref) async {
  ref.watch(salesTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final firstDay = ref.watch(firstDayOfWeekProvider);
  final choice = ref.watch(periodProvider);
  final now = DateTime.now();
  final span = spanOf(choice.period, now, firstDay, custom: choice.custom);
  final buckets = bucketsOf(span, trendRange(span), firstDay);
  return (
    anySale: await db.hasAnySale(),
    span: span,
    now: await db.figures(span),
    before: await db.figures(previousOf(choice.period, span)),
    stockValue: await db.stockValue(),
    monthlySales: await db.monthlySales(now),
    buckets: buckets,
    trendValue: await db.trend(span, buckets),
    trendQty: await db.trend(span, buckets, qty: true),
    groups: await db.salesByGroup(span),
    itemsByValue: await db.topItems(span),
    itemsByQty: await db.topItems(span, qty: true),
    modes: await db.paymentModes(span),
  );
});

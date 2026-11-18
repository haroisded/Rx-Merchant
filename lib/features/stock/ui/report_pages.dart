import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/format.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/link_field.dart';
import '../../../core/widgets/report_table.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/simple_masters.dart' show priceListsProvider;
import '../data/stock_ledger.dart';
import '../data/stock_reports.dart';
import 'scan.dart';
import 'stock_masters_pages.dart' show batchStatusText;
import 'stock_providers.dart';

// The stock reports (STK-R43; 02-stock section 5, Reports).

enum _Filter {
  dates,
  warehouse,
  item,
  itemGroup,
  batch,
  serial,
  priceList,
  voucher,
}

/// How a column is shown.
enum _Col { text, qty, money, rate, dateTime, date, inOut, status }

enum StockReport {
  stockLedger('stock-ledger'),
  stockBalance('stock-balance'),
  quickStockBalance('quick-stock-balance'),
  batchBalance('batch-wise-balance-history'),
  serialLedger('serial-no-ledger'),
  itemPriceStock('item-price-stock'),
  lowStock('low-stock');

  const StockReport(this.slug);
  final String slug;

  static StockReport? of(String slug) =>
      values.where((r) => r.slug == slug).firstOrNull;

  String title(AppLocalizations l) => switch (this) {
    stockLedger => l.reportStockLedger,
    stockBalance => l.reportStockBalance,
    quickStockBalance => l.reportQuickStockBalance,
    batchBalance => l.reportBatchBalance,
    serialLedger => l.reportSerialNoLedger,
    itemPriceStock => l.reportItemPriceStock,
    lowStock => l.reportLowStock,
  };

  Set<_Filter> get _filters => switch (this) {
    stockLedger => {
      _Filter.dates, _Filter.warehouse, _Filter.item, _Filter.itemGroup, //
      _Filter.batch, _Filter.voucher,
    },
    stockBalance => {
      _Filter.dates,
      _Filter.itemGroup,
      _Filter.item,
      _Filter.warehouse,
    },
    batchBalance => {_Filter.dates, _Filter.item, _Filter.warehouse},
    serialLedger => {_Filter.serial, _Filter.item},
    itemPriceStock => {_Filter.item, _Filter.priceList},
    lowStock => {_Filter.warehouse, _Filter.itemGroup},
    quickStockBalance => const {},
  };

  List<(String, _Col)> _columns(AppLocalizations l) => switch (this) {
    stockLedger => [
      (l.date, _Col.dateTime), (l.item, _Col.text), (l.stockUom, _Col.text), //
      (l.inQty, _Col.qty), (l.outQty, _Col.qty), (l.balanceQty, _Col.qty),
      (l.warehouse, _Col.text), (l.incomingRate, _Col.rate),
      (l.valuationRate, _Col.rate), (l.balanceValue, _Col.money),
      (l.valueChange, _Col.money), (l.voucherType, _Col.text),
      (l.voucherNo, _Col.text), (l.batch, _Col.text),
    ],
    stockBalance => [
      (l.item, _Col.text), (l.itemName, _Col.text), (l.warehouse, _Col.text), //
      (l.stockUom, _Col.text), (l.openingQty, _Col.qty),
      (l.openingValue, _Col.money),
      (l.inQty, _Col.qty),
      (l.inValue, _Col.money),
      (l.outQty, _Col.qty), (l.outValue, _Col.money), (l.balanceQty, _Col.qty),
      (l.balanceValue, _Col.money), (l.valuationRate, _Col.rate),
    ],
    batchBalance => [
      (l.item, _Col.text), (l.batch, _Col.text), (l.warehouse, _Col.text), //
      (l.openingQty, _Col.qty), (l.inQty, _Col.qty), (l.outQty, _Col.qty),
      (l.balanceQty, _Col.qty),
      (l.expiryDate, _Col.date),
      (l.status, _Col.status),
    ],
    serialLedger => [
      (l.date, _Col.dateTime),
      (l.serialNo, _Col.text),
      (l.voucherType, _Col.text), //
      (l.voucherNo, _Col.text),
      (l.warehouse, _Col.text),
      (l.inOrOut, _Col.inOut),
      (l.status, _Col.status),
    ],
    itemPriceStock => [
      (l.item, _Col.text), (l.priceList, _Col.text), (l.rate, _Col.money), //
      (l.uom, _Col.text), (l.availableQty, _Col.qty),
    ],
    lowStock => [
      (l.item, _Col.text), (l.itemName, _Col.text), (l.warehouse, _Col.text), //
      (l.actualQty, _Col.qty),
      (l.reorderLevel, _Col.qty),
      (l.reorderQty, _Col.qty),
      (l.shortage, _Col.qty),
    ],
    quickStockBalance => const [],
  };

  Future<ReportRows> _run(AppDatabase db, StockFilters f) => switch (this) {
    stockLedger => db.stockLedgerReport(f),
    stockBalance => db.stockBalanceReport(f),
    batchBalance =>
      db
          .batchBalanceReport(f)
          .then(
            (rows) => [
              for (final r in rows) [...r, r[7]],
            ],
          ),
    serialLedger => db.serialLedgerReport(f),
    itemPriceStock => db.itemPriceStockReport(f),
    lowStock => db.lowStockReport(f),
    quickStockBalance => Future.value(const []),
  };
}

String _today() => toStorage(DateTime.now()).substring(0, 10);

/// One report: its filter bar and table. Links fill filters through
/// [query]: `warehouse`, `item`, `voucher`, `from`, `to`.
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key, required this.report, this.query = const {}});

  final StockReport report;
  final Map<String, String> query;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late StockFilters _f = StockFilters(
    from:
        widget.query['from'] ??
        (widget.query.containsKey('voucher')
            ? null
            : toStorage(DateTime.now().subtract(const Duration(days: 30)))
                  .substring(0, 10)),
    to: widget.query['to'] ?? _today(),
    warehouseId: int.tryParse(widget.query['warehouse'] ?? ''),
    itemId: int.tryParse(widget.query['item'] ?? ''),
    voucherNo: widget.query['voucher'],
  );
  late Future<ReportRows> _rows = _load();

  Future<ReportRows> _load() =>
      widget.report._run(ref.read(appDatabaseProvider), _f);

  void _set(StockFilters f) => setState(() {
    _f = f;
    _rows = _load();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final report = widget.report;
    if (report == StockReport.quickStockBalance) {
      return const _QuickStockBalance();
    }
    final formats = ref.watch(formatsProvider);
    final columns = report._columns(l);
    return Scaffold(
      appBar: AppBar(title: Text(report.title(l))),
      body: FutureBuilder(
        future: _rows,
        builder: (context, snap) {
          final rows = snap.data ?? const [];
          return ReportTable(
            columns: [for (final (c, _) in columns) c],
            rows: rows,
            exportName: report.slug,
            emptyText: snap.hasData ? l.noEntries : null,
            filters: ReportFilters(
              fields: (changed) => _FilterBar(
                filters: report._filters,
                value: _f,
                onChanged: (f) {
                  _set(f);
                  changed();
                },
              ),
            ),
            cell: (c, v) => _format(l, formats, columns[c].$2, v),
            totals: _totals(columns, rows),
            onRowTap:
                report == StockReport.stockLedger ||
                    report == StockReport.serialLedger
                ? (row) => _openVoucher(
                    context,
                    row[row.length - 2] as String,
                    row.last as int,
                  )
                : null,
          );
        },
      ),
    );
  }

  List<Object?>? _totals(List<(String, _Col)> columns, ReportRows rows) {
    if (rows.isEmpty) return null;
    final sum = switch (widget.report) {
      StockReport.stockLedger => {3, 4, 10},
      StockReport.stockBalance => {4, 5, 6, 7, 8, 9, 10, 11},
      StockReport.batchBalance => {3, 4, 5, 6},
      _ => const <int>{},
    };
    if (sum.isEmpty) return null;
    return [
      for (var c = 0; c < columns.length; c++)
        sum.contains(c)
            ? rows.fold<double>(
                0,
                (s, r) => s + ((r[c] as num?)?.toDouble() ?? 0),
              )
            : c == 0
            ? AppLocalizations.of(context).total
            : null,
    ];
  }
}

void _openVoucher(BuildContext context, String type, int id) {
  final slug = switch (type) {
    'Stock Entry' => 'stock-entry',
    'Stock Reconciliation' => 'stock-reconciliation',
    _ => null,
  };
  if (slug != null) context.go('/stock/$slug/$id');
}

String _format(AppLocalizations l, Formats f, _Col kind, Object? v) {
  if (v == null) return '';
  // The totals row puts its label in the first column, whatever its kind.
  if (v is String && (kind == _Col.dateTime || kind == _Col.date)) {
    if (DateTime.tryParse(v) == null) return v;
  }
  return switch (kind) {
    _Col.text => '$v',
    _Col.qty => v is num ? f.number(v) : '$v',
    _Col.money => v is num ? f.money(v) : '$v',
    _Col.rate => v is num ? f.number(v, f.system.currencyPrecision) : '$v',
    _Col.dateTime =>
      '${f.date(DateTime.parse('$v'))} ${f.time(DateTime.parse('$v'))}',
    _Col.date => f.date(DateTime.parse('$v')),
    _Col.inOut => v == 1 ? l.inLabel : l.outLabel,
    _Col.status => switch (v) {
      'Available' || 'Delivered' || 'Inactive' => l.serialStatus('$v'),
      _ => batchStatusText(l, '$v'),
    },
  };
}

/// The filter fields one report uses.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.filters,
    required this.value,
    required this.onChanged,
  });

  final Set<_Filter> filters;
  final StockFilters value;
  final ValueChanged<StockFilters> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final f = value;
    final items = ref.watch(itemRowsProvider).value ?? [];
    final warehouses = ref.watch(warehousesProvider).value ?? [];
    final groups = ref.watch(itemGroupsProvider).value ?? [];
    final lists = ref.watch(priceListsProvider).value ?? [];
    Widget box(Widget child) => SizedBox(width: 200, child: child);
    DropdownMenu<int?> menu(
      String label,
      int? v,
      List<(int, String)> options,
      ValueChanged<int?> set,
    ) => DropdownMenu<int?>(
      label: Text(label),
      initialSelection: v,
      expandedInsets: EdgeInsets.zero,
      onSelected: set,
      dropdownMenuEntries: [
        DropdownMenuEntry(value: null, label: l.all),
        for (final (id, name) in options)
          DropdownMenuEntry(value: id, label: name),
      ],
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (filters.contains(_Filter.dates)) ...[
          box(
            DateField(
              label: l.fromDate,
              value: f.from,
              formats: formats,
              onChanged: (v) => onChanged(f..from = v),
            ),
          ),
          box(
            DateField(
              label: l.toDate,
              value: f.to,
              formats: formats,
              onChanged: (v) => onChanged(f..to = v),
            ),
          ),
        ],
        if (filters.contains(_Filter.item))
          box(
            LinkField<ItemRow>(
              label: l.item,
              value: items.where((i) => i.id == f.itemId).firstOrNull,
              search: (q) => searchItems(items, q),
              labelOf: (r) => r.code,
              onChanged: (r) => onChanged(f..itemId = r?.id),
            ),
          ),
        if (filters.contains(_Filter.warehouse))
          box(
            menu(l.warehouse, f.warehouseId, [
              for (final w in warehouses) (w.id, w.name),
            ], (v) => onChanged(f..warehouseId = v)),
          ),
        if (filters.contains(_Filter.itemGroup))
          box(
            menu(l.itemGroup, f.itemGroupId, [
              for (final g in groups) (g.id, g.name),
            ], (v) => onChanged(f..itemGroupId = v)),
          ),
        if (filters.contains(_Filter.priceList))
          box(
            menu(l.priceList, f.priceListId, [
              for (final p in lists) (p.id, p.name),
            ], (v) => onChanged(f..priceListId = v)),
          ),
        if (filters.contains(_Filter.batch) && f.itemId != null)
          box(
            menu(l.batch, f.batchId, [
              for (final b
                  in ref.watch(itemBatchesProvider(f.itemId!)).value ??
                      <BatchRow>[])
                (b.id, b.batchId),
            ], (v) => onChanged(f..batchId = v)),
          ),
        if (filters.contains(_Filter.serial))
          box(
            TextFormField(
              initialValue: '',
              decoration: InputDecoration(labelText: l.serialNo),
              onFieldSubmitted: (v) async {
                final db = ref.read(appDatabaseProvider);
                final s = await (db.select(
                  db.serialNo,
                )..where((x) => x.serialNo.equals(v.trim()))).getSingleOrNull();
                onChanged(
                  f..serialId = s?.id ?? (v.trim().isEmpty ? null : -1),
                );
              },
            ),
          ),
        if (filters.contains(_Filter.voucher))
          box(
            TextFormField(
              initialValue: f.voucherNo,
              decoration: InputDecoration(labelText: l.voucherNo),
              onFieldSubmitted: (v) =>
                  onChanged(f..voucherNo = v.trim().isEmpty ? null : v.trim()),
            ),
          ),
      ],
    );
  }
}

/// Quick Stock Balance: one item (or a scanned barcode) in one warehouse on
/// one date, with a link to Stock Balance filtered the same way.
class _QuickStockBalance extends ConsumerStatefulWidget {
  const _QuickStockBalance();

  @override
  ConsumerState<_QuickStockBalance> createState() => _QuickStockBalanceState();
}

class _QuickStockBalanceState extends ConsumerState<_QuickStockBalance> {
  int? _itemId;
  int? _warehouseId;
  var _date = _today();
  ({double qty, double rate, double value})? _result;

  Future<void> _run() async {
    final item = _itemId, wh = _warehouseId;
    if (item == null || wh == null) return setState(() => _result = null);
    final b = await ref
        .read(appDatabaseProvider)
        .balanceAt(item, wh, '$_date 23:59:59');
    if (mounted) setState(() => _result = b);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final items = ref.watch(itemRowsProvider).value ?? [];
    final warehouses = usable(ref.watch(warehousesProvider).value ?? []);
    _warehouseId ??= warehouses
        .where(
          (w) => w.name == ref.watch(stockSettingsProvider).defaultWarehouse,
        )
        .firstOrNull
        ?.id;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l.reportQuickStockBalance)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: LinkField<ItemRow>(
                  label: l.item,
                  mandatory: true,
                  value: items.where((i) => i.id == _itemId).firstOrNull,
                  search: (q) => searchItems(items, q),
                  labelOf: (r) => '${r.code} · ${r.name}',
                  onChanged: (r) {
                    _itemId = r?.id;
                    _run();
                  },
                ),
              ),
              ScanButton(
                onScanned: (code) async {
                  final found = await itemByBarcode(
                    ref.read(appDatabaseProvider),
                    code,
                  );
                  _itemId = found?.itemId;
                  _run();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownMenu<int?>(
            label: Text('${l.warehouse} *'),
            initialSelection: _warehouseId,
            expandedInsets: EdgeInsets.zero,
            onSelected: (v) {
              _warehouseId = v;
              _run();
            },
            dropdownMenuEntries: [
              for (final w in warehouses)
                DropdownMenuEntry(value: w.id, label: w.name),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DateField(
            label: l.date,
            value: _date,
            mandatory: true,
            formats: formats,
            onChanged: (v) {
              _date = v ?? _date;
              _run();
            },
          ),
          if (r != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Card.filled(
              child: Column(
                children: [
                  ListTile(
                    title: Text(l.quantity),
                    trailing: Text(formats.number(r.qty)),
                  ),
                  ListTile(
                    title: Text(l.valuationRate),
                    trailing: Text(formats.money(r.rate)),
                  ),
                  ListTile(
                    title: Text(l.balanceValue),
                    trailing: Text(formats.money(r.value)),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go(
                '/stock/stock-balance?item=$_itemId&warehouse=$_warehouseId&to=$_date',
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.reportStockBalance),
            ),
          ],
        ],
      ),
    );
  }
}

import 'stock_rules.dart';

// Draft Stock Entry and Stock Reconciliation lines, and the checks a line
// must pass before the document is saved (STK-R3, R6, R14, R23, R33, R38,
// R42). No database access.

/// One Serial / Batch Entry of a line, by name (STK-R27). A serialised entry
/// has qty 1.
class SbEntry {
  SbEntry({this.serialNo, this.batchNo, this.qty = 1});

  String? serialNo;
  String? batchNo;
  double qty;
}

/// One row of a Stock Entry's Items table.
class EntryLine {
  EntryLine({
    this.id,
    required this.itemId,
    this.sWarehouseId,
    this.tWarehouseId,
    this.qty = 1,
    required this.uomId,
    this.factor = 1,
    this.basicRate = 0,
    this.allowZero = false,
    List<SbEntry>? entries,
  }) : entries = entries ?? [];

  int? id;
  int itemId;
  int? sWarehouseId;
  int? tWarehouseId;
  double qty;
  int uomId;

  /// Stock units in one [uomId].
  double factor;

  /// Per Stock UOM.
  double basicRate;
  bool allowZero;
  List<SbEntry> entries;
}

/// Edit Posting Date and Time is not stored: a draft saved with it off
/// takes its save time as both posting and modified time, so a posting time
/// that differs from `modified_at` was set by hand. Submit moves an unedited
/// one to the moment of submit.
bool postingSetByHand(String posting, String modified) => posting != modified;

/// One row of a Stock Reconciliation.
class ReconciliationLine {
  ReconciliationLine({
    this.id,
    required this.itemId,
    required this.warehouseId,
    this.qty = 0,
    this.rate = 0,
    this.currentQty = 0,
    this.currentRate = 0,
  });

  int? id;
  int itemId;
  int warehouseId;

  /// The counted quantity, in the Stock UOM.
  double qty;
  double rate;
  double currentQty;
  double currentRate;
}

enum StockPurpose {
  materialReceipt('Material Receipt'),
  materialIssue('Material Issue'),
  materialTransfer('Material Transfer');

  const StockPurpose(this.value);
  final String value;

  bool get hasSource => this != materialReceipt;
  bool get hasTarget => this != materialIssue;

  static StockPurpose of(String value) =>
      values.firstWhere((p) => p.value == value);
}

enum LineProblem {
  missingItem,
  qtyNotPositive,
  sourceRequired,
  targetRequired,
  sameWarehouse,
  groupWarehouse,
  fraction,
  itemDisabled,
  itemEndOfLife,
  itemTemplate,
  itemNotStock,
  zeroRate,
  serialCount,
  duplicateSerial,
  entriesQty,
  batchOrSerialItem,
  duplicateRow,
}

/// What the line checks need to know about an item.
typedef ItemFacts = ({
  String code,
  bool disabled,
  String? endOfLife,
  bool template,
  bool stockItem,
  bool hasBatch,
  bool hasSerial,
  bool stockUomWhole,
});

/// STK-R3, R6, R14, R23, R33, R38 for each line of a Stock Entry. Rows are
/// numbered from 1. [usableWarehouses] are the enabled, non-group ones;
/// [wholeUoms] the units marked Must be Whole Number; [date] is the posting
/// date, `YYYY-MM-DD`.
List<(int, LineProblem)> checkEntryLines(
  StockPurpose purpose,
  List<EntryLine> lines, {
  required Map<int, ItemFacts> items,
  required Set<int> usableWarehouses,
  required Set<int> wholeUoms,
  required String date,
  required int floatPrecision,
}) {
  final problems = <(int, LineProblem)>[];
  // STK-R23, R27: a serial number is one unit, on one line only.
  final serials = <String>{};
  for (final (i, l) in lines.indexed) {
    void add(LineProblem p) => problems.add((i + 1, p));
    final item = items[l.itemId];
    if (item == null) {
      add(LineProblem.missingItem);
      continue;
    }
    _itemProblems(item, date).forEach(add);
    if (l.entries.any((e) => e.serialNo != null && !serials.add(e.serialNo!))) {
      add(LineProblem.duplicateSerial);
    }
    if (l.qty <= 0) add(LineProblem.qtyNotPositive);
    final s = purpose.hasSource ? l.sWarehouseId : null;
    final t = purpose.hasTarget ? l.tWarehouseId : null;
    if (purpose.hasSource && s == null) add(LineProblem.sourceRequired);
    if (purpose.hasTarget && t == null) add(LineProblem.targetRequired);
    if (s != null && s == t) add(LineProblem.sameWarehouse);
    if ([s, t].any((w) => w != null && !usableWarehouses.contains(w))) {
      add(LineProblem.groupWarehouse);
    }
    final stock = stockQty(l.qty, l.factor, floatPrecision);
    if ((wholeUoms.contains(l.uomId) && !isWhole(l.qty)) ||
        (item.stockUomWhole && !isWhole(stock))) {
      add(LineProblem.fraction);
    }
    // STK-R33: a receipt needs a rate unless zero is allowed.
    if (purpose == StockPurpose.materialReceipt &&
        l.basicRate <= 0 &&
        !l.allowZero) {
      add(LineProblem.zeroRate);
    }
    if (item.hasSerial &&
        (!isWhole(stock) ||
            (l.entries.isNotEmpty &&
                l.entries.where((e) => e.serialNo != null).length != stock))) {
      add(LineProblem.serialCount);
    } else if ((item.hasBatch || item.hasSerial) &&
        l.entries.isNotEmpty &&
        (l.entries.fold(0.0, (s, e) => s + e.qty) - stock).abs() > 1e-9) {
      add(LineProblem.entriesQty);
    }
  }
  return problems;
}

/// STK-R42 for each row of a Stock Reconciliation.
List<(int, LineProblem)> checkReconciliationLines(
  List<ReconciliationLine> lines, {
  required Map<int, ItemFacts> items,
  required Set<int> usableWarehouses,
  required String date,
}) {
  final problems = <(int, LineProblem)>[];
  final seen = <(int, int)>{};
  for (final (i, l) in lines.indexed) {
    void add(LineProblem p) => problems.add((i + 1, p));
    final item = items[l.itemId];
    if (item == null) {
      add(LineProblem.missingItem);
      continue;
    }
    _itemProblems(item, date).forEach(add);
    if (item.hasBatch || item.hasSerial) add(LineProblem.batchOrSerialItem);
    if (!usableWarehouses.contains(l.warehouseId)) {
      add(LineProblem.groupWarehouse);
    }
    if (!seen.add((l.itemId, l.warehouseId))) add(LineProblem.duplicateRow);
    if (l.qty < 0) add(LineProblem.qtyNotPositive);
    if (item.stockUomWhole && !isWhole(l.qty)) add(LineProblem.fraction);
    if (l.qty > 0 && l.rate <= 0) add(LineProblem.zeroRate);
  }
  return problems;
}

/// STK-R6, R14: a disabled item, one past its End of Life, a template, or an
/// item that does not maintain stock cannot be moved.
List<LineProblem> _itemProblems(ItemFacts item, String date) => [
  if (item.disabled) LineProblem.itemDisabled,
  if (item.endOfLife case final eol? when eol.compareTo(date) < 0)
    LineProblem.itemEndOfLife,
  if (item.template) LineProblem.itemTemplate,
  if (!item.stockItem) LineProblem.itemNotStock,
];

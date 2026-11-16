import '../../stock/logic/barcode.dart';

/// Column labels of the import templates (SET-R16). The file's header row
/// uses these, and the import reads cells by them.
abstract final class Col {
  static const itemCode = 'Item Code';
  static const itemName = 'Item Name';
  static const itemGroup = 'Item Group';
  static const stockUom = 'Default Unit of Measure';
  static const maintainStock = 'Maintain Stock';
  static const isSalesItem = 'Is Sales Item';
  static const standardRate = 'Standard Selling Rate';
  static const valuationRate = 'Valuation Rate';
  static const barcode = 'Barcode';
  static const brand = 'Brand';
  static const description = 'Description';
  static const maxDiscount = 'Max Discount (%)';
  static const itemTaxTemplate = 'Item Tax Template';
  static const priceList = 'Price List';
  static const uom = 'UOM';
  static const rate = 'Rate';
  static const validFrom = 'Valid From';
  static const validUpto = 'Valid Upto';
  static const barcodeType = 'Barcode Type';
}

enum ColumnKind { text, number, check, date }

/// The master a cell must name.
enum LinkTo { item, itemGroup, uom, brand, priceList, itemTaxTemplate }

class ImportColumn {
  const ImportColumn(
    this.label, {
    this.mandatory = false,
    this.kind = ColumnKind.text,
    this.link,
  });

  final String label;
  final bool mandatory;
  final ColumnKind kind;
  final LinkTo? link;
}

enum ImportRecordType {
  item(
    'Item',
    [
      ImportColumn(Col.itemCode, mandatory: true),
      ImportColumn(Col.itemName),
      ImportColumn(Col.itemGroup, mandatory: true, link: LinkTo.itemGroup),
      ImportColumn(Col.stockUom, mandatory: true, link: LinkTo.uom),
      ImportColumn(Col.maintainStock, kind: ColumnKind.check),
      ImportColumn(Col.isSalesItem, kind: ColumnKind.check),
      ImportColumn(Col.standardRate, kind: ColumnKind.number),
      ImportColumn(Col.valuationRate, kind: ColumnKind.number),
      ImportColumn(Col.barcode),
      ImportColumn(Col.brand, link: LinkTo.brand),
      ImportColumn(Col.description),
      ImportColumn(Col.maxDiscount, kind: ColumnKind.number),
      ImportColumn(Col.itemTaxTemplate, link: LinkTo.itemTaxTemplate),
    ],
    keys: [Col.itemCode],
  ),
  itemPrice(
    'Item Price',
    [
      ImportColumn(Col.itemCode, mandatory: true, link: LinkTo.item),
      ImportColumn(Col.priceList, mandatory: true, link: LinkTo.priceList),
      ImportColumn(Col.uom, link: LinkTo.uom),
      ImportColumn(Col.rate, mandatory: true, kind: ColumnKind.number),
      ImportColumn(Col.validFrom, kind: ColumnKind.date),
      ImportColumn(Col.validUpto, kind: ColumnKind.date),
    ],
    keys: [Col.itemCode, Col.priceList],
  ),
  itemBarcode(
    'Item Barcode',
    [
      ImportColumn(Col.itemCode, mandatory: true, link: LinkTo.item),
      ImportColumn(Col.barcode, mandatory: true),
      ImportColumn(Col.barcodeType),
      ImportColumn(Col.uom, link: LinkTo.uom),
    ],
    keys: [Col.barcode],
  );

  const ImportRecordType(this.label, this.columns, {required this.keys});
  final String label;
  final List<ImportColumn> columns;

  /// Columns that identify the record; the only mandatory ones on update.
  final List<String> keys;
}

enum ImportType { insert, update }

/// What the import is checked against: the names already in the database.
class ImportLookups {
  const ImportLookups({
    this.items = const {},
    this.itemGroups = const {},
    this.uoms = const {},
    this.brands = const {},
    this.priceLists = const {},
    this.itemTaxTemplates = const {},
    this.barcodes = const {},
    this.prices = const {},
  });

  final Set<String> items;
  final Set<String> itemGroups;
  final Set<String> uoms;
  final Set<String> brands;
  final Set<String> priceLists;
  final Set<String> itemTaxTemplates;

  /// Barcode → the Item Code it belongs to.
  final Map<String, String> barcodes;

  /// Validity of existing Item Prices, keyed by [priceKey].
  final Map<String, List<({String? from, String? upto})>> prices;

  Set<String> of(LinkTo link) => switch (link) {
    LinkTo.item => items,
    LinkTo.itemGroup => itemGroups,
    LinkTo.uom => uoms,
    LinkTo.brand => brands,
    LinkTo.priceList => priceLists,
    LinkTo.itemTaxTemplate => itemTaxTemplates,
  };
}

/// Item Prices with the same key must not overlap in validity (STK-R10).
String priceKey(String item, String priceList, String uom) =>
    '$item\u0000$priceList\u0000$uom';

enum ImportProblemKind {
  missing,
  duplicate,
  notFound,
  unknownLink,
  badNumber,
  badValue,
  badDate,
  badBarcode,
  overlappingPrice,
}

/// One problem, by spreadsheet [row] (the header is row 1) and [column].
typedef ImportProblem = ({
  int row,
  String column,
  ImportProblemKind kind,
  String value,
});

String _normal(String header) => header
    .replaceAll('*', '')
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ');

/// The column each header cell names, or null for a header the user has to
/// map by hand. Case, spacing and a trailing `*` are ignored.
List<String?> matchHeaders(ImportRecordType type, List<String> header) => [
  for (final cell in header)
    type.columns
        .map((c) => c.label)
        .where((label) => _normal(label) == _normal(cell))
        .firstOrNull,
];

/// The data rows as `column → trimmed cell`; columns mapped to null are
/// dropped and fully blank rows are skipped.
List<Map<String, String>> rowsOf(
  List<List<String>> body,
  List<String?> mapping,
) => [
  for (final cells in body)
    if (cells.any((c) => c.trim().isNotEmpty))
      {
        for (final (i, column) in mapping.indexed)
          if (column != null && i < cells.length) column: cells[i].trim(),
      },
];

final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Every row is checked before anything is written (SET-R16 step 3).
List<ImportProblem> validateImport(
  ImportRecordType type,
  ImportType importType,
  List<Map<String, String>> rows,
  ImportLookups lookups,
) {
  final problems = <ImportProblem>[];
  final seenKeys = <String>{};
  final seenBarcodes = <String, String>{};
  final filePrices = <String, List<({String? from, String? upto})>>{};

  for (final (i, row) in rows.indexed) {
    final n = i + 2;
    String cell(String column) => row[column] ?? '';
    void add(String column, ImportProblemKind kind) =>
        problems.add((row: n, column: column, kind: kind, value: cell(column)));

    for (final c in type.columns) {
      final v = cell(c.label);
      if (v.isEmpty) {
        final required = importType == ImportType.insert
            ? c.mandatory
            : type.keys.contains(c.label);
        if (required) add(c.label, ImportProblemKind.missing);
        continue;
      }
      final ok = switch (c.kind) {
        ColumnKind.number => double.tryParse(v)?.isFinite ?? false,
        ColumnKind.check => v == '0' || v == '1',
        ColumnKind.date => _date.hasMatch(v) && DateTime.tryParse(v) != null,
        ColumnKind.text => true,
      };
      if (!ok) {
        add(c.label, switch (c.kind) {
          ColumnKind.number => ImportProblemKind.badNumber,
          ColumnKind.date => ImportProblemKind.badDate,
          _ => ImportProblemKind.badValue,
        });
      } else if (c.link case final link? when !lookups.of(link).contains(v)) {
        add(c.label, ImportProblemKind.unknownLink);
      }
    }

    switch (type) {
      case ImportRecordType.item:
        final code = cell(Col.itemCode);
        if (code.isEmpty) break;
        final exists = lookups.items.contains(code);
        if (!seenKeys.add(code) ||
            (importType == ImportType.insert && exists)) {
          add(Col.itemCode, ImportProblemKind.duplicate);
        } else if (importType == ImportType.update && !exists) {
          add(Col.itemCode, ImportProblemKind.notFound);
        }
        final barcode = cell(Col.barcode);
        if (barcode.isNotEmpty) {
          final owner = lookups.barcodes[barcode] ?? seenBarcodes[barcode];
          if (owner != null && owner != code) {
            add(Col.barcode, ImportProblemKind.duplicate);
          }
          seenBarcodes[barcode] = code;
        }

      case ImportRecordType.itemBarcode:
        final barcode = cell(Col.barcode);
        if (barcode.isEmpty) break;
        final barcodeType = cell(Col.barcodeType);
        final exists = lookups.barcodes.containsKey(barcode);
        if (!seenKeys.add(barcode) ||
            (importType == ImportType.insert && exists)) {
          add(Col.barcode, ImportProblemKind.duplicate);
        } else if (importType == ImportType.update && !exists) {
          add(Col.barcode, ImportProblemKind.notFound);
        }
        if (!const {'', 'EAN', 'UPC'}.contains(barcodeType)) {
          add(Col.barcodeType, ImportProblemKind.badValue);
        } else if (!validBarcode(barcodeType, barcode)) {
          add(Col.barcode, ImportProblemKind.badBarcode);
        }

      case ImportRecordType.itemPrice:
        final from = cell(Col.validFrom).isEmpty ? null : cell(Col.validFrom);
        final upto = cell(Col.validUpto).isEmpty ? null : cell(Col.validUpto);
        if (from != null && upto != null && from.compareTo(upto) > 0) {
          add(Col.validUpto, ImportProblemKind.badDate);
          break;
        }
        final key = priceKey(
          cell(Col.itemCode),
          cell(Col.priceList),
          cell(Col.uom),
        );
        final existing = lookups.prices[key] ?? const [];
        // On update the row replaces the price with the same Valid From.
        final self = existing.where((p) => p.from == from).firstOrNull;
        if (importType == ImportType.update && self == null) {
          add(Col.itemCode, ImportProblemKind.notFound);
          break;
        }
        final others = [
          ...existing.where(
            (p) => importType == ImportType.insert || p != self,
          ),
          ...?filePrices[key],
        ];
        if (others.any((p) => _overlaps(p.from, p.upto, from, upto))) {
          add(Col.validFrom, ImportProblemKind.overlappingPrice);
        }
        (filePrices[key] ??= []).add((from: from, upto: upto));
    }
  }
  return problems;
}

/// Empty bounds are open-ended. Dates are `YYYY-MM-DD`, so text order is
/// date order.
bool _overlaps(String? aFrom, String? aUpto, String? bFrom, String? bUpto) =>
    (aFrom == null || bUpto == null || aFrom.compareTo(bUpto) <= 0) &&
    (bFrom == null || aUpto == null || bFrom.compareTo(aUpto) <= 0);

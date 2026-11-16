import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/features/setup/logic/data_import.dart';
import 'package:rx_merchant/features/stock/logic/barcode.dart';

const lookups = ImportLookups(
  items: {'PEN'},
  itemGroups: {'Products'},
  uoms: {'Nos', 'Box'},
  priceLists: {'Standard Selling'},
  barcodes: {'4006381333931': 'PEN'},
  prices: {
    'PEN\u0000Standard Selling\u0000': [
      (from: '2026-01-01', upto: '2026-06-30'),
    ],
  },
);

List<ImportProblemKind> kinds(
  ImportRecordType type,
  List<Map<String, String>> rows, [
  ImportType importType = ImportType.insert,
]) => [for (final p in validateImport(type, importType, rows, lookups)) p.kind];

Map<String, String> item(String code, {String group = 'Products'}) => {
  Col.itemCode: code,
  Col.itemGroup: group,
  Col.stockUom: 'Nos',
};

void main() {
  test('headers match ignoring case, spacing and *; unknown ones are null', () {
    expect(
      matchHeaders(ImportRecordType.item, [
        'item code*',
        ' Item  Group',
        'Colour',
      ]),
      [Col.itemCode, Col.itemGroup, null],
    );
  });

  test('rowsOf drops unmapped columns and blank rows', () {
    expect(
      rowsOf(
        [
          ['A', 'x'],
          [' ', ''],
        ],
        [Col.itemCode, null],
      ),
      [
        {Col.itemCode: 'A'},
      ],
    );
  });

  test('SET-A17 an unknown Item Group is named by row and column', () {
    final problems = validateImport(ImportRecordType.item, ImportType.insert, [
      item('A'),
      item('B', group: 'Toys'),
    ], lookups);
    expect(problems, [
      (
        row: 3,
        column: Col.itemGroup,
        kind: ImportProblemKind.unknownLink,
        value: 'Toys',
      ),
    ]);
  });

  test('insert: missing mandatory, duplicate name, bad number and check', () {
    expect(
      kinds(ImportRecordType.item, [
        {Col.itemCode: 'C'},
        item('PEN'),
        {...item('D'), Col.standardRate: 'ten', Col.maintainStock: 'yes'},
        item('D'),
      ]),
      [
        ImportProblemKind.missing,
        ImportProblemKind.missing,
        ImportProblemKind.duplicate,
        ImportProblemKind.badValue,
        ImportProblemKind.badNumber,
        ImportProblemKind.duplicate,
      ],
    );
  });

  test('update: only the key is mandatory, and it must exist', () {
    expect(
      kinds(ImportRecordType.item, [
        {Col.itemCode: 'PEN', Col.itemName: 'Blue pen'},
        {Col.itemCode: 'NOPE'},
      ], ImportType.update),
      [ImportProblemKind.notFound],
    );
  });

  test('a barcode belongs to one item only', () {
    expect(
      kinds(ImportRecordType.item, [
        {...item('E'), Col.barcode: '4006381333931'},
      ]),
      [ImportProblemKind.duplicate],
    );
  });

  test('Item Barcode: type and check digit (STK-R8)', () {
    expect(
      kinds(ImportRecordType.itemBarcode, [
        {
          Col.itemCode: 'PEN',
          Col.barcode: '4006381333932',
          Col.barcodeType: 'EAN',
        },
        {Col.itemCode: 'PEN', Col.barcode: '12345', Col.barcodeType: 'QR'},
        {
          Col.itemCode: 'PEN',
          Col.barcode: '036000291452',
          Col.barcodeType: 'UPC',
        },
      ]),
      [ImportProblemKind.badBarcode, ImportProblemKind.badValue],
    );
  });

  test('Item Price validity must not overlap (STK-R10)', () {
    Map<String, String> price(String? from, String? upto) => {
      Col.itemCode: 'PEN',
      Col.priceList: 'Standard Selling',
      Col.rate: '10',
      Col.validFrom: ?from,
      Col.validUpto: ?upto,
    };
    expect(
      kinds(ImportRecordType.itemPrice, [price('2026-07-01', null)]),
      isEmpty,
    );
    expect(kinds(ImportRecordType.itemPrice, [price('2026-06-01', null)]), [
      ImportProblemKind.overlappingPrice,
    ]);
    expect(
      kinds(ImportRecordType.itemPrice, [
        price('2026-07-01', '2026-07-31'),
        price('2026-07-15', null),
      ]),
      [ImportProblemKind.overlappingPrice],
    );
    expect(
      kinds(ImportRecordType.itemPrice, [price('2026-08-01', '2026-07-01')]),
      [ImportProblemKind.badDate],
    );
    // Update replaces the price with the same Valid From.
    expect(
      kinds(ImportRecordType.itemPrice, [
        price('2026-01-01', '2026-12-31'),
      ], ImportType.update),
      isEmpty,
    );
  });

  test('validBarcode', () {
    expect(validBarcode('EAN', '4006381333931'), isTrue);
    expect(validBarcode('EAN', '4006381333932'), isFalse);
    expect(validBarcode('EAN', '400638133393'), isFalse);
    expect(validBarcode('UPC', '036000291452'), isTrue);
    expect(validBarcode('UPC', '03600029145A'), isFalse);
    expect(validBarcode(null, 'ANY-CODE'), isTrue);
  });
}

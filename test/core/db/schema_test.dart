import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';

/// The table index in section 8 of 00-overview-and-foundation.md.
const specTables = <String>{
  // 01-setup.md
  'singles', 'currency', 'naming_series_option', 'series', 'mode_of_payment',
  'tax', 'sales_taxes_template', 'sales_taxes_template_row',
  'item_tax_template', 'item_tax_template_row', 'price_list', 'pos_profile',
  'pos_profile_payment', 'pos_profile_item_group',
  // 02-stock.md
  'warehouse', 'item_group', 'uom', 'brand', 'item', 'item_barcode',
  'item_uom', 'item_reorder', 'item_tax', 'item_attribute',
  'item_attribute_value', 'item_variant_attribute', 'item_price', 'batch',
  'serial_no', 'stock_entry', 'stock_entry_item',
  'stock_entry_additional_cost', 'stock_reconciliation',
  'stock_reconciliation_item', 'serial_and_batch_entry', 'stock_ledger_entry',
  'bin',
  // 03-cash-register.md
  'pos_opening_entry', 'pos_opening_entry_detail', 'pos_closing_entry',
  'pos_closing_entry_detail', 'sales_invoice', 'sales_invoice_item',
  'sales_invoice_tax', 'sales_invoice_payment',
  // 05-invoices-and-receipts.md
  'letter_head', 'print_heading', 'terms_and_conditions',
};

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<String>> namesOf(String type) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = ? AND name NOT LIKE 'sqlite_%'",
          variables: [Variable.withString(type)],
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  test('schema v1 creates exactly the 48 tables of the table index', () async {
    expect(specTables, hasLength(48));
    expect((await namesOf('table')).toSet(), specTables);
  });

  test('schema v1 creates the 14 indexes of the feature plans', () async {
    expect(await namesOf('index'), hasLength(14));
  });

  test('foreign keys are switched on', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('a child row pointing at a missing parent is refused', () async {
    await expectLater(
      db.customStatement(
        "INSERT INTO sales_taxes_template_row "
        "(template_id, idx, charge_type, tax_id) VALUES (999, 1, 'Actual', 999)",
      ),
      throwsA(predicate((e) => '$e'.contains('FOREIGN KEY'))),
    );
  });
}

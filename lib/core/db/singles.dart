import 'package:drift/drift.dart';

import 'app_database.dart';

/// ERPNext "Single" settings pages, kept as key-value rows in `singles`
/// (00-overview, section 6.5). A missing key falls back to the default in
/// the typed classes below, so adding a setting needs no migration.
extension SinglesAccess on AppDatabase {
  /// The stored fields of [doctype]. Unset and cleared keys are absent.
  Future<Map<String, String>> readSingle(String doctype) =>
      _rowsOf(doctype).get().then(_toMap);

  /// Like [readSingle], and emits again whenever `singles` changes.
  Stream<Map<String, String>> watchSingle(String doctype) =>
      _rowsOf(doctype).watch().map(_toMap);

  /// Upserts [values]. Booleans are stored as '1' / '0'; null clears a key.
  Future<void> writeSingle(String doctype, Map<String, Object?> values) =>
      batch((b) {
        for (final MapEntry(:key, :value) in values.entries) {
          final text = switch (value) {
            null => null,
            final bool flag => flag ? '1' : '0',
            _ => '$value',
          };
          b.insert(
            singles,
            SinglesCompanion.insert(
              doctype: doctype,
              field: key,
              value: Value(text),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  SimpleSelectStatement<Singles, Single> _rowsOf(String doctype) =>
      select(singles)..where((s) => s.doctype.equals(doctype));
}

Map<String, String> _toMap(List<Single> rows) => {
  for (final r in rows)
    if (r.value != null) r.field: r.value!,
};

bool _flag(Map<String, String> v, String key, bool fallback) =>
    v.containsKey(key) ? v[key] == '1' : fallback;

int _int(Map<String, String> v, String key, int fallback) =>
    int.tryParse(v[key] ?? '') ?? fallback;

/// Keys and defaults: 01-setup.md, "Settings stored in `singles`".
class StoreProfile {
  const StoreProfile(this.v);
  static const doctype = 'Store Profile';
  final Map<String, String> v;

  String get storeName => v['store_name'] ?? '';

  /// Defaults to the initials of the store name, also when saved blank.
  String get abbr => switch (v['abbr']?.trim()) {
    final a? when a.isNotEmpty => a,
    _ =>
      storeName
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase())
          .join(),
  };
  String? get country => v['country'];
  String? get defaultCurrency => v['default_currency'];

  /// 0 switches the sales goal off.
  double get monthlySalesTarget =>
      double.tryParse(v['monthly_sales_target'] ?? '') ?? 0;
}

class SystemSettings {
  const SystemSettings(this.v);
  static const doctype = 'System Settings';
  final Map<String, String> v;

  String? get country => v['country'];
  String get language => v['language'] ?? 'en';
  String get dateFormat => v['date_format'] ?? 'yyyy-mm-dd';
  String get timeFormat => v['time_format'] ?? 'HH:mm:ss';
  String get numberFormat => v['number_format'] ?? '#,###.##';
  String get firstDayOfWeek => v['first_day_of_week'] ?? 'Monday';
  int get floatPrecision => _int(v, 'float_precision', 3);
  int get currencyPrecision => _int(v, 'currency_precision', 2);

  /// "Banker's Rounding" or "Commercial Rounding"; see `RoundingMethod`.
  String get roundingMethod => v['rounding_method'] ?? "Banker's Rounding";
  int get numberOfBackups => _int(v, 'number_of_backups', 3);

  /// Set by the first-run wizard (SET-R1).
  bool get setupComplete => _flag(v, 'setup_complete', false);
}

class GlobalDefaults {
  const GlobalDefaults(this.v);
  static const doctype = 'Global Defaults';
  final Map<String, String> v;

  bool get hideCurrencySymbol => _flag(v, 'hide_currency_symbol', false);
  bool get disableRoundedTotal => _flag(v, 'disable_rounded_total', false);
  bool get disableInWords => _flag(v, 'disable_in_words', false);
}

class SellingSettings {
  const SellingSettings(this.v);
  static const doctype = 'Selling Settings';
  final Map<String, String> v;

  String get sellingPriceList => v['selling_price_list'] ?? 'Standard Selling';
  bool get fallbackToDefaultPriceList =>
      _flag(v, 'fallback_to_default_price_list', false);
  bool get editablePriceListRate => _flag(v, 'editable_price_list_rate', false);
  bool get validateSellingPrice => _flag(v, 'validate_selling_price', false);
}

/// How the Cash Register behaves: what ERPNext keeps on a POS Profile, for
/// the one register of a one-owner store (01-setup, SET-R14). Keys are
/// ERPNext's POS Profile field names.
class PosSettings {
  const PosSettings(this.v);
  static const doctype = 'POS Settings';
  final Map<String, String> v;

  /// Pre-filled at checkout; unset or blank means Cash, as in ERPNext. A
  /// mode disabled since is replaced at checkout by the first enabled mode
  /// of Type Cash (SET-R14).
  String get defaultModeOfPayment =>
      _optionalText(v, 'default_mode_of_payment') ?? 'Cash';
  bool get hideImages => _flag(v, 'hide_images', false);
  bool get hideUnavailableItems => _flag(v, 'hide_unavailable_items', false);
  bool get allowRateChange => _flag(v, 'allow_rate_change', false);
  bool get autoAddItemToCart => _flag(v, 'auto_add_item_to_cart', false);
  bool get allowDiscountChange => _flag(v, 'allow_discount_change', false);
  bool get validateStockOnSave => _flag(v, 'validate_stock_on_save', false);
  bool get setGrandTotalToDefaultMop =>
      _flag(v, 'set_grand_total_to_default_mop', true);
  bool get printReceiptOnOrderComplete =>
      _flag(v, 'print_receipt_on_order_complete', false);

  /// 'Always Ask', 'Save Changes and Load New Invoice' or
  /// 'Discard Changes and Load New Invoice'.
  String get actionOnNewInvoice => v['action_on_new_invoice'] ?? 'Always Ask';

  /// 'Grand Total' or 'Net Total'.
  String get applyDiscountOn => v['apply_discount_on'] ?? 'Grand Total';

  /// 'POS Receipt' or 'Standard'.
  String get printFormat => v['print_format'] ?? 'POS Receipt';

  /// Print Heading name; null for the document's own title.
  String? get selectPrintHeading => _optionalText(v, 'select_print_heading');

  /// Terms and Conditions title; null for none.
  String? get tcName => _optionalText(v, 'tc_name');
}

/// A stored text, or null when unset or saved blank ("None").
String? _optionalText(Map<String, String> v, String key) =>
    (v[key] ?? '').isEmpty ? null : v[key];

/// Keys and defaults: 02-stock.md, "Stock Settings (in `singles`)".
class StockSettings {
  const StockSettings(this.v);
  static const doctype = 'Stock Settings';
  final Map<String, String> v;

  /// 'Item Code' or 'Naming Series'.
  String get itemNamingBy => v['item_naming_by'] ?? 'Item Code';
  String get itemGroup => v['item_group'] ?? 'Products';
  String get stockUom => v['stock_uom'] ?? 'Nos';
  String get defaultWarehouse => v['default_warehouse'] ?? 'Stores';

  /// 'FIFO' or 'Moving Average'.
  String get valuationMethod => v['valuation_method'] ?? 'FIFO';
  bool get showBarcodeField => _flag(v, 'show_barcode_field', true);
  bool get autoInsertPriceListRateIfMissing =>
      _flag(v, 'auto_insert_price_list_rate_if_missing', true);
  bool get allowNegativeStock => _flag(v, 'allow_negative_stock', false);

  /// "Show low-stock alerts".
  bool get autoIndent => _flag(v, 'auto_indent', true);
  String? get stockFrozenUpto => v['stock_frozen_upto'];
  bool get enableSerialAndBatchNoForItem =>
      _flag(v, 'enable_serial_and_batch_no_for_item', false);

  /// 'FIFO', 'LIFO' or 'Expiry'.
  String get pickSerialAndBatchBasedOn =>
      v['pick_serial_and_batch_based_on'] ?? 'FIFO';
  bool get autoCreateSerialAndBatchBundleForOutward =>
      _flag(v, 'auto_create_serial_and_batch_bundle_for_outward', true);
}

/// Keys and defaults: 05-invoices-and-receipts.md, "Print Settings (in `singles`)".
class PrintSettings {
  const PrintSettings(this.v);
  static const doctype = 'Print Settings';
  final Map<String, String> v;

  /// 'A4', 'A5' or 'Letter'.
  String get pdfPageSize => v['pdf_page_size'] ?? 'A4';
  bool get repeatHeaderFooter => _flag(v, 'repeat_header_footer', true);
  bool get withLetterhead => _flag(v, 'with_letterhead', true);
  bool get compactItemPrint => _flag(v, 'compact_item_print', true);
  bool get allowPrintForDraft => _flag(v, 'allow_print_for_draft', true);
  bool get addDraftHeading => _flag(v, 'add_draft_heading', true);
  bool get allowPrintForCancelled =>
      _flag(v, 'allow_print_for_cancelled', false);
  bool get printTaxesWithZeroAmount =>
      _flag(v, 'print_taxes_with_zero_amount', false);
  bool get enableRawPrinting => _flag(v, 'enable_raw_printing', false);
  String? get rawPrinterName => v['raw_printer_name'];
  String? get rawPrinterAddress => v['raw_printer_address'];

  /// '80mm' or '58mm'.
  String get rawPaperWidth => v['raw_paper_width'] ?? '80mm';

  /// 48 for 80mm paper, 32 for 58mm, unless edited.
  int get rawCharsPerLine =>
      _int(v, 'raw_chars_per_line', rawPaperWidth == '58mm' ? 32 : 48);
  bool get rawCutPaper => _flag(v, 'raw_cut_paper', true);
  bool get rawOpenCashDrawer => _flag(v, 'raw_open_cash_drawer', false);
}

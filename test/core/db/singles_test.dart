import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_merchant/core/db/app_database.dart';
import 'package:rx_merchant/core/db/singles.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('defaults when nothing is stored', () {
    test('System Settings', () async {
      final s = SystemSettings(await db.readSingle(SystemSettings.doctype));
      expect(s.country, isNull);
      expect(s.language, 'en');
      expect(s.dateFormat, 'yyyy-mm-dd');
      expect(s.timeFormat, 'HH:mm:ss');
      expect(s.numberFormat, '#,###.##');
      expect(s.firstDayOfWeek, 'Monday');
      expect(s.floatPrecision, 3);
      expect(s.currencyPrecision, 2);
      expect(s.roundingMethod, "Banker's Rounding");
      expect(s.numberOfBackups, 3);
      expect(s.setupComplete, isFalse);
    });

    test('Store Profile', () async {
      final s = StoreProfile(await db.readSingle(StoreProfile.doctype));
      expect(s.storeName, '');
      expect(s.abbr, '');
      expect(s.country, isNull);
      expect(s.defaultCurrency, isNull);
      expect(s.monthlySalesTarget, 0);
    });

    test('Store Profile abbreviation defaults to the initials of the name', () {
      expect(
        const StoreProfile({'store_name': 'Rx merchant Store'}).abbr,
        'RMS',
      );
      expect(
        const StoreProfile({'store_name': 'Rx Merchant', 'abbr': 'RX'}).abbr,
        'RX',
      );
      expect(
        const StoreProfile({'store_name': 'Rx Merchant', 'abbr': ' '}).abbr,
        'RM',
      );
    });

    test('Global Defaults', () async {
      final s = GlobalDefaults(await db.readSingle(GlobalDefaults.doctype));
      expect(s.hideCurrencySymbol, isFalse);
      expect(s.disableRoundedTotal, isFalse);
      expect(s.disableInWords, isFalse);
    });

    test('Selling Settings', () async {
      final s = SellingSettings(await db.readSingle(SellingSettings.doctype));
      expect(s.sellingPriceList, 'Standard Selling');
      expect(s.fallbackToDefaultPriceList, isFalse);
      expect(s.editablePriceListRate, isFalse);
      expect(s.validateSellingPrice, isFalse);
    });

    test('Stock Settings', () async {
      final s = StockSettings(await db.readSingle(StockSettings.doctype));
      expect(s.itemNamingBy, 'Item Code');
      expect(s.itemGroup, 'Products');
      expect(s.stockUom, 'Nos');
      expect(s.defaultWarehouse, 'Stores');
      expect(s.valuationMethod, 'FIFO');
      expect(s.showBarcodeField, isTrue);
      expect(s.autoInsertPriceListRateIfMissing, isTrue);
      expect(s.allowNegativeStock, isFalse);
      expect(s.autoIndent, isTrue);
      expect(s.stockFrozenUpto, isNull);
      expect(s.enableSerialAndBatchNoForItem, isFalse);
      expect(s.pickSerialAndBatchBasedOn, 'FIFO');
      expect(s.autoCreateSerialAndBatchBundleForOutward, isTrue);
    });

    test('Print Settings', () async {
      final s = PrintSettings(await db.readSingle(PrintSettings.doctype));
      expect(s.pdfPageSize, 'A4');
      expect(s.repeatHeaderFooter, isTrue);
      expect(s.withLetterhead, isTrue);
      expect(s.compactItemPrint, isTrue);
      expect(s.allowPrintForDraft, isTrue);
      expect(s.addDraftHeading, isTrue);
      expect(s.allowPrintForCancelled, isFalse);
      expect(s.printTaxesWithZeroAmount, isFalse);
      expect(s.enableRawPrinting, isFalse);
      expect(s.rawPrinterName, isNull);
      expect(s.rawPrinterAddress, isNull);
      expect(s.rawPaperWidth, '80mm');
      expect(s.rawCharsPerLine, 48);
      expect(s.rawCutPaper, isTrue);
      expect(s.rawOpenCashDrawer, isFalse);
    });

    test('Print Settings characters per line follows the paper width', () {
      expect(
        const PrintSettings({'raw_paper_width': '58mm'}).rawCharsPerLine,
        32,
      );
      expect(
        const PrintSettings({
          'raw_paper_width': '58mm',
          'raw_chars_per_line': '30',
        }).rawCharsPerLine,
        30,
      );
    });
  });

  test('written values are read back through the typed getters', () async {
    await db.writeSingle(SystemSettings.doctype, {
      'currency_precision': 3,
      'setup_complete': true,
      'date_format': 'dd-mm-yyyy',
    });
    final s = SystemSettings(await db.readSingle(SystemSettings.doctype));
    expect(s.currencyPrecision, 3);
    expect(s.setupComplete, isTrue);
    expect(s.dateFormat, 'dd-mm-yyyy');
    expect(s.floatPrecision, 3, reason: 'unwritten keys keep their default');
  });

  test('writing a key twice keeps one row holding the last value', () async {
    await db.writeSingle(SystemSettings.doctype, {'language': 'fr'});
    await db.writeSingle(SystemSettings.doctype, {'language': 'de'});
    expect(await db.readSingle(SystemSettings.doctype), {'language': 'de'});
  });

  test('writing null clears the key so the default comes back', () async {
    await db.writeSingle(SystemSettings.doctype, {'language': 'fr'});
    await db.writeSingle(SystemSettings.doctype, {'language': null});
    final s = SystemSettings(await db.readSingle(SystemSettings.doctype));
    expect(s.language, 'en');
  });

  test('the same field under two doctypes stays separate', () async {
    await db.writeSingle(StoreProfile.doctype, {'country': 'Philippines'});
    await db.writeSingle(SystemSettings.doctype, {'country': 'Japan'});
    expect(
      StoreProfile(await db.readSingle(StoreProfile.doctype)).country,
      'Philippines',
    );
    expect(
      SystemSettings(await db.readSingle(SystemSettings.doctype)).country,
      'Japan',
    );
  });

  test('watchSingle emits again after a write', () async {
    final languages = db
        .watchSingle(SystemSettings.doctype)
        .map((m) => SystemSettings(m).language);
    final seen = expectLater(languages, emitsInOrder(['en', 'fr']));
    await pumpEventQueue();
    await db.writeSingle(SystemSettings.doctype, {'language': 'fr'});
    await seen;
  });
}

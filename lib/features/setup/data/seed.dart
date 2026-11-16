import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import 'country_info.dart';

/// ERPNext's default naming series (01-setup, section 3).
const defaultNamingSeries = {
  'Sales Invoice': 'ACC-SINV-.YYYY.-',
  'Sales Invoice Return': 'ACC-SINV-RET-.YYYY.-',
  'Stock Entry': 'MAT-STE-.YYYY.-',
  'Stock Reconciliation': 'MAT-RECO-.YYYY.-',
  'POS Opening Entry': 'POS-OPE-.YYYY.-',
  'POS Closing Entry': 'POS-CLO-.YYYY.-',
  'Item': 'STO-ITEM-.YYYY.-',
};

const _wholeNumberUoms = [
  'Nos', 'Unit', 'Box', 'Carton', 'Pack', 'Pair', 'Set', 'Dozen', //
];
const _fractionalUoms = ['Kg', 'Gram', 'Litre', 'Millilitre', 'Meter'];

extension SetupSeed on AppDatabase {
  /// Finishes the first-run wizard (SET-R1, SET-R3): writes every seed record
  /// and sets `setup_complete`, all in one transaction.
  ///
  /// [currencyOf] is the country whose currency was chosen; it is [country]
  /// unless the owner picked another currency.
  Future<void> completeSetup({
    required String language,
    required CountryInfo country,
    required CountryInfo currencyOf,
    required String storeName,
    required String abbr,
  }) => transaction(() async {
    final currencyCode = currencyOf.currency!;
    await into(currency).insert(currencyOf.toCurrency());

    final allWarehouses = await into(warehouse).insert(
      WarehouseCompanion.insert(
        name: 'All Warehouses',
        isGroup: const Value(1),
      ),
    );
    final stores = await into(warehouse).insert(
      WarehouseCompanion.insert(name: 'Stores', parentId: Value(allWarehouses)),
    );

    final allGroups = await into(itemGroup).insert(
      ItemGroupCompanion.insert(
        name: 'All Item Groups',
        isGroup: const Value(1),
      ),
    );
    for (final name in ['Products', 'Services', 'Consumable']) {
      await into(itemGroup).insert(
        ItemGroupCompanion.insert(name: name, parentId: Value(allGroups)),
      );
    }

    for (final name in _wholeNumberUoms) {
      await into(uom).insert(
        UomCompanion.insert(name: name, mustBeWholeNumber: const Value(1)),
      );
    }
    for (final name in _fractionalUoms) {
      await into(uom).insert(UomCompanion.insert(name: name));
    }

    final standardSelling = await into(priceList)
        .insert(PriceListCompanion.insert(name: 'Standard Selling'));

    final cash = await into(modeOfPayment).insert(
      ModeOfPaymentCompanion.insert(name: 'Cash', type: const Value('Cash')),
    );
    for (final name in ['Credit Card', 'Wire Transfer']) {
      await into(modeOfPayment).insert(
        ModeOfPaymentCompanion.insert(name: name, type: const Value('Bank')),
      );
    }

    final mainCounter = await into(posProfile).insert(
      PosProfileCompanion.insert(
        name: 'Main Counter',
        isDefault: const Value(1),
        warehouseId: stores,
        priceListId: standardSelling,
      ),
    );
    await into(posProfilePayment).insert(
      PosProfilePaymentCompanion.insert(
        posProfileId: mainCounter,
        modeOfPaymentId: cash,
        isDefault: const Value(1),
        allowInReturns: const Value(1),
      ),
    );

    for (final MapEntry(key: doctype, value: pattern)
        in defaultNamingSeries.entries) {
      await into(namingSeriesOption).insert(
        NamingSeriesOptionCompanion.insert(
          doctype: doctype,
          pattern: pattern,
          idx: 1,
        ),
      );
    }

    await into(letterHead).insert(
      LetterHeadCompanion.insert(
        name: storeName,
        isDefault: const Value(1),
        header: Value(storeName),
      ),
    );

    await writeSingle(StockSettings.doctype, {
      'item_group': 'Products',
      'stock_uom': 'Nos',
      'default_warehouse': 'Stores',
      'valuation_method': 'FIFO',
    });
    await writeSingle(SellingSettings.doctype, {
      'selling_price_list': 'Standard Selling',
    });
    await writeSingle(StoreProfile.doctype, {
      'store_name': storeName,
      'abbr': abbr,
      'country': country.name,
      'default_currency': currencyCode,
    });
    await writeSingle(SystemSettings.doctype, {
      'country': country.name,
      'language': language,
      'date_format': country.dateFormat,
      'number_format': country.numberFormat,
      'currency_precision': currencyOf.currencyPrecision,
      'setup_complete': true,
    });
  });
}

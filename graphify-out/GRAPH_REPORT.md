# Graph Report - rx_merchant  (2026-11-18)

## Corpus Check
- 105 files · ~76,718 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2021 nodes · 3281 edges · 97 communities (90 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6ed71b85`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- singles.dart
- report_table.dart
- router.dart
- package:material_ui/material_ui.dart
- formats.dart
- format.dart
- link_field.dart
- app_test.dart
- batch_table.dart
- valuation.dart
- spacing.dart
- package:flutter_test/flutter_test.dart
- MainActivity.kt
- rx_merchant
- data_import.dart
- settings_pages.dart
- tax_template_pages.dart
- totals.dart
- simple_masters.dart
- country_info.dart
- data_pages.dart
- setup_queries.dart
- form_kit.dart
- tax_template.dart
- wizard_screen.dart
- naming_series_page.dart
- item_pages.dart
- backup.dart
- ../../../core/numbers/format.dart
- stock_entry_page.dart
- State
- ConsumerState
- sale.dart
- StatelessWidget
- setup_db_test.dart
- package:drift/drift.dart
- AppDatabase
- stock_masters_pages.dart
- ../../../core/db/app_database.dart
- stock_reconciliation_page.dart
- appDatabaseProvider
- stock_logic_test.dart
- serial_batch_editor.dart
- stock_documents.dart
- formatsProvider
- barcode.dart
- stock_db_test.dart
- report_pages.dart
- tree_masters.dart
- stock_entry_db.dart
- stock_masters.dart
- stock_reports.dart
- stock_providers.dart
- stock_rules.dart
- stock_ledger.dart
- build
- ../../../core/widgets/spacing.dart
- stock_screen.dart
- stock_reconciliation_db.dart
- typedef
- status_chip_test.dart
- stock_ui_test.dart
- ValueChanged
- scan.dart
- pos_db.dart
- providers.dart
- return
- List
- ConsumerWidget
- package:go_router/go_router.dart
- list_detail_pane.dart
- serials.dart
- l10n/app_localizations.dart
- pos_providers.dart
- Batches
- cartProvider
- _CostEditor
- _ValueEditor
- pos_screen.dart
- pos_widgets.dart
- pos_db_test.dart
- payment_panel.dart
- item_selector.dart
- cart_panel.dart
- closing_page.dart
- in_words.dart
- pos_closing_db.dart
- flt.dart
- pos_ui_test.dart
- core/db/providers.dart
- item_detail.dart
- import_backup_test.dart
- totals_test.dart
- app_database.dart

## God Nodes (most connected - your core abstractions)
1. `appDatabaseProvider` - 70 edges
2. `formatsProvider` - 65 edges
3. `warehousesProvider` - 26 edges
4. `itemRowsProvider` - 23 edges
5. `AppDatabase` - 22 edges
6. `cartProvider` - 19 edges
7. `stockSettingsProvider` - 19 edges
8. `build` - 17 edges
9. `uomsProvider` - 17 edges
10. `posSettingsProvider` - 16 edges

## Surprising Connections (you probably didn't know these)
- `PosClosingDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/pos/data/pos_closing_db.dart → lib/core/db/app_database.dart
- `Backups` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/backup.dart → lib/core/db/app_database.dart
- `DataImportDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/data_import_db.dart → lib/core/db/app_database.dart
- `SetupSeed` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/seed.dart → lib/core/db/app_database.dart
- `StockLists` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/stock/data/stock_lists.dart → lib/core/db/app_database.dart

## Import Cycles
- None detected.

## Communities (97 total, 4 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (75): abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, allowRateChange (+67 more)

### Community 1 - "report_table.dart"
Cohesion: 0.08
Nodes (25): _body, build, columns, createState, dispose, emptyText, _export, exportName (+17 more)

### Community 2 - "router.dart"
Cohesion: 0.09
Nodes (24): core/widgets/adaptive_shell.dart, features/pos/ui/pos_providers.dart, features/pos/ui/pos_screen.dart, features/setup/ui/setup_screen.dart, features/setup/ui/wizard_screen.dart, features/stock/ui/stock_providers.dart, features/stock/ui/stock_screen.dart, GoRouter (+16 more)

### Community 3 - "package:material_ui/material_ui.dart"
Cohesion: 0.20
Nodes (8): app.dart, compact,

  
  medium,, expanded, of, WindowSize, main, package:flutter_riverpod/flutter_riverpod.dart, package:material_ui/material_ui.dart

### Community 4 - "formats.dart"
Cohesion: 0.12
Nodes (15): CurrencyData?, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date, defaults (+7 more)

### Community 5 - "format.dart"
Cohesion: 0.08
Nodes (25): cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber (+17 more)

### Community 6 - "link_field.dart"
Cohesion: 0.20
Nodes (9): build, errorText, label, LinkField, mandatory, onChanged, onCreateNew, value (+1 more)

### Community 7 - "app_test.dart"
Cohesion: 0.11
Nodes (18): ListTile, NavigationDestination, NavigationRail, package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/providers.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart (+10 more)

### Community 8 - "batch_table.dart"
Cohesion: 0.13
Nodes (14): IntColumn get, batchId, createdAt, disabled, expiryDate, id, itemId, manufacturingDate (+6 more)

### Community 9 - "valuation.dart"
Cohesion: 0.09
Nodes (21): fifo,
  movingAverage,, _addLayer, _bySerial, _fromQueue, fromSetting, issue, method, precision (+13 more)

### Community 10 - "spacing.dart"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (14): package:flutter_test/flutter_test.dart, package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/core/numbers/format.dart, package:rx_merchant/core/numbers/in_words.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial, main (+6 more)

### Community 17 - "data_import.dart"
Cohesion: 0.04
Nodes (51): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+43 more)

### Community 18 - "settings_pages.dart"
Cohesion: 0.07
Nodes (31): Iterable, createState, dateFormats, db, doctype, _enabledPriceListsProvider, _field, FieldKind (+23 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.04
Nodes (47): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+39 more)

### Community 20 - "totals.dart"
Cohesion: 0.04
Nodes (56): double get, addToLastRow, amount, c, _Calc, computeTotals, disableRoundedTotal, discount (+48 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.09
Nodes (23): CurrencyCompanion?, FormState, _choice, createState, CurrencyPage, db, dispose, _edit (+15 more)

### Community 22 - "country_info.dart"
Cohesion: 0.11
Nodes (18): dart:convert, bytes, code, CountryInfo, currency, currencyName, currencyPrecision, dateFormat (+10 more)

### Community 23 - "data_pages.dart"
Cohesion: 0.06
Nodes (34): ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, _body, _busy, _chooseFile, copy (+26 more)

### Community 24 - "setup_queries.dart"
Cohesion: 0.09
Nodes (21): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, exists, highestUsedNumber, itemTaxTemplateRows (+13 more)

### Community 25 - "form_kit.dart"
Cohesion: 0.07
Nodes (29): AsyncValue, ../data/refusal.dart, GlobalKey, a, actions, attempt, build, children (+21 more)

### Community 26 - "tax_template.dart"
Cohesion: 0.09
Nodes (21): bool get, ChargeType, description, effectiveRate, included, isPreviousRow, method, of (+13 more)

### Community 27 - "wizard_screen.dart"
Cohesion: 0.05
Nodes (41): ../../../core/widgets/link_field.dart, ../../../core/widgets/list_detail_pane.dart, ../data/country_info.dart, data_pages.dart, ../data/seed.dart, build, id, page (+33 more)

### Community 28 - "naming_series_page.dart"
Cohesion: 0.10
Nodes (23): ../data/setup_queries.dart, form_kit.dart, build, createState, current, db, digits, dispose (+15 more)

### Community 29 - "item_pages.dart"
Cohesion: 0.03
Nodes (74): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, _code, _combos (+66 more)

### Community 30 - "backup.dart"
Cohesion: 0.12
Nodes (15): File, backupDirectory, Backups, checkRestorable, close, databasePath, out, restoreDatabase (+7 more)

### Community 31 - "../../../core/numbers/format.dart"
Cohesion: 0.15
Nodes (12): ../../../core/numbers/format.dart, double d when, _cell, d, DataImportDb, exportRows, _ids, ImportLogLine (+4 more)

### Community 32 - "stock_entry_page.dart"
Cohesion: 0.04
Nodes (51): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+43 more)

### Community 33 - "State"
Cohesion: 0.14
Nodes (20): ReportTable, _ReportTableState, MasterList, _MasterListState, _AttributeEditor, _AttributeEditorState, _BarcodeEditor, _BarcodeEditorState (+12 more)

### Community 34 - "ConsumerState"
Cohesion: 0.09
Nodes (30): ConsumerState, ConsumerStatefulWidget, _ClosingPageState, BackupsPage, _BackupsPageState, _backupsProvider, build, DataImportPage (+22 more)

### Community 35 - "sale.dart"
Cohesion: 0.05
Nodes (36): additionalDiscountPercentage, addToSale, batchNo, dirty, discountAmount, discountOnNetTotal, discountPercentage, entries (+28 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.15
Nodes (13): _Labelled, NumberPad, TotalRow, _RecordTypePicker, FieldGrid, FormPage, LockNote, SectionHeading (+5 more)

### Community 37 - "setup_db_test.dart"
Cohesion: 0.15
Nodes (12): Exception, RefusedAll, RefusedException, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/seed.dart, package:rx_merchant/features/setup/data/setup_queries.dart, completeSetup, db (+4 more)

### Community 38 - "package:drift/drift.dart"
Cohesion: 0.33
Nodes (5): package:drift/drift.dart, db, main, namesOf, specTables

### Community 39 - "AppDatabase"
Cohesion: 0.10
Nodes (20): _, @DriftDatabase, ../db/app_database.dart, AppDatabase, SinglesAccess, counter, DefaultSeries, NamingSeries (+12 more)

### Community 40 - "stock_masters_pages.dart"
Cohesion: 0.04
Nodes (47): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchId (+39 more)

### Community 41 - "../../../core/db/app_database.dart"
Cohesion: 0.22
Nodes (8): ../../../core/db/app_database.dart, ../../../core/db/singles.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, SetupSeed, _wholeNumberUoms

### Community 42 - "stock_reconciliation_page.dart"
Cohesion: 0.05
Nodes (39): ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty, _currentRate (+31 more)

### Community 43 - "appDatabaseProvider"
Cohesion: 0.15
Nodes (32): AsyncNotifier, appDatabaseProvider, CartNotifier, PriceListPage, priceListsProvider, _inventory, _load, _save (+24 more)

### Community 44 - "stock_logic_test.dart"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, package:rx_merchant/features/stock/logic/serials.dart, package:rx_merchant/features/stock/logic/stock_rules.dart, package:rx_merchant/features/stock/logic/valuation.dart, package:rx_merchant/features/stock/logic/variants.dart, item, kinds (+7 more)

### Community 45 - "serial_batch_editor.dart"
Cohesion: 0.07
Nodes (29): _add, _batch, build, _changed, createState, _csvHeader, dispose, _edit (+21 more)

### Community 46 - "stock_documents.dart"
Cohesion: 0.06
Nodes (32): allowZero, basicRate, batchNo, currentQty, currentRate, entries, EntryLine, factor (+24 more)

### Community 47 - "formatsProvider"
Cohesion: 0.14
Nodes (22): formatsProvider, storeCurrencyProvider, totalsRows, build, _OpeningFormState, build, OrderSummary, cancellableClosingProvider (+14 more)

### Community 48 - "barcode.dart"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "stock_db_test.dart"
Cohesion: 0.07
Nodes (26): int? to,
  List, ItemTables, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart, package:rx_merchant/features/stock/data/stock_reports.dart, allowNegative, batch, binOf (+18 more)

### Community 50 - "report_pages.dart"
Cohesion: 0.07
Nodes (28): ../../../core/widgets/date_field.dart, ../../../core/widgets/report_table.dart, ../data/stock_ledger.dart, Future, _Col, createState, _date, _f (+20 more)

### Community 51 - "tree_masters.dart"
Cohesion: 0.07
Nodes (29): ../data/stock_masters.dart, ItemGroupData?, all, createState, _disabled, dispose, _flat, _formKey (+21 more)

### Community 52 - "stock_entry_db.dart"
Cohesion: 0.07
Nodes (27): amendedName, amendStockEntry, availableEntries, cancelStockEntry, _checkEntries, _clearLines, createBatch, currencyPrecision (+19 more)

### Community 53 - "stock_masters.dart"
Cohesion: 0.08
Nodes (24): _checkBarcodes, _checkDefaultWarehouse, _checkItemChange, createVariants, _defaultWarehouseName, deleteWarehouse, hasLedger, itemTaxTemplateOf (+16 more)

### Community 54 - "stock_reports.dart"
Cohesion: 0.04
Nodes (41): batchBalanceReport, batchId, from, itemGroupId, itemId, itemPriceStockReport, _lowStock, lowStockReport (+33 more)

### Community 55 - "stock_providers.dart"
Cohesion: 0.09
Nodes (21): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, _Strip, b, db, i (+13 more)

### Community 56 - "stock_rules.dart"
Cohesion: 0.06
Nodes (29): all, args, detail, _foreignKey, _primaryKey, reason, Refusal, toString (+21 more)

### Community 57 - "stock_ledger.dart"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "build"
Cohesion: 0.25
Nodes (17): itemTaxTemplatesProvider, build, _details, _ItemFormState, ItemPage, build, ItemPricePage, _itemPricesProvider (+9 more)

### Community 59 - "../../../core/widgets/spacing.dart"
Cohesion: 0.13
Nodes (16): ../../../core/widgets/spacing.dart, core/widgets/window_size.dart, ../data/pos_closing_db.dart, ../data/pos_db.dart, _amounts, createState, OpeningForm, createState (+8 more)

### Community 60 - "stock_screen.dart"
Cohesion: 0.13
Nodes (14): item_pages.dart, id, page, path, query, selected, stockPage, stockPath (+6 more)

### Community 61 - "stock_reconciliation_db.dart"
Cohesion: 0.14
Nodes (13): amendStockReconciliation, cancelStockReconciliation, fetchItems, fillCurrent, reconciliationLines, saveStockReconciliation, stockReconciliationType, submitStockReconciliation (+5 more)

### Community 62 - "typedef"
Cohesion: 0.13
Nodes (14): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+6 more)

### Community 63 - "status_chip_test.dart"
Cohesion: 0.15
Nodes (11): Chip, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/status_chip.dart, package:rx_merchant/l10n/app_localizations.dart, pumpAndSettle, pumpInApp, pumpWidget, width (+3 more)

### Community 64 - "stock_ui_test.dart"
Cohesion: 0.17
Nodes (11): ../data/stock_db_test.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock, pumpWidget (+3 more)

### Community 65 - "ValueChanged"
Cohesion: 0.15
Nodes (12): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+4 more)

### Community 66 - "scan.dart"
Cohesion: 0.20
Nodes (10): ../../../core/widgets/child_table.dart, build, createState, _done, onScanned, scanBarcode, ScanButton, _ScanSheet (+2 more)

### Community 67 - "pos_db.dart"
Cohesion: 0.06
Nodes (31): ../../../core/numbers/in_words.dart, _batchIdOf, _checkSaleEntries, _clearChildren, deleteSale, _deliverSerials, _entriesOf, formats (+23 more)

### Community 68 - "providers.dart"
Cohesion: 0.25
Nodes (7): app_database.dart, code, db, SystemSettings, Formats, ../numbers/formats.dart, singles.dart

### Community 69 - "return"
Cohesion: 0.22
Nodes (8): ../../../core/numbers/flt.dart, AttributeValue, combinations, numericValues, plainNumber, r, variantCode, return

### Community 70 - "List"
Cohesion: 0.18
Nodes (10): build, ChildTable, _edit, leading, readOnly, rows, _sideSheetRadius, _sideSheetWidth (+2 more)

### Community 71 - "ConsumerWidget"
Cohesion: 0.09
Nodes (27): ConsumerWidget, singleProvider, _ModeRow, build, _ItemCard, _ItemTile, build, countryInfoProvider (+19 more)

### Community 72 - "package:go_router/go_router.dart"
Cohesion: 0.25
Nodes (7): AdaptiveShell, build, _go, navigationShell, stockBadge, package:go_router/go_router.dart, StatefulNavigationShell

### Community 73 - "list_detail_pane.dart"
Cohesion: 0.25
Nodes (7): build, detail, list, ListDetailPane, _listWidth, Widget?, window_size.dart

### Community 74 - "serials.dart"
Cohesion: 0.29
Nodes (6): from, m, prefix, serialRange, to, width

### Community 75 - "l10n/app_localizations.dart"
Cohesion: 0.40
Nodes (4): l10n/app_localizations.dart, build, status, StatusChip

### Community 76 - "pos_providers.dart"
Cohesion: 0.08
Nodes (25): AppDatabase get, PosSettings, SellingSettings, add, build, changed, _db, list (+17 more)

### Community 77 - "Batches"
Cohesion: 0.67
Nodes (3): @DataClassName, Batches, Table

### Community 78 - "cartProvider"
Cohesion: 0.14
Nodes (26): build, CartPanel, _LinePad, _LinePadState, build, ItemDetail, _changed, _ItemSelectorState (+18 more)

### Community 81 - "pos_screen.dart"
Cohesion: 0.08
Nodes (24): closing_page.dart, item_detail.dart, item_selector.dart, Submitted, _cartOpen, _checkout, _compact, createState (+16 more)

### Community 82 - "pos_widgets.dart"
Cohesion: 0.09
Nodes (23): ../../../core/numbers/formats.dart, build, createState, didUpdateWidget, dispose, enabled, _error, _focus (+15 more)

### Community 83 - "pos_db_test.dart"
Cohesion: 0.09
Nodes (21): Map, package:rx_merchant/features/pos/data/pos_closing_db.dart, package:rx_merchant/features/pos/data/pos_db.dart, package:rx_merchant/features/pos/logic/sale.dart, package:rx_merchant/features/stock/data/stock_entry_db.dart, package:rx_merchant/features/stock/logic/stock_documents.dart, cart, db (+13 more)

### Community 84 - "payment_panel.dart"
Cohesion: 0.10
Nodes (20): cart_panel.dart, ../../../core/widgets/status_chip.dart, _int, Sale, name, onNewOrder, sale, createState (+12 more)

### Community 85 - "item_selector.dart"
Cohesion: 0.11
Nodes (18): dart:async, RegisterItem, _add, _autoAdd, _clear, createState, _descendants, dispose (+10 more)

### Community 86 - "cart_panel.dart"
Cohesion: 0.11
Nodes (18): byPercent, createState, didUpdateWidget, _discountDialog, _field, formats, _key, l (+10 more)

### Community 87 - "closing_page.dart"
Cohesion: 0.13
Nodes (14): Color, build, ClosingPage, compact, _counted, createState, _draft, errorColor (+6 more)

### Community 88 - "in_words.dart"
Cohesion: 0.13
Nodes (14): _below1000, cents, groups, hundreds, moneyInWords, _ones, out, parts (+6 more)

### Community 89 - "pos_closing_db.dart"
Cohesion: 0.17
Nodes (11): ../../../core/naming/naming_series.dart, cancellableClosing, cancelLastClosing, ClosingDraft, _heldOrders, PosClosingDb, posClosingType, ReconciliationRow (+3 more)

### Community 90 - "flt.dart"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

### Community 91 - "pos_ui_test.dart"
Cohesion: 0.17
Nodes (11): package:rx_merchant/features/stock/data/stock_masters.dart, ../../stock/data/stock_db_test.dart, db, height, main, pumpPos, pumpWidget, runAsync (+3 more)

### Community 92 - "core/db/providers.dart"
Cohesion: 0.20
Nodes (9): core/db/providers.dart, AppTheme, dark, _from, light, _seed, router.dart, static const (+1 more)

### Community 93 - "item_detail.dart"
Cohesion: 0.20
Nodes (9): SaleLine, line, onClose, pos_widgets.dart, ../../stock/data/stock_entry_db.dart, ../../stock/logic/stock_documents.dart, ../../stock/logic/stock_rules.dart, ../../stock/ui/serial_batch_editor.dart (+1 more)

### Community 94 - "import_backup_test.dart"
Cohesion: 0.25
Nodes (7): dart:io, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/data_import_db.dart, package:rx_merchant/features/setup/data/refusal.dart, package:sqlite3/sqlite3.dart, setup_db_test.dart, main

### Community 95 - "totals_test.dart"
Cohesion: 0.25
Nodes (7): package:rx_merchant/features/pos/logic/totals.dart, calc, levy, line, main, onNet, vat

### Community 96 - "app_database.dart"
Cohesion: 0.29
Nodes (6): ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, MigrationStrategy get, package:drift_flutter/drift_flutter.dart

## Knowledge Gaps
- **1342 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+1337 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1481 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_int` connect `payment_panel.dart` to `singles.dart`, `stock_entry_page.dart`, `sale.dart`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `stock_documents.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `report_pages.dart`, `item_selector.dart`, `stock_reports.dart`, `tree_masters.dart`, `tax_template.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `Formats` connect `providers.dart` to `stock_entry_page.dart`, `ValueChanged`, `formats.dart`, `serial_batch_editor.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `appDatabaseProvider` connect `appDatabaseProvider` to `stock_entry_page.dart`, `ConsumerState`, `providers.dart`, `ConsumerWidget`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `cartProvider`, `formatsProvider`, `settings_pages.dart`, `tax_template_pages.dart`, `data_pages.dart`, `build`, `../../../core/widgets/spacing.dart`, `naming_series_page.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _1342 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._
# Graph Report - rx_merchant  (2026-11-18)

## Corpus Check
- 115 files · ~86,153 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2230 nodes · 3624 edges · 104 communities (94 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `861d78d0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- singles.dart
- report_table.dart
- router.dart
- window_size.dart
- formats.dart
- format.dart
- package:material_ui/material_ui.dart
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
- dashboard_db_test.dart
- typedef
- stock_entry_page.dart
- State
- ConsumerState
- sale.dart
- StatelessWidget
- setup_db_test.dart
- sales_report_pages.dart
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
- recent_orders.dart
- stock_screen.dart
- stock_reconciliation_db.dart
- stock_lists.dart
- status_chip_test.dart
- stock_ui_test.dart
- ValueChanged
- dashboard_screen.dart
- pos_db.dart
- providers.dart
- return
- List
- build
- package:go_router/go_router.dart
- list_detail_pane.dart
- serials.dart
- dashboard_charts.dart
- pos_providers.dart
- Batches
- periods.dart
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
- dashboard_providers.dart
- flt.dart
- pos_ui_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- sales_reports.dart
- setup_screen.dart
- dashboard_db.dart
- package:drift/drift.dart
- dashboard_ui_test.dart
- itemRowsProvider
- refusal.dart
- periods_test.dart
- dashboardProvider
- _ItemTaxRowEditor
- SalesTaxesTemplatePage

## God Nodes (most connected - your core abstractions)
1. `formatsProvider` - 76 edges
2. `appDatabaseProvider` - 72 edges
3. `warehousesProvider` - 26 edges
4. `itemRowsProvider` - 25 edges
5. `AppDatabase` - 24 edges
6. `cartProvider` - 19 edges
7. `stockSettingsProvider` - 19 edges
8. `build` - 17 edges
9. `itemGroupsProvider` - 17 edges
10. `uomsProvider` - 17 edges

## Surprising Connections (you probably didn't know these)
- `DashboardDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/dashboard/data/dashboard_db.dart → lib/core/db/app_database.dart
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

## Communities (104 total, 7 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (75): abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, allowRateChange (+67 more)

### Community 1 - "report_table.dart"
Cohesion: 0.07
Nodes (29): child_table.dart, _body, build, columns, createState, dispose, emptyText, _export (+21 more)

### Community 2 - "router.dart"
Cohesion: 0.08
Nodes (27): core/widgets/adaptive_shell.dart, features/dashboard/ui/dashboard_providers.dart, features/dashboard/ui/dashboard_screen.dart, features/dashboard/ui/sales_report_pages.dart, features/pos/ui/pos_providers.dart, features/pos/ui/pos_screen.dart, features/setup/ui/setup_screen.dart, features/setup/ui/wizard_screen.dart (+19 more)

### Community 3 - "window_size.dart"
Cohesion: 0.40
Nodes (4): compact,

  
  medium,, expanded, of, WindowSize

### Community 4 - "formats.dart"
Cohesion: 0.12
Nodes (15): CurrencyData?, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date, defaults (+7 more)

### Community 5 - "format.dart"
Cohesion: 0.05
Nodes (40): File, cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate (+32 more)

### Community 6 - "package:material_ui/material_ui.dart"
Cohesion: 0.09
Nodes (20): ../../../core/widgets/child_table.dart, l10n/app_localizations.dart, build, errorText, label, LinkField, mandatory, onChanged (+12 more)

### Community 7 - "app_test.dart"
Cohesion: 0.17
Nodes (11): ListTile, NavigationDestination, NavigationRail, package:rx_merchant/core/db/providers.dart, required double width,
  bool, db, main, pumpAndSettle (+3 more)

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
Cohesion: 0.09
Nodes (19): package:flutter_test/flutter_test.dart, package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/core/numbers/in_words.dart, package:rx_merchant/features/pos/logic/totals.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial, main (+11 more)

### Community 17 - "data_import.dart"
Cohesion: 0.04
Nodes (51): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+43 more)

### Community 18 - "settings_pages.dart"
Cohesion: 0.07
Nodes (31): Iterable, createState, dateFormats, db, doctype, _enabledPriceListsProvider, _field, FieldKind (+23 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.05
Nodes (41): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+33 more)

### Community 20 - "totals.dart"
Cohesion: 0.04
Nodes (56): double get, addToLastRow, amount, c, _Calc, computeTotals, disableRoundedTotal, discount (+48 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.08
Nodes (25): CurrencyCompanion?, ../data/setup_queries.dart, form_kit.dart, FormState, _choice, createState, CurrencyPage, db (+17 more)

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
Cohesion: 0.08
Nodes (24): ../../../core/widgets/link_field.dart, ../data/country_info.dart, _abbr, _abbrEdited, build, _busy, _canGoOn, _country (+16 more)

### Community 28 - "naming_series_page.dart"
Cohesion: 0.11
Nodes (22): ../data/seed.dart, build, createState, current, db, digits, dispose, _doctype (+14 more)

### Community 29 - "item_pages.dart"
Cohesion: 0.03
Nodes (74): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, _code, _combos (+66 more)

### Community 30 - "dashboard_db_test.dart"
Cohesion: 0.07
Nodes (27): await, package:rx_merchant/core/numbers/format.dart, package:rx_merchant/features/dashboard/data/dashboard_db.dart, package:rx_merchant/features/dashboard/data/sales_reports.dart, main, a, b, cancel (+19 more)

### Community 31 - "typedef"
Cohesion: 0.14
Nodes (13): ../../../core/numbers/format.dart, double d when, _cell, d, DataImportDb, exportRows, _ids, ImportLogLine (+5 more)

### Community 32 - "stock_entry_page.dart"
Cohesion: 0.04
Nodes (51): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+43 more)

### Community 33 - "State"
Cohesion: 0.13
Nodes (22): LiveNumberField, _LiveNumberFieldState, MasterList, _MasterListState, _TaxRowEditor, _TaxRowEditorState, _AttributeEditor, _AttributeEditorState (+14 more)

### Community 34 - "ConsumerState"
Cohesion: 0.08
Nodes (35): ConsumerState, ConsumerStatefulWidget, _ClosingPageState, BackupsPage, _BackupsPageState, _backupsProvider, build, DataImportPage (+27 more)

### Community 35 - "sale.dart"
Cohesion: 0.05
Nodes (36): additionalDiscountPercentage, addToSale, batchNo, dirty, discountAmount, discountOnNetTotal, discountPercentage, entries (+28 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.12
Nodes (17): ReportFilters, StatusChip, ChartCard, _FirstSale, _Labelled, NumberPad, TotalRow, _RecordTypePicker (+9 more)

### Community 37 - "setup_db_test.dart"
Cohesion: 0.09
Nodes (23): dart:io, package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/data_import_db.dart (+15 more)

### Community 38 - "sales_report_pages.dart"
Cohesion: 0.08
Nodes (25): ../../../core/widgets/date_field.dart, ../../../core/widgets/report_table.dart, ../data/sales_reports.dart, Future, _changed, _chart, _Col, createState (+17 more)

### Community 39 - "AppDatabase"
Cohesion: 0.09
Nodes (22): _, @DriftDatabase, ../db/app_database.dart, AppDatabase, SinglesAccess, counter, DefaultSeries, NamingSeries (+14 more)

### Community 40 - "stock_masters_pages.dart"
Cohesion: 0.04
Nodes (47): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchId (+39 more)

### Community 41 - "../../../core/db/app_database.dart"
Cohesion: 0.25
Nodes (7): ../../../core/db/app_database.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, SetupSeed, _wholeNumberUoms

### Community 42 - "stock_reconciliation_page.dart"
Cohesion: 0.05
Nodes (39): ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty, _currentRate (+31 more)

### Community 43 - "appDatabaseProvider"
Cohesion: 0.16
Nodes (28): AsyncNotifier, appDatabaseProvider, firstDayOfWeekProvider, _load, _SalesReportPageState, build, ItemDetail, _ItemSelectorState (+20 more)

### Community 44 - "stock_logic_test.dart"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, package:rx_merchant/features/stock/logic/serials.dart, package:rx_merchant/features/stock/logic/stock_rules.dart, package:rx_merchant/features/stock/logic/valuation.dart, package:rx_merchant/features/stock/logic/variants.dart, item, kinds (+7 more)

### Community 45 - "serial_batch_editor.dart"
Cohesion: 0.07
Nodes (31): _add, _batch, build, _changed, createState, _csvHeader, dispose, _edit (+23 more)

### Community 46 - "stock_documents.dart"
Cohesion: 0.06
Nodes (32): allowZero, basicRate, batchNo, currentQty, currentRate, entries, EntryLine, factor (+24 more)

### Community 47 - "formatsProvider"
Cohesion: 0.09
Nodes (40): ConsumerWidget, formatsProvider, storeCurrencyProvider, BarsChart, LinesChart, _GoalCard, _NumberCard, _PeriodBar (+32 more)

### Community 48 - "barcode.dart"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "stock_db_test.dart"
Cohesion: 0.07
Nodes (26): int? to,
  List, ItemTables, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart, package:rx_merchant/features/stock/data/stock_reports.dart, allowNegative, batch, binOf (+18 more)

### Community 50 - "report_pages.dart"
Cohesion: 0.07
Nodes (26): ../data/stock_ledger.dart, _Col, createState, _date, _f, _Filter, _filters, _format (+18 more)

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
Cohesion: 0.11
Nodes (17): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, b, db, i, it (+9 more)

### Community 56 - "stock_rules.dart"
Cohesion: 0.11
Nodes (18): base, BatchStatus, best, defaultExpiry, given, isWhole, itemTaxTemplateFor, left (+10 more)

### Community 57 - "stock_ledger.dart"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "build"
Cohesion: 0.17
Nodes (22): ItemTaxTemplatePage, itemTaxTemplatesProvider, build, _details, _ItemFormState, ItemPage, _Tax, BrandPage (+14 more)

### Community 59 - "recent_orders.dart"
Cohesion: 0.20
Nodes (9): ../data/pos_db.dart, createState, _delete, _keep, onEdit, _query, RecentOrders, _status (+1 more)

### Community 60 - "stock_screen.dart"
Cohesion: 0.12
Nodes (15): item_pages.dart, id, page, path, query, selected, stockPage, stockPath (+7 more)

### Community 61 - "stock_reconciliation_db.dart"
Cohesion: 0.08
Nodes (25): ../../../core/naming/naming_series.dart, ../../../core/numbers/flt.dart, cancellableClosing, cancelLastClosing, changeModeOf, ClosingDraft, _heldOrders, posClosingType (+17 more)

### Community 62 - "stock_lists.dart"
Cohesion: 0.14
Nodes (13): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+5 more)

### Community 63 - "status_chip_test.dart"
Cohesion: 0.15
Nodes (11): Chip, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/status_chip.dart, package:rx_merchant/l10n/app_localizations.dart, pumpAndSettle, pumpInApp, pumpWidget, width (+3 more)

### Community 64 - "stock_ui_test.dart"
Cohesion: 0.17
Nodes (11): ../data/stock_db_test.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock, pumpWidget (+3 more)

### Community 65 - "ValueChanged"
Cohesion: 0.15
Nodes (12): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+4 more)

### Community 66 - "dashboard_screen.dart"
Cohesion: 0.08
Nodes (23): dashboard_charts.dart, dashboard_providers.dart, double?, before, _Body, createState, d, detail (+15 more)

### Community 67 - "pos_db.dart"
Cohesion: 0.06
Nodes (31): ../../../core/numbers/in_words.dart, _batchIdOf, _checkSaleEntries, _clearChildren, deleteSale, _deliverSerials, _entriesOf, formats (+23 more)

### Community 68 - "providers.dart"
Cohesion: 0.25
Nodes (7): app_database.dart, code, db, SystemSettings, Formats, ../numbers/formats.dart, singles.dart

### Community 69 - "return"
Cohesion: 0.25
Nodes (7): AttributeValue, combinations, numericValues, plainNumber, r, variantCode, return

### Community 70 - "List"
Cohesion: 0.18
Nodes (10): build, ChildTable, _edit, leading, readOnly, rows, _sideSheetRadius, _sideSheetWidth (+2 more)

### Community 71 - "build"
Cohesion: 0.19
Nodes (13): singleProvider, periodProvider, _BodyState, build, build, countryInfoProvider, GlobalDefaultsPage, StoreProfilePage (+5 more)

### Community 72 - "package:go_router/go_router.dart"
Cohesion: 0.25
Nodes (7): AdaptiveShell, build, _go, navigationShell, stockBadge, package:go_router/go_router.dart, StatefulNavigationShell

### Community 73 - "list_detail_pane.dart"
Cohesion: 0.25
Nodes (7): build, detail, list, ListDetailPane, _listWidth, Widget, window_size.dart

### Community 74 - "serials.dart"
Cohesion: 0.29
Nodes (6): from, m, prefix, serialRange, to, width

### Community 75 - "dashboard_charts.dart"
Cohesion: 0.10
Nodes (20): Color, ../../../core/numbers/formats.dart, action, _axisLabel, bars, bucketLabel, build, chart (+12 more)

### Community 76 - "pos_providers.dart"
Cohesion: 0.08
Nodes (25): AppDatabase get, PosSettings, SellingSettings, add, build, changed, _db, list (+17 more)

### Community 77 - "Batches"
Cohesion: 0.67
Nodes (3): @DataClassName, Batches, Table

### Community 78 - "periods.dart"
Cohesion: 0.10
Nodes (19): bucketsOf, dayIndex, dayOf, first, lengthOf, out, parseDay, Period (+11 more)

### Community 81 - "pos_screen.dart"
Cohesion: 0.08
Nodes (24): closing_page.dart, item_detail.dart, item_selector.dart, Submitted, _cartOpen, _checkout, _compact, createState (+16 more)

### Community 82 - "pos_widgets.dart"
Cohesion: 0.10
Nodes (20): build, createState, didUpdateWidget, dispose, enabled, _error, _focus, formats (+12 more)

### Community 83 - "pos_db_test.dart"
Cohesion: 0.08
Nodes (23): Exception, RefusedAll, RefusedException, Map, package:rx_merchant/features/pos/data/pos_closing_db.dart, package:rx_merchant/features/pos/logic/sale.dart, package:rx_merchant/features/stock/data/stock_entry_db.dart, package:rx_merchant/features/stock/logic/stock_documents.dart (+15 more)

### Community 84 - "payment_panel.dart"
Cohesion: 0.10
Nodes (20): cart_panel.dart, ../../../core/widgets/status_chip.dart, Sale, name, onNewOrder, sale, createState, defaultMode (+12 more)

### Community 85 - "item_selector.dart"
Cohesion: 0.07
Nodes (27): dart:async, RegisterItem, SaleLine, line, onClose, _add, _autoAdd, _clear (+19 more)

### Community 86 - "cart_panel.dart"
Cohesion: 0.08
Nodes (36): build, byPercent, CartPanel, createState, didUpdateWidget, _discountDialog, _field, formats (+28 more)

### Community 87 - "closing_page.dart"
Cohesion: 0.10
Nodes (20): ../../../core/widgets/spacing.dart, core/widgets/window_size.dart, ../data/pos_closing_db.dart, build, ClosingPage, compact, _counted, createState (+12 more)

### Community 88 - "in_words.dart"
Cohesion: 0.13
Nodes (14): _below1000, cents, groups, hundreds, moneyInWords, _ones, out, parts (+6 more)

### Community 89 - "dashboard_providers.dart"
Cohesion: 0.12
Nodes (17): ../../../core/db/singles.dart, ../data/dashboard_db.dart, buckets, build, choice, choose, Dashboard, dashboardPath (+9 more)

### Community 90 - "flt.dart"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

### Community 91 - "pos_ui_test.dart"
Cohesion: 0.17
Nodes (11): package:rx_merchant/features/stock/data/stock_masters.dart, ../../stock/data/stock_db_test.dart, db, height, main, pumpPos, pumpWidget, runAsync (+3 more)

### Community 92 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.14
Nodes (12): app.dart, core/db/providers.dart, AppTheme, dark, _from, light, _seed, main (+4 more)

### Community 93 - "sales_reports.dart"
Cohesion: 0.11
Nodes (17): dashboard_db.dart, _int, Analytics, byGroup, grossProfit, groupBy, itemGroupId, itemId (+9 more)

### Community 94 - "setup_screen.dart"
Cohesion: 0.12
Nodes (16): ../../../core/widgets/list_detail_pane.dart, data_pages.dart, build, id, page, path, selected, SetupHome (+8 more)

### Community 95 - "dashboard_db.dart"
Cohesion: 0.12
Nodes (16): achievement, Bar, _bars, DashboardDb, Figures, hasAnySale, monthlySales, paymentModes (+8 more)

### Community 96 - "package:drift/drift.dart"
Cohesion: 0.15
Nodes (11): ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, MigrationStrategy get, package:drift/drift.dart, package:drift_flutter/drift_flutter.dart, db (+3 more)

### Community 97 - "dashboard_ui_test.dart"
Cohesion: 0.12
Nodes (16): package:rx_merchant/features/dashboard/ui/dashboard_screen.dart, package:rx_merchant/features/dashboard/ui/sales_report_pages.dart, package:rx_merchant/features/pos/data/pos_db.dart, ../../pos/data/pos_db_test.dart, ../../pos/ui/pos_ui_test.dart, db, home, main (+8 more)

### Community 98 - "itemRowsProvider"
Cohesion: 0.18
Nodes (13): build, PriceListPage, priceListsProvider, _VariantList, _FilterBar, _batchesProvider, BatchPage, _ItemPriceForm (+5 more)

### Community 99 - "refusal.dart"
Cohesion: 0.17
Nodes (11): all, args, detail, _foreignKey, _primaryKey, reason, Refusal, toString (+3 more)

### Community 100 - "periods_test.dart"
Cohesion: 0.40
Nodes (4): package:rx_merchant/features/dashboard/logic/periods.dart, main, show, wednesday

## Knowledge Gaps
- **1485 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+1480 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1638 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_int` connect `sales_reports.dart` to `singles.dart`, `stock_entry_page.dart`, `sale.dart`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `stock_documents.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `payment_panel.dart`, `item_selector.dart`, `stock_reports.dart`, `report_pages.dart`, `tree_masters.dart`, `tax_template.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `Formats` connect `providers.dart` to `stock_entry_page.dart`, `ValueChanged`, `formats.dart`, `serial_batch_editor.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `appDatabaseProvider` connect `appDatabaseProvider` to `stock_entry_page.dart`, `ConsumerState`, `itemRowsProvider`, `providers.dart`, `build`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `formatsProvider`, `settings_pages.dart`, `tax_template_pages.dart`, `data_pages.dart`, `build`, `recent_orders.dart`, `naming_series_page.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _1485 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07936507936507936 - nodes in this community are weakly interconnected._
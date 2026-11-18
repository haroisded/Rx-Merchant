# Graph Report - rx_merchant  (2026-11-18)

## Corpus Check
- 135 files · ~102,523 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2620 nodes · 4280 edges · 125 communities (116 shown, 6 thin omitted)
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
- invoice.dart
- formats.dart
- format.dart
- VoidCallback?
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
- data_import_db.dart
- stock_entry_page.dart
- State
- ConsumerState
- sale.dart
- StatelessWidget
- setup_db_test.dart
- sales_report_pages.dart
- AppDatabase
- stock_masters_pages.dart
- ../../../core/db/singles.dart
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
- printing_pages.dart
- ../../../core/widgets/spacing.dart
- stock_screen.dart
- stock_reconciliation_db.dart
- stock_lists.dart
- package:material_ui/material_ui.dart
- stock_ui_test.dart
- ValueChanged
- dashboard_screen.dart
- pos_db.dart
- _return
- typedef
- List
- singleProvider
- l10n/app_localizations.dart
- list_detail_pane.dart
- serials.dart
- dashboard_charts.dart
- pos_providers.dart
- print_layout.dart
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
- app_database.dart
- dashboard_ui_test.dart
- cartProvider
- refusal.dart
- print_page.dart
- invoices_db_test.dart
- _ItemTaxRowEditor
- SalesTaxesTemplatePage
- invoices_screen.dart
- invoice_pdf.dart
- return_form.dart
- item_detail.dart
- invoice_db.dart
- receipt_text.dart
- invoice_detail.dart
- backup.dart
- returns_db.dart
- returns.dart
- pos_closing_db.dart
- _PrintPageState
- scan.dart
- print_layout_test.dart
- ../../../core/numbers/format.dart
- invoice_pdf_test.dart
- String?
- package:drift/drift.dart
- ../../../core/db/app_database.dart
- systemSettingsProvider
- _TaxRowEditor

## God Nodes (most connected - your core abstractions)
1. `formatsProvider` - 90 edges
2. `appDatabaseProvider` - 82 edges
3. `warehousesProvider` - 28 edges
4. `AppDatabase` - 27 edges
5. `_return` - 25 edges
6. `itemRowsProvider` - 25 edges
7. `posSettingsProvider` - 20 edges
8. `cartProvider` - 20 edges
9. `_int` - 19 edges
10. `stockSettingsProvider` - 19 edges

## Surprising Connections (you probably didn't know these)
- `DefaultSeries` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/naming/naming_series.dart → lib/core/db/app_database.dart
- `NamingSeries` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/naming/naming_series.dart → lib/core/db/app_database.dart
- `DashboardDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/dashboard/data/dashboard_db.dart → lib/core/db/app_database.dart
- `PrintMasters` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/invoices/data/print_masters.dart → lib/core/db/app_database.dart
- `PosClosingDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/pos/data/pos_closing_db.dart → lib/core/db/app_database.dart

## Import Cycles
- None detected.

## Communities (125 total, 6 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (75): abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, allowRateChange (+67 more)

### Community 1 - "report_table.dart"
Cohesion: 0.07
Nodes (29): child_table.dart, _body, build, columns, createState, dispose, emptyText, _export (+21 more)

### Community 2 - "router.dart"
Cohesion: 0.10
Nodes (20): core/widgets/adaptive_shell.dart, features/dashboard/ui/dashboard_providers.dart, features/dashboard/ui/dashboard_screen.dart, features/dashboard/ui/sales_report_pages.dart, features/invoices/ui/invoice_providers.dart, features/invoices/ui/invoices_screen.dart, features/pos/ui/pos_providers.dart, features/pos/ui/pos_screen.dart (+12 more)

### Community 3 - "invoice.dart"
Cohesion: 0.04
Nodes (46): DateTime, against, amount, batches, changeAmount, description, discountAmount, discountPercentage (+38 more)

### Community 4 - "formats.dart"
Cohesion: 0.12
Nodes (16): CurrencyData?, ../db/app_database.dart, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date (+8 more)

### Community 5 - "format.dart"
Cohesion: 0.08
Nodes (25): cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber (+17 more)

### Community 6 - "VoidCallback?"
Cohesion: 0.20
Nodes (9): build, errorText, label, LinkField, mandatory, onChanged, onCreateNew, value (+1 more)

### Community 7 - "app_test.dart"
Cohesion: 0.17
Nodes (11): ListTile, NavigationDestination, NavigationRail, package:rx_merchant/core/db/providers.dart, required double width,
  bool, db, main, pumpAndSettle (+3 more)

### Community 8 - "batch_table.dart"
Cohesion: 0.11
Nodes (17): @DataClassName, IntColumn get, Batches, batchId, createdAt, disabled, expiryDate, id (+9 more)

### Community 9 - "valuation.dart"
Cohesion: 0.09
Nodes (21): fifo,
  movingAverage,, _addLayer, _bySerial, _fromQueue, fromSetting, issue, method, precision (+13 more)

### Community 10 - "spacing.dart"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (18): package:flutter_test/flutter_test.dart, package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/core/numbers/format.dart, package:rx_merchant/core/numbers/in_words.dart, package:rx_merchant/features/dashboard/logic/periods.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial (+10 more)

### Community 12 - "MainActivity.kt"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterActivity, FlutterEngine

### Community 17 - "data_import.dart"
Cohesion: 0.04
Nodes (51): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+43 more)

### Community 18 - "settings_pages.dart"
Cohesion: 0.07
Nodes (38): Iterable, build, countryInfoProvider, createState, dateFormats, db, doctype, _enabledPriceListsProvider (+30 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.05
Nodes (41): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+33 more)

### Community 20 - "totals.dart"
Cohesion: 0.04
Nodes (56): double get, addToLastRow, amount, c, _Calc, computeTotals, disableRoundedTotal, discount (+48 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.09
Nodes (23): CurrencyCompanion?, FormState, _choice, createState, CurrencyPage, db, dispose, _edit (+15 more)

### Community 22 - "country_info.dart"
Cohesion: 0.05
Nodes (41): dart:convert, _align, _ascii, _bold, cut, drawer, escCut, escDrawer (+33 more)

### Community 23 - "data_pages.dart"
Cohesion: 0.06
Nodes (34): ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, _body, _busy, _chooseFile, copy (+26 more)

### Community 24 - "setup_queries.dart"
Cohesion: 0.10
Nodes (20): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, exists, highestUsedNumber, itemTaxTemplateRows (+12 more)

### Community 25 - "form_kit.dart"
Cohesion: 0.06
Nodes (31): AsyncValue, ../data/refusal.dart, GlobalKey, a, actions, attempt, build, children (+23 more)

### Community 26 - "tax_template.dart"
Cohesion: 0.10
Nodes (19): ChargeType, description, effectiveRate, included, isPreviousRow, method, of, out (+11 more)

### Community 27 - "wizard_screen.dart"
Cohesion: 0.08
Nodes (24): ../../../core/widgets/link_field.dart, ../data/country_info.dart, _abbr, _abbrEdited, build, _busy, _canGoOn, _country (+16 more)

### Community 28 - "naming_series_page.dart"
Cohesion: 0.10
Nodes (24): ../data/seed.dart, ../data/setup_queries.dart, form_kit.dart, build, createState, current, db, digits (+16 more)

### Community 29 - "item_pages.dart"
Cohesion: 0.03
Nodes (72): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, _code, _combos (+64 more)

### Community 30 - "dashboard_db_test.dart"
Cohesion: 0.08
Nodes (24): await, package:rx_merchant/features/dashboard/data/sales_reports.dart, a, b, cancel, day1, day2, days (+16 more)

### Community 31 - "data_import_db.dart"
Cohesion: 0.17
Nodes (11): double d when, _cell, d, DataImportDb, exportRows, _ids, ImportLogLine, importLookups (+3 more)

### Community 32 - "stock_entry_page.dart"
Cohesion: 0.04
Nodes (51): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+43 more)

### Community 33 - "State"
Cohesion: 0.16
Nodes (18): _AttributeEditor, _AttributeEditorState, _BarcodeEditor, _BarcodeEditorState, _ReorderEditor, _ReorderEditorState, _TaxEditor, _TaxEditorState (+10 more)

### Community 34 - "ConsumerState"
Cohesion: 0.07
Nodes (35): ConsumerState, ConsumerStatefulWidget, firstDayOfWeekProvider, _load, _SalesReportPageState, _LetterHeadForm, _LetterHeadFormState, _TermsForm (+27 more)

### Community 35 - "sale.dart"
Cohesion: 0.05
Nodes (40): additionalDiscountPercentage, addToSale, againstLineId, batchNo, dirty, discountAmount, discountOnNetTotal, discountPercentage (+32 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.12
Nodes (16): ReportFilters, ChartCard, _FirstSale, InvoicesScreen, _Labelled, NumberPad, TotalRow, _RecordTypePicker (+8 more)

### Community 37 - "setup_db_test.dart"
Cohesion: 0.08
Nodes (26): package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/data_import_db.dart, package:rx_merchant/features/setup/data/refusal.dart (+18 more)

### Community 38 - "sales_report_pages.dart"
Cohesion: 0.08
Nodes (25): ../../../core/widgets/date_field.dart, ../../../core/widgets/report_table.dart, ../data/sales_reports.dart, Future, _changed, _chart, _Col, createState (+17 more)

### Community 39 - "AppDatabase"
Cohesion: 0.14
Nodes (14): _, @DriftDatabase, AppDatabase, SinglesAccess, SalesReports, InvoiceDb, ReturnsDb, PosDb (+6 more)

### Community 40 - "stock_masters_pages.dart"
Cohesion: 0.04
Nodes (46): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchId (+38 more)

### Community 41 - "../../../core/db/singles.dart"
Cohesion: 0.25
Nodes (7): ../../../core/db/singles.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, SetupSeed, _wholeNumberUoms

### Community 42 - "stock_reconciliation_page.dart"
Cohesion: 0.05
Nodes (39): ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty, _currentRate (+31 more)

### Community 43 - "appDatabaseProvider"
Cohesion: 0.11
Nodes (47): AsyncNotifier, appDatabaseProvider, build, ItemDetail, CartNotifier, sellingSettingsProvider, PriceListPage, priceListsProvider (+39 more)

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
Cohesion: 0.10
Nodes (32): ConsumerWidget, formatsProvider, storeCurrencyProvider, BarsChart, LinesChart, _GoalCard, _NumberCard, _PeriodBar (+24 more)

### Community 48 - "barcode.dart"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "stock_db_test.dart"
Cohesion: 0.07
Nodes (26): int? to,
  List, ItemTables, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart, package:rx_merchant/features/stock/data/stock_reports.dart, allowNegative, batch, binOf (+18 more)

### Community 50 - "report_pages.dart"
Cohesion: 0.07
Nodes (27): ../data/stock_ledger.dart, _Col, createState, _date, _f, _Filter, _filters, _format (+19 more)

### Community 51 - "tree_masters.dart"
Cohesion: 0.07
Nodes (28): ../data/stock_masters.dart, ItemGroupData?, all, createState, _disabled, dispose, _flat, _formKey (+20 more)

### Community 52 - "stock_entry_db.dart"
Cohesion: 0.07
Nodes (27): amendedName, amendStockEntry, availableEntries, cancelStockEntry, _checkEntries, _clearLines, createBatch, currencyPrecision (+19 more)

### Community 53 - "stock_masters.dart"
Cohesion: 0.08
Nodes (24): _checkBarcodes, _checkDefaultWarehouse, _checkItemChange, createVariants, _defaultWarehouseName, deleteWarehouse, hasLedger, itemTaxTemplateOf (+16 more)

### Community 54 - "stock_reports.dart"
Cohesion: 0.09
Nodes (22): batchBalanceReport, batchId, from, itemGroupId, itemId, itemPriceStockReport, _lowStock, lowStockReport (+14 more)

### Community 55 - "stock_providers.dart"
Cohesion: 0.07
Nodes (36): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, build, build, _shown, ItemTaxTemplatePage (+28 more)

### Community 56 - "stock_rules.dart"
Cohesion: 0.11
Nodes (18): base, BatchStatus, best, defaultExpiry, given, isWhole, itemTaxTemplateFor, left (+10 more)

### Community 57 - "stock_ledger.dart"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "printing_pages.dart"
Cohesion: 0.06
Nodes (34): ../data/print_masters.dart, LetterHeadData?, createState, db, _default, _disabled, dispose, _footer (+26 more)

### Community 59 - "../../../core/widgets/spacing.dart"
Cohesion: 0.18
Nodes (10): ../../../core/widgets/spacing.dart, ../../invoices/ui/invoice_providers.dart, ../../invoices/ui/invoices_screen.dart, createState, _keep, onEdit, _query, RecentOrders (+2 more)

### Community 60 - "stock_screen.dart"
Cohesion: 0.12
Nodes (15): item_pages.dart, id, page, path, query, selected, stockPage, stockPath (+7 more)

### Community 61 - "stock_reconciliation_db.dart"
Cohesion: 0.14
Nodes (13): amendStockReconciliation, cancelStockReconciliation, fetchItems, fillCurrent, reconciliationLines, saveStockReconciliation, StockReconciliationDb, stockReconciliationType (+5 more)

### Community 62 - "stock_lists.dart"
Cohesion: 0.14
Nodes (13): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+5 more)

### Community 63 - "package:material_ui/material_ui.dart"
Cohesion: 0.07
Nodes (26): Chip, compact,

  
  medium,, expanded, of, WindowSize, package:material_ui/material_ui.dart, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/child_table.dart (+18 more)

### Community 64 - "stock_ui_test.dart"
Cohesion: 0.17
Nodes (11): ../data/stock_db_test.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock, pumpWidget (+3 more)

### Community 65 - "ValueChanged"
Cohesion: 0.15
Nodes (12): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+4 more)

### Community 66 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (22): dashboard_charts.dart, dashboard_providers.dart, double?, before, _Body, createState, d, detail (+14 more)

### Community 67 - "pos_db.dart"
Cohesion: 0.06
Nodes (31): ../../../core/numbers/in_words.dart, _batchIdOf, _checkSaleEntries, _clearChildren, deleteSale, deliverSerials, _entriesOf, formats (+23 more)

### Community 68 - "_return"
Cohesion: 0.22
Nodes (8): app_database.dart, code, db, SystemSettings, Formats, _return, ../numbers/formats.dart, singles.dart

### Community 69 - "typedef"
Cohesion: 0.22
Nodes (8): ../../../core/numbers/flt.dart, AttributeValue, combinations, numericValues, plainNumber, r, variantCode, typedef

### Community 70 - "List"
Cohesion: 0.18
Nodes (10): build, ChildTable, _edit, leading, readOnly, rows, _sideSheetRadius, _sideSheetWidth (+2 more)

### Community 71 - "singleProvider"
Cohesion: 0.22
Nodes (10): singleProvider, dashboardProvider, periodProvider, _BodyState, build, DashboardScreen, GlobalDefaultsPage, lowStockCountProvider (+2 more)

### Community 72 - "l10n/app_localizations.dart"
Cohesion: 0.14
Nodes (12): l10n/app_localizations.dart, AdaptiveShell, build, _go, navigationShell, stockBadge, build, status (+4 more)

### Community 73 - "list_detail_pane.dart"
Cohesion: 0.25
Nodes (7): build, detail, list, ListDetailPane, _listWidth, Widget, window_size.dart

### Community 74 - "serials.dart"
Cohesion: 0.29
Nodes (6): from, m, prefix, serialRange, to, width

### Community 75 - "dashboard_charts.dart"
Cohesion: 0.11
Nodes (18): action, _axisLabel, bars, bucketLabel, build, chart, chartHeight, color (+10 more)

### Community 76 - "pos_providers.dart"
Cohesion: 0.08
Nodes (25): AppDatabase get, PosSettings, SellingSettings, add, build, changed, _db, list (+17 more)

### Community 77 - "print_layout.dart"
Cohesion: 0.06
Nodes (30): invoice.dart, barcode, columns, compact, discountOf, footer, full, head (+22 more)

### Community 78 - "periods.dart"
Cohesion: 0.10
Nodes (19): bucketsOf, dayIndex, dayOf, first, lengthOf, out, parseDay, Period (+11 more)

### Community 81 - "pos_screen.dart"
Cohesion: 0.07
Nodes (29): closing_page.dart, item_detail.dart, item_selector.dart, Submitted, _cartOpen, _checkout, _compact, createState (+21 more)

### Community 82 - "pos_widgets.dart"
Cohesion: 0.09
Nodes (22): build, createState, didUpdateWidget, dispose, enabled, _error, _focus, formats (+14 more)

### Community 83 - "pos_db_test.dart"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/pos/data/pos_closing_db.dart, package:rx_merchant/features/stock/data/stock_entry_db.dart, cart, db, invoice, main, openSessionWith, paid (+7 more)

### Community 84 - "payment_panel.dart"
Cohesion: 0.09
Nodes (21): bool get, cart_panel.dart, ../../../core/widgets/status_chip.dart, ../../invoices/ui/print_page.dart, Sale, name, onNewOrder, sale (+13 more)

### Community 85 - "item_selector.dart"
Cohesion: 0.12
Nodes (16): dart:async, RegisterItem, _add, _autoAdd, _clear, createState, _descendants, dispose (+8 more)

### Community 86 - "cart_panel.dart"
Cohesion: 0.10
Nodes (19): byPercent, createState, didUpdateWidget, _discountDialog, _field, formats, _key, l (+11 more)

### Community 87 - "closing_page.dart"
Cohesion: 0.12
Nodes (15): Color, ../../invoices/data/invoice_db.dart, build, ClosingPage, compact, _counted, createState, _draft (+7 more)

### Community 88 - "in_words.dart"
Cohesion: 0.12
Nodes (16): _below1000, cents, groups, hundreds, indian, moneyInWords, _ones, out (+8 more)

### Community 89 - "dashboard_providers.dart"
Cohesion: 0.12
Nodes (17): ../data/dashboard_db.dart, buckets, build, choice, choose, Dashboard, dashboardPath, db (+9 more)

### Community 90 - "flt.dart"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

### Community 91 - "pos_ui_test.dart"
Cohesion: 0.17
Nodes (11): package:rx_merchant/features/stock/data/stock_masters.dart, ../../stock/data/stock_db_test.dart, db, height, main, pumpPos, pumpWidget, runAsync (+3 more)

### Community 92 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.15
Nodes (11): app.dart, core/db/providers.dart, AppTheme, dark, _from, light, _seed, main (+3 more)

### Community 93 - "sales_reports.dart"
Cohesion: 0.11
Nodes (17): dashboard_db.dart, _int, Analytics, byGroup, grossProfit, groupBy, itemGroupId, itemId (+9 more)

### Community 94 - "setup_screen.dart"
Cohesion: 0.11
Nodes (17): ../../../core/widgets/list_detail_pane.dart, data_pages.dart, ../../invoices/ui/printing_pages.dart, build, id, page, path, selected (+9 more)

### Community 95 - "dashboard_db.dart"
Cohesion: 0.12
Nodes (15): achievement, Bar, _bars, DashboardDb, Figures, hasAnySale, monthlySales, paymentModes (+7 more)

### Community 96 - "app_database.dart"
Cohesion: 0.29
Nodes (6): ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, MigrationStrategy get, package:drift_flutter/drift_flutter.dart

### Community 97 - "dashboard_ui_test.dart"
Cohesion: 0.08
Nodes (24): package:rx_merchant/features/dashboard/ui/dashboard_screen.dart, package:rx_merchant/features/dashboard/ui/sales_report_pages.dart, package:rx_merchant/features/pos/data/pos_db.dart, ../../pos/data/pos_db_test.dart, ../../pos/ui/pos_ui_test.dart, db, home, main (+16 more)

### Community 98 - "cartProvider"
Cohesion: 0.13
Nodes (27): build, _ReturnFormState, build, CartPanel, _LinePadState, _changed, _ItemSelectorState, _submit (+19 more)

### Community 99 - "refusal.dart"
Cohesion: 0.14
Nodes (14): Exception, all, args, detail, _foreignKey, _primaryKey, reason, Refusal (+6 more)

### Community 100 - "print_page.dart"
Cohesion: 0.08
Nodes (25): invoice_pdf.dart, PrintSettings, address, createState, doc, _format, invoiceId, l (+17 more)

### Community 101 - "invoices_db_test.dart"
Cohesion: 0.08
Nodes (23): package:rx_merchant/features/dashboard/data/dashboard_db.dart, package:rx_merchant/features/invoices/data/invoice_db.dart, package:rx_merchant/features/invoices/data/print_masters.dart, package:rx_merchant/features/invoices/data/returns_db.dart, package:rx_merchant/features/invoices/logic/returns.dart, package:rx_merchant/features/pos/logic/sale.dart, package:rx_merchant/features/pos/logic/totals.dart, package:rx_merchant/features/stock/logic/stock_documents.dart (+15 more)

### Community 104 - "invoices_screen.dart"
Cohesion: 0.10
Nodes (21): invoice_detail.dart, invoiceListProvider, build, createState, dispose, _filters, id, InvoiceList (+13 more)

### Community 105 - "invoice_pdf.dart"
Cohesion: 0.10
Nodes (19): bold, doc, footer, header, invoiceDocument, loadPdfFonts, logo, of (+11 more)

### Community 106 - "return_form.dart"
Cohesion: 0.11
Nodes (18): _apply, createState, _draft, _error, initState, _line, _lines, _name (+10 more)

### Community 107 - "item_detail.dart"
Cohesion: 0.13
Nodes (15): core/widgets/window_size.dart, ../data/pos_closing_db.dart, ../data/pos_db.dart, SaleLine, line, onClose, _amounts, createState (+7 more)

### Community 108 - "invoice_db.dart"
Cohesion: 0.12
Nodes (16): from, hashCode, InvoiceFilters, invoiceIdByName, invoiceView, _line, of, operator (+8 more)

### Community 109 - "receipt_text.dart"
Cohesion: 0.12
Nodes (16): center, indent, last, left, line, lines, out, pair (+8 more)

### Community 110 - "invoice_detail.dart"
Cohesion: 0.12
Nodes (15): ../../../core/numbers/formats.dart, ../data/returns_db.dart, invoice_providers.dart, Invoice, _cancel, doc, id, inv (+7 more)

### Community 111 - "backup.dart"
Cohesion: 0.12
Nodes (15): File, backupDirectory, Backups, checkRestorable, close, databasePath, out, restoreDatabase (+7 more)

### Community 112 - "returns_db.dart"
Cohesion: 0.12
Nodes (15): _batchesFit, cancelInvoice, _returnable, ReturnDraft, _returned, returnProblems, salesReturnType, _serialsAvailable (+7 more)

### Community 113 - "returns.dart"
Cohesion: 0.14
Nodes (13): f, method, need, out, ReturnBasis, returned, scaleReturn, share (+5 more)

### Community 114 - "pos_closing_db.dart"
Cohesion: 0.15
Nodes (12): ../../../core/naming/naming_series.dart, cancellableClosing, cancelLastClosing, changeModeOf, ClosingDraft, _heldOrders, PosClosingDb, posClosingType (+4 more)

### Community 115 - "_PrintPageState"
Cohesion: 0.19
Nodes (13): build, InvoiceDetail, invoiceViewProvider, build, pdfFontsProvider, printAfterSale, _PrintPageState, printSettingsProvider (+5 more)

### Community 116 - "scan.dart"
Cohesion: 0.20
Nodes (10): ../../../core/widgets/child_table.dart, build, createState, _done, onScanned, scanBarcode, ScanButton, _ScanSheet (+2 more)

### Community 117 - "print_layout_test.dart"
Cohesion: 0.18
Nodes (10): package:rx_merchant/features/invoices/logic/escpos.dart, package:rx_merchant/features/invoices/logic/invoice.dart, package:rx_merchant/features/invoices/logic/receipt_text.dart, _invoice, itemName, _layout, main, _options (+2 more)

### Community 118 - "../../../core/numbers/format.dart"
Cohesion: 0.20
Nodes (9): ../../../core/numbers/format.dart, _followRename, _now, PrintMasters, saveLetterHead, savePrintHeading, saveTerms, _Value (+1 more)

### Community 119 - "invoice_pdf_test.dart"
Cohesion: 0.20
Nodes (9): dart:io, package:pdf/pdf.dart, package:pdf/widgets.dart, package:rx_merchant/features/invoices/logic/print_layout.dart, package:rx_merchant/features/invoices/ui/invoice_pdf.dart, _doc, font, _fonts (+1 more)

### Community 120 - "String?"
Cohesion: 0.20
Nodes (9): package:rx_merchant/core/widgets/link_field.dart, String?, cleared, created, field, groups, main, picked (+1 more)

### Community 121 - "package:drift/drift.dart"
Cohesion: 0.22
Nodes (8): counter, DefaultSeries, NamingSeries, nextName, parseSeries, resolved, two, package:drift/drift.dart

### Community 122 - "../../../core/db/app_database.dart"
Cohesion: 0.25
Nodes (7): ../../../core/db/app_database.dart, ../data/invoice_db.dart, db, invoicePath, invoicesLink, invoicesPath, returnPath

### Community 123 - "systemSettingsProvider"
Cohesion: 0.40
Nodes (6): App, build, systemSettingsProvider, build, _LoadingScreen, routerProvider

## Knowledge Gaps
- **1753 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+1748 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1927 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_return` connect `_return` to `router.dart`, `data_import.dart`, `country_info.dart`, `form_kit.dart`, `tax_template.dart`, `setup_db_test.dart`, `stock_documents.dart`, `stock_db_test.dart`, `stock_providers.dart`, `stock_rules.dart`, `stock_ui_test.dart`, `typedef`, `pos_providers.dart`, `periods.dart`, `pos_db_test.dart`, `payment_panel.dart`, `item_selector.dart`, `in_words.dart`, `pos_ui_test.dart`, `dashboard_ui_test.dart`, `invoice_pdf.dart`, `receipt_text.dart`, `returns.dart`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Why does `_int` connect `sales_reports.dart` to `singles.dart`, `stock_entry_page.dart`, `sale.dart`, `invoices_screen.dart`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `invoice_db.dart`, `stock_documents.dart`, `pos_screen.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `payment_panel.dart`, `item_selector.dart`, `stock_reports.dart`, `report_pages.dart`, `tree_masters.dart`, `tax_template.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `app_database.dart`, `_return`, `setup_db_test.dart`, `../../../core/db/singles.dart`, `backup.dart`, `pos_closing_db.dart`, `../../../core/numbers/format.dart`, `package:drift/drift.dart`, `data_import_db.dart`, `stock_reconciliation_db.dart`, `stock_lists.dart`, `dashboard_db.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _1753 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
# Graph Report - rx_merchant  (2026-11-28)

## Corpus Check
- 136 files · ~103,552 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2632 nodes · 4306 edges · 124 communities (117 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6749be6c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Singles Settings Fields
- report_table.dart
- App Feature Screens
- Invoice Model
- formats.dart
- format.dart
- package:material_ui/material_ui.dart
- country_info.dart
- batch_table.dart
- Stock Valuation Methods
- Spacing Constants
- tax_template_test.dart
- Android Main Activity
- Project README
- Data Import Columns
- settings_pages.dart
- tax_template_pages.dart
- Sale Totals Calculation
- simple_masters.dart
- escpos.dart
- data_pages.dart
- Setup Master Queries
- form_kit.dart
- Tax Template Logic
- wizard_screen.dart
- Naming Series Page
- item_pages.dart
- dashboard_db_test.dart
- ../../../core/db/app_database.dart
- stock_entry_page.dart
- State
- appDatabaseProvider
- Sale Cart Model
- StatelessWidget
- app_test.dart
- sales_report_pages.dart
- AppDatabase
- stock_masters_pages.dart
- import_backup_test.dart
- stock_reconciliation_page.dart
- formatsProvider
- stock_logic_test.dart
- serial_batch_editor.dart
- Stock Document Lines
- build
- Barcode Validation
- Stock Database Tests
- report_pages.dart
- tree_masters.dart
- Stock Entry Database
- Stock Masters Data
- Stock Report Queries
- stock_providers.dart
- stock_rules.dart
- Stock Ledger Posting
- printing_pages.dart
- recent_orders.dart
- setup_db_test.dart
- Stock Reconciliation Database
- Stock List Queries
- package:flutter_test/flutter_test.dart
- Stock UI Tests
- date_field.dart
- dashboard_screen.dart
- POS Sale Database
- providers.dart
- _return
- List
- singleProvider
- Adaptive Navigation Shell
- List Detail Layout
- Serial Number Ranges
- dashboard_charts.dart
- pos_providers.dart
- Print Layout
- Dashboard Periods
- Cost Editor Widget
- typedef
- pos_screen.dart
- pos_widgets.dart
- pos_db_test.dart
- ../../../core/widgets/spacing.dart
- item_selector.dart
- cart_panel.dart
- closing_page.dart
- Amount In Words
- Dashboard Providers
- Float Rounding
- POS UI Tests
- app.dart
- Sales Analytics Reports
- Setup Screen Navigation
- Dashboard Data Queries
- package:drift/drift.dart
- Dashboard UI Tests
- cartProvider
- refusal.dart
- print_page.dart
- Invoice Database Tests
- Item Tax Row Editor
- build
- invoices_screen.dart
- Invoice PDF Rendering
- return_form.dart
- modesOfPaymentProvider
- Invoice Queries
- Receipt Text Layout
- invoice_detail.dart
- Database Backup & Restore
- returns_db.dart
- package:flutter_riverpod/flutter_riverpod.dart
- POS Closing Database
- _PrintPageState
- ValueChanged
- print_layout_test.dart
- Print Masters Settings
- invoice_pdf_test.dart
- Link Field Widget
- dart:io
- Batches
- Tax Row Editor

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
- `DashboardDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/dashboard/data/dashboard_db.dart → lib/core/db/app_database.dart
- `PrintMasters` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/invoices/data/print_masters.dart → lib/core/db/app_database.dart
- `PosClosingDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/pos/data/pos_closing_db.dart → lib/core/db/app_database.dart
- `Backups` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/backup.dart → lib/core/db/app_database.dart
- `DataImportDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/data_import_db.dart → lib/core/db/app_database.dart

## Import Cycles
- None detected.

## Communities (124 total, 4 thin omitted)

### Community 0 - "Singles Settings Fields"
Cohesion: 0.03
Nodes (75): abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, allowRateChange (+67 more)

### Community 1 - "report_table.dart"
Cohesion: 0.07
Nodes (27): child_table.dart, _body, build, columns, createState, dispose, emptyText, _export (+19 more)

### Community 2 - "App Feature Screens"
Cohesion: 0.10
Nodes (20): core/widgets/adaptive_shell.dart, features/dashboard/ui/dashboard_providers.dart, features/dashboard/ui/dashboard_screen.dart, features/dashboard/ui/sales_report_pages.dart, features/invoices/ui/invoice_providers.dart, features/invoices/ui/invoices_screen.dart, features/pos/ui/pos_providers.dart, features/pos/ui/pos_screen.dart (+12 more)

### Community 3 - "Invoice Model"
Cohesion: 0.04
Nodes (46): DateTime, against, amount, batches, changeAmount, description, discountAmount, discountPercentage (+38 more)

### Community 4 - "formats.dart"
Cohesion: 0.12
Nodes (15): CurrencyData?, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date, defaults (+7 more)

### Community 5 - "format.dart"
Cohesion: 0.07
Nodes (26): cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber (+18 more)

### Community 6 - "package:material_ui/material_ui.dart"
Cohesion: 0.11
Nodes (16): compact,

  
  medium,, build, errorText, label, LinkField, mandatory, onChanged, onCreateNew (+8 more)

### Community 7 - "country_info.dart"
Cohesion: 0.11
Nodes (17): int get, bytes, code, CountryInfo, currency, currencyName, currencyPrecision, dateFormat (+9 more)

### Community 8 - "batch_table.dart"
Cohesion: 0.13
Nodes (14): IntColumn get, batchId, createdAt, disabled, expiryDate, id, itemId, manufacturingDate (+6 more)

### Community 9 - "Stock Valuation Methods"
Cohesion: 0.09
Nodes (21): fifo,
  movingAverage,, _addLayer, _bySerial, _fromQueue, fromSetting, issue, method, precision (+13 more)

### Community 10 - "Spacing Constants"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "tax_template_test.dart"
Cohesion: 0.18
Nodes (9): package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial, main, main, qty, row (+1 more)

### Community 12 - "Android Main Activity"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterActivity, FlutterEngine

### Community 17 - "Data Import Columns"
Cohesion: 0.04
Nodes (51): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+43 more)

### Community 18 - "settings_pages.dart"
Cohesion: 0.07
Nodes (37): Iterable, build, countryInfoProvider, createState, dateFormats, db, doctype, _enabledPriceListsProvider (+29 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.05
Nodes (38): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+30 more)

### Community 20 - "Sale Totals Calculation"
Cohesion: 0.04
Nodes (56): double get, addToLastRow, amount, c, _Calc, computeTotals, disableRoundedTotal, discount (+48 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.09
Nodes (22): CurrencyCompanion?, FormState, _choice, createState, db, dispose, _edit, _formKey (+14 more)

### Community 22 - "escpos.dart"
Cohesion: 0.11
Nodes (17): _align, _ascii, _bold, cut, drawer, escCut, escDrawer, escInit (+9 more)

### Community 23 - "data_pages.dart"
Cohesion: 0.06
Nodes (38): ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, BackupsPage, _BackupsPageState, _backupsProvider, _body (+30 more)

### Community 24 - "Setup Master Queries"
Cohesion: 0.10
Nodes (20): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, exists, highestUsedNumber, itemTaxTemplateRows (+12 more)

### Community 25 - "form_kit.dart"
Cohesion: 0.06
Nodes (34): ../data/refusal.dart, GlobalKey, a, actions, attempt, build, _changed, children (+26 more)

### Community 26 - "Tax Template Logic"
Cohesion: 0.10
Nodes (19): ChargeType, description, effectiveRate, included, isPreviousRow, method, of, out (+11 more)

### Community 27 - "wizard_screen.dart"
Cohesion: 0.09
Nodes (23): ../../../core/widgets/link_field.dart, ../data/country_info.dart, _abbr, _abbrEdited, _busy, _canGoOn, _country, createState (+15 more)

### Community 28 - "Naming Series Page"
Cohesion: 0.10
Nodes (24): ../data/seed.dart, ../data/setup_queries.dart, form_kit.dart, build, createState, current, db, digits (+16 more)

### Community 29 - "item_pages.dart"
Cohesion: 0.03
Nodes (73): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, child, _code (+65 more)

### Community 30 - "dashboard_db_test.dart"
Cohesion: 0.07
Nodes (28): await, package:rx_merchant/features/dashboard/data/sales_reports.dart, package:rx_merchant/features/dashboard/logic/periods.dart, a, b, cancel, day1, day2 (+20 more)

### Community 31 - "../../../core/db/app_database.dart"
Cohesion: 0.10
Nodes (19): ../../../core/db/app_database.dart, ../../../core/db/singles.dart, country_info.dart, double d when, _cell, d, DataImportDb, exportRows (+11 more)

### Community 32 - "stock_entry_page.dart"
Cohesion: 0.04
Nodes (48): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+40 more)

### Community 33 - "State"
Cohesion: 0.12
Nodes (24): AutomaticKeepAliveClientMixin, ReportTable, _ReportTableState, DiscardGuard, FormPage, _FormPageState, _AttributeEditor, _AttributeEditorState (+16 more)

### Community 34 - "appDatabaseProvider"
Cohesion: 0.06
Nodes (59): AsyncNotifier, ConsumerState, ConsumerStatefulWidget, appDatabaseProvider, firstDayOfWeekProvider, _load, SalesReportPage, _SalesReportPageState (+51 more)

### Community 35 - "Sale Cart Model"
Cohesion: 0.05
Nodes (40): additionalDiscountPercentage, addToSale, againstLineId, batchNo, dirty, discountAmount, discountOnNetTotal, discountPercentage (+32 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.13
Nodes (15): ReportFilters, ChartCard, _FirstSale, InvoicesScreen, _Labelled, NumberPad, TotalRow, _RecordTypePicker (+7 more)

### Community 37 - "app_test.dart"
Cohesion: 0.09
Nodes (22): ListTile, NavigationDestination, NavigationRail, package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/providers.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart (+14 more)

### Community 38 - "sales_report_pages.dart"
Cohesion: 0.08
Nodes (24): ../../../core/widgets/date_field.dart, ../../../core/widgets/report_table.dart, ../data/sales_reports.dart, Future, _changed, _chart, _Col, createState (+16 more)

### Community 39 - "AppDatabase"
Cohesion: 0.09
Nodes (22): _, @DriftDatabase, ../db/app_database.dart, AppDatabase, SinglesAccess, counter, DefaultSeries, NamingSeries (+14 more)

### Community 40 - "stock_masters_pages.dart"
Cohesion: 0.04
Nodes (52): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchesProvider (+44 more)

### Community 41 - "import_backup_test.dart"
Cohesion: 0.14
Nodes (12): package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/data_import_db.dart, package:rx_merchant/features/setup/data/refusal.dart, package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, package:sqlite3/sqlite3.dart, setup_db_test.dart, main (+4 more)

### Community 42 - "stock_reconciliation_page.dart"
Cohesion: 0.05
Nodes (36): ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty, _currentRate (+28 more)

### Community 43 - "formatsProvider"
Cohesion: 0.11
Nodes (41): ConsumerWidget, formatsProvider, _GoalCard, _NumberCard, _PeriodBar, _FilterBar, _PrinterPanel, _ItemCard (+33 more)

### Community 44 - "stock_logic_test.dart"
Cohesion: 0.20
Nodes (9): package:rx_merchant/features/stock/logic/serials.dart, package:rx_merchant/features/stock/logic/stock_rules.dart, package:rx_merchant/features/stock/logic/valuation.dart, package:rx_merchant/features/stock/logic/variants.dart, b, balance, before, main (+1 more)

### Community 45 - "serial_batch_editor.dart"
Cohesion: 0.07
Nodes (31): _add, _batch, build, _changed, createState, _csvHeader, dispose, _edit (+23 more)

### Community 46 - "Stock Document Lines"
Cohesion: 0.06
Nodes (32): allowZero, basicRate, batchNo, currentQty, currentRate, entries, EntryLine, factor (+24 more)

### Community 47 - "build"
Cohesion: 0.29
Nodes (7): storeCurrencyProvider, totalsRows, build, CurrencyPage, _CurrencyPageState, taxesProvider, TaxPage

### Community 48 - "Barcode Validation"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "Stock Database Tests"
Cohesion: 0.07
Nodes (26): int? to,
  List, ItemTables, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart, package:rx_merchant/features/stock/data/stock_reports.dart, allowNegative, batch, binOf (+18 more)

### Community 50 - "report_pages.dart"
Cohesion: 0.08
Nodes (25): ../data/stock_ledger.dart, _Col, createState, _date, _f, _Filter, _filters, _format (+17 more)

### Community 51 - "tree_masters.dart"
Cohesion: 0.04
Nodes (46): AsyncValue, ../data/stock_masters.dart, item_pages.dart, ItemGroupData?, id, page, path, query (+38 more)

### Community 52 - "Stock Entry Database"
Cohesion: 0.07
Nodes (27): amendedName, amendStockEntry, availableEntries, cancelStockEntry, _checkEntries, _clearLines, createBatch, currencyPrecision (+19 more)

### Community 53 - "Stock Masters Data"
Cohesion: 0.08
Nodes (24): _checkBarcodes, _checkDefaultWarehouse, _checkItemChange, createVariants, _defaultWarehouseName, deleteWarehouse, hasLedger, itemTaxTemplateOf (+16 more)

### Community 54 - "Stock Report Queries"
Cohesion: 0.09
Nodes (22): batchBalanceReport, batchId, from, itemGroupId, itemId, itemPriceStockReport, _lowStock, lowStockReport (+14 more)

### Community 55 - "stock_providers.dart"
Cohesion: 0.07
Nodes (39): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, build, build, _shown, ItemTaxTemplatePage (+31 more)

### Community 56 - "stock_rules.dart"
Cohesion: 0.10
Nodes (19): base, BatchStatus, best, defaultExpiry, given, isWhole, itemTaxTemplateFor, left (+11 more)

### Community 57 - "Stock Ledger Posting"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "printing_pages.dart"
Cohesion: 0.06
Nodes (38): ../data/print_masters.dart, LetterHeadData?, build, createState, db, _default, _disabled, dispose (+30 more)

### Community 59 - "recent_orders.dart"
Cohesion: 0.18
Nodes (10): ../../../core/widgets/status_chip.dart, ../../invoices/ui/invoice_providers.dart, ../../invoices/ui/invoices_screen.dart, ../../invoices/ui/print_page.dart, createState, _keep, onEdit, _query (+2 more)

### Community 60 - "setup_db_test.dart"
Cohesion: 0.15
Nodes (12): Exception, RefusedAll, RefusedException, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/seed.dart, package:rx_merchant/features/setup/data/setup_queries.dart, completeSetup, db (+4 more)

### Community 61 - "Stock Reconciliation Database"
Cohesion: 0.14
Nodes (13): amendStockReconciliation, cancelStockReconciliation, fetchItems, fillCurrent, reconciliationLines, saveStockReconciliation, StockReconciliationDb, stockReconciliationType (+5 more)

### Community 62 - "Stock List Queries"
Cohesion: 0.14
Nodes (13): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+5 more)

### Community 63 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (22): Chip, package:flutter_test/flutter_test.dart, package:rx_merchant/app.dart, package:rx_merchant/core/numbers/in_words.dart, package:rx_merchant/core/widgets/child_table.dart, package:rx_merchant/core/widgets/list_detail_pane.dart, package:rx_merchant/core/widgets/status_chip.dart, package:rx_merchant/l10n/app_localizations.dart (+14 more)

### Community 64 - "Stock UI Tests"
Cohesion: 0.17
Nodes (11): ../data/stock_db_test.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock, pumpWidget (+3 more)

### Community 65 - "date_field.dart"
Cohesion: 0.17
Nodes (11): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+3 more)

### Community 66 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (21): dashboard_charts.dart, dashboard_providers.dart, double?, before, createState, d, detail, extra (+13 more)

### Community 67 - "POS Sale Database"
Cohesion: 0.06
Nodes (31): ../../../core/numbers/in_words.dart, _batchIdOf, _checkSaleEntries, _clearChildren, deleteSale, deliverSerials, _entriesOf, formats (+23 more)

### Community 68 - "providers.dart"
Cohesion: 0.25
Nodes (7): app_database.dart, code, db, SystemSettings, Formats, ../numbers/formats.dart, singles.dart

### Community 69 - "_return"
Cohesion: 0.25
Nodes (7): _return, AttributeValue, combinations, numericValues, plainNumber, r, variantCode

### Community 70 - "List"
Cohesion: 0.15
Nodes (12): build, ChildTable, _edit, FormChanged, leading, readOnly, rows, _sideSheetRadius (+4 more)

### Community 71 - "singleProvider"
Cohesion: 0.20
Nodes (11): singleProvider, dashboardProvider, periodProvider, _Body, _BodyState, build, DashboardScreen, GlobalDefaultsPage (+3 more)

### Community 72 - "Adaptive Navigation Shell"
Cohesion: 0.14
Nodes (12): l10n/app_localizations.dart, AdaptiveShell, build, _go, navigationShell, stockBadge, build, status (+4 more)

### Community 73 - "List Detail Layout"
Cohesion: 0.25
Nodes (7): build, detail, list, ListDetailPane, _listWidth, Widget, window_size.dart

### Community 74 - "Serial Number Ranges"
Cohesion: 0.29
Nodes (6): from, m, prefix, serialRange, to, width

### Community 75 - "dashboard_charts.dart"
Cohesion: 0.10
Nodes (20): action, _axisLabel, bars, BarsChart, bucketLabel, build, chart, chartHeight (+12 more)

### Community 76 - "pos_providers.dart"
Cohesion: 0.07
Nodes (26): AppDatabase get, PosSettings, SellingSettings, add, build, changed, _db, list (+18 more)

### Community 77 - "Print Layout"
Cohesion: 0.06
Nodes (30): invoice.dart, barcode, columns, compact, discountOf, footer, full, head (+22 more)

### Community 78 - "Dashboard Periods"
Cohesion: 0.10
Nodes (19): bucketsOf, dayIndex, dayOf, first, lengthOf, out, parseDay, Period (+11 more)

### Community 80 - "typedef"
Cohesion: 0.22
Nodes (8): openSystemSettings, Printer, PrinterState, sendRaw, _settings, package:flutter/services.dart, package:print_bluetooth_thermal/print_bluetooth_thermal.dart, typedef

### Community 81 - "pos_screen.dart"
Cohesion: 0.07
Nodes (26): closing_page.dart, item_detail.dart, item_selector.dart, Submitted, _cartOpen, _checkout, _compact, createState (+18 more)

### Community 82 - "pos_widgets.dart"
Cohesion: 0.09
Nodes (23): ../../../core/numbers/formats.dart, build, createState, didUpdateWidget, dispose, enabled, _error, _focus (+15 more)

### Community 83 - "pos_db_test.dart"
Cohesion: 0.11
Nodes (17): package:rx_merchant/core/numbers/format.dart, package:rx_merchant/features/pos/data/pos_closing_db.dart, package:rx_merchant/features/stock/data/stock_entry_db.dart, main, cart, db, invoice, main (+9 more)

### Community 84 - "../../../core/widgets/spacing.dart"
Cohesion: 0.08
Nodes (31): bool get, cart_panel.dart, ../../../core/widgets/spacing.dart, core/widgets/window_size.dart, ../data/pos_closing_db.dart, ../data/pos_db.dart, SaleLine, line (+23 more)

### Community 85 - "item_selector.dart"
Cohesion: 0.12
Nodes (16): dart:async, RegisterItem, _add, _autoAdd, _clear, createState, _descendants, dispose (+8 more)

### Community 86 - "cart_panel.dart"
Cohesion: 0.11
Nodes (17): byPercent, createState, didUpdateWidget, _discountDialog, _field, formats, l, line (+9 more)

### Community 87 - "closing_page.dart"
Cohesion: 0.12
Nodes (15): Color, ../../invoices/data/invoice_db.dart, build, compact, _counted, createState, _draft, errorColor (+7 more)

### Community 88 - "Amount In Words"
Cohesion: 0.12
Nodes (16): _below1000, cents, groups, hundreds, indian, moneyInWords, _ones, out (+8 more)

### Community 89 - "Dashboard Providers"
Cohesion: 0.12
Nodes (17): ../data/dashboard_db.dart, buckets, build, choice, choose, Dashboard, dashboardPath, db (+9 more)

### Community 90 - "Float Rounding"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

### Community 91 - "POS UI Tests"
Cohesion: 0.17
Nodes (11): package:rx_merchant/features/stock/data/stock_masters.dart, ../../stock/data/stock_db_test.dart, db, height, main, pumpPos, pumpWidget, runAsync (+3 more)

### Community 92 - "app.dart"
Cohesion: 0.15
Nodes (14): App, AppTheme, build, dark, _from, light, _seed, systemSettingsProvider (+6 more)

### Community 93 - "Sales Analytics Reports"
Cohesion: 0.11
Nodes (17): dashboard_db.dart, _int, Analytics, byGroup, grossProfit, groupBy, itemGroupId, itemId (+9 more)

### Community 94 - "Setup Screen Navigation"
Cohesion: 0.11
Nodes (17): ../../../core/widgets/list_detail_pane.dart, data_pages.dart, ../../invoices/ui/printing_pages.dart, build, id, page, path, selected (+9 more)

### Community 95 - "Dashboard Data Queries"
Cohesion: 0.12
Nodes (15): achievement, Bar, _bars, DashboardDb, Figures, hasAnySale, monthlySales, paymentModes (+7 more)

### Community 96 - "package:drift/drift.dart"
Cohesion: 0.29
Nodes (6): ../../features/stock/data/batch_table.dart, migration, schemaVersion, MigrationStrategy get, package:drift/drift.dart, package:drift_flutter/drift_flutter.dart

### Community 97 - "Dashboard UI Tests"
Cohesion: 0.08
Nodes (24): package:rx_merchant/features/dashboard/ui/dashboard_screen.dart, package:rx_merchant/features/dashboard/ui/sales_report_pages.dart, package:rx_merchant/features/pos/data/pos_db.dart, ../../pos/data/pos_db_test.dart, ../../pos/ui/pos_ui_test.dart, db, home, main (+16 more)

### Community 98 - "cartProvider"
Cohesion: 0.12
Nodes (29): build, build, CartPanel, _key, build, ItemDetail, _changed, ItemSelector (+21 more)

### Community 99 - "refusal.dart"
Cohesion: 0.17
Nodes (11): all, args, detail, _foreignKey, _primaryKey, reason, Refusal, toString (+3 more)

### Community 100 - "print_page.dart"
Cohesion: 0.08
Nodes (24): invoice_pdf.dart, PrintSettings, address, createState, doc, _format, invoiceId, l (+16 more)

### Community 101 - "Invoice Database Tests"
Cohesion: 0.08
Nodes (23): package:rx_merchant/features/dashboard/data/dashboard_db.dart, package:rx_merchant/features/invoices/data/invoice_db.dart, package:rx_merchant/features/invoices/data/print_masters.dart, package:rx_merchant/features/invoices/data/returns_db.dart, package:rx_merchant/features/invoices/logic/returns.dart, package:rx_merchant/features/pos/logic/sale.dart, package:rx_merchant/features/pos/logic/totals.dart, package:rx_merchant/features/stock/logic/stock_documents.dart (+15 more)

### Community 103 - "build"
Cohesion: 0.67
Nodes (3): build, SalesTaxesTemplatePage, salesTaxesTemplatesProvider

### Community 104 - "invoices_screen.dart"
Cohesion: 0.08
Nodes (27): core/db/providers.dart, ../data/invoice_db.dart, invoice_detail.dart, db, invoiceListProvider, invoicePath, invoicesLink, invoicesPath (+19 more)

### Community 105 - "Invoice PDF Rendering"
Cohesion: 0.10
Nodes (19): bold, doc, footer, header, invoiceDocument, loadPdfFonts, logo, of (+11 more)

### Community 106 - "return_form.dart"
Cohesion: 0.10
Nodes (20): _apply, createState, _draft, _error, initState, _line, _lines, _name (+12 more)

### Community 107 - "modesOfPaymentProvider"
Cohesion: 0.33
Nodes (7): build, OpeningForm, _OpeningFormState, build, cancellableClosingProvider, ModeOfPaymentPage, modesOfPaymentProvider

### Community 108 - "Invoice Queries"
Cohesion: 0.12
Nodes (16): from, hashCode, InvoiceFilters, invoiceIdByName, invoiceView, _line, of, operator (+8 more)

### Community 109 - "Receipt Text Layout"
Cohesion: 0.12
Nodes (16): center, indent, last, left, line, lines, out, pair (+8 more)

### Community 110 - "invoice_detail.dart"
Cohesion: 0.12
Nodes (15): ../data/returns_db.dart, invoice_providers.dart, Invoice, _cancel, _Detail, doc, id, inv (+7 more)

### Community 111 - "Database Backup & Restore"
Cohesion: 0.12
Nodes (15): File, backupDirectory, Backups, checkRestorable, close, databasePath, out, restoreDatabase (+7 more)

### Community 112 - "returns_db.dart"
Cohesion: 0.07
Nodes (29): ../../../core/numbers/flt.dart, _batchesFit, cancelInvoice, _returnable, ReturnDraft, _returned, returnProblems, salesReturnType (+21 more)

### Community 113 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.50
Nodes (3): app.dart, main, package:flutter_riverpod/flutter_riverpod.dart

### Community 114 - "POS Closing Database"
Cohesion: 0.15
Nodes (12): ../../../core/naming/naming_series.dart, cancellableClosing, cancelLastClosing, changeModeOf, ClosingDraft, _heldOrders, PosClosingDb, posClosingType (+4 more)

### Community 115 - "_PrintPageState"
Cohesion: 0.28
Nodes (9): build, InvoiceDetail, invoiceViewProvider, build, pdfFontsProvider, printAfterSale, PrintPage, _PrintPageState (+1 more)

### Community 116 - "ValueChanged"
Cohesion: 0.18
Nodes (11): ../../../core/widgets/child_table.dart, build, createState, _done, onScanned, scanBarcode, ScanButton, _ScanSheet (+3 more)

### Community 117 - "print_layout_test.dart"
Cohesion: 0.20
Nodes (9): package:rx_merchant/features/invoices/logic/escpos.dart, package:rx_merchant/features/invoices/logic/receipt_text.dart, _invoice, itemName, _layout, main, _options, status (+1 more)

### Community 118 - "Print Masters Settings"
Cohesion: 0.20
Nodes (9): ../../../core/numbers/format.dart, _followRename, _now, PrintMasters, saveLetterHead, savePrintHeading, saveTerms, _Value (+1 more)

### Community 119 - "invoice_pdf_test.dart"
Cohesion: 0.20
Nodes (9): package:pdf/pdf.dart, package:pdf/widgets.dart, package:rx_merchant/features/invoices/logic/invoice.dart, package:rx_merchant/features/invoices/logic/print_layout.dart, package:rx_merchant/features/invoices/ui/invoice_pdf.dart, _doc, font, _fonts (+1 more)

### Community 120 - "Link Field Widget"
Cohesion: 0.20
Nodes (9): package:rx_merchant/core/widgets/link_field.dart, String?, cleared, created, field, groups, main, picked (+1 more)

### Community 121 - "dart:io"
Cohesion: 0.50
Nodes (3): dart:convert, dart:io, main

### Community 122 - "Batches"
Cohesion: 0.67
Nodes (3): @DataClassName, Batches, Table

## Knowledge Gaps
- **1757 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+1752 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1933 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_return` connect `_return` to `App Feature Screens`, `Data Import Columns`, `escpos.dart`, `form_kit.dart`, `Tax Template Logic`, `Stock Document Lines`, `Stock Database Tests`, `stock_providers.dart`, `stock_rules.dart`, `setup_db_test.dart`, `Stock UI Tests`, `providers.dart`, `pos_providers.dart`, `Dashboard Periods`, `pos_db_test.dart`, `../../../core/widgets/spacing.dart`, `item_selector.dart`, `Amount In Words`, `POS UI Tests`, `Dashboard UI Tests`, `Invoice PDF Rendering`, `Receipt Text Layout`, `returns_db.dart`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `_int` connect `Sales Analytics Reports` to `Singles Settings Fields`, `stock_entry_page.dart`, `Sale Cart Model`, `invoices_screen.dart`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `Invoice Queries`, `Stock Document Lines`, `pos_screen.dart`, `pos_widgets.dart`, `tax_template_pages.dart`, `../../../core/widgets/spacing.dart`, `item_selector.dart`, `Stock Report Queries`, `report_pages.dart`, `tree_masters.dart`, `Tax Template Logic`, `item_pages.dart`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `formatsProvider` connect `formatsProvider` to `settings_pages.dart`, `data_pages.dart`, `appDatabaseProvider`, `stock_masters_pages.dart`, `build`, `stock_providers.dart`, `printing_pages.dart`, `providers.dart`, `singleProvider`, `dashboard_charts.dart`, `pos_providers.dart`, `item_selector.dart`, `cart_panel.dart`, `closing_page.dart`, `cartProvider`, `build`, `invoices_screen.dart`, `return_form.dart`, `modesOfPaymentProvider`, `invoice_detail.dart`, `_PrintPageState`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _1757 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Singles Settings Fields` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._
- **Should `App Feature Screens` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
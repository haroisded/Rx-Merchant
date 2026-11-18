# Graph Report - rx_merchant  (2026-11-18)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 2620 nodes · 4280 edges · 125 communities (116 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 77,479 input · 3,882 output

## Graph Freshness
- Built from commit: `861d78d0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Singles Settings Fields
- Report Table Widget
- App Feature Screens
- Invoice Model
- Currency Formats
- Number & Date Formatting
- Link Field Widget
- App Widget Tests
- Batch Table Schema
- Stock Valuation Methods
- Spacing Constants
- Number Logic Tests
- Android Main Activity
- Project README
- Data Import Columns
- Settings Pages
- Item Tax Template Pages
- Sale Totals Calculation
- Simple Master Pages
- ESC/POS Printing
- Data Import/Export Pages
- Setup Master Queries
- Form Kit Widgets
- Tax Template Logic
- Setup Wizard
- Naming Series Page
- Item Form Page
- Dashboard Database Tests
- Data Import Database
- Stock Entry Form
- Item Child Editors
- Stateful Consumer Pages
- Sale Cart Model
- Shared UI Components
- Setup Database Tests
- Sales Report Pages
- App Database Accessors
- Stock Master Pages
- Setup Seed Data
- Stock Reconciliation Page
- Stock & Selling Providers
- Stock Logic Tests
- Serial/Batch Editor
- Stock Document Lines
- Dashboard Card Widgets
- Barcode Validation
- Stock Database Tests
- Stock Report Pages
- Item Group Tree
- Stock Entry Database
- Stock Masters Data
- Stock Report Queries
- Item & Tax Page Widgets
- Stock Rules
- Stock Ledger Posting
- Letter Head Printing Pages
- Recent Orders List
- Stock Screen Navigation
- Stock Reconciliation Database
- Stock List Queries
- Window Size & Core Widgets
- Stock UI Tests
- Date Field Widget
- Dashboard Screen
- POS Sale Database
- System Settings Singletons
- Item Variant Combinations
- Child Table Widget
- Dashboard and Stock Home
- Adaptive Navigation Shell
- List Detail Layout
- Serial Number Ranges
- Dashboard Charts
- POS Providers
- Print Layout
- Dashboard Periods
- Cost Editor Widget
- Value Editor Widget
- POS Screen
- POS Input Widgets
- POS Database Tests
- Order Summary & Payment
- Item Selector
- Cart Line Pad
- POS Closing Page
- Amount In Words
- Dashboard Providers
- Float Rounding
- POS UI Tests
- App Theme & Entry
- Sales Analytics Reports
- Setup Screen Navigation
- Dashboard Data Queries
- Database Schema Migration
- Dashboard UI Tests
- POS Cart Forms
- Refusal Exceptions
- Invoice Print Page
- Invoice Database Tests
- Item Tax Row Editor
- Sales Taxes Templates
- Invoice List Screen
- Invoice PDF Rendering
- Sales Return Form
- POS Opening Form
- Invoice Queries
- Receipt Text Layout
- Invoice Detail View
- Database Backup & Restore
- Returns & Cancellation
- Return Scaling Logic
- POS Closing Database
- Print Settings Providers
- Barcode Scanner
- Print Layout Tests
- Print Masters Settings
- Invoice PDF Generation
- Link Field Widget
- Naming Series Generator
- Invoice Providers and Routes
- App Root Bootstrap
- Tax Row Editor

## God Nodes (most connected - your core abstractions)
1. `formatsProvider` - 90 edges
2. `appDatabaseProvider` - 82 edges
3. `warehousesProvider` - 28 edges
4. `AppDatabase` - 27 edges
5. `itemRowsProvider` - 25 edges
6. `_return` - 25 edges
7. `cartProvider` - 20 edges
8. `posSettingsProvider` - 20 edges
9. `stockSettingsProvider` - 19 edges
10. `_int` - 19 edges

## Surprising Connections (you probably didn't know these)
- `openScanned` --references--> `appDatabaseProvider`  [EXTRACTED]
  lib/features/invoices/ui/invoices_screen.dart → lib/core/db/providers.dart
- `_apply` --references--> `formatsProvider`  [EXTRACTED]
  lib/features/invoices/ui/return_form.dart → lib/core/db/providers.dart
- `_line` --references--> `formatsProvider`  [EXTRACTED]
  lib/features/invoices/ui/return_form.dart → lib/core/db/providers.dart
- `_cancel` --references--> `appDatabaseProvider`  [EXTRACTED]
  lib/features/invoices/ui/invoice_detail.dart → lib/core/db/providers.dart
- `Backups` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/backup.dart → lib/core/db/app_database.dart

## Import Cycles
- None detected.

## Communities (125 total, 6 thin omitted)

### Community 0 - "Singles Settings Fields"
Cohesion: 0.03
Nodes (75): abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, allowRateChange (+67 more)

### Community 1 - "Report Table Widget"
Cohesion: 0.07
Nodes (29): child_table.dart, _body, build, columns, createState, dispose, emptyText, _export (+21 more)

### Community 2 - "App Feature Screens"
Cohesion: 0.10
Nodes (20): core/widgets/adaptive_shell.dart, features/dashboard/ui/dashboard_providers.dart, features/dashboard/ui/dashboard_screen.dart, features/dashboard/ui/sales_report_pages.dart, features/invoices/ui/invoice_providers.dart, features/invoices/ui/invoices_screen.dart, features/pos/ui/pos_providers.dart, features/pos/ui/pos_screen.dart (+12 more)

### Community 3 - "Invoice Model"
Cohesion: 0.04
Nodes (46): DateTime, against, amount, batches, changeAmount, description, discountAmount, discountPercentage (+38 more)

### Community 4 - "Currency Formats"
Cohesion: 0.12
Nodes (16): CurrencyData?, ../db/app_database.dart, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date (+8 more)

### Community 5 - "Number & Date Formatting"
Cohesion: 0.08
Nodes (25): cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber (+17 more)

### Community 6 - "Link Field Widget"
Cohesion: 0.20
Nodes (9): build, errorText, label, LinkField, mandatory, onChanged, onCreateNew, value (+1 more)

### Community 7 - "App Widget Tests"
Cohesion: 0.17
Nodes (11): ListTile, NavigationDestination, NavigationRail, package:rx_merchant/core/db/providers.dart, required double width,
  bool, db, main, pumpAndSettle (+3 more)

### Community 8 - "Batch Table Schema"
Cohesion: 0.11
Nodes (17): @DataClassName, IntColumn get, Batches, batchId, createdAt, disabled, expiryDate, id (+9 more)

### Community 9 - "Stock Valuation Methods"
Cohesion: 0.09
Nodes (21): fifo,
  movingAverage,, _addLayer, _bySerial, _fromQueue, fromSetting, issue, method, precision (+13 more)

### Community 10 - "Spacing Constants"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "Number Logic Tests"
Cohesion: 0.09
Nodes (18): package:flutter_test/flutter_test.dart, package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/core/numbers/format.dart, package:rx_merchant/core/numbers/in_words.dart, package:rx_merchant/features/dashboard/logic/periods.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial (+10 more)

### Community 12 - "Android Main Activity"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterActivity, FlutterEngine

### Community 17 - "Data Import Columns"
Cohesion: 0.04
Nodes (51): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+43 more)

### Community 18 - "Settings Pages"
Cohesion: 0.07
Nodes (38): Iterable, build, countryInfoProvider, createState, dateFormats, db, doctype, _enabledPriceListsProvider (+30 more)

### Community 19 - "Item Tax Template Pages"
Cohesion: 0.05
Nodes (41): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+33 more)

### Community 20 - "Sale Totals Calculation"
Cohesion: 0.04
Nodes (56): double get, addToLastRow, amount, c, _Calc, computeTotals, disableRoundedTotal, discount (+48 more)

### Community 21 - "Simple Master Pages"
Cohesion: 0.09
Nodes (23): CurrencyCompanion?, FormState, _choice, createState, CurrencyPage, db, dispose, _edit (+15 more)

### Community 22 - "ESC/POS Printing"
Cohesion: 0.05
Nodes (41): dart:convert, _align, _ascii, _bold, cut, drawer, escCut, escDrawer (+33 more)

### Community 23 - "Data Import/Export Pages"
Cohesion: 0.06
Nodes (34): ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, _body, _busy, _chooseFile, copy (+26 more)

### Community 24 - "Setup Master Queries"
Cohesion: 0.10
Nodes (20): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, exists, highestUsedNumber, itemTaxTemplateRows (+12 more)

### Community 25 - "Form Kit Widgets"
Cohesion: 0.06
Nodes (31): AsyncValue, ../data/refusal.dart, GlobalKey, a, actions, attempt, build, children (+23 more)

### Community 26 - "Tax Template Logic"
Cohesion: 0.10
Nodes (19): ChargeType, description, effectiveRate, included, isPreviousRow, method, of, out (+11 more)

### Community 27 - "Setup Wizard"
Cohesion: 0.08
Nodes (24): ../../../core/widgets/link_field.dart, ../data/country_info.dart, _abbr, _abbrEdited, build, _busy, _canGoOn, _country (+16 more)

### Community 28 - "Naming Series Page"
Cohesion: 0.10
Nodes (24): ../data/seed.dart, ../data/setup_queries.dart, form_kit.dart, build, createState, current, db, digits (+16 more)

### Community 29 - "Item Form Page"
Cohesion: 0.03
Nodes (72): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, _code, _combos (+64 more)

### Community 30 - "Dashboard Database Tests"
Cohesion: 0.08
Nodes (24): await, package:rx_merchant/features/dashboard/data/sales_reports.dart, a, b, cancel, day1, day2, days (+16 more)

### Community 31 - "Data Import Database"
Cohesion: 0.17
Nodes (11): double d when, _cell, d, DataImportDb, exportRows, _ids, ImportLogLine, importLookups (+3 more)

### Community 32 - "Stock Entry Form"
Cohesion: 0.04
Nodes (51): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+43 more)

### Community 33 - "Item Child Editors"
Cohesion: 0.16
Nodes (18): _AttributeEditor, _AttributeEditorState, _BarcodeEditor, _BarcodeEditorState, _ReorderEditor, _ReorderEditorState, _TaxEditor, _TaxEditorState (+10 more)

### Community 34 - "Stateful Consumer Pages"
Cohesion: 0.07
Nodes (35): ConsumerState, ConsumerStatefulWidget, firstDayOfWeekProvider, _load, _SalesReportPageState, _LetterHeadForm, _LetterHeadFormState, _TermsForm (+27 more)

### Community 35 - "Sale Cart Model"
Cohesion: 0.05
Nodes (40): additionalDiscountPercentage, addToSale, againstLineId, batchNo, dirty, discountAmount, discountOnNetTotal, discountPercentage (+32 more)

### Community 36 - "Shared UI Components"
Cohesion: 0.12
Nodes (16): ReportFilters, ChartCard, _FirstSale, InvoicesScreen, _Labelled, NumberPad, TotalRow, _RecordTypePicker (+8 more)

### Community 37 - "Setup Database Tests"
Cohesion: 0.08
Nodes (26): package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/data_import_db.dart, package:rx_merchant/features/setup/data/refusal.dart (+18 more)

### Community 38 - "Sales Report Pages"
Cohesion: 0.08
Nodes (25): ../../../core/widgets/date_field.dart, ../../../core/widgets/report_table.dart, ../data/sales_reports.dart, Future, _changed, _chart, _Col, createState (+17 more)

### Community 39 - "App Database Accessors"
Cohesion: 0.14
Nodes (14): _, @DriftDatabase, AppDatabase, SinglesAccess, SalesReports, InvoiceDb, ReturnsDb, PosDb (+6 more)

### Community 40 - "Stock Master Pages"
Cohesion: 0.04
Nodes (46): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchId (+38 more)

### Community 41 - "Setup Seed Data"
Cohesion: 0.25
Nodes (7): ../../../core/db/singles.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, SetupSeed, _wholeNumberUoms

### Community 42 - "Stock Reconciliation Page"
Cohesion: 0.05
Nodes (39): ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty, _currentRate (+31 more)

### Community 43 - "Stock & Selling Providers"
Cohesion: 0.11
Nodes (47): AsyncNotifier, appDatabaseProvider, build, ItemDetail, CartNotifier, sellingSettingsProvider, PriceListPage, priceListsProvider (+39 more)

### Community 44 - "Stock Logic Tests"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, package:rx_merchant/features/stock/logic/serials.dart, package:rx_merchant/features/stock/logic/stock_rules.dart, package:rx_merchant/features/stock/logic/valuation.dart, package:rx_merchant/features/stock/logic/variants.dart, item, kinds (+7 more)

### Community 45 - "Serial/Batch Editor"
Cohesion: 0.07
Nodes (29): _add, _batch, build, _changed, createState, _csvHeader, dispose, _edit (+21 more)

### Community 46 - "Stock Document Lines"
Cohesion: 0.06
Nodes (32): allowZero, basicRate, batchNo, currentQty, currentRate, entries, EntryLine, factor (+24 more)

### Community 47 - "Dashboard Card Widgets"
Cohesion: 0.10
Nodes (32): ConsumerWidget, formatsProvider, storeCurrencyProvider, BarsChart, LinesChart, _GoalCard, _NumberCard, _PeriodBar (+24 more)

### Community 48 - "Barcode Validation"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "Stock Database Tests"
Cohesion: 0.07
Nodes (26): int? to,
  List, ItemTables, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart, package:rx_merchant/features/stock/data/stock_reports.dart, allowNegative, batch, binOf (+18 more)

### Community 50 - "Stock Report Pages"
Cohesion: 0.07
Nodes (27): ../data/stock_ledger.dart, _Col, createState, _date, _f, _Filter, _filters, _format (+19 more)

### Community 51 - "Item Group Tree"
Cohesion: 0.07
Nodes (28): ../data/stock_masters.dart, ItemGroupData?, all, createState, _disabled, dispose, _flat, _formKey (+20 more)

### Community 52 - "Stock Entry Database"
Cohesion: 0.07
Nodes (27): amendedName, amendStockEntry, availableEntries, cancelStockEntry, _checkEntries, _clearLines, createBatch, currencyPrecision (+19 more)

### Community 53 - "Stock Masters Data"
Cohesion: 0.08
Nodes (24): _checkBarcodes, _checkDefaultWarehouse, _checkItemChange, createVariants, _defaultWarehouseName, deleteWarehouse, hasLedger, itemTaxTemplateOf (+16 more)

### Community 54 - "Stock Report Queries"
Cohesion: 0.09
Nodes (22): batchBalanceReport, batchId, from, itemGroupId, itemId, itemPriceStockReport, _lowStock, lowStockReport (+14 more)

### Community 55 - "Item & Tax Page Widgets"
Cohesion: 0.07
Nodes (36): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, build, build, _shown, ItemTaxTemplatePage (+28 more)

### Community 56 - "Stock Rules"
Cohesion: 0.11
Nodes (18): base, BatchStatus, best, defaultExpiry, given, isWhole, itemTaxTemplateFor, left (+10 more)

### Community 57 - "Stock Ledger Posting"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "Letter Head Printing Pages"
Cohesion: 0.06
Nodes (34): ../data/print_masters.dart, LetterHeadData?, createState, db, _default, _disabled, dispose, _footer (+26 more)

### Community 59 - "Recent Orders List"
Cohesion: 0.18
Nodes (10): ../../../core/widgets/spacing.dart, ../../invoices/ui/invoice_providers.dart, ../../invoices/ui/invoices_screen.dart, createState, _keep, onEdit, _query, RecentOrders (+2 more)

### Community 60 - "Stock Screen Navigation"
Cohesion: 0.12
Nodes (15): item_pages.dart, id, page, path, query, selected, stockPage, stockPath (+7 more)

### Community 61 - "Stock Reconciliation Database"
Cohesion: 0.14
Nodes (13): amendStockReconciliation, cancelStockReconciliation, fetchItems, fillCurrent, reconciliationLines, saveStockReconciliation, StockReconciliationDb, stockReconciliationType (+5 more)

### Community 62 - "Stock List Queries"
Cohesion: 0.14
Nodes (13): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+5 more)

### Community 63 - "Window Size & Core Widgets"
Cohesion: 0.07
Nodes (26): Chip, compact,

  
  medium,, expanded, of, WindowSize, package:material_ui/material_ui.dart, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/child_table.dart (+18 more)

### Community 64 - "Stock UI Tests"
Cohesion: 0.17
Nodes (11): ../data/stock_db_test.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock, pumpWidget (+3 more)

### Community 65 - "Date Field Widget"
Cohesion: 0.15
Nodes (12): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+4 more)

### Community 66 - "Dashboard Screen"
Cohesion: 0.09
Nodes (22): dashboard_charts.dart, dashboard_providers.dart, double?, before, _Body, createState, d, detail (+14 more)

### Community 67 - "POS Sale Database"
Cohesion: 0.06
Nodes (31): ../../../core/numbers/in_words.dart, _batchIdOf, _checkSaleEntries, _clearChildren, deleteSale, deliverSerials, _entriesOf, formats (+23 more)

### Community 68 - "System Settings Singletons"
Cohesion: 0.22
Nodes (8): app_database.dart, code, db, SystemSettings, Formats, _return, ../numbers/formats.dart, singles.dart

### Community 69 - "Item Variant Combinations"
Cohesion: 0.22
Nodes (8): ../../../core/numbers/flt.dart, AttributeValue, combinations, numericValues, plainNumber, r, variantCode, typedef

### Community 70 - "Child Table Widget"
Cohesion: 0.18
Nodes (10): build, ChildTable, _edit, leading, readOnly, rows, _sideSheetRadius, _sideSheetWidth (+2 more)

### Community 71 - "Dashboard and Stock Home"
Cohesion: 0.22
Nodes (10): singleProvider, dashboardProvider, periodProvider, _BodyState, build, DashboardScreen, GlobalDefaultsPage, lowStockCountProvider (+2 more)

### Community 72 - "Adaptive Navigation Shell"
Cohesion: 0.14
Nodes (12): l10n/app_localizations.dart, AdaptiveShell, build, _go, navigationShell, stockBadge, build, status (+4 more)

### Community 73 - "List Detail Layout"
Cohesion: 0.25
Nodes (7): build, detail, list, ListDetailPane, _listWidth, Widget, window_size.dart

### Community 74 - "Serial Number Ranges"
Cohesion: 0.29
Nodes (6): from, m, prefix, serialRange, to, width

### Community 75 - "Dashboard Charts"
Cohesion: 0.11
Nodes (18): action, _axisLabel, bars, bucketLabel, build, chart, chartHeight, color (+10 more)

### Community 76 - "POS Providers"
Cohesion: 0.08
Nodes (25): AppDatabase get, PosSettings, SellingSettings, add, build, changed, _db, list (+17 more)

### Community 77 - "Print Layout"
Cohesion: 0.06
Nodes (30): invoice.dart, barcode, columns, compact, discountOf, footer, full, head (+22 more)

### Community 78 - "Dashboard Periods"
Cohesion: 0.10
Nodes (19): bucketsOf, dayIndex, dayOf, first, lengthOf, out, parseDay, Period (+11 more)

### Community 81 - "POS Screen"
Cohesion: 0.07
Nodes (29): closing_page.dart, item_detail.dart, item_selector.dart, Submitted, _cartOpen, _checkout, _compact, createState (+21 more)

### Community 82 - "POS Input Widgets"
Cohesion: 0.09
Nodes (22): build, createState, didUpdateWidget, dispose, enabled, _error, _focus, formats (+14 more)

### Community 83 - "POS Database Tests"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/pos/data/pos_closing_db.dart, package:rx_merchant/features/stock/data/stock_entry_db.dart, cart, db, invoice, main, openSessionWith, paid (+7 more)

### Community 84 - "Order Summary & Payment"
Cohesion: 0.09
Nodes (21): bool get, cart_panel.dart, ../../../core/widgets/status_chip.dart, ../../invoices/ui/print_page.dart, Sale, name, onNewOrder, sale (+13 more)

### Community 85 - "Item Selector"
Cohesion: 0.12
Nodes (16): dart:async, RegisterItem, _add, _autoAdd, _clear, createState, _descendants, dispose (+8 more)

### Community 86 - "Cart Line Pad"
Cohesion: 0.10
Nodes (19): byPercent, createState, didUpdateWidget, _discountDialog, _field, formats, _key, l (+11 more)

### Community 87 - "POS Closing Page"
Cohesion: 0.12
Nodes (15): Color, ../../invoices/data/invoice_db.dart, build, ClosingPage, compact, _counted, createState, _draft (+7 more)

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

### Community 92 - "App Theme & Entry"
Cohesion: 0.15
Nodes (11): app.dart, core/db/providers.dart, AppTheme, dark, _from, light, _seed, main (+3 more)

### Community 93 - "Sales Analytics Reports"
Cohesion: 0.11
Nodes (17): dashboard_db.dart, _int, Analytics, byGroup, grossProfit, groupBy, itemGroupId, itemId (+9 more)

### Community 94 - "Setup Screen Navigation"
Cohesion: 0.11
Nodes (17): ../../../core/widgets/list_detail_pane.dart, data_pages.dart, ../../invoices/ui/printing_pages.dart, build, id, page, path, selected (+9 more)

### Community 95 - "Dashboard Data Queries"
Cohesion: 0.12
Nodes (15): achievement, Bar, _bars, DashboardDb, Figures, hasAnySale, monthlySales, paymentModes (+7 more)

### Community 96 - "Database Schema Migration"
Cohesion: 0.29
Nodes (6): ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, MigrationStrategy get, package:drift_flutter/drift_flutter.dart

### Community 97 - "Dashboard UI Tests"
Cohesion: 0.08
Nodes (24): package:rx_merchant/features/dashboard/ui/dashboard_screen.dart, package:rx_merchant/features/dashboard/ui/sales_report_pages.dart, package:rx_merchant/features/pos/data/pos_db.dart, ../../pos/data/pos_db_test.dart, ../../pos/ui/pos_ui_test.dart, db, home, main (+16 more)

### Community 98 - "POS Cart Forms"
Cohesion: 0.13
Nodes (27): build, _ReturnFormState, build, CartPanel, _LinePadState, _changed, _ItemSelectorState, _submit (+19 more)

### Community 99 - "Refusal Exceptions"
Cohesion: 0.14
Nodes (14): Exception, all, args, detail, _foreignKey, _primaryKey, reason, Refusal (+6 more)

### Community 100 - "Invoice Print Page"
Cohesion: 0.08
Nodes (25): invoice_pdf.dart, PrintSettings, address, createState, doc, _format, invoiceId, l (+17 more)

### Community 101 - "Invoice Database Tests"
Cohesion: 0.08
Nodes (23): package:rx_merchant/features/dashboard/data/dashboard_db.dart, package:rx_merchant/features/invoices/data/invoice_db.dart, package:rx_merchant/features/invoices/data/print_masters.dart, package:rx_merchant/features/invoices/data/returns_db.dart, package:rx_merchant/features/invoices/logic/returns.dart, package:rx_merchant/features/pos/logic/sale.dart, package:rx_merchant/features/pos/logic/totals.dart, package:rx_merchant/features/stock/logic/stock_documents.dart (+15 more)

### Community 104 - "Invoice List Screen"
Cohesion: 0.10
Nodes (21): invoice_detail.dart, invoiceListProvider, build, createState, dispose, _filters, id, InvoiceList (+13 more)

### Community 105 - "Invoice PDF Rendering"
Cohesion: 0.10
Nodes (19): bold, doc, footer, header, invoiceDocument, loadPdfFonts, logo, of (+11 more)

### Community 106 - "Sales Return Form"
Cohesion: 0.11
Nodes (18): _apply, createState, _draft, _error, initState, _line, _lines, _name (+10 more)

### Community 107 - "POS Opening Form"
Cohesion: 0.13
Nodes (15): core/widgets/window_size.dart, ../data/pos_closing_db.dart, ../data/pos_db.dart, SaleLine, line, onClose, _amounts, createState (+7 more)

### Community 108 - "Invoice Queries"
Cohesion: 0.12
Nodes (16): from, hashCode, InvoiceFilters, invoiceIdByName, invoiceView, _line, of, operator (+8 more)

### Community 109 - "Receipt Text Layout"
Cohesion: 0.12
Nodes (16): center, indent, last, left, line, lines, out, pair (+8 more)

### Community 110 - "Invoice Detail View"
Cohesion: 0.12
Nodes (15): ../../../core/numbers/formats.dart, ../data/returns_db.dart, invoice_providers.dart, Invoice, _cancel, doc, id, inv (+7 more)

### Community 111 - "Database Backup & Restore"
Cohesion: 0.12
Nodes (15): File, backupDirectory, Backups, checkRestorable, close, databasePath, out, restoreDatabase (+7 more)

### Community 112 - "Returns & Cancellation"
Cohesion: 0.12
Nodes (15): _batchesFit, cancelInvoice, _returnable, ReturnDraft, _returned, returnProblems, salesReturnType, _serialsAvailable (+7 more)

### Community 113 - "Return Scaling Logic"
Cohesion: 0.14
Nodes (13): f, method, need, out, ReturnBasis, returned, scaleReturn, share (+5 more)

### Community 114 - "POS Closing Database"
Cohesion: 0.15
Nodes (12): ../../../core/naming/naming_series.dart, cancellableClosing, cancelLastClosing, changeModeOf, ClosingDraft, _heldOrders, PosClosingDb, posClosingType (+4 more)

### Community 115 - "Print Settings Providers"
Cohesion: 0.19
Nodes (13): build, InvoiceDetail, invoiceViewProvider, build, pdfFontsProvider, printAfterSale, _PrintPageState, printSettingsProvider (+5 more)

### Community 116 - "Barcode Scanner"
Cohesion: 0.20
Nodes (10): ../../../core/widgets/child_table.dart, build, createState, _done, onScanned, scanBarcode, ScanButton, _ScanSheet (+2 more)

### Community 117 - "Print Layout Tests"
Cohesion: 0.18
Nodes (10): package:rx_merchant/features/invoices/logic/escpos.dart, package:rx_merchant/features/invoices/logic/invoice.dart, package:rx_merchant/features/invoices/logic/receipt_text.dart, _invoice, itemName, _layout, main, _options (+2 more)

### Community 118 - "Print Masters Settings"
Cohesion: 0.20
Nodes (9): ../../../core/numbers/format.dart, _followRename, _now, PrintMasters, saveLetterHead, savePrintHeading, saveTerms, _Value (+1 more)

### Community 119 - "Invoice PDF Generation"
Cohesion: 0.20
Nodes (9): dart:io, package:pdf/pdf.dart, package:pdf/widgets.dart, package:rx_merchant/features/invoices/logic/print_layout.dart, package:rx_merchant/features/invoices/ui/invoice_pdf.dart, _doc, font, _fonts (+1 more)

### Community 120 - "Link Field Widget"
Cohesion: 0.20
Nodes (9): package:rx_merchant/core/widgets/link_field.dart, String?, cleared, created, field, groups, main, picked (+1 more)

### Community 121 - "Naming Series Generator"
Cohesion: 0.22
Nodes (8): counter, DefaultSeries, NamingSeries, nextName, parseSeries, resolved, two, package:drift/drift.dart

### Community 122 - "Invoice Providers and Routes"
Cohesion: 0.25
Nodes (7): ../../../core/db/app_database.dart, ../data/invoice_db.dart, db, invoicePath, invoicesLink, invoicesPath, returnPath

### Community 123 - "App Root Bootstrap"
Cohesion: 0.40
Nodes (6): App, build, systemSettingsProvider, build, _LoadingScreen, routerProvider

## Knowledge Gaps
- **1753 isolated node(s):** `abbr`, `actionOnNewInvoice`, `addDraftHeading`, `allowDiscountChange`, `allowNegativeStock` (+1748 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1927 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_return` connect `System Settings Singletons` to `App Feature Screens`, `Data Import Columns`, `ESC/POS Printing`, `Form Kit Widgets`, `Tax Template Logic`, `Setup Database Tests`, `Stock Document Lines`, `Stock Database Tests`, `Item & Tax Page Widgets`, `Stock Rules`, `Stock UI Tests`, `Item Variant Combinations`, `POS Providers`, `Dashboard Periods`, `POS Database Tests`, `Order Summary & Payment`, `Item Selector`, `Amount In Words`, `POS UI Tests`, `Dashboard UI Tests`, `Invoice PDF Rendering`, `Receipt Text Layout`, `Return Scaling Logic`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Why does `_int` connect `Sales Analytics Reports` to `Singles Settings Fields`, `Stock Entry Form`, `Sale Cart Model`, `Invoice List Screen`, `Stock Master Pages`, `Stock Reconciliation Page`, `Invoice Queries`, `Stock Document Lines`, `POS Screen`, `POS Input Widgets`, `Item Tax Template Pages`, `Order Summary & Payment`, `Item Selector`, `Stock Report Queries`, `Stock Report Pages`, `Item Group Tree`, `Tax Template Logic`, `Item Form Page`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `App Database Accessors` to `Database Schema Migration`, `System Settings Singletons`, `Setup Database Tests`, `Setup Seed Data`, `Database Backup & Restore`, `POS Closing Database`, `Print Masters Settings`, `Naming Series Generator`, `Data Import Database`, `Stock Reconciliation Database`, `Stock List Queries`, `Dashboard Data Queries`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `abbr`, `actionOnNewInvoice`, `addDraftHeading` to the rest of the system?**
  _1753 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Singles Settings Fields` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `Report Table Widget` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `App Feature Screens` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
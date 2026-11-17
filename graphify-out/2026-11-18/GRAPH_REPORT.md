# Graph Report - rx_merchant  (2026-11-17)

## Corpus Check
- 84 files · ~60,408 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1610 nodes · 2519 edges · 81 communities (73 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `65f427ab`
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
- List
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
- data_import_db.dart
- stock_entry_page.dart
- State
- formatsProvider
- appDatabaseProvider
- StatelessWidget
- setup_db_test.dart
- package:drift/drift.dart
- AppDatabase
- stock_masters_pages.dart
- ../../../core/db/app_database.dart
- stock_reconciliation_page.dart
- ConsumerWidget
- stock_logic_test.dart
- serial_batch_editor.dart
- stock_documents.dart
- build
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
- setup_screen.dart
- stock_screen.dart
- stock_reconciliation_db.dart
- stock_lists.dart
- status_chip_test.dart
- stock_ui_test.dart
- date_field.dart
- scan.dart
- String?
- providers.dart
- typedef
- child_table.dart
- build
- package:go_router/go_router.dart
- list_detail_pane.dart
- serials.dart
- l10n/app_localizations.dart
- package:flutter_riverpod/flutter_riverpod.dart
- Batches
- _ItemTaxRowEditor
- _CostEditor
- _ValueEditor

## God Nodes (most connected - your core abstractions)
1. `appDatabaseProvider` - 60 edges
2. `formatsProvider` - 41 edges
3. `warehousesProvider` - 23 edges
4. `itemRowsProvider` - 23 edges
5. `AppDatabase` - 20 edges
6. `build` - 17 edges
7. `stockSettingsProvider` - 16 edges
8. `uomsProvider` - 15 edges
9. `build` - 13 edges
10. `_ItemFormState` - 12 edges

## Surprising Connections (you probably didn't know these)
- `Backups` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/backup.dart → lib/core/db/app_database.dart
- `SetupSeed` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/seed.dart → lib/core/db/app_database.dart
- `StockLists` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/stock/data/stock_lists.dart → lib/core/db/app_database.dart
- `_save` --references--> `appDatabaseProvider`  [EXTRACTED]
  lib/features/setup/ui/naming_series_page.dart → lib/core/db/providers.dart
- `_updateSeries` --references--> `appDatabaseProvider`  [EXTRACTED]
  lib/features/setup/ui/naming_series_page.dart → lib/core/db/providers.dart

## Import Cycles
- None detected.

## Communities (81 total, 5 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (78): double get, abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft (+70 more)

### Community 1 - "report_table.dart"
Cohesion: 0.07
Nodes (27): _body, build, columns, createState, dispose, emptyText, _export, exportName (+19 more)

### Community 2 - "router.dart"
Cohesion: 0.07
Nodes (31): core/db/providers.dart, core/widgets/adaptive_shell.dart, core/widgets/window_size.dart, features/setup/ui/setup_screen.dart, features/setup/ui/wizard_screen.dart, features/stock/ui/stock_providers.dart, features/stock/ui/stock_screen.dart, GoRouter (+23 more)

### Community 3 - "package:material_ui/material_ui.dart"
Cohesion: 0.12
Nodes (15): compact,

  
  medium,, expanded, of, WindowSize, package:material_ui/material_ui.dart, package:rx_merchant/core/widgets/child_table.dart, package:rx_merchant/core/widgets/list_detail_pane.dart, package:rx_merchant/core/widgets/report_table.dart (+7 more)

### Community 4 - "formats.dart"
Cohesion: 0.12
Nodes (15): CurrencyData?, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, currency, date, defaults (+7 more)

### Community 5 - "format.dart"
Cohesion: 0.08
Nodes (25): cut, decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber (+17 more)

### Community 6 - "link_field.dart"
Cohesion: 0.18
Nodes (10): build, errorText, label, LinkField, mandatory, onChanged, onCreateNew, value (+2 more)

### Community 7 - "app_test.dart"
Cohesion: 0.17
Nodes (11): ListTile, NavigationDestination, NavigationRail, package:rx_merchant/core/db/providers.dart, required double width,
  bool, db, main, pumpAndSettle (+3 more)

### Community 8 - "batch_table.dart"
Cohesion: 0.13
Nodes (14): IntColumn get, batchId, createdAt, disabled, expiryDate, id, itemId, manufacturingDate (+6 more)

### Community 9 - "valuation.dart"
Cohesion: 0.06
Nodes (32): dart:math, fifo,
  movingAverage,, flt, fromSetting, method, _relativeError, rounded, RoundingMethod (+24 more)

### Community 10 - "spacing.dart"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.14
Nodes (12): package:flutter_test/flutter_test.dart, package:rx_merchant/core/numbers/flt.dart, package:rx_merchant/core/numbers/format.dart, package:rx_merchant/features/setup/logic/tax_template.dart, bankers, commercial, main, main (+4 more)

### Community 17 - "data_import.dart"
Cohesion: 0.04
Nodes (52): barcode, barcodes, barcodeType, brand, brands, Col, ColumnKind, columns (+44 more)

### Community 18 - "settings_pages.dart"
Cohesion: 0.07
Nodes (30): ../../../core/widgets/date_field.dart, Iterable, createState, dateFormats, db, doctype, _enabledPriceListsProvider, FieldKind (+22 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.05
Nodes (39): class, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled, dispose (+31 more)

### Community 20 - "List"
Cohesion: 0.18
Nodes (10): args, detail, _foreignKey, _primaryKey, reason, Refusal, toString, _unique (+2 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.08
Nodes (30): CurrencyCompanion?, FormState, storeCurrencyProvider, build, _choice, createState, CurrencyPage, _CurrencyPageState (+22 more)

### Community 22 - "country_info.dart"
Cohesion: 0.08
Nodes (24): dart:convert, ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, bytes, code, CountryInfo (+16 more)

### Community 23 - "data_pages.dart"
Cohesion: 0.06
Nodes (34): ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, BackupsPage, _BackupsPageState, _backupsProvider, _body (+26 more)

### Community 24 - "setup_queries.dart"
Cohesion: 0.09
Nodes (21): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, exists, highestUsedNumber, itemTaxTemplateRows (+13 more)

### Community 25 - "form_kit.dart"
Cohesion: 0.06
Nodes (30): AsyncValue, ../data/refusal.dart, GlobalKey, a, actions, attempt, build, children (+22 more)

### Community 26 - "tax_template.dart"
Cohesion: 0.09
Nodes (21): bool get, ChargeType, description, effectiveRate, included, isPreviousRow, method, of (+13 more)

### Community 27 - "wizard_screen.dart"
Cohesion: 0.09
Nodes (23): ../../../core/widgets/link_field.dart, ../data/country_info.dart, _abbr, _abbrEdited, _busy, _canGoOn, _country, createState (+15 more)

### Community 28 - "naming_series_page.dart"
Cohesion: 0.10
Nodes (24): ../data/seed.dart, ../data/setup_queries.dart, form_kit.dart, build, createState, current, db, digits (+16 more)

### Community 29 - "item_pages.dart"
Cohesion: 0.03
Nodes (72): int? _shelfLife,, ItemData?, _attributes, _Barcode, _barcodes, _batchSeries, _code, _combos (+64 more)

### Community 30 - "backup.dart"
Cohesion: 0.12
Nodes (15): File, backupDirectory, Backups, checkRestorable, close, databasePath, out, restoreDatabase (+7 more)

### Community 31 - "data_import_db.dart"
Cohesion: 0.17
Nodes (11): ../../../core/numbers/format.dart, double d when, _cell, d, exportRows, _ids, ImportLogLine, importLookups (+3 more)

### Community 32 - "stock_entry_page.dart"
Cohesion: 0.04
Nodes (48): int? _from,, _act, _allowZero, _amount, _costs, createState, db, _description (+40 more)

### Community 33 - "State"
Cohesion: 0.13
Nodes (22): MasterList, _MasterListState, _TaxRowEditor, _TaxRowEditorState, _AttributeEditor, _AttributeEditorState, _BarcodeEditor, _BarcodeEditorState (+14 more)

### Community 34 - "formatsProvider"
Cohesion: 0.10
Nodes (35): ConsumerState, ConsumerStatefulWidget, formatsProvider, DataExportPage, _DataExportPageState, DataImportPage, _DataImportPageState, _field (+27 more)

### Community 35 - "appDatabaseProvider"
Cohesion: 0.10
Nodes (25): appDatabaseProvider, restoreAndReopen, _start, _save, initState, _save, _load, _save (+17 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.15
Nodes (13): _RecordTypePicker, FieldGrid, FormPage, LockNote, SectionHeading, SetupHome, SetupScreen, NumberField (+5 more)

### Community 37 - "setup_db_test.dart"
Cohesion: 0.09
Nodes (23): dart:io, package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/data_import_db.dart (+15 more)

### Community 38 - "package:drift/drift.dart"
Cohesion: 0.33
Nodes (5): package:drift/drift.dart, db, main, namesOf, specTables

### Community 39 - "AppDatabase"
Cohesion: 0.10
Nodes (20): _, @DriftDatabase, ../db/app_database.dart, AppDatabase, SinglesAccess, counter, DefaultSeries, NamingSeries (+12 more)

### Community 40 - "stock_masters_pages.dart"
Cohesion: 0.04
Nodes (45): BatchRow?, BrandData, ItemAttributeData?, ItemPriceData?, _abbr, attribute, batch, _batchId (+37 more)

### Community 41 - "../../../core/db/app_database.dart"
Cohesion: 0.22
Nodes (8): ../../../core/db/app_database.dart, ../../../core/db/singles.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, SetupSeed, _wholeNumberUoms

### Community 42 - "stock_reconciliation_page.dart"
Cohesion: 0.05
Nodes (37): ../../../core/widgets/status_chip.dart, ../data/stock_entry_db.dart, ../data/stock_reconciliation_db.dart, _act, _at, createState, _csvHeader, _currentQty (+29 more)

### Community 43 - "ConsumerWidget"
Cohesion: 0.12
Nodes (36): ConsumerWidget, _FormatPreview, PriceListPage, priceListsProvider, _inventory, _VariantList, build, _FilterBar (+28 more)

### Community 44 - "stock_logic_test.dart"
Cohesion: 0.12
Nodes (15): package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, package:rx_merchant/features/stock/logic/serials.dart, package:rx_merchant/features/stock/logic/stock_rules.dart, package:rx_merchant/features/stock/logic/valuation.dart, package:rx_merchant/features/stock/logic/variants.dart, item, kinds (+7 more)

### Community 45 - "serial_batch_editor.dart"
Cohesion: 0.06
Nodes (32): ../../../core/numbers/formats.dart, _add, _batch, build, _changed, createState, _csvHeader, dispose (+24 more)

### Community 46 - "stock_documents.dart"
Cohesion: 0.06
Nodes (32): allowZero, basicRate, batchNo, currentQty, currentRate, entries, EntryLine, factor (+24 more)

### Community 47 - "build"
Cohesion: 0.67
Nodes (3): build, SalesTaxesTemplatePage, salesTaxesTemplatesProvider

### Community 48 - "barcode.dart"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

### Community 49 - "stock_db_test.dart"
Cohesion: 0.06
Nodes (30): Exception, int? to,
  List, RefusedException, ItemTables, package:rx_merchant/features/stock/data/stock_entry_db.dart, package:rx_merchant/features/stock/data/stock_ledger.dart, package:rx_merchant/features/stock/data/stock_masters.dart, package:rx_merchant/features/stock/data/stock_reconciliation_db.dart (+22 more)

### Community 50 - "report_pages.dart"
Cohesion: 0.07
Nodes (28): ../../../core/widgets/report_table.dart, ../data/stock_ledger.dart, Future, _Col, createState, _date, _f, _Filter (+20 more)

### Community 51 - "tree_masters.dart"
Cohesion: 0.07
Nodes (28): ../data/stock_masters.dart, ItemGroupData?, all, createState, _disabled, dispose, _flat, _formKey (+20 more)

### Community 52 - "stock_entry_db.dart"
Cohesion: 0.07
Nodes (26): amendedName, amendStockEntry, availableEntries, cancelStockEntry, _checkEntries, _clearLines, createBatch, currencyPrecision (+18 more)

### Community 53 - "stock_masters.dart"
Cohesion: 0.08
Nodes (24): _checkBarcodes, _checkDefaultWarehouse, _checkItemChange, createVariants, _defaultWarehouseName, deleteWarehouse, hasLedger, itemTaxTemplateOf (+16 more)

### Community 54 - "stock_reports.dart"
Cohesion: 0.08
Nodes (23): _int, batchBalanceReport, batchId, from, itemGroupId, itemId, itemPriceStockReport, _lowStock (+15 more)

### Community 55 - "stock_providers.dart"
Cohesion: 0.10
Nodes (20): dart:typed_data, ../data/stock_lists.dart, ../data/stock_reports.dart, StockSettings, _Strip, _Thumbnail, b, db (+12 more)

### Community 56 - "stock_rules.dart"
Cohesion: 0.11
Nodes (18): base, BatchStatus, best, defaultExpiry, given, isWhole, itemTaxTemplateFor, left (+10 more)

### Community 57 - "stock_ledger.dart"
Cohesion: 0.11
Nodes (17): cancelLedger, Chain, Changes, checkNotFrozen, _never, _passOnTransferRates, postLedger, rebuildBins (+9 more)

### Community 58 - "build"
Cohesion: 0.18
Nodes (17): ItemTaxTemplatePage, itemTaxTemplatesProvider, build, _details, _ItemForm, _ItemFormState, ItemPage, _Tax (+9 more)

### Community 59 - "setup_screen.dart"
Cohesion: 0.12
Nodes (15): ../../../core/widgets/list_detail_pane.dart, ../../../core/widgets/spacing.dart, data_pages.dart, build, id, page, path, selected (+7 more)

### Community 60 - "stock_screen.dart"
Cohesion: 0.12
Nodes (15): item_pages.dart, id, page, path, query, selected, stockPage, stockPath (+7 more)

### Community 61 - "stock_reconciliation_db.dart"
Cohesion: 0.13
Nodes (14): ../../../core/naming/naming_series.dart, amendStockReconciliation, cancelStockReconciliation, fetchItems, fillCurrent, reconciliationLines, saveStockReconciliation, stockReconciliationType (+6 more)

### Community 62 - "stock_lists.dart"
Cohesion: 0.14
Nodes (13): BatchListRow, idByName, ItemRow, PriceRow, SerialListRow, StockLists, StripChip, valuationMethodLocked (+5 more)

### Community 63 - "status_chip_test.dart"
Cohesion: 0.15
Nodes (11): Chip, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/status_chip.dart, package:rx_merchant/l10n/app_localizations.dart, pumpAndSettle, pumpInApp, pumpWidget, width (+3 more)

### Community 64 - "stock_ui_test.dart"
Cohesion: 0.15
Nodes (12): ../data/stock_db_test.dart, package:rx_merchant/features/stock/logic/stock_documents.dart, ../../setup/data/setup_db_test.dart, db, height, main, pumpAndSettle, pumpStock (+4 more)

### Community 65 - "date_field.dart"
Cohesion: 0.17
Nodes (11): build, DateField, enabled, formats, label, mandatory, onChanged, _pick (+3 more)

### Community 66 - "scan.dart"
Cohesion: 0.20
Nodes (9): ../../../core/widgets/child_table.dart, build, createState, _done, onScanned, scanBarcode, ScanButton, package:mobile_scanner/mobile_scanner.dart (+1 more)

### Community 67 - "String?"
Cohesion: 0.20
Nodes (9): package:rx_merchant/core/widgets/link_field.dart, String?, cleared, created, field, groups, main, picked (+1 more)

### Community 68 - "providers.dart"
Cohesion: 0.22
Nodes (8): app_database.dart, code, db, SystemSettings, Formats, ../numbers/formats.dart, return, singles.dart

### Community 69 - "typedef"
Cohesion: 0.22
Nodes (8): ../../../core/numbers/flt.dart, AttributeValue, combinations, numericValues, plainNumber, r, variantCode, typedef

### Community 70 - "child_table.dart"
Cohesion: 0.22
Nodes (8): build, ChildTable, _edit, readOnly, rows, _sideSheetRadius, _sideSheetWidth, R

### Community 71 - "build"
Cohesion: 0.32
Nodes (8): singleProvider, build, countryInfoProvider, GlobalDefaultsPage, StoreProfilePage, submittedProvider, SystemSettingsPage, build

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

### Community 76 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.50
Nodes (3): app.dart, main, package:flutter_riverpod/flutter_riverpod.dart

### Community 77 - "Batches"
Cohesion: 0.67
Nodes (3): @DataClassName, Batches, Table

## Knowledge Gaps
- **1059 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+1054 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1179 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_int` connect `stock_reports.dart` to `singles.dart`, `stock_entry_page.dart`, `stock_masters_pages.dart`, `stock_reconciliation_page.dart`, `stock_documents.dart`, `report_pages.dart`, `tax_template_pages.dart`, `tree_masters.dart`, `tax_template.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `Formats` connect `providers.dart` to `stock_entry_page.dart`, `date_field.dart`, `formats.dart`, `serial_batch_editor.dart`, `tax_template_pages.dart`, `item_pages.dart`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _1059 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07007575757575757 - nodes in this community are weakly interconnected._
- **Should `package:material_ui/material_ui.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11695906432748537 - nodes in this community are weakly interconnected._
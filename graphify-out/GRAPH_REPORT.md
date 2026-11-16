# Graph Report - rx_merchant  (2026-11-16)

## Corpus Check
- 60 files · ~26,610 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 860 nodes · 1177 edges · 46 communities (41 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d5b4836b`
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
- flt.dart
- spacing.dart
- package:flutter_test/flutter_test.dart
- MainActivity.kt
- rx_merchant
- data_import.dart
- settings_pages.dart
- tax_template_pages.dart
- refusal.dart
- simple_masters.dart
- country_info.dart
- data_pages.dart
- setup_queries.dart
- form_kit.dart
- tax_template.dart
- wizard_screen.dart
- naming_series_page.dart
- backup.dart
- data_import_db.dart
- State
- ConsumerState
- appDatabaseProvider
- StatelessWidget
- setup_db_test.dart
- schema_test.dart
- AppDatabase
- CLAUDE.md
- ../../../core/db/app_database.dart
- import_backup_test.dart
- singles_test.dart
- data_import_test.dart
- package:drift/drift.dart
- build
- barcode.dart

## God Nodes (most connected - your core abstractions)
1. `appDatabaseProvider` - 24 edges
2. `AppDatabase` - 12 edges
3. `formatsProvider` - 12 edges
4. `build` - 8 edges
5. `build` - 7 edges
6. `_BackupsPageState` - 6 edges
7. `_NamingSeriesPageState` - 6 edges
8. `countryInfoProvider` - 6 edges
9. `_CurrencyPageState` - 6 edges
10. `taxesProvider` - 6 edges

## Surprising Connections (you probably didn't know these)
- `NamingSeries` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/naming/naming_series.dart → lib/core/db/app_database.dart
- `SinglesAccess` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/db/singles.dart → lib/core/db/app_database.dart
- `Backups` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/backup.dart → lib/core/db/app_database.dart
- `DataImportDb` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/data_import_db.dart → lib/core/db/app_database.dart
- `SetupSeed` --extends--> `AppDatabase`  [EXTRACTED]
  lib/features/setup/data/seed.dart → lib/core/db/app_database.dart

## Import Cycles
- None detected.

## Communities (46 total, 2 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (79): double get, abbr, actionOnNewInvoice, addDraftHeading, allowDiscountChange, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft (+71 more)

### Community 1 - "report_table.dart"
Cohesion: 0.06
Nodes (29): build, ChildTable, _edit, readOnly, rows, _sideSheetRadius, _sideSheetWidth, build (+21 more)

### Community 2 - "router.dart"
Cohesion: 0.05
Nodes (40): app.dart, app_database.dart, core/db/providers.dart, core/widgets/adaptive_shell.dart, core/widgets/window_size.dart, features/setup/ui/setup_screen.dart, features/setup/ui/wizard_screen.dart, GoRouter (+32 more)

### Community 3 - "package:material_ui/material_ui.dart"
Cohesion: 0.05
Nodes (35): Chip, compact,

  
  medium,, expanded, of, WindowSize, package:material_ui/material_ui.dart, package:rx_merchant/app.dart, package:rx_merchant/core/widgets/child_table.dart (+27 more)

### Community 4 - "formats.dart"
Cohesion: 0.08
Nodes (22): CurrencyData?, ../db/app_database.dart, ../db/singles.dart, flt.dart, format.dart, GlobalDefaults, counter, NamingSeries (+14 more)

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
Cohesion: 0.11
Nodes (17): @DataClassName, IntColumn get, Batches, batchId, createdAt, disabled, expiryDate, id (+9 more)

### Community 9 - "flt.dart"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

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
Cohesion: 0.06
Nodes (44): ConsumerWidget, ../../../core/numbers/formats.dart, Iterable, formatsProvider, singleProvider, build, countryInfoProvider, createState (+36 more)

### Community 19 - "tax_template_pages.dart"
Cohesion: 0.05
Nodes (40): class, ../../../core/widgets/child_table.dart, ItemTaxTemplateData?, _amount, createState, db, _description, _disabled (+32 more)

### Community 20 - "refusal.dart"
Cohesion: 0.17
Nodes (11): Exception, detail, _foreignKey, _primaryKey, reason, Refusal, RefusedException, toString (+3 more)

### Community 21 - "simple_masters.dart"
Cohesion: 0.08
Nodes (31): CurrencyCompanion?, FormState, storeCurrencyProvider, build, _choice, createState, CurrencyPage, _CurrencyPageState (+23 more)

### Community 22 - "country_info.dart"
Cohesion: 0.11
Nodes (18): dart:convert, bytes, code, CountryInfo, currency, currencyName, currencyPrecision, dateFormat (+10 more)

### Community 23 - "data_pages.dart"
Cohesion: 0.07
Nodes (29): dart:typed_data, ../data/backup.dart, ../data/data_import_db.dart, ImportRecordType, ImportType, _body, _busy, _chooseFile (+21 more)

### Community 24 - "setup_queries.dart"
Cohesion: 0.09
Nodes (21): addCurrency, anySubmittedDocument, _checkPriceLists, _defaultPriceListName, deleteMaster, _exists, highestUsedNumber, itemTaxTemplateRows (+13 more)

### Community 25 - "form_kit.dart"
Cohesion: 0.08
Nodes (23): AsyncValue, ../data/refusal.dart, GlobalKey, actions, attempt, build, children, confirm (+15 more)

### Community 26 - "tax_template.dart"
Cohesion: 0.08
Nodes (23): bool get, ../../../core/numbers/flt.dart, _int, ChargeType, description, effectiveRate, included, isPreviousRow (+15 more)

### Community 27 - "wizard_screen.dart"
Cohesion: 0.05
Nodes (45): ../../../core/widgets/link_field.dart, ../../../core/widgets/list_detail_pane.dart, ../../../core/widgets/spacing.dart, ../data/country_info.dart, data_pages.dart, l10n/app_localizations.dart, AdaptiveShell, build (+37 more)

### Community 28 - "naming_series_page.dart"
Cohesion: 0.10
Nodes (22): ../../../core/naming/naming_series.dart, ../data/seed.dart, ../data/setup_queries.dart, form_kit.dart, build, createState, current, db (+14 more)

### Community 30 - "backup.dart"
Cohesion: 0.14
Nodes (13): File, backupDirectory, checkRestorable, close, databasePath, out, restoreDatabase, _stamp (+5 more)

### Community 31 - "data_import_db.dart"
Cohesion: 0.15
Nodes (12): ../../../core/numbers/format.dart, double d when, _cell, d, exportRows, _ids, ImportLogLine, importLookups (+4 more)

### Community 33 - "State"
Cohesion: 0.32
Nodes (8): MasterList, _MasterListState, _ItemTaxRowEditor, _ItemTaxRowEditorState, _TaxRowEditor, _TaxRowEditorState, State, StatefulWidget

### Community 34 - "ConsumerState"
Cohesion: 0.21
Nodes (13): ConsumerState, ConsumerStatefulWidget, DataExportPage, _DataExportPageState, DataImportPage, _DataImportPageState, NamingSeriesPage, _ItemTaxTemplateForm (+5 more)

### Community 35 - "appDatabaseProvider"
Cohesion: 0.17
Nodes (13): appDatabaseProvider, BackupsPage, _BackupsPageState, _backupsProvider, build, restoreAndReopen, _start, _save (+5 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _RecordTypePicker, FieldGrid, FormPage, LockNote, SectionHeading, SetupHome, SetupScreen, NumberField (+3 more)

### Community 37 - "setup_db_test.dart"
Cohesion: 0.20
Nodes (9): package:rx_merchant/features/setup/data/country_info.dart, package:rx_merchant/features/setup/data/seed.dart, package:rx_merchant/features/setup/data/setup_queries.dart, completeSetup, db, main, philippines, refused (+1 more)

### Community 38 - "schema_test.dart"
Cohesion: 0.22
Nodes (8): package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/naming/naming_series.dart, db, main, namesOf, specTables, main

### Community 39 - "AppDatabase"
Cohesion: 0.25
Nodes (8): _, @DriftDatabase, AppDatabase, SinglesAccess, Backups, DataImportDb, SetupSeed, SetupQueries

### Community 40 - "CLAUDE.md"
Cohesion: 0.25
Nodes (7): Code Review, Codebase Navigation, Commits, Documentation, Expected AI Response, Finalization, Tool Calling

### Community 41 - "../../../core/db/app_database.dart"
Cohesion: 0.25
Nodes (7): ../../../core/db/app_database.dart, ../../../core/db/singles.dart, country_info.dart, completeSetup, defaultNamingSeries, _fractionalUoms, _wholeNumberUoms

### Community 42 - "import_backup_test.dart"
Cohesion: 0.25
Nodes (7): dart:io, package:rx_merchant/features/setup/data/backup.dart, package:rx_merchant/features/setup/data/data_import_db.dart, package:rx_merchant/features/setup/data/refusal.dart, package:sqlite3/sqlite3.dart, setup_db_test.dart, main

### Community 43 - "singles_test.dart"
Cohesion: 0.50
Nodes (3): package:rx_merchant/core/db/singles.dart, db, main

### Community 44 - "data_import_test.dart"
Cohesion: 0.29
Nodes (6): package:rx_merchant/features/setup/logic/data_import.dart, package:rx_merchant/features/stock/logic/barcode.dart, item, kinds, lookups, main

### Community 45 - "package:drift/drift.dart"
Cohesion: 0.25
Nodes (7): ../../features/stock/data/batch_table.dart, int get, migration, schemaVersion, MigrationStrategy get, package:drift/drift.dart, package:drift_flutter/drift_flutter.dart

### Community 47 - "build"
Cohesion: 0.40
Nodes (5): build, ItemTaxTemplatePage, itemTaxTemplatesProvider, SalesTaxesTemplatePage, salesTaxesTemplatesProvider

### Community 48 - "barcode.dart"
Cohesion: 0.40
Nodes (4): _checkDigitOk, digitsOnly, sum, validBarcode

## Knowledge Gaps
- **543 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+538 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 630 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Formats` connect `router.dart` to `tax_template_pages.dart`, `formats.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `_int` connect `tax_template.dart` to `singles.dart`, `tax_template_pages.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `AppDatabase` to `router.dart`, `formats.dart`, `schema_test.dart`, `singles_test.dart`, `package:drift/drift.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _543 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05391120507399577 - nodes in this community are weakly interconnected._
# Graph Report - rx_merchant  (2026-11-15)

## Corpus Check
- 37 files · ~8,396 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 337 nodes · 392 edges · 17 communities (12 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fafec23c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- singles.dart
- report_table.dart
- router.dart
- package:material_ui/material_ui.dart
- schema_test.dart
- format.dart
- link_field.dart
- app_test.dart
- batch_table.dart
- flt.dart
- spacing.dart
- flt_test.dart
- MainActivity.kt
- rx_merchant

## God Nodes (most connected - your core abstractions)
1. `AppDatabase` - 8 edges
2. `App` - 3 edges
3. `appDatabaseProvider` - 3 edges
4. `systemSettingsProvider` - 3 edges
5. `WizardScreen` - 3 edges
6. `Batches` - 3 edges
7. `_LoadingScreen` - 3 edges
8. `routerProvider` - 3 edges
9. `MainActivity` - 2 edges
10. `build` - 2 edges

## Surprising Connections (you probably didn't know these)
- `SinglesAccess` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/db/singles.dart → lib/core/db/app_database.dart
- `NamingSeries` --extends--> `AppDatabase`  [EXTRACTED]
  lib/core/naming/naming_series.dart → lib/core/db/app_database.dart
- `App` --references--> `routerProvider`  [EXTRACTED]
  lib/app.dart → lib/router.dart
- `build` --references--> `routerProvider`  [EXTRACTED]
  lib/app.dart → lib/router.dart
- `build` --references--> `appDatabaseProvider`  [EXTRACTED]
  lib/features/setup/ui/wizard_screen.dart → lib/core/db/providers.dart

## Import Cycles
- None detected.

## Communities (17 total, 2 thin omitted)

### Community 0 - "singles.dart"
Cohesion: 0.03
Nodes (67): bool get, double get, abbr, addDraftHeading, allowNegativeStock, allowPrintForCancelled, allowPrintForDraft, autoCreateSerialAndBatchBundleForOutward (+59 more)

### Community 1 - "report_table.dart"
Cohesion: 0.05
Nodes (43): dart:io, l10n/app_localizations.dart, AdaptiveShell, build, _go, navigationShell, build, ChildTable (+35 more)

### Community 2 - "router.dart"
Cohesion: 0.06
Nodes (39): app.dart, app_database.dart, ConsumerWidget, core/db/providers.dart, ../../../core/db/singles.dart, core/widgets/adaptive_shell.dart, ../../../core/widgets/spacing.dart, features/setup/ui/wizard_screen.dart (+31 more)

### Community 3 - "package:material_ui/material_ui.dart"
Cohesion: 0.07
Nodes (29): Chip, compact,

  
  medium,, expanded, of, WindowSize, package:flutter_test/flutter_test.dart, package:material_ui/material_ui.dart, package:rx_merchant/app.dart (+21 more)

### Community 4 - "schema_test.dart"
Cohesion: 0.09
Nodes (22): _, @DriftDatabase, ../db/app_database.dart, ../../features/stock/data/batch_table.dart, int get, AppDatabase, migration, schemaVersion (+14 more)

### Community 5 - "format.dart"
Cohesion: 0.09
Nodes (22): decimalPart, decimalSeparator, dot, fixed, formatCurrency, formatDate, formatNumber, formatTime (+14 more)

### Community 6 - "link_field.dart"
Cohesion: 0.10
Nodes (19): build, errorText, label, mandatory, onChanged, onCreateNew, value, package:rx_merchant/core/widgets/link_field.dart (+11 more)

### Community 7 - "app_test.dart"
Cohesion: 0.12
Nodes (17): NavigationDestination, NavigationRail, package:drift/native.dart, package:rx_merchant/core/db/app_database.dart, package:rx_merchant/core/db/providers.dart, package:rx_merchant/core/db/singles.dart, package:rx_merchant/core/naming/naming_series.dart, required double width,
  bool (+9 more)

### Community 8 - "batch_table.dart"
Cohesion: 0.11
Nodes (17): @DataClassName, IntColumn get, Batches, batchId, createdAt, disabled, expiryDate, id (+9 more)

### Community 9 - "flt.dart"
Cohesion: 0.17
Nodes (11): dart:math, flt, fromSetting, method, _relativeError, rounded, RoundingMethod, scale (+3 more)

### Community 10 - "spacing.dart"
Cohesion: 0.25
Nodes (7): AppSpacing, lg, md, sm, unit, xs, static const double

### Community 11 - "flt_test.dart"
Cohesion: 0.40
Nodes (4): package:rx_merchant/core/numbers/flt.dart, bankers, commercial, main

## Knowledge Gaps
- **202 isolated node(s):** `AppTheme`, `_seed`, `light`, `dark`, `_from` (+197 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 258 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppDatabase` connect `schema_test.dart` to `router.dart`, `app_test.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `SystemSettings` connect `router.dart` to `singles.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `AppTheme`, `_seed`, `light` to the rest of the system?**
  _202 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `singles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Should `report_table.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.047872340425531915 - nodes in this community are weakly interconnected._
- **Should `router.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.056025369978858354 - nodes in this community are weakly interconnected._
- **Should `package:material_ui/material_ui.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06825396825396825 - nodes in this community are weakly interconnected._
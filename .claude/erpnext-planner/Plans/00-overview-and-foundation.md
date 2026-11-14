# Offline POS: Overview and Foundation

This is the first of six plan files. Read it before the others: it fixes the scope, the stack, the
shared rules and the table names that the five feature plans rely on.

| File | Feature |
|---|---|
| `00-overview-and-foundation.md` | This file |
| `01-setup.md` | Setup |
| `02-stock.md` | Stocks |
| `03-cash-register.md` | Cash Register (sale transactions) |
| `04-sales-dashboard.md` | Sales Dashboard |
| `05-invoices-and-receipts.md` | Invoices / Receipts |

Source material: `erpnext-docs-merged.md`, navigated through `links.txt`. Each feature plan lists the
pages it was built from, with their `docs.frappe.io` link and line range in the merged file.

---

## 1. Product in one paragraph

An Android app for one store run by one owner. It works with no internet at all. It keeps the item
catalogue and stock, sells at a cash register, prints receipts and invoices, and shows a sales
dashboard. Flutter is the whole application (interface and logic) and SQLite is the only data store.
It runs on phones and tablets from the first build. It is not being published, so there is no
store-listing, signing or release work in these plans.

## 2. Scope

### Included

| # | Area | ERPNext module it follows |
|---|---|---|
| 1 | Setup | Setting Up, plus the settings pages of Selling, Accounting (tax and payment only) and Printing |
| 2 | Stocks | Stock |
| 3 | Cash Register | Point of Sale, Sales Invoice |
| 4 | Sales Dashboard | Selling dashboard, Sales Analytics |
| 5 | Invoices / Receipts | Sales Invoice, Credit Note, Sales Return, Printing |

### Excluded, and the rule each exclusion applies everywhere

| Excluded | Rule used in every plan |
|---|---|
| Multi Company Handling | There is exactly one **Store Profile** (ERPNext "Company"). No Company field appears on any screen or table. Warehouse names carry no company abbreviation. |
| Cost Centers | Every "Cost Center" field is removed. |
| Fixed Assets | "Is Fixed Asset" and asset fields are removed from Item. |
| Customers | No Customer master, no customer field on a sale. Every sale is to an anonymous walk-in buyer and is paid in full at checkout. Removed with it: credit sales, partial payment, receivables, loyalty points, customer-specific prices, Tax Category, Territory, Customer Group. |
| Sales Person | No sales team, commission or target allocation. |
| Chart of Accounts / Accounts Handling | No ledgers. Every "Account", "Account Head", "Write Off", "Income Account", "Expense Account" and "Difference Account" field is removed. Sales tax is still calculated; a small `tax` master replaces the Account Head as the thing a tax row points to. |
| Staff / Employees | No users, roles, permissions or login. "Applicable for Users" on the POS Profile is removed. |

Two more consequences of those exclusions:

- **No purchasing documents.** Suppliers, Purchase Orders, Purchase Receipts and Material Requests are
  not in the included list. Stock arrives through a Stock Entry of type Material Receipt.
- **No Fiscal Year.** It exists for accounting periods. Naming series and reports use the calendar year.

## 3. How "nearly 1:1 with ERPNext" is applied

1. **Same words.** Screens, fields and statuses use ERPNext's labels exactly: Item Code, Stock UOM,
   Price List Rate, Net Total, Grand Total, Rounded Total, Material Receipt, Stock Reconciliation, POS
   Opening Entry, Is Return, Credit Note Issued, and so on.
2. **Same records.** Each ERPNext document or master that is kept becomes one table with the same
   name in `snake_case`, and each child table becomes its own table.
3. **Same rules.** Validations, calculation order and worked numbers come from the docs. Each rule in
   a feature plan cites the doc page it comes from.
4. **Same flow.** List view, then form view; Save, then Submit; corrections by Cancel or Return, never
   by editing a submitted document.
5. **Marked deviations.** Wherever the app differs, the scope table of that plan says "adapted" or
   "dropped" and gives the reason. A deviation is only allowed for one of three reasons: an excluded
   area, the offline single-device setting, or a touch screen.

Where the merged docs describe behaviour but not the exact fields or formula (the POS Opening and
Closing Entry forms, the POS screen layout, the order of steps in the totals calculation), the plans
use ERPNext's standard behaviour and say so at that point.

## 4. Stack

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter, stable channel, Dart 3 | Required. |
| Target | Android only | Required. No iOS, web or desktop folders are kept in the project. |
| UI | `package:flutter/material.dart` with `useMaterial3: true` | Required. No Cupertino widgets and no third-party UI kits. |
| Database | SQLite through `drift` (with `sqlite3_flutter_libs`) | Typed queries, migrations, in-memory databases for tests, and streams that refresh the screen when a table changes. |
| State | `flutter_riverpod` | Providers wrap drift streams; no extra layers. |
| Routing | `go_router` | Nested navigation for the shell with five destinations. |
| Barcode scanning | `mobile_scanner`, bundled model | The bundled model needs no download, so scanning works on a device that has never been online. |
| PDF and system print | `pdf` + `printing` | Builds invoice and receipt PDFs on the device and hands them to Android's print and share sheets. |
| Thermal printing | An ESC/POS Bluetooth package, picked at build time | Check which one is maintained when step INV-B7 starts. The plan needs only: list paired printers, connect, send bytes. |
| Charts | `fl_chart` | Material has no chart component. This is the one non-Material visual; it takes its colours from the theme. |
| Files | `file_picker`, `share_plus`, `path_provider` | Backup, restore, CSV import and export. |
| Images | `image_picker` | Item photo and letterhead logo. |
| Formats | `intl`, `csv` | Dates, numbers, CSV. |
| Text | Flutter `gen_l10n` | Every label goes through it from the first screen. English ships; another language is one more ARB file. |

Offline is enforced, not assumed: the release `AndroidManifest.xml` does not request
`android.permission.INTERNET`. Permissions requested: `CAMERA` (scanning, photos) and
`BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` (thermal printer).

## 5. Project layout

```
lib/
  main.dart
  app.dart                     MaterialApp.router, theme, localisation
  core/
    db/                        AppDatabase (drift), migrations, singles access
    numbers/                   flt() rounding, money and quantity formatting, amount in words
    naming/                    naming series resolver
    documents/                 docstatus rules shared by all documents
    widgets/                   adaptive shell, list-detail pane, link field, child table, status chip
  features/
    setup/      data/  logic/  ui/
    stock/      data/  logic/  ui/
    pos/        data/  logic/  ui/
    dashboard/  data/          ui/
    invoices/   data/  logic/  ui/
test/                          mirrors lib/, pure logic and in-memory database tests
integration_test/              one end-to-end flow
assets/
  country_info.json            countries with currency, symbol, fraction, number and date format
```

- `data/` holds drift table definitions and query classes for that feature's tables.
- `logic/` holds pure Dart functions with no Flutter or database import: the totals and tax engine,
  the valuation calculators, the naming resolver. These carry the unit tests.
- `ui/` holds screens and Riverpod providers.

There are no repository interfaces, use-case classes or DTO mappers. A screen reads a provider, the
provider calls a query class or a pure function.

## 6. App-wide standards

### 6.1 Documents and their lifecycle

ERPNext documents that are kept: Sales Invoice, Stock Entry, Stock Reconciliation, POS Opening Entry,
POS Closing Entry. All follow one lifecycle through a `docstatus` column.

| docstatus | Meaning | Rule |
|---|---|---|
| 0 | Draft | Editable. No effect on stock or reports. |
| 1 | Submitted | Read-only. Stock ledger and reports are affected. |
| 2 | Cancelled | Read-only. Its ledger effects are reversed. Kept for the audit trail. |

- A submitted document is never edited. A wrong sale is corrected by a Return / Credit Note, or
  cancelled if the whole sale was a mistake. A wrong stock document is cancelled and amended.
- **Amend** copies a cancelled document into a new draft whose name is the old name plus `-1`, `-2`…
- Submit and Cancel each run inside one SQLite transaction, so a failure leaves nothing half-written.
- Submit and Cancel ask for confirmation in an `AlertDialog`, as ERPNext does.

### 6.2 Naming

Documents get their name from a Naming Series (defined in `01-setup.md`). Masters are named by their
own key field (Item Code, Warehouse name, and so on). A master that is referenced by any document can
be disabled but not deleted.

### 6.3 Numbers

- All numeric columns are SQLite `REAL`.
- One helper, `flt(value, precision)`, rounds every calculated value before it is stored. It honours
  the **Rounding Method** setting (Banker's Rounding or Commercial Rounding).
- Money uses **Currency Precision** (default 2). Quantities and conversion factors use **Float
  Precision** (default 3). Valuation rates inside the stock ledger keep 9 decimals so that an average
  such as 113.333… is not truncated; stock values are rounded to Currency Precision.
- Known ceiling: `REAL` is a binary float. Because every stored amount is already rounded, sums stay
  exact far beyond a single store's volume. If a total is ever observed to drift, move money columns
  to scaled integers.

### 6.4 Dates and times

- Documents carry `posting_datetime` as text, `YYYY-MM-DD HH:MM:SS`, in the device's local time.
- Display follows the Date Format and Time Format settings. Storage never changes.

### 6.5 Settings ("Single" documents)

ERPNext keeps one-record settings pages (System Settings, Stock Settings…) as key-value rows. The app
does the same in one `singles` table with six groups: Store Profile, System Settings, Global Defaults,
Selling Settings, Stock Settings, Print Settings. Each has a typed Dart accessor that supplies the
default when a key is missing, so adding a setting needs no migration.

### 6.6 Database conventions

- `PRAGMA foreign_keys = ON`.
- Every table has `id INTEGER PRIMARY KEY` unless its DDL shows another key.
- Every master and document table also has `created_at TEXT` and `modified_at TEXT`. They are left out
  of the DDL blocks in the plans to keep them readable.
- Booleans are `INTEGER` 0 or 1. Child-table row order is `idx`, starting at 1.
- Schema changes go through drift migrations with a `schemaVersion`; version 1 is the full set below.

## 7. Interface standards

### 7.1 Material 3 only

One `ThemeData` built from `ColorScheme.fromSeed`, light and dark. Colours always come from
`ColorScheme` roles, never from literal values.

| ERPNext desk pattern | Material 3 component |
|---|---|
| Workspace with cards | `ListView` of `Card`s with `ListTile` links |
| List view with filters | `SearchBar`, `FilterChip`s, `ListView` of `ListTile`; `DataTable` in the wide layout |
| Form view | Scrolling form of sections; `TextFormField` (outlined), `DropdownMenu`, `SwitchListTile`, `CheckboxListTile`, `SegmentedButton`, `showDatePicker`, `showTimePicker` |
| Link field (pick a master) | `SearchAnchor` with a list of matches and a "Create new" entry |
| Child table | A list of rows inside the form; tapping a row opens the row editor (bottom sheet on phones, side sheet on tablets), as the pencil icon does in ERPNext |
| Tree view | Nested `ExpansionTile`s |
| Status indicator | `Chip`: Draft `secondaryContainer`, Submitted / Paid `primaryContainer`, Return / Credit Note Issued `surfaceContainerHighest`, Cancelled `errorContainer` |
| Primary action (Save, Submit) | `FilledButton` in the app bar or a bottom bar |
| "Create >" menu on a submitted document | `MenuAnchor` |
| Confirmation | `AlertDialog` |
| Message | `SnackBar`; blocking validation errors in an `AlertDialog` listing each problem |
| Mandatory field | Label ends with `*`; error text under the field |
| Report | Filter bar plus `DataTable` (horizontal scroll on phones) with a CSV export action |

### 7.2 Responsive rules

Layouts switch on the Material 3 window size classes, read once per screen with
`MediaQuery.sizeOf(context).width`.

| Class | Width | Navigation | Panes |
|---|---|---|---|
| Compact | under 600dp | `NavigationBar` at the bottom | One. List, then a pushed detail screen. |
| Medium | 600 to 839dp | `NavigationRail` | One wide pane; forms use two columns. The Cash Register already shows items and cart side by side. |
| Expanded | 840dp and up | `NavigationRail` with labels | Two. List on the left, detail on the right. |

- Every screen is built for all three classes in the same step it is created; no screen is
  phone-only "for now".
- Orientation is not locked. Rotating a tablet moves between Medium and Expanded.
- Touch targets are at least 48dp. Text scales with the system font size.

### 7.3 Navigation map

Five destinations, in this order:

1. **Cash Register**: opens the POS screen, or the POS Opening Entry prompt when no session is open.
2. **Invoices**: Sales Invoice list.
3. **Stock**: Items, stock transactions, stock reports.
4. **Dashboard**: Sales Dashboard and sales reports.
5. **Setup**: every settings page.

Until setup is complete the app shows only the first-run wizard.

## 8. Table index

Each table is defined once, in the file named here.

| File | Tables |
|---|---|
| `01-setup.md` | `singles`, `currency`, `naming_series_option`, `series`, `mode_of_payment`, `tax`, `sales_taxes_template`, `sales_taxes_template_row`, `item_tax_template`, `item_tax_template_row`, `price_list`, `pos_profile`, `pos_profile_payment`, `pos_profile_item_group` |
| `02-stock.md` | `warehouse`, `item_group`, `uom`, `brand`, `item`, `item_barcode`, `item_uom`, `item_reorder`, `item_tax`, `item_attribute`, `item_attribute_value`, `item_variant_attribute`, `item_price`, `batch`, `serial_no`, `stock_entry`, `stock_entry_item`, `stock_entry_additional_cost`, `stock_reconciliation`, `stock_reconciliation_item`, `serial_and_batch_entry`, `stock_ledger_entry`, `bin` |
| `03-cash-register.md` | `pos_opening_entry`, `pos_opening_entry_detail`, `pos_closing_entry`, `pos_closing_entry_detail`, `sales_invoice`, `sales_invoice_item`, `sales_invoice_tax`, `sales_invoice_payment` |
| `04-sales-dashboard.md` | none (read-only queries) |
| `05-invoices-and-receipts.md` | `letter_head`, `print_heading`, `terms_and_conditions` |

## 9. Build order

Each milestone ends with an app that runs and does something complete. Step codes (for example
`STK-B4`) refer to the build steps in the feature plans.

| Milestone | Contents | Steps |
|---|---|---|
| M0 Foundation | Project, database, `singles`, rounding helper, naming resolver, theme, adaptive shell with five empty destinations | below |
| M1 Setup A | First-run wizard, Store Profile, System Settings, Global Defaults, Currency, Price List, Naming Series | SET-B1 to B4 |
| M2 Stock A | Warehouse, Item Group, UoM, Brand, Item with barcodes and UoMs, Item Price, Stock Settings | STK-B1 to B4 |
| M3 Stock B | Stock ledger engine, Stock Entry, Stock Reconciliation, core stock reports | STK-B5 to B9 |
| M4 Setup B | Mode of Payment, taxes, POS Profile, Selling Settings | SET-B5 to B7 |
| M5 Cash Register | Sessions, POS screen, totals engine, payment, submit | POS-B1 to B8 |
| M6 Invoices | List, detail, print formats, PDF, thermal printing, returns, cancel | INV-B1 to B9 |
| M7 Dashboard | Cards, charts, sales goal, reports | DSH-B1 to B5 |
| M8 Stock C | Variants, batches, serial numbers across stock documents and the Cash Register | STK-B10 to B13, POS-B9 |
| M9 Setup C | Data Import and Export, Backup and Restore | SET-B8, B9 |

The tables for batches and serial numbers are created in M3 with the rest of the schema, so M8 adds
behaviour without a schema rewrite.

### M0 steps

1. `flutter create --platforms=android`; add the packages in section 4; remove the INTERNET
   permission from the release manifest.
2. `AppDatabase` with schema version 1 (all tables in section 8) and `PRAGMA foreign_keys = ON`.
3. `singles` accessor with typed getters and defaults.
4. `flt()` and the number, currency and date formatters, with their unit tests.
5. Naming series resolver, with its unit tests.
6. Theme, localisation scaffold, adaptive shell (`NavigationBar` / `NavigationRail`), `go_router`
   with five placeholder destinations and the wizard gate.
7. Shared widgets: list-detail pane, link field, child table with row editor, status chip, report
   table with CSV export.

Done when: the app starts on a phone and a tablet emulator, shows the wizard gate, and
`flutter test` passes.

## 10. Testing

- **Unit tests** for everything in `logic/`. The expected values are the worked numbers in the ERPNext
  docs; each feature plan lists them under Acceptance checks.
- **Database tests** against an in-memory drift database for the stock ledger and for Submit and
  Cancel of each document.
- **One integration test**: wizard, create an item, receive stock, open a session, sell with tax and a
  discount, print to PDF, return one unit, close the session, read the dashboard.
- **Manual pass** on one phone and one tablet for every screen, in both orientations on the tablet.

## 11. Short glossary

| ERPNext term | In this app |
|---|---|
| Company | Store Profile |
| DocType | A kind of record: a master (Item), a document (Sales Invoice) or a settings page |
| Child table | Rows that belong to one parent record (the items of an invoice) |
| Submit | Make a document final so it affects stock and reports |
| Stock Ledger Entry | One line of stock movement for one item in one warehouse |
| Bin | The running balance of one item in one warehouse |
| Price List Rate | The price before any discount |
| Net Total | Sum of item amounts without tax, after discounts |
| Grand Total | Net Total plus taxes |
| Rounded Total | Grand Total rounded to the smallest coin |
| Update Stock | A sales invoice that also moves stock. Always on in this app. |

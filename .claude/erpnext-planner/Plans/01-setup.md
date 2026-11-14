# Plan 01: Setup

Read `00-overview-and-foundation.md` first. This plan covers the first-run wizard and every settings
page that is not stock-specific or print-specific. Stock Settings are in `02-stock.md`; Print
Settings, Letter Head, Print Heading and Terms and Conditions are in `05-invoices-and-receipts.md`.
Both are reached from the Setup destination.

---

## 1. Purpose and ERPNext sources

Setup turns an empty install into a store that can sell: who the store is, how dates and money are
shown, how documents are numbered, how customers pay, what tax applies, and how the cash register
behaves.

| ERPNext page | Link | Line in merged doc |
|---|---|---|
| Setting Up | https://docs.frappe.io/erpnext/setting-up | 620 |
| Company | https://docs.frappe.io/erpnext/company-setup | 677 |
| Country | https://docs.frappe.io/erpnext/country | 743 |
| System Settings | https://docs.frappe.io/erpnext/system-settings | 899 |
| Global Defaults | https://docs.frappe.io/erpnext/global-defaults | 1037 |
| Data Import | https://docs.frappe.io/erpnext/data-import | 1413 |
| Downloading Backups | https://docs.frappe.io/erpnext/download-backup | 1658 |
| Mode of Payment | https://docs.frappe.io/erpnext/mode-of-payment | 8086 |
| Item Tax Template | https://docs.frappe.io/erpnext/item-tax-template | 13159 |
| Types in Tax Template | https://docs.frappe.io/erpnext/types-in-tax-template | 13339 |
| Sales Taxes and Charges Template | https://docs.frappe.io/erpnext/sales-taxes-and-charges-template | 13723 |
| Tax Inclusive Accounting | https://docs.frappe.io/erpnext/tax-inclusive-accounting | 14225 |
| Currency | https://docs.frappe.io/erpnext/currency | 15801 |
| Invoice rounding issue | https://docs.frappe.io/erpnext/invoice-rounding-issue | 19388 |
| Selling Settings | https://docs.frappe.io/erpnext/selling-settings | 22689 |
| Setting Company Sales Goal | https://docs.frappe.io/erpnext/setting-company-sales-goal | 26446 |
| Price Lists | https://docs.frappe.io/erpnext/price-lists | 27228 |
| POS Profile | https://docs.frappe.io/erpnext/pos-profile | 35585 |
| Naming Series | https://docs.frappe.io/erpnext/naming-series | 40702 |
| Disable Rounded Total | https://docs.frappe.io/erpnext/disable-rounded-total | 42387 |

## 2. Scope

| ERPNext element | In the app | Status | Reason |
|---|---|---|---|
| Setup wizard and recommended setup order | First-run wizard: language, country, currency, store name | Kept | |
| Company | **Store Profile**, one record | Adapted | Multi-company excluded |
| Company: Is Group, Parent Company, Reporting Currency | none | Dropped | Multi-company excluded |
| Company: chart of accounts, root cost center | none | Dropped | Accounts and cost centers excluded |
| Company: default warehouses created on save | One warehouse tree seeded by the wizard | Kept | |
| Company: Monthly Sales Target, Total Monthly Sales | On Store Profile; shown on the dashboard | Kept | |
| Country record | Bundled `country_info.json`, read by the wizard | Adapted | Reference data only; no table needed |
| System Settings: Country, Language, Date Format, Time Format, Number Format, First Day of the Week, Float Precision, Currency Precision, Rounding Method, Number of Backups | Same fields | Kept | |
| System Settings: Time Zone | Shown read-only from the device | Adapted | One device, one clock |
| System Settings: sessions, login, passwords, two-factor, email, file upload, sharing, telemetry | none | Dropped | No users, no network |
| Global Defaults: Default Currency, Hide Currency Symbol, Disable Rounded Total, Disable In Words | Same fields | Kept | |
| Global Defaults: Default Company, Default Country, Default Distance Unit, Demo Company | none | Dropped | Single store |
| Global Defaults: Use Posting Datetime for Naming Documents | Always on | Adapted | One less switch; names follow the posting date |
| Currency: Fraction, Fraction Units, Smallest Currency Fraction Value, Symbol, Show Currency Symbol on Right Side | Same fields, for the store's one currency | Kept | |
| Currency: Number Format | Lives on System Settings only | Adapted | With one currency there is one format |
| Currency Exchange, multi-currency | none | Dropped | Needs foreign-currency accounts and parties |
| Naming Series: prefixes, default series, current value | Same | Kept | |
| Naming Series: `.FY.` token | `.YYYY.` only | Adapted | No Fiscal Year |
| Mode of Payment: name, Type, Enabled | Same | Kept | |
| Mode of Payment: Accounts table | none | Dropped | Accounts excluded |
| Sales Taxes and Charges Template: Title, Default, Disabled, rows with Type, Description, Tax Rate, Tax Amount, Reference Row #, Is this Tax included in Basic Rate? | Same | Kept | |
| Tax row: Account Head | Link to a `tax` record (a name such as "VAT") | Adapted | Accounts excluded; the row still needs something to match item overrides against |
| Tax row: Cost Center, Is Tax Withholding Account, Considered In Paid Amount | none | Dropped | Accounting |
| Tax Category, Tax Rule | none | Dropped | Both select tax by customer or address |
| Item Tax Template: Title, Tax Rates rows, Not Applicable, Disabled | Same | Kept | |
| Price List: Enabled, Price Not UOM Dependent | Same | Kept | |
| Price List: Buying, country restriction, customer tagging | none | Dropped | No purchasing, no customers |
| POS Profile: Warehouse, Payment Methods (Default, Allow in Returns), Item Group filter, Price List, Taxes and Charges, Apply Discount On, Print Format, Letterhead, Print Heading, Terms and Conditions | Same | Kept | |
| POS Profile configurations: Hide images, Hide unavailable Items, Allow User to Edit Rate, Automatically Add Filtered Item To Cart, Allow User to Edit Discount, Validate Stock on Save, Set Grand Total to Default Payment Method, Print Receipt on Order Complete, Action on New Invoice | Same | Kept | |
| POS Profile: Allow Partial Payment | none | Dropped | No customer to owe the balance |
| POS Profile: Ignore Pricing Rule | none | Dropped | Pricing Rules are not built (section 8) |
| POS Profile: Company, Customer, Customer Group, Applicable for Users, Currency, accounts, Accounting Dimensions, Tax Category | none | Dropped | Excluded areas; currency is the store's |
| Selling Settings: Default Price List, Use prices from Default Price List as fallback, Allow editing Price List rate in transactions, Validate selling price against purchase or valuation rate | Same | Kept | |
| Selling Settings: everything about customers, sales orders, delivery notes, quotations, commissions, UTM | none | Dropped | Excluded areas |
| Selling Settings: Allow same Item to be added multiple times | none | Dropped | The POS cart always merges identical lines, as ERPNext's POS does |
| Data Import: template, validation, warnings, import | For Item, Item Price, Item Barcode | Kept | |
| Data Export | Same three types | Kept | |
| Downloading Backups, Number of Backups | Backup and Restore of the SQLite file | Adapted | The backup is a file on the device, not a download |
| Cloud backups, Encrypt Backups | none | Dropped | Offline; see section 8 |

## 3. Data model

```sql
-- One-record settings pages, stored as key-value rows (see 00, section 6.5).
CREATE TABLE singles (
  doctype TEXT NOT NULL,          -- 'Store Profile', 'System Settings', 'Global Defaults',
                                  -- 'Selling Settings', 'Stock Settings', 'Print Settings'
  field   TEXT NOT NULL,
  value   TEXT,
  PRIMARY KEY (doctype, field)
);

CREATE TABLE currency (
  code TEXT PRIMARY KEY,          -- ISO code, e.g. 'USD'
  enabled INTEGER NOT NULL DEFAULT 1,
  fraction TEXT,                  -- 'Cent'
  fraction_units INTEGER NOT NULL DEFAULT 100,
  smallest_currency_fraction_value REAL NOT NULL DEFAULT 0.01,
  symbol TEXT,
  symbol_on_right INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE naming_series_option (
  id INTEGER PRIMARY KEY,
  doctype TEXT NOT NULL,          -- 'Sales Invoice', 'Sales Invoice Return', 'Stock Entry', ...
  pattern TEXT NOT NULL,          -- 'ACC-SINV-.YYYY.-'
  idx INTEGER NOT NULL,           -- 1 is the default series for the doctype
  UNIQUE (doctype, pattern)
);

CREATE TABLE series (
  name TEXT PRIMARY KEY,          -- resolved prefix, e.g. 'ACC-SINV-2026-'
  current INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE mode_of_payment (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'General' CHECK (type IN ('Cash','Bank','General','Phone')),
  enabled INTEGER NOT NULL DEFAULT 1
);

-- Stands in for the tax "Account Head".
CREATE TABLE tax (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,      -- 'VAT', 'Service Charge'
  disabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE sales_taxes_template (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL UNIQUE,
  is_default INTEGER NOT NULL DEFAULT 0,
  disabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE sales_taxes_template_row (
  id INTEGER PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES sales_taxes_template(id) ON DELETE CASCADE,
  idx INTEGER NOT NULL,
  charge_type TEXT NOT NULL CHECK (charge_type IN
    ('Actual','On Net Total','On Previous Row Amount','On Previous Row Total','On Item Quantity')),
  tax_id INTEGER NOT NULL REFERENCES tax(id),
  description TEXT,
  rate REAL NOT NULL DEFAULT 0,         -- percent, or amount per unit for 'On Item Quantity'
  tax_amount REAL NOT NULL DEFAULT 0,   -- used by 'Actual'
  row_id INTEGER,                       -- Reference Row #
  included_in_print_rate INTEGER NOT NULL DEFAULT 0,  -- Is this Tax included in Basic Rate?
  UNIQUE (template_id, idx)
);

CREATE TABLE item_tax_template (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL UNIQUE,
  disabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE item_tax_template_row (
  id INTEGER PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES item_tax_template(id) ON DELETE CASCADE,
  tax_id INTEGER NOT NULL REFERENCES tax(id),
  tax_rate REAL NOT NULL DEFAULT 0,
  not_applicable INTEGER NOT NULL DEFAULT 0,
  UNIQUE (template_id, tax_id)
);

CREATE TABLE price_list (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  enabled INTEGER NOT NULL DEFAULT 1,
  price_not_uom_dependent INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE pos_profile (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  is_default INTEGER NOT NULL DEFAULT 0,
  disabled INTEGER NOT NULL DEFAULT 0,
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  price_list_id INTEGER NOT NULL REFERENCES price_list(id),
  taxes_template_id INTEGER REFERENCES sales_taxes_template(id),
  apply_discount_on TEXT NOT NULL DEFAULT 'Grand Total'
    CHECK (apply_discount_on IN ('Grand Total','Net Total')),
  hide_images INTEGER NOT NULL DEFAULT 0,
  hide_unavailable_items INTEGER NOT NULL DEFAULT 0,
  allow_rate_change INTEGER NOT NULL DEFAULT 0,
  auto_add_item_to_cart INTEGER NOT NULL DEFAULT 0,
  allow_discount_change INTEGER NOT NULL DEFAULT 0,
  validate_stock_on_save INTEGER NOT NULL DEFAULT 0,
  set_grand_total_to_default_mop INTEGER NOT NULL DEFAULT 1,
  print_receipt_on_order_complete INTEGER NOT NULL DEFAULT 0,
  action_on_new_invoice TEXT NOT NULL DEFAULT 'Always Ask' CHECK (action_on_new_invoice IN
    ('Always Ask','Save Changes and Load New Invoice','Discard Changes and Load New Invoice')),
  print_format TEXT NOT NULL DEFAULT 'POS Receipt',   -- 'POS Receipt' or 'Standard'
  letter_head_id INTEGER REFERENCES letter_head(id),
  print_heading_id INTEGER REFERENCES print_heading(id),
  tc_id INTEGER REFERENCES terms_and_conditions(id)
);

CREATE TABLE pos_profile_payment (
  id INTEGER PRIMARY KEY,
  pos_profile_id INTEGER NOT NULL REFERENCES pos_profile(id) ON DELETE CASCADE,
  mode_of_payment_id INTEGER NOT NULL REFERENCES mode_of_payment(id),
  is_default INTEGER NOT NULL DEFAULT 0,
  allow_in_returns INTEGER NOT NULL DEFAULT 0,
  UNIQUE (pos_profile_id, mode_of_payment_id)
);

CREATE TABLE pos_profile_item_group (
  pos_profile_id INTEGER NOT NULL REFERENCES pos_profile(id) ON DELETE CASCADE,
  item_group_id INTEGER NOT NULL REFERENCES item_group(id),
  PRIMARY KEY (pos_profile_id, item_group_id)
);
```

### Settings stored in `singles`

**Store Profile**

| Label | Key | Default | Note |
|---|---|---|---|
| Store Name | `store_name` | from wizard | Mandatory |
| Abbreviation | `abbr` | initials of the name | Used in backup file names |
| Country | `country` | from wizard | |
| Default Currency | `default_currency` | from wizard | Locked by SET-R2 |
| Monthly Sales Target | `monthly_sales_target` | 0 | 0 switches the goal off |

**System Settings**

| Label | Key | Default | Options |
|---|---|---|---|
| Country | `country` | from wizard | |
| Language | `language` | `en` | Languages shipped with the app |
| Time Zone | none | device | Read-only |
| Date Format | `date_format` | from country | `yyyy-mm-dd`, `dd-mm-yyyy`, `dd/mm/yyyy`, `dd.mm.yyyy`, `mm/dd/yyyy`, `mm-dd-yyyy` |
| Time Format | `time_format` | `HH:mm:ss` | `HH:mm:ss`, `HH:mm` |
| Number Format | `number_format` | from country | `#,###.##`, `#.###,##`, `# ###.##`, `#,##,###.##`, `#,###`, `#.###` |
| First Day of the Week | `first_day_of_week` | Monday | Seven days |
| Float Precision | `float_precision` | 3 | 2 to 9 |
| Currency Precision | `currency_precision` | 2 | 0 to 9. Locked by SET-R2 |
| Rounding Method | `rounding_method` | Banker's Rounding | Banker's Rounding, Commercial Rounding |
| Number of Backups | `number_of_backups` | 3 | |
| Setup Complete | `setup_complete` | 0 | Set by the wizard; not editable |

**Global Defaults**

| Label | Key | Default |
|---|---|---|
| Default Currency | shows Store Profile value | read-only |
| Hide Currency Symbol | `hide_currency_symbol` | 0 |
| Disable Rounded Total | `disable_rounded_total` | 0 |
| Disable In Words | `disable_in_words` | 0 |

**Selling Settings**

| Label | Key | Default |
|---|---|---|
| Default Price List | `selling_price_list` | Standard Selling |
| Use prices from Default Price List as fallback | `fallback_to_default_price_list` | 0 |
| Allow editing Price List rate in transactions | `editable_price_list_rate` | 0 |
| Validate selling price against purchase or valuation rate | `validate_selling_price` | 0 |

### Default naming series (ERPNext's defaults)

| Document | Pattern | Example |
|---|---|---|
| Sales Invoice | `ACC-SINV-.YYYY.-` | `ACC-SINV-2026-00001` |
| Sales Invoice Return | `ACC-SINV-RET-.YYYY.-` | `ACC-SINV-RET-2026-00001` |
| Stock Entry | `MAT-STE-.YYYY.-` | `MAT-STE-2026-00001` |
| Stock Reconciliation | `MAT-RECO-.YYYY.-` | `MAT-RECO-2026-00001` |
| POS Opening Entry | `POS-OPE-.YYYY.-` | `POS-OPE-2026-00001` |
| POS Closing Entry | `POS-CLO-.YYYY.-` | `POS-CLO-2026-00001` |
| Item (only when Item Naming By is Naming Series) | `STO-ITEM-.YYYY.-` | `STO-ITEM-2026-00001` |

## 4. Business rules

**SET-R1 Setup gate.** While `setup_complete` is 0 the app shows only the wizard. Finishing the
wizard writes all seed data in one transaction and sets it to 1. (Setting Up: "A good setup begins
with the decisions that affect every transaction.")

**SET-R2 Decisions that lock.** Default Currency and Currency Precision become read-only once any
document has been submitted. The form shows why. (Setting Up: changing currency after transactions
exist "can be disruptive"; Currency: a Currency record "does not convert historical accounting data".)

**SET-R3 Wizard seed data.**

| Seeded | Records |
|---|---|
| Currency | The chosen one, with symbol, fraction, fraction units and smallest fraction from `country_info.json` |
| Warehouse | "All Warehouses" (group) containing "Stores" |
| Item Group | "All Item Groups" (group) containing "Products", "Services", "Consumable" |
| UoM | Nos, Unit, Box, Carton, Pack, Pair, Set, Dozen (Must be Whole Number on); Kg, Gram, Litre, Millilitre, Meter (off) |
| Price List | "Standard Selling", enabled |
| Mode of Payment | Cash (Cash), Credit Card (Bank), Wire Transfer (Bank) |
| POS Profile | "Main Counter": warehouse Stores, price list Standard Selling, Cash as default payment and allowed in returns, default profile |
| Naming series | The table in section 3 |
| Letter Head | One default letter head holding the store name |
| Stock Settings | Default Item Group "Products", Default Stock UOM "Nos", Default Warehouse "Stores", Default Valuation Method FIFO |

No tax is seeded. Sales are tax-free until a Sales Taxes and Charges Template is created and chosen on
the POS Profile.

**SET-R4 Rounding.** `flt(value, precision)` implements both methods. Banker's Rounding sends a
midpoint to the nearest even digit (2.345 to 2.34, 2.355 to 2.36). Commercial Rounding sends a midpoint
away from zero (2.345 to 2.35). The helper corrects for binary float error before deciding whether a
value is a midpoint. (System Settings: Rounding Method.)

**SET-R5 Number and date formats** affect display and typing only. `#,###.##` shows 12345.67 as
12,345.67; `#.###,##` shows it as 12.345,67. Stored values never change. (System Settings; Currency:
"A number format changes presentation".)

**SET-R6 Naming series resolution.**
1. Split the pattern on `.`. `YYYY`, `YY`, `MM`, `DD` become parts of the document's posting date. A
   run of `#` is the counter and its length is the number of digits. Anything else is literal.
2. If the pattern has no `#` run, a five-digit counter is appended.
3. Everything before the counter is the series key. Read `series.current` for that key, add 1, store
   it, and pad to the digit count.
4. This happens inside the document's Submit transaction, so a failed submit does not burn a number.

Example: `ACC-SINV-.YYYY.-` on a 2026 posting date gives key `ACC-SINV-2026-` and name
`ACC-SINV-2026-00001`. A new year starts a new key, so numbering restarts at 1. (Naming Series: "a
series with prefix INV12#### will have numbers INV120001, INV120002".)

**SET-R7 Editing a series.** The first pattern listed for a document is its default. When a document
has more than one pattern, its form shows a Series dropdown. "Update Series" sets `series.current` for
a chosen key; the next document takes current + 1. Setting it lower than a number already used is
refused, because the name would collide. (Naming Series, sections 1 and 3.)

**SET-R8 Mode of Payment.** A disabled mode cannot be chosen on a POS Profile or at checkout. A mode
used on any invoice can be disabled but not deleted. Type classifies the mode; the app uses it for one
thing only: change is given from, and cash counts apply to, modes of Type Cash. (Mode of Payment:
"The Type describes the method".)

**SET-R9 Tax template rows.** (Sales Taxes and Charges Template; Types in Tax Template.)
- Rows calculate in `idx` order.
- Reference Row # is allowed only for On Previous Row Amount and On Previous Row Total, and must point
  to an earlier row. The first row cannot be a previous-row type.
- For On Item Quantity the rate is an amount per unit, not a percentage.
- For Actual, the amount is entered in Tax Amount and the rate is ignored.
- An Actual row cannot be marked as included in the basic rate. A previous-row row can be included
  only if the row it references is included too.
- Only one template is the default. Setting a new default clears the old one.
- A disabled template cannot be selected but stays on old invoices.

Worked examples on a Net Total of 1,000 (Types in Tax Template):

| Rows | Result |
|---|---|
| Actual 25 | 25; running total 1,025 |
| 8% On Net Total | 80; running total 1,080 |
| Row 1: 8% On Net Total; row 2: 2% On Previous Row Amount, reference 1 | Row 2 = 1.60; total 1,081.60 |
| Row 1: 8% On Net Total; row 2: 2% On Previous Row Total, reference 1 | Row 2 = 21.60; total 1,101.60 |
| On Item Quantity, rate 2, total quantity 5 | 10 |

**SET-R10 Templates are copied, not linked.** Choosing a template on a sale copies its rows into the
sale. Editing the template later changes future sales only. (Sales Taxes and Charges Template: "Does
changing a template update submitted invoices?")

**SET-R11 Tax included in the basic rate.** When a row is marked as included, the entered price
already contains that tax: `net = price ÷ (1 + rate ÷ 100)`. A price of 108 at 8% gives net 100 and
tax 8, and the buyer pays 108, not 116.64. The full calculation is in `03-cash-register.md`.
(Tax Inclusive Accounting.)

**SET-R12 Item Tax Template.** A template row overrides the rate of the matching `tax` for the items
it is assigned to. It has an effect only when the sale's tax rows include that same `tax`. **Not
Applicable** removes the tax from the item; a rate of 0 keeps the item taxable at zero. The two are
reported differently, so they are stored differently. It follows the included / not included setting
of the matching tax row. Assignment to items and item groups is in `02-stock.md`. (Item Tax Template.)

Worked example: standard row 8%; items 699 at 8%, 149 with a 4% template, 99 with a 0% template. Tax
is 55.92 + 5.96 + 0.00 = 61.88 on a net of 947.

**SET-R13 Price List.** A disabled list cannot be chosen on a POS Profile. At least one list stays
enabled. **Price Not UOM Dependent**: when on, a price stored for the stock unit is multiplied by the
conversion factor for other units (1 Box = 10 Kilos, 10 per Kilo, so a Box is 100). When off, a unit
with no price of its own shows the stock-unit price unchanged (the Box shows 10), so each selling unit
should get its own Item Price. The lookup order is STK-R10 in `02-stock.md`. (Price Lists.)

**SET-R14 POS Profile.**
- Warehouse must not be a group warehouse.
- If the payment table is empty, Cash is used. Otherwise exactly one row is the default. Only modes
  in the table are offered at checkout; only rows with Allow in Returns are offered on a return.
- Exactly one enabled profile is the default; it is preselected when a session is opened.
- A profile with an open POS Opening Entry cannot be edited or disabled until the session is closed.
- Item Groups: when the table has rows, the item selector shows only items in those groups and their
  sub-groups.
- Apply Discount On: **Net Total** spreads the discount over the items before tax; **Grand Total**
  takes it off the after-tax total. (The POS Profile page describes these the other way round. The
  Apply Discounts page is the consistent one and is the one followed.)
(POS Profile.)

**SET-R15 Sales goal.** Monthly Sales Target is one recurring monthly figure in the store currency.
It blocks nothing. The calculation is in `04-sales-dashboard.md`. (Setting Company Sales Goal.)

**SET-R16 Data Import.**
1. Choose the record type and Insert New Records or Update Existing Records.
2. Download the template CSV. Mandatory columns are listed in the dialog.
3. Upload the filled file. Every row is validated before anything is written.
4. Problems are listed by row number and column. All must be fixed before the import can start.
5. The import runs in one transaction. The result lists each record created or updated.

Checks: a duplicate key on insert ("Duplicate Name"), a missing mandatory value, a link value that does
not exist (Item Group, UoM, Brand, Price List, Item Code), a number that does not parse. Unrecognised
column headers are shown so the user can map them to a field. (Data Import.)

| Record type | Columns (`*` mandatory) |
|---|---|
| Item | Item Code*, Item Name, Item Group*, Default Unit of Measure*, Maintain Stock, Is Sales Item, Standard Selling Rate, Valuation Rate, Barcode, Brand, Description, Max Discount (%), Item Tax Template |
| Item Price | Item Code*, Price List*, UOM, Rate*, Valid From, Valid Upto |
| Item Barcode | Item Code*, Barcode*, Barcode Type, UOM |

Opening stock quantities are imported through Stock Reconciliation (`02-stock.md`). "Do not import
everything": history from an old system is not imported. (Setting Up.)

**SET-R17 Backup.**
- A backup is one file made with `VACUUM INTO`, which gives a consistent copy while the app is running.
  Item photos and the letterhead logo are stored inside the database, so the one file is complete.
- File name: `{abbr}-backup-{YYYYMMDD-HHMMSS}.sqlite`, in the app's backup folder.
- A backup is taken automatically when a POS Closing Entry is submitted, and on demand.
- Only the newest **Number of Backups** files are kept.
- "Export" saves or shares a backup outside the app's folder. The screen states plainly that backups
  left only on the device are lost with the device.
(Downloading Backups; System Settings: Number of Backups.)

**SET-R18 Restore.** The user picks a file. The app checks that it is a SQLite database containing
`singles`, and that its schema version is not newer than the app's. It takes a backup of the current
data first, replaces the database, runs any pending migrations, and restarts. Restore is refused while
a POS session is open.

## 5. Screens

### First-run wizard

Three steps and a finish screen, one `Stepper`-style flow.

1. **Language.** List of shipped languages.
2. **Region.** Country (`SearchAnchor`), Currency (pre-filled from the country, changeable), and a
   read-only preview of the date and number format.
3. **Store.** Store Name, Abbreviation (suggested from the initials, editable).
4. **Done.** "Add your first item" and "Open Cash Register" buttons.

Compact: one step per screen. Medium and Expanded: centred card, 560dp wide.

### Setup home

A list of grouped cards, as an ERPNext workspace:

| Group | Links |
|---|---|
| Store | Store Profile, System Settings, Global Defaults, Currency |
| Selling | POS Profile, Mode of Payment, Price List, Selling Settings |
| Taxes | Tax, Sales Taxes and Charges Template, Item Tax Template |
| Stock | Stock Settings (see `02-stock.md`) |
| Printing | Print Settings, Letter Head, Print Heading, Terms and Conditions (see `05-invoices-and-receipts.md`) |
| Data | Naming Series, Data Import, Data Export, Backups |

Compact and Medium: the list fills the screen and a link pushes the page. Expanded: the list is the
left pane and the chosen page fills the right pane.

### Settings pages (Store Profile, System Settings, Global Defaults, Selling Settings, Currency)

One form each, sections with a heading, a Save `FilledButton`. Locked fields show a lock icon and a
one-line reason. System Settings shows a live preview line: today's date and `1234567.891` in the
chosen formats.

### Masters (Mode of Payment, Tax, Price List, templates, POS Profile)

List view with a search bar and an "Add" `FloatingActionButton`, then a form.

- **Sales Taxes and Charges Template form.** Title, Default, Disabled, then the rows as a child table
  showing Type, Tax, Rate. The row editor has Type, Tax, Description, Tax Rate or Tax Amount (whichever
  the Type uses), Reference Row # (only for previous-row types), and the included-in-basic-rate switch.
  A "Try it" panel under the table takes a net amount and a quantity and shows each row's Amount and
  running Total, so a compound template can be checked before use.
- **POS Profile form.** Sections in ERPNext's order: Warehouse; Payment Methods (child table with
  Default and Allow in Returns); Configurations (the nine switches and Action on New Invoice as a
  `DropdownMenu`); Item Groups; Print Settings; Price List, Taxes and Charges, Apply Discount On.

### Naming Series

Pick a document; its patterns are listed one per line with the first marked default; add, reorder,
remove. Below, "Update Series": pick a resolved prefix, see the current number, enter a new one.

### Data Import and Data Export

Import: record type, import type, Download Template, Choose File, a results area that shows either
the warnings table (row, column, problem) or the import log. Export: record type and Export.

### Backups

List of backups with date and size; "Back up now", "Export", "Restore from file"; Number of Backups.

Empty and error states: every list has an empty message with its "Add" action; a failed save shows
the validation problems in a dialog and keeps the form contents.

## 6. Build steps

| Step | Work | Runnable result |
|---|---|---|
| SET-B1 | `country_info.json`, wizard screens, seed transaction (SET-R1, R3) | A fresh install walks through the wizard and lands on the shell |
| SET-B2 | Store Profile, System Settings, Global Defaults forms; formats applied app-wide (SET-R2, R4, R5) | Changing Date Format or Number Format changes the preview and every list |
| SET-B3 | Currency form, Price List list and form (SET-R13) | Symbol and symbol position change how amounts print |
| SET-B4 | Naming Series screen (SET-R6, R7) | A test document takes the next number; Update Series moves it |
| SET-B5 | Mode of Payment list and form (SET-R8) | Modes can be added, disabled |
| SET-B6 | Tax, Sales Taxes and Charges Template with the "Try it" panel, Item Tax Template (SET-R9 to R12) | The panel reproduces the worked examples |
| SET-B7 | POS Profile form, Selling Settings (SET-R14) | A second profile can be created and made default |
| SET-B8 | Data Import and Export (SET-R16) | 200 items imported from a CSV; a bad row blocks the import with a clear message |
| SET-B9 | Backup and Restore (SET-R17, R18) | Back up, wipe app data, reinstall, restore, data is back |

SET-B1 to B4 are milestone M1, B5 to B7 are M4, B8 and B9 are M9.

## 7. Acceptance checks

Unit tests:

| Check | Expected |
|---|---|
| SET-A1 `flt(2.345, 2)` and `flt(2.355, 2)` under Banker's Rounding | 2.34 and 2.36 |
| SET-A2 `flt(2.345, 2)` under Commercial Rounding | 2.35 |
| SET-A3 `flt(1.005, 2)` under Commercial Rounding (binary float trap) | 1.01 |
| SET-A4 Format 12345.67 with `#,###.##` and with `#.###,##` | `12,345.67` and `12.345,67` |
| SET-A5 Resolve `ACC-SINV-.YYYY.-` for a 2026 date, three times | `…-00001`, `…-00002`, `…-00003` |
| SET-A6 Resolve the same pattern for a 2027 date | `ACC-SINV-2027-00001` |
| SET-A7 Resolve `INV12.####` | `INV120001` |
| SET-A8 Template with a previous-row type in row 1 | Rejected |
| SET-A9 Reference Row # pointing at a later row | Rejected |
| SET-A10 Actual row marked as included in basic rate | Rejected |
| SET-A11 "Try it" numbers for the five rows in SET-R9 | 25; 80; 1.60; 21.60; 10 |

Database and manual checks:

| Check | Expected |
|---|---|
| SET-A12 Finish the wizard | Every record in SET-R3 exists; `setup_complete` is 1 |
| SET-A13 Submit any document, then open Store Profile | Default Currency and Currency Precision are locked |
| SET-A14 Disable the only enabled Price List | Refused |
| SET-A15 Make a second template default | The first is no longer default |
| SET-A16 Edit a POS Profile during an open session | Refused with the reason |
| SET-A17 Import a CSV with one unknown Item Group | Nothing imported; warning names the row and column |
| SET-A18 Take five backups with Number of Backups = 3 | Three files remain, the newest three |
| SET-A19 Restore a file that is not a POS backup | Refused; current data untouched |
| SET-A20 Wizard and every Setup page on a phone and on a tablet in both orientations | No clipped or overlapping content; Expanded shows two panes |

## 8. Left out on purpose

| Not built | Add it when |
|---|---|
| Users, roles, permissions, login, app lock | A second person starts using the device and needs restricted access |
| Multi-currency, Currency Exchange | The store prices or accepts payment in a second currency |
| Fiscal Year and the `.FY.` naming token | Numbering must follow a non-calendar tax year |
| Tax Category, Tax Rule | Customers are added and tax depends on who is buying |
| Pricing Rule, Promotional Scheme, Coupon Code, and "Ignore Pricing Rule" | The owner wants automatic promotions such as buy one get one |
| Encrypted backups | Backups are stored somewhere other people can reach |
| Scheduled or cloud backups | Never while the app is offline-only; export to removable storage covers it |
| Import of documents (invoices, stock entries) | Never; history stays in the old system, as ERPNext advises |
| A saved import log | Imports become frequent enough that past results need reviewing |
| Module Settings, Domain Settings, Session Defaults, Show or Hide Modules | Never; they manage modules and users this app does not have |

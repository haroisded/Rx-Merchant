# Plan 03: Cash Register (Sale Transactions)

Read `00-overview-and-foundation.md` first. This plan covers the selling session, the POS screen, the
calculation of a sale, payment, and what happens when a sale is submitted. Viewing, printing,
returning and cancelling a finished sale are in `05-invoices-and-receipts.md`.

---

## 1. Purpose and ERPNext sources

The Cash Register is ERPNext's Point of Sale: "Item selection, pricing, taxes, stock update, billing,
and payment are combined in a checkout-oriented interface." Each completed sale is a paid Sales
Invoice with Update Stock on.

| ERPNext page | Link | Line in merged doc |
|---|---|---|
| Point of Sale: Introduction | https://docs.frappe.io/erpnext/point-of-sale | 35550 |
| Point of Sale: Getting Started | https://docs.frappe.io/erpnext/point-of-sale/setup | 35567 |
| POS Profile | https://docs.frappe.io/erpnext/pos-profile | 35585 |
| POS Workflows | https://docs.frappe.io/erpnext/pos-workflows | 35698 |
| POS Invoice Consolidation | https://docs.frappe.io/erpnext/pos-invoice-consolidation | 35741 |
| Accounting Workflows by Business Type (Retail and point-of-sale sale) | https://docs.frappe.io/erpnext/accounting-workflows-by-business-type | 3806 |
| Sales Invoice | https://docs.frappe.io/erpnext/sales-invoice | 5947 |
| Delivery from Sales Invoice (Update Stock) | https://docs.frappe.io/erpnext/update-stock-option-in-sales-invoice | 35388 |
| Apply Discounts to Sales Transactions | https://docs.frappe.io/erpnext/applying-discount | 27259 |
| Sell Items in Different Units of Measure | https://docs.frappe.io/erpnext/Selling-in-different-UOM | 28212 |
| Sales Taxes and Charges Template | https://docs.frappe.io/erpnext/sales-taxes-and-charges-template | 13723 |
| Types in Tax Template | https://docs.frappe.io/erpnext/types-in-tax-template | 13339 |
| Tax Inclusive Accounting | https://docs.frappe.io/erpnext/tax-inclusive-accounting | 14225 |
| Item Tax Template | https://docs.frappe.io/erpnext/item-tax-template | 13159 |
| Mode of Payment | https://docs.frappe.io/erpnext/mode-of-payment | 8086 |
| Selling Settings | https://docs.frappe.io/erpnext/selling-settings | 22689 |
| Invoice rounding issue | https://docs.frappe.io/erpnext/invoice-rounding-issue | 19388 |
| Disable Rounded Total | https://docs.frappe.io/erpnext/disable-rounded-total | 42387 |

Two things the merged docs describe only in outline, so the plan uses ERPNext's standard behaviour
and marks it: the fields of the POS Opening and Closing Entry forms (POS-R2, POS-R20), and the exact
order of steps in the totals calculation (POS-R9 to R14).

## 2. Scope

| ERPNext element | In the app | Status | Reason |
|---|---|---|---|
| POS Opening Entry before selling, with opening cash | Same | Kept | |
| POS screen: add items, edit quantities, Pay, select payment mode, Submit | Same | Kept | |
| Select Customer | none | Dropped | Customers excluded |
| POS Invoice, later consolidated into a Sales Invoice at closing | One `sales_invoice` per sale, posted to the stock ledger at once | Adapted | Consolidation exists to spare the General Ledger, which this app does not have. "Sales Invoice with Update Stock" is the documented direct flow |
| "Reserved for POS Transactions" quantity | none | Dropped | Stock is deducted at the moment of sale, so nothing waits to be reserved |
| Sale blocked when not enough stock is on hand | Same | Kept | |
| POS Profile chosen for the session; profile warehouse takes priority over the item's warehouse | No profile. The register always sells from Stock Settings' Default Warehouse, which takes priority over the item's | Adapted | One owner, one register (`00`, section 2; SET-R14) |
| Multiple payment methods on one sale | Same | Kept | |
| Allow Partial Payment, outstanding amount, Unpaid / Overdue / Partly Paid statuses | none | Dropped | No customer to owe the balance |
| Change amount | Same, without "Account for Change Amount" | Kept | |
| Write Off Account, Limit | none | Dropped | Accounts excluded |
| Item discount (% or amount), Additional Discount on Net Total or Grand Total | Same | Kept | |
| Allow User to Edit Rate / Edit Discount | Same | Kept | |
| Taxes from the profile's template, inclusive or exclusive, item tax overrides | Taxes from the default Sales Taxes and Charges Template; the rest the same | Adapted | No POS Profile |
| Sell in another unit of measure | Same | Kept | |
| Rounded Total, Rounding Adjustment, In Words | Same | Kept | |
| Save as draft, Action on New Invoice | Same | Kept | |
| Document named when first saved | Named on Submit | Adapted | Held orders that are discarded must not leave gaps in receipt numbers |
| Print Receipt on Order Complete | Same | Kept | |
| POS Closing Entry: period, session totals, expected and counted amount per payment mode | Same, as a cash-drawer reconciliation | Adapted | It no longer posts ledgers |
| Loyalty points earning and redemption | none | Dropped | Needs customers |
| Pricing Rules, coupon codes | none | Dropped | See `01-setup.md`, section 8 |
| Email receipt | none | Dropped | Offline |

## 3. Data model

```sql
CREATE TABLE pos_opening_entry (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,                         -- assigned on Submit
  docstatus INTEGER NOT NULL DEFAULT 0 CHECK (docstatus IN (0,1,2)),
  status TEXT NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Open','Closed','Cancelled')),
  period_start_datetime TEXT NOT NULL,
  period_end_datetime TEXT
);
-- One open session at a time: one device, one drawer.
CREATE UNIQUE INDEX one_open_session_idx ON pos_opening_entry (status) WHERE status = 'Open';

CREATE TABLE pos_opening_entry_detail (
  id INTEGER PRIMARY KEY,
  pos_opening_entry_id INTEGER NOT NULL REFERENCES pos_opening_entry(id) ON DELETE CASCADE,
  mode_of_payment_id INTEGER NOT NULL REFERENCES mode_of_payment(id),
  opening_amount REAL NOT NULL DEFAULT 0,
  UNIQUE (pos_opening_entry_id, mode_of_payment_id)
);

CREATE TABLE pos_closing_entry (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,
  docstatus INTEGER NOT NULL DEFAULT 0 CHECK (docstatus IN (0,1,2)),
  pos_opening_entry_id INTEGER NOT NULL REFERENCES pos_opening_entry(id),
  period_start_datetime TEXT NOT NULL,
  period_end_datetime TEXT NOT NULL,
  posting_datetime TEXT NOT NULL,
  total_quantity REAL NOT NULL DEFAULT 0,
  net_total REAL NOT NULL DEFAULT 0,
  total_taxes_and_charges REAL NOT NULL DEFAULT 0,
  grand_total REAL NOT NULL DEFAULT 0,
  remarks TEXT
);

-- Payment Reconciliation table of the closing entry.
CREATE TABLE pos_closing_entry_detail (
  id INTEGER PRIMARY KEY,
  pos_closing_entry_id INTEGER NOT NULL REFERENCES pos_closing_entry(id) ON DELETE CASCADE,
  mode_of_payment_id INTEGER NOT NULL REFERENCES mode_of_payment(id),
  opening_amount REAL NOT NULL DEFAULT 0,
  expected_amount REAL NOT NULL DEFAULT 0,
  closing_amount REAL NOT NULL DEFAULT 0,   -- counted by the owner
  difference REAL NOT NULL DEFAULT 0,
  UNIQUE (pos_closing_entry_id, mode_of_payment_id)
);

CREATE TABLE sales_invoice (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,                         -- assigned on Submit
  docstatus INTEGER NOT NULL DEFAULT 0 CHECK (docstatus IN (0,1,2)),
  status TEXT NOT NULL DEFAULT 'Draft'
    CHECK (status IN ('Draft','Paid','Return','Credit Note Issued','Cancelled')),
  posting_datetime TEXT NOT NULL,
  pos_opening_entry_id INTEGER NOT NULL REFERENCES pos_opening_entry(id),
  is_return INTEGER NOT NULL DEFAULT 0,
  return_against_id INTEGER REFERENCES sales_invoice(id),
  update_stock INTEGER NOT NULL DEFAULT 1,
  set_warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  price_list_id INTEGER NOT NULL REFERENCES price_list(id),
  taxes_template_id INTEGER REFERENCES sales_taxes_template(id),
  total_qty REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL DEFAULT 0,            -- sum of item amounts
  net_total REAL NOT NULL DEFAULT 0,        -- sum of item net amounts
  apply_discount_on TEXT NOT NULL DEFAULT 'Grand Total'
    CHECK (apply_discount_on IN ('Grand Total','Net Total')),
  additional_discount_percentage REAL NOT NULL DEFAULT 0,
  discount_amount REAL NOT NULL DEFAULT 0,
  total_taxes_and_charges REAL NOT NULL DEFAULT 0,
  grand_total REAL NOT NULL DEFAULT 0,
  rounding_adjustment REAL NOT NULL DEFAULT 0,
  rounded_total REAL NOT NULL DEFAULT 0,
  in_words TEXT,
  paid_amount REAL NOT NULL DEFAULT 0,
  change_amount REAL NOT NULL DEFAULT 0,
  letter_head_id INTEGER REFERENCES letter_head(id),
  print_heading_id INTEGER REFERENCES print_heading(id),
  tc_id INTEGER REFERENCES terms_and_conditions(id),
  terms TEXT,                               -- Terms and Conditions Details, copied text
  remarks TEXT
);
CREATE INDEX si_posting_idx ON sales_invoice (docstatus, posting_datetime);
CREATE INDEX si_session_idx ON sales_invoice (pos_opening_entry_id);
CREATE INDEX si_return_idx ON sales_invoice (return_against_id);

CREATE TABLE sales_invoice_item (
  id INTEGER PRIMARY KEY,
  sales_invoice_id INTEGER NOT NULL REFERENCES sales_invoice(id) ON DELETE CASCADE,
  idx INTEGER NOT NULL,
  item_id INTEGER NOT NULL REFERENCES item(id),
  item_name TEXT NOT NULL,                  -- copied, so later renames do not change old receipts
  description TEXT,
  qty REAL NOT NULL,                        -- negative on a return
  uom_id INTEGER NOT NULL REFERENCES uom(id),
  conversion_factor REAL NOT NULL DEFAULT 1,
  stock_qty REAL NOT NULL,
  price_list_rate REAL NOT NULL DEFAULT 0,
  discount_percentage REAL NOT NULL DEFAULT 0,
  discount_amount REAL NOT NULL DEFAULT 0,
  rate REAL NOT NULL DEFAULT 0,
  amount REAL NOT NULL DEFAULT 0,
  net_rate REAL NOT NULL DEFAULT 0,
  net_amount REAL NOT NULL DEFAULT 0,
  item_tax_template_id INTEGER REFERENCES item_tax_template(id),
  item_tax_rate TEXT NOT NULL DEFAULT '{}', -- JSON: tax id -> rate, or "NA" for Not Applicable
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  incoming_rate REAL NOT NULL DEFAULT 0,    -- cost per stock unit when posted; feeds Gross Profit
  sales_invoice_item_id INTEGER REFERENCES sales_invoice_item(id)  -- on a return: the original row
);
CREATE INDEX sii_item_idx ON sales_invoice_item (item_id);

CREATE TABLE sales_invoice_tax (
  id INTEGER PRIMARY KEY,
  sales_invoice_id INTEGER NOT NULL REFERENCES sales_invoice(id) ON DELETE CASCADE,
  idx INTEGER NOT NULL,
  charge_type TEXT NOT NULL,
  tax_id INTEGER NOT NULL REFERENCES tax(id),
  description TEXT,
  rate REAL NOT NULL DEFAULT 0,
  row_id INTEGER,
  included_in_print_rate INTEGER NOT NULL DEFAULT 0,
  tax_amount REAL NOT NULL DEFAULT 0,
  tax_amount_after_discount_amount REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL DEFAULT 0,            -- running total after this row
  item_wise_tax_detail TEXT NOT NULL DEFAULT '{}'   -- JSON: item row id -> [rate, amount]
);

CREATE TABLE sales_invoice_payment (
  id INTEGER PRIMARY KEY,
  sales_invoice_id INTEGER NOT NULL REFERENCES sales_invoice(id) ON DELETE CASCADE,
  mode_of_payment_id INTEGER NOT NULL REFERENCES mode_of_payment(id),
  amount REAL NOT NULL                      -- amount tendered; negative on a return
);
```

## 4. Business rules

### Session

**POS-R1 A session is required.** Nothing can be sold, returned or held without an open POS Opening
Entry. Opening the Cash Register with no open session shows the opening dialog. "Before selling, open
a session with an Opening Entry." (POS Workflows.)

**POS-R2 POS Opening Entry.** Fields (ERPNext's standard form, without the POS Profile, which this app
does not keep): period start (now), and one row per enabled Mode of Payment with its Opening Amount,
zero by default. Submitting it sets the status to Open. Only one entry can be Open at a time.

**POS-R2a What a sale starts with.** A new sale copies, from the settings in force when it starts
(SET-R14): the Default Warehouse of Stock Settings into `set_warehouse_id`, the Default Price List of
Selling Settings into `price_list_id`, the default Sales Taxes and Charges Template (if not disabled)
into `taxes_template_id` and its rows, Apply Discount On from POS Settings, the default Letter Head,
and the Print Heading and Terms and Conditions of POS Settings. Changing a setting later changes only
sales started afterwards.

### Building the sale

**POS-R3 Item selector.** Shows items that are enabled, are sales items, are not templates and are not
past End of Life. Each item shows its name, price in the sale's price list, available quantity in the
sale's warehouse, and its image unless POS Settings has Hide images on, in which case the selector is
a list. With Hide unavailable Items on, stock items with no positive stock are hidden. (POS Profile,
Configurations.)

**POS-R4 Finding and adding.**
- The search field matches Item Name, Item Code and barcode. A group filter narrows by Item Group.
- An exact barcode match adds the item to the cart at once, in the barcode's unit if it has one.
- With Automatically Add Filtered Item To Cart on, a search that leaves exactly one item adds it.
- Adding an item that is already in the cart with the same unit, rate and batch increases that line's
  quantity by 1. Otherwise a new line is added.
- A stock item with less available than the line would need is refused with "Item is unavailable",
  unless negative stock is allowed for it (STK-R34).

**POS-R5 Quantity and unit.** Quantity is positive. The unit defaults to the item's Default Sales
Unit of Measure, else its Stock UOM; only units in the item's UoM table are offered.
`stock_qty = qty × conversion_factor`. Whole-number units refuse fractions (STK-R3). (Sell Items in
Different Units of Measure.)

**POS-R6 Price.** Price List Rate comes from the lookup in STK-R10 for the sale's price list, the
line's unit and the posting date. Changing the unit looks the price up again. Price List Rate is
editable only when Selling Settings allows editing it. "Price List Rate remains the reference rate."
(Apply Discounts.)

**POS-R7 Editing the rate.** Allowed only when POS Settings has Allow User to Edit Rate. A rate below
the Price List Rate is recorded as a discount: `discount_percentage = (price_list_rate − rate) ÷
price_list_rate × 100`. A rate above it leaves the discount at zero.

**POS-R8 Item discount.** Allowed only when POS Settings has Allow User to Edit Discount. Enter either
Discount (%) or Discount Amount; the other is derived. `rate = price_list_rate − discount_amount`.
"Item-level discounts are calculated against the Price List Rate." If the item has Max Discount (%)
above zero, a larger percentage is refused. Example: Price List Rate 200, discount 10%, rate 180;
quantity 2, amount 360. (Apply Discounts; Item, 3.13.)

### The totals engine

One pure function recalculates the whole sale after every change. The steps and their order are
ERPNext's.

**POS-R9 Item values and net total.** For each line: `amount = flt(rate × qty)`, and to start with
`net_rate = rate`, `net_amount = amount`. Then `total_qty = Σ qty`, `total = Σ amount`,
`net_total = Σ net_amount`.

**POS-R10 Tax rows.** The default template's rows are copied into the sale when it starts (SET-R10,
POS-R2a).
They are calculated in order; each produces an Amount and a running Total.

| Type | Amount for the row |
|---|---|
| Actual | The fixed Tax Amount, shared over the lines in proportion to net amount |
| On Net Total | For each line: net amount × rate ÷ 100 |
| On Previous Row Amount | For each line: that line's share of the referenced row's Amount × rate ÷ 100 |
| On Previous Row Total | For each line: that line's running total after the referenced row × rate ÷ 100 |
| On Item Quantity | For each line: quantity × rate (an amount per unit) |

Per-line amounts are summed and the row's Amount is rounded to Currency Precision. Running Total =
previous row's Total (Net Total for the first row) + Amount. Each row stores the per-line breakdown
for the tax summary on the print. (Types in Tax Template.)

**POS-R11 Item tax override.** For each line, find its Item Tax Template (STK-R13). Where the
template has a row for the same `tax` as a tax row, that rate replaces the row's rate for this line;
Not Applicable makes the line's amount for that row zero. The rates in force are copied into the
line's `item_tax_rate` so the sale no longer depends on the template. (Item Tax Template.)

Example: 8% On Net Total; lines 699 (no template), 149 (4% template), 99 (0% template). Tax =
55.92 + 5.96 + 0.00 = 61.88. Net Total 947.00, Grand Total 1,008.88.

**POS-R12 Tax included in the basic rate.** For rows marked as included, the entered rate already
contains the tax, so the net amount is worked backwards before the rows are calculated:

- Each included row contributes a fraction for the line: On Net Total contributes rate ÷ 100; On
  Previous Row Amount contributes rate ÷ 100 × the referenced row's fraction; On Previous Row Total
  contributes rate ÷ 100 × (1 + the fractions up to the referenced row). Item overrides apply.
- `net_amount = (amount − included per-unit charges × qty) ÷ (1 + sum of fractions)`, then
  `net_rate = net_amount ÷ qty`.
- When every tax row is included, the Grand Total must equal the sum of the entered amounts. A
  rounding remainder of a few of the smallest units is added to the last tax row.

Example: rate 108, 8% included: net 100.00, tax 8.00, Grand Total 108.00, not 116.64. The line shows
Rate 108.00 and Net Rate 100.00. (Tax Inclusive Accounting.)

**POS-R13 Additional discount.** Entered as a percentage or an amount, applied on the sale's Apply
Discount On (copied from POS Settings). Editing it requires Allow User to Edit Discount.

- **On Net Total.** `discount_amount = flt(net_total × percentage ÷ 100)` when a percentage is given.
  Each line's net amount is reduced by `discount_amount × line net amount ÷ net_total`; the last line
  absorbs the rounding remainder. Taxes are then recalculated on the reduced amounts.
- **On Grand Total.** `discount_amount = flt(grand_total × percentage ÷ 100)` when a percentage is
  given. Each line's net amount is reduced by `discount_amount × line net amount ÷ (grand_total −
  taxes of type Actual and On Item Quantity)`. Taxes are recalculated, and the new Grand Total is the
  old one minus the discount.
- An item discount and an additional discount can both apply to the same sale.

Example with one line of 1,000 and 8% tax added on top (Grand Total 1,080 before discount):

| Discount | On Net Total | On Grand Total |
|---|---|---|
| 10% | Net 900.00, tax 72.00, Grand Total 972.00 | Discount 108.00; net 900.00, tax 72.00, Grand Total 972.00 |
| Amount 50 | Net 950.00, tax 76.00, Grand Total 1,026.00 | Net 953.70, tax 76.30, Grand Total 1,030.00 |

(Apply Discounts: "Discount on Net Total… Discount on Grand Total".)

**POS-R14 Grand Total and Rounded Total.**
- `grand_total = net_total + total_taxes_and_charges`.
- Rounded Total rounds the Grand Total to the currency's Smallest Currency Fraction Value: divide,
  take the remainder, round up when the remainder is more than half the fraction, otherwise down. With
  no fraction set it rounds to a whole unit. `rounding_adjustment = rounded_total − grand_total`.
- With Disable Rounded Total on, there is no Rounded Total and the amount to pay is the Grand Total.
- Amount to pay = Rounded Total when it exists, otherwise Grand Total.
- In Words spells the amount to pay using the currency's name and Fraction, unless Disable In Words
  is on.

Example: Grand Total 754.92. Fraction 0.01: Rounded Total 754.92. Fraction 0.05: Rounded Total
754.90, adjustment −0.02. No fraction: 755, adjustment +0.08. (Disable Rounded Total; Invoice
rounding issue; Currency.)

### Payment

**POS-R15 Payment.**
- Every enabled Mode of Payment is offered. With Set Grand Total to Default Payment Method on, the
  Default Mode of Payment of POS Settings is pre-filled with the amount to pay (Cash when that mode is
  missing or disabled, SET-R14).
- Several modes can share one sale. The sale cannot be completed until the payments cover the amount
  to pay. There is no partial payment.
- `paid_amount = Σ payments`. `change_amount = paid_amount − amount to pay`.
- Change is cash. Change cannot exceed the amount tendered in modes of Type Cash, so a card or bank
  mode cannot be entered for more than what is still due.

Examples on an amount to pay of 754.90: cash 1,000 gives change 245.10. Card 500 and cash 300 gives
change 45.10. Card 800 is refused. (POS Profile, Payment Methods; Mode of Payment.)

### Completing the sale

**POS-R16 Checks on Submit.** All problems are reported together.
1. A POS Opening Entry is open.
2. The cart has at least one line and every quantity is above zero.
3. Every item is still enabled, a sales item, not a template, not past End of Life.
4. Quantities respect whole-number units.
5. No item discount exceeds the item's Max Discount.
6. With "Validate selling price against purchase or valuation rate" on: no line's net rate per stock
   unit is below the item's valuation rate in the warehouse.
7. Stock: each stock item has enough in the sale's warehouse as of the posting date and time,
   unless negative stock is allowed for it. The same check runs when a draft is saved if POS Settings
   has Validate Stock on Save.
8. Batch and serial lines have entries that add up to the line quantity (POS-R21).
9. Payments satisfy POS-R15.

**POS-R17 Effects of Submit.** In one transaction:
1. The name is taken from the Sales Invoice naming series.
2. For each stock-item line, a Stock Ledger Entry of `−stock_qty` is written against the sale's
   warehouse (Stock Settings' Default Warehouse), which "gets priority" over the item's own, as the
   POS Profile warehouse does in ERPNext. The cost per stock unit that the ledger
   returns is saved on the line as `incoming_rate`.
3. Serial numbers on the sale become Delivered and get their warranty expiry (STK-R24, R26).
4. With auto-insert on, a missing Item Price is created (STK-R11).
5. Status becomes Paid, `docstatus` 1.
6. The order summary is shown. With Print Receipt on Order Complete, the print preview opens.

**POS-R18 Held orders.** "Save as Draft" stores the cart as a draft invoice with no name and no stock
effect. Starting a new sale while the cart has unsaved changes follows Action on New Invoice: Always
Ask, Save Changes and Load New Invoice, or Discard Changes and Load New Invoice. A held order can be
reopened, edited, completed or deleted. Prices and stock are re-checked when it is completed. A held
order completed in a later session is attached to that session. (POS Profile.)

**POS-R19 Recent orders.** A list of the register's invoices filtered by status (Draft, Paid,
Return), searchable by name. A draft offers Edit and Delete. A paid sale offers Print Receipt and
Return, which starts the flow in `05-invoices-and-receipts.md`.

### Closing

**POS-R20 POS Closing Entry.** "Close the POS" builds a closing entry for the open session (ERPNext's
standard form):
- Period start (from the opening entry) and period end (now).
- The session's submitted invoices, sales and returns, with their count.
- Total Quantity, Net Total, taxes and Grand Total summed over them. Returns are negative.
- Payment Reconciliation, one row per payment mode on the opening entry or used in the session (a mode
  enabled mid-session gets a row with Opening Amount 0): Opening Amount; Expected Amount = opening amount
  + payments received in that mode − refunds paid in that mode − change given (change is taken from
  the Cash-type mode of the sale); Closing Amount, typed by the owner after counting; Difference =
  Closing Amount − Expected Amount.
- Remarks, for explaining a difference.

Submitting it sets the opening entry to Closed and takes a backup (SET-R17). Held orders are not
affected; the screen says how many remain. The most recent closing entry can be cancelled while no
newer session exists, which reopens the session. "Confirm opening and closing procedures and
cash-difference responsibility." (POS Workflows; Accounting Workflows by Business Type.)

Example: opening cash 500. Sale A: cash 1,000, change 245.10. Sale B: card 500, cash 300, change
45.10. Return C: cash refund 108. Expected cash = 500 + 1,000 + 300 − 245.10 − 45.10 − 108 =
1,401.80; expected card = 500. Counting 1,400 in cash gives a difference of −1.80.

### Batches and serial numbers at the counter

**POS-R21.** A cart line for a batch or serial item needs its entries before Submit (STK-R27).
- Scanning or typing a serial number in the search field finds its item and adds a line for that
  exact unit. Scanning further serial numbers of the same item adds them to the line.
- Scanning a batch barcode is not assumed; batches are chosen in the item detail panel.
- With "Auto Create Serial and Batch Bundle For Outward" on, a line left without entries is filled at
  Submit using Pick Serial / Batch Based On. With it off, Submit is refused until they are chosen.
- Only Available serial numbers in the sale's warehouse, and unexpired batches with stock there,
  can be chosen.

## 5. Screens

The layout follows ERPNext's POS: an item selector, a cart, an item detail panel, a payment panel and
an order summary. The Cash Register is the one screen that uses two panes from Medium width up.

### Opening dialog

`AlertDialog` on Compact, centred card otherwise: a list of the enabled payment modes with an Opening
Amount field each, and "Open" as the `FilledButton`.

### POS screen

| Area | Content |
|---|---|
| Item selector | `SearchBar` with a scan button; Item Group `DropdownMenu`; grid of item `Card`s (image, name, price, available quantity; quantity in `ColorScheme.error` at zero) or a `ListTile` list when Hide images is on |
| Cart | Lines with name, quantity × rate, amount, and discount when present; swipe to remove. Below: Net Total, each tax row, discount, Grand Total, Rounded Total. Buttons: "Add Discount" (`OutlinedButton`), "Checkout" (`FilledButton`) |
| Item detail | Quantity (stepper and field), UOM, Rate, Discount (%), Discount Amount, Price List Rate, Available Qty, warehouse, Serial / Batch Entries when relevant. Fields POS Settings does not allow are read-only |
| Payment | One `Card` per payment mode with its amount; a number pad; Grand Total, Paid Amount, and To Be Paid or Change; "Complete Order" |
| Order summary | Invoice name and status chip, lines, totals, payments, change. Buttons: "Print Receipt", "New Order" |
| Menu (`MenuAnchor` in the app bar) | Toggle Recent Orders, Save as Draft, Close the POS |

| Width class | Arrangement |
|---|---|
| Compact | Two steps. Step 1: the selector fills the screen, with a bottom bar showing line count and Grand Total that opens step 2, the cart. Item detail is a bottom sheet. Payment and summary are full screens. Grid is 2 columns. |
| Medium | Selector on the left, cart on the right (about 340dp). Item detail and payment open as side sheets over the selector. Grid is 2 to 3 columns. |
| Expanded | Selector on the left, cart on the right (about 400dp). Item detail and payment replace the selector pane, as in ERPNext, so the cart stays visible. A number pad with Quantity, Discount, Rate and Remove sits under the cart. Grid is 4 or more columns. |

The camera scanner opens as a full-screen sheet and returns to the selector after each scan; scanning
again is one tap.

### Closing entry form

Header with period and session totals; the invoice count as a link to the list; the Payment
Reconciliation table with an editable Closing Amount column and the Difference shown in
`ColorScheme.error` when not zero; Remarks; "Submit". Compact shows each payment mode as a card.

### States

- No open session: the opening dialog.
- Empty cart: "Scan or tap an item to start a sale."
- No items match: "No items found", with "Add Item" when the search text could be a new item.
- Submit problems: one dialog listing every failed check from POS-R16, each naming the line.

## 6. Build steps

| Step | Work | Runnable result |
|---|---|---|
| POS-B1 | POS Opening Entry dialog and gate (POS-R1, R2) | The Cash Register asks to open a session, then opens |
| POS-B2 | Totals engine in `logic/` with all of POS-R9 to R14 and its unit tests | Every worked example in section 4 passes |
| POS-B3 | Item selector and cart: search, group filter, grid and list, barcode scan, add and merge, stock check on add (POS-R3 to R5) | Items can be scanned into a cart with live totals |
| POS-B4 | Item detail panel and Add Discount, with POS Settings permissions (POS-R6 to R8, R13) | Unit, rate and discounts change the totals correctly |
| POS-B5 | Payment panel: modes, split payment, change, default amount (POS-R15) | Change is right for cash, split and refused overpayment |
| POS-B6 | Submit: checks, naming, ledger posting, statuses, order summary (POS-R16, R17) | A sale reduces stock and appears in the Stock Ledger |
| POS-B7 | Save as Draft, Action on New Invoice, Recent Orders (POS-R18, R19) | A held order survives an app restart and can be completed |
| POS-B8 | POS Closing Entry with expected amounts and backup (POS-R20) | The example in POS-R20 reproduces |
| POS-B9 | Serial and batch entries in the cart, serial scan, auto pick at Submit (POS-R21) | A serialised unit is sold by scanning its serial number |

B1 to B8 are milestone M5. B9 is part of M8, after STK-B11 to B13.

## 7. Acceptance checks

Unit tests on the totals engine:

| Check | Expected |
|---|---|
| POS-A1 One line 699, 8% On Net Total | Tax 55.92; Grand Total 754.92 |
| POS-A2 Rate 108, 8% included in basic rate | Net 100.00; tax 8.00; Grand Total 108.00 |
| POS-A3 Lines 699 (8%), 149 (4% template), 99 (0% template) | Tax 61.88; Net Total 947.00; Grand Total 1,008.88 |
| POS-A4 A line whose template marks the tax Not Applicable | Tax 0 for the line; stored as "NA", not 0 |
| POS-A5 Net 1,000: row 1 8% On Net Total; row 2 2% On Previous Row Amount | 80.00 and 1.60; Grand Total 1,081.60 |
| POS-A6 Same with row 2 On Previous Row Total | 80.00 and 21.60; Grand Total 1,101.60 |
| POS-A7 Actual 25 on net 1,000 | Grand Total 1,025.00 |
| POS-A8 On Item Quantity, rate 2, total quantity 5 | 10.00 |
| POS-A9 Price List Rate 200, discount 10%, quantity 2 | Rate 180; amount 360 |
| POS-A10 Discount 25% on an item with Max Discount 20% | Refused |
| POS-A11 The four cells of the table in POS-R13 | As shown |
| POS-A12 Grand Total 754.92 with fraction 0.01 / 0.05 / none | 754.92 / 754.90 (−0.02) / 755 (+0.08) |
| POS-A13 Grand Total 754.93 with fraction 0.05 | 754.95 |
| POS-A14 Amount to pay 754.90: cash 1,000; card 500 + cash 300; card 800 | Change 245.10; change 45.10; refused |
| POS-A15 3 Cartons at factor 10 | `stock_qty` 30 |
| POS-A16 Two lines at 54 each with 8% included, all rows included | Grand Total exactly 108.00 |

Database tests:

| Check | Expected |
|---|---|
| POS-A17 Submit a sale of 2 units of a FIFO item received at 100 | Ledger entry −2; `incoming_rate` 100; status Paid; name `ACC-SINV-{year}-00001` |
| POS-A18 Save three drafts, delete two, submit the third | Its name is `…-00001`; no gaps |
| POS-A19 Sell more than is in stock with negative stock off | Refused; nothing written |
| POS-A20 Submit with payments below the amount to pay | Refused |
| POS-A21 Open a second session while one is Open | Refused |
| POS-A22 The closing example in POS-R20 | Expected cash 1,401.80; card 500; difference −1.80 |
| POS-A23 Edit a tax template after a sale | The sale's tax rows and totals are unchanged |
| POS-A24 Complete a held order in a later session | It belongs to the later session's closing entry |
| POS-A25 Sell a serial number that is Delivered | Refused |

Manual checks: a 20-line sale on a phone and on a tablet in both orientations; rotate mid-sale and
the cart is intact; scan ten items in a row with the camera; kill the app mid-sale and the held order
is offered on restart only if it was saved, with no half-written invoice.

## 8. Left out on purpose

| Not built | Add it when |
|---|---|
| Customer on the sale, credit sales, partial payment | The store starts selling on account |
| Loyalty points | Customers are added |
| Pricing Rules, promotional schemes, coupon codes | The owner wants automatic promotions |
| POS Invoice consolidation and "Reserved for POS Transactions" | Never; they solve a ledger-load problem this app does not have |
| Write-off of small shortfalls | Never without accounts; rounding to the smallest coin covers cash sales |
| Several open sessions at once | A second counter runs on the same device, which one device cannot do |
| Email or SMS receipts | The app is allowed online |
| Sales Order, Quotation, Delivery Note | The store takes orders for later delivery |

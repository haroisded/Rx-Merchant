# Plan 02: Stocks

Read `00-overview-and-foundation.md` first. This plan covers the item catalogue, prices, warehouses,
stock transactions, the stock ledger and valuation engine, item variants, batches, serial numbers and
the stock reports.

---

## 1. Purpose and ERPNext sources

Stock answers three questions at any moment: what do I have, where is it, and what is it worth. Every
movement is one line in the Stock Ledger, and everything else (balances, valuation, reports, the
profit figure on the dashboard) is derived from it.

| ERPNext page | Link | Line in merged doc |
|---|---|---|
| Introduction to Stock Module | https://docs.frappe.io/erpnext/stock | 29956 |
| Warehouse | https://docs.frappe.io/erpnext/warehouse | 29968 |
| Item | https://docs.frappe.io/erpnext/item | 30053 |
| Item Group | https://docs.frappe.io/erpnext/item-group | 30357 |
| Unit of Measure (UoM) | https://docs.frappe.io/erpnext/uom | 30422 |
| Serial and Batch | https://docs.frappe.io/erpnext/serial-and-batch | 30436 |
| Item Variants | https://docs.frappe.io/erpnext/item-variants | 30448 |
| Item Attribute | https://docs.frappe.io/erpnext/item-attribute | 30504 |
| Brand | https://docs.frappe.io/erpnext/brand | 30542 |
| Item Price | https://docs.frappe.io/erpnext/item-price | 30727 |
| Opening Stock | https://docs.frappe.io/erpnext/opening-stock | 30798 |
| Stock Settings | https://docs.frappe.io/erpnext/stock-settings | 30826 |
| FIFO and Moving Average | https://docs.frappe.io/erpnext/fifo-and-moving-average | 31311 |
| Stock Entry | https://docs.frappe.io/erpnext/stock-entry | 32025 |
| Stock Reconciliation | https://docs.frappe.io/erpnext/stock-reconciliation | 32180 |
| Batch | https://docs.frappe.io/erpnext/batch | 32318 |
| Serial Number | https://docs.frappe.io/erpnext/serial-no | 32387 |
| Serial and Batch Bundle | https://docs.frappe.io/erpnext/serial-and-batch-bundle | 32459 |
| Managing Batch wise Inventory | https://docs.frappe.io/erpnext/managing-batch-wise-inventory | 33123 |
| Auto Creation of Material Request | https://docs.frappe.io/erpnext/auto-creation-of-material-request | 33202 |
| Projected Quantity | https://docs.frappe.io/erpnext/projected-quantity | 33721 |
| Use Inline Serial / Batch Editor | https://docs.frappe.io/erpnext/use-inline-serial-batch-editor | 33869 |
| Use Serial No Wise Valuation | https://docs.frappe.io/erpnext/use-serial-no-wise-valuation | 33946 |
| Stock Ledger Report | https://docs.frappe.io/erpnext/stock-ledger | 34270 |
| Stock Level Report | https://docs.frappe.io/erpnext/stock-level-report | 34309 |
| Quick Stock Balance | https://docs.frappe.io/erpnext/quick-stock-balance | 34332 |
| Closing Stock Balance | https://docs.frappe.io/erpnext/closing-stock-balance | 34356 |
| Managing Fractions in UOM | https://docs.frappe.io/erpnext/managing-fractions-in-uom | 34676 |
| Delivery Note Negative Stock Error | https://docs.frappe.io/erpnext/delivery-note-stock-error | 34748 |
| Maintain Stock field Frozen in the Item master | https://docs.frappe.io/erpnext/maintain-stock-field-frozen-in-item-master | 34756 |
| Item Codification | https://docs.frappe.io/erpnext/item-codification | 34877 |
| Track Items Using Barcode | https://docs.frappe.io/erpnext/track-items-using-barcode | 34969 |
| Item Valuation Setup and Transactions | https://docs.frappe.io/erpnext/item-valuation-transactions | 34998 |
| FIFO and Moving Average calculation difference | https://docs.frappe.io/erpnext/calculation-of-valuation-rate-in-fifo-and-moving-average | 35028 |
| Serialised Item Valuation Rate calculation | https://docs.frappe.io/erpnext/how-is-valuation-rate-of-serialised-item-calculated-in-erpnext | 35064 |
| Opening Stock Balance Entry for Serialized and Batch Item | https://docs.frappe.io/erpnext/opening-stock-balance-entry-for-serialized-and-batch-item | 35242 |
| Stock Entry Purpose | https://docs.frappe.io/erpnext/stock-entry-purpose | 35299 |
| Sell Items in Different Units of Measure | https://docs.frappe.io/erpnext/Selling-in-different-UOM | 28212 |

## 2. Scope

| ERPNext element | In the app | Status | Reason |
|---|---|---|---|
| Warehouse: name, Parent Warehouse, Is Group, Warehouse Type, tree view, Stock Balance shortcut | Same | Kept | |
| Warehouse: Account, address and contact, company abbreviation in the name | none | Dropped | Accounts and multi-company excluded |
| Item: Item Code, Item Name, Item Group, Default Unit of Measure, Disabled, Maintain Stock, Valuation Rate, Standard Selling Rate, opening stock, image, Brand, Description | Same | Kept | |
| Item: Barcodes table (EAN, UPC, UoM-specific) | Same | Kept | |
| Item: Shelf Life In Days, End of Life, Warranty, Valuation Method, Allow negative stock | Same | Kept | |
| Item: Automatic Reordering (Re-order Level, Re-order Qty per warehouse) | Kept; raises a low-stock list entry | Adapted | No Material Request without purchasing |
| Item: Multiple Units of Measure with conversion factor | Same | Kept | |
| Item: Has Batch No, Batch Number Series, Automatically Create New Batch, Has Expiry Date, Has Serial No, Serial Number Series | Same | Kept | |
| Item: Has Variants and the attributes table | Same | Kept | |
| Item: Default Warehouse | Same | Kept | |
| Item: Default Sales Unit of Measure, Max Discount (%), Is Sales Item | Same | Kept | |
| Item: Item Tax (template, Valid From) | Same | Kept | |
| Item: Is Fixed Asset, Auto Create Assets | none | Dropped | Fixed assets excluded |
| Item: default accounts, cost center, deferred revenue and expense | none | Dropped | Accounts excluded |
| Item: supplier, purchase and foreign-trade sections, Safety Stock, Lead Time, Default Material Request Type | none | Dropped | No purchasing |
| Item: Customer Details, Grant Commission | none | Dropped | Customers and sales persons excluded |
| Item: manufacturing, inspection, website, hub, alternative item, weight, retain sample | none | Dropped | Outside the five areas |
| Item Group: tree, Item Tax template | Same | Kept | |
| Item Group: default price list, warehouse, accounts, supplier, website | none | Dropped | Selling Settings supplies the price list and Stock Settings the warehouse |
| UoM: name, Must be Whole Number | Same | Kept | |
| UoM Conversion Factor (global list) | none | Dropped | Conversions are entered on the item |
| Brand: name, description | Same | Kept | |
| Brand defaults | none | Dropped | Same reason as Item Group |
| Item Attribute: text values with abbreviations, numeric range and increment | Same | Kept | |
| Item Variants based on attributes; single and multiple creation; template updates variants | Same | Kept | |
| Item Variants based on Manufacturers | none | Dropped | Manufacturer master is not kept |
| Item Price: Item, Price List, UOM, Rate, Valid From, Valid Upto, Batch, Note | Same | Kept | |
| Item Price: customer, supplier, Packing Unit, Minimum quantity, Lead Time | none | Dropped | Customers and purchasing excluded |
| Stock Settings: Item Naming By, Default Item Group, Default Stock UOM, Default Warehouse, Default Valuation Method, Show Barcode Field, Auto insert Price List rate if missing, Allow Negative Stock, Stock Frozen Upto, Enable Serial and Batch No for Item, Pick Serial / Batch Based On, Auto Create Serial and Batch Bundle For Outward | Same | Kept | |
| Stock Settings: Raise Material Request when stock reaches re-order level | "Show low-stock alerts" | Adapted | |
| Stock Settings: Allow UOM with Conversion Rate Defined in Item | Always on | Adapted | A unit without a conversion cannot be sold correctly |
| Stock Settings: limit percent, over-delivery role, inter-warehouse transfer via Delivery Note, sample retention, freeze by age, email notification | none | Dropped | Depend on orders, users or documents not kept |
| Valuation: FIFO, Moving Average | Same | Kept | |
| Valuation: Standard Cost, LIFO | none | Dropped | Section 8 |
| Stock Entry: Material Receipt, Material Issue, Material Transfer | Same | Kept | |
| Stock Entry: manufacturing purposes, Repack, Send to Subcontractor, Add to Transit, Stock Entry Type master, inspection | none | Dropped | Outside the five areas |
| Stock Entry: Additional Costs | Description and amount | Adapted | Expense Account dropped |
| Stock Entry: Is Opening, Remarks, Edit Posting Date and Time, Allow Zero Valuation Rate | Same | Kept | |
| Stock Reconciliation: Opening Stock and Stock Reconciliation purposes, fetch items as of a date, CSV upload, Scan Mode | Same | Kept | |
| Stock Reconciliation: Difference Account, Cost Center | none | Dropped | Accounts excluded |
| Stock Reconciliation for serial and batch items | Use Stock Entry instead | Adapted | Follows the older rule in the docs (line 35242); see section 8 |
| Batch: Batch ID, Item, expiry date and status, manufacturing date | Same | Kept | |
| Serial No: number, item, status, warehouse, warranty expiry | Same | Kept | |
| Serial and Batch Bundle | Rows in `serial_and_batch_entry` grouped by transaction line | Adapted | One table gives the same guarantee: a set of rows belongs to exactly one line |
| Inline Serial / Batch Editor: add, edit, delete, Auto Fetch, Scan, Create Serial Nos from Range, CSV | Same | Kept | |
| Serial-wise valuation | Always on | Adapted | A single store has few enough serials |
| Stock Ledger, Stock Balance, Quick Stock Balance, Batch-wise Balance History, Serial No Ledger, Item Price Stock | Same | Kept | |
| Stock Projected Qty | Low-stock list | Adapted | With no orders or reservations, projected equals actual |
| Purchase Receipt, Delivery Note, Product Bundle, Landed Cost Voucher, Quality Inspection, Pick List, Putaway Rule, Packing Slip, Shipment, Stock Reservation, Inventory Dimension | none | Dropped | Not in the five areas |

## 3. Data model

```sql
CREATE TABLE warehouse (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  parent_id INTEGER REFERENCES warehouse(id),
  is_group INTEGER NOT NULL DEFAULT 0,
  warehouse_type TEXT,
  disabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE item_group (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  parent_id INTEGER REFERENCES item_group(id),
  is_group INTEGER NOT NULL DEFAULT 0,
  item_tax_template_id INTEGER REFERENCES item_tax_template(id)
);

CREATE TABLE uom (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  must_be_whole_number INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE brand (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE item (
  id INTEGER PRIMARY KEY,
  item_code TEXT NOT NULL UNIQUE,
  item_name TEXT NOT NULL,
  item_group_id INTEGER NOT NULL REFERENCES item_group(id),
  stock_uom_id INTEGER NOT NULL REFERENCES uom(id),     -- Default Unit of Measure
  disabled INTEGER NOT NULL DEFAULT 0,
  is_stock_item INTEGER NOT NULL DEFAULT 1,             -- Maintain Stock
  is_sales_item INTEGER NOT NULL DEFAULT 1,
  description TEXT,
  image BLOB,                                           -- JPEG, longest side 512px
  brand_id INTEGER REFERENCES brand(id),
  standard_rate REAL NOT NULL DEFAULT 0,                -- Standard Selling Rate, used on create
  valuation_rate REAL NOT NULL DEFAULT 0,               -- fallback cost when the ledger has none
  valuation_method TEXT CHECK (valuation_method IN ('FIFO','Moving Average')),  -- NULL = setting
  allow_negative_stock INTEGER NOT NULL DEFAULT 0,
  shelf_life_in_days INTEGER,
  end_of_life TEXT,
  warranty_period INTEGER,                              -- days
  sales_uom_id INTEGER REFERENCES uom(id),
  max_discount REAL NOT NULL DEFAULT 0,
  default_warehouse_id INTEGER REFERENCES warehouse(id),
  has_variants INTEGER NOT NULL DEFAULT 0,
  variant_of_id INTEGER REFERENCES item(id),
  has_batch_no INTEGER NOT NULL DEFAULT 0,
  create_new_batch INTEGER NOT NULL DEFAULT 0,          -- Automatically Create New Batch
  batch_number_series TEXT,
  has_expiry_date INTEGER NOT NULL DEFAULT 0,
  has_serial_no INTEGER NOT NULL DEFAULT 0,
  serial_no_series TEXT
);
CREATE INDEX item_group_idx ON item (item_group_id);
CREATE INDEX item_variant_of_idx ON item (variant_of_id);

CREATE TABLE item_barcode (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  barcode TEXT NOT NULL UNIQUE,
  barcode_type TEXT CHECK (barcode_type IN ('EAN','UPC')),
  uom_id INTEGER REFERENCES uom(id)
);

CREATE TABLE item_uom (
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  uom_id INTEGER NOT NULL REFERENCES uom(id),
  conversion_factor REAL NOT NULL,      -- stock units in one of this unit
  PRIMARY KEY (item_id, uom_id)
);

CREATE TABLE item_reorder (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  warehouse_reorder_level REAL NOT NULL DEFAULT 0,
  warehouse_reorder_qty REAL NOT NULL DEFAULT 0,
  UNIQUE (item_id, warehouse_id)
);

CREATE TABLE item_tax (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  item_tax_template_id INTEGER NOT NULL REFERENCES item_tax_template(id),
  valid_from TEXT
);

CREATE TABLE item_attribute (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  numeric_values INTEGER NOT NULL DEFAULT 0,
  from_range REAL, to_range REAL, increment REAL
);

CREATE TABLE item_attribute_value (
  id INTEGER PRIMARY KEY,
  attribute_id INTEGER NOT NULL REFERENCES item_attribute(id) ON DELETE CASCADE,
  attribute_value TEXT NOT NULL,
  abbr TEXT NOT NULL,
  UNIQUE (attribute_id, attribute_value),
  UNIQUE (attribute_id, abbr)
);

-- On a template: which attributes it varies by (attribute_value NULL).
-- On a variant: the value it has for each attribute.
CREATE TABLE item_variant_attribute (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  attribute_id INTEGER NOT NULL REFERENCES item_attribute(id),
  attribute_value TEXT,
  UNIQUE (item_id, attribute_id)
);

CREATE TABLE batch (
  id INTEGER PRIMARY KEY,
  batch_id TEXT NOT NULL UNIQUE,
  item_id INTEGER NOT NULL REFERENCES item(id),
  manufacturing_date TEXT,
  expiry_date TEXT,
  disabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE serial_no (
  id INTEGER PRIMARY KEY,
  serial_no TEXT NOT NULL UNIQUE,
  item_id INTEGER NOT NULL REFERENCES item(id),
  status TEXT NOT NULL DEFAULT 'Inactive' CHECK (status IN ('Inactive','Available','Delivered')),
  warehouse_id INTEGER REFERENCES warehouse(id),        -- set only while Available
  batch_id INTEGER REFERENCES batch(id),
  incoming_rate REAL NOT NULL DEFAULT 0,                -- what this unit cost
  warranty_expiry_date TEXT
);
CREATE INDEX serial_item_status_idx ON serial_no (item_id, status, warehouse_id);

CREATE TABLE item_price (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  price_list_id INTEGER NOT NULL REFERENCES price_list(id),
  uom_id INTEGER REFERENCES uom(id),                    -- NULL = Stock UOM
  price_list_rate REAL NOT NULL,
  valid_from TEXT,
  valid_upto TEXT,
  batch_id INTEGER REFERENCES batch(id),
  note TEXT
);
CREATE INDEX item_price_lookup_idx ON item_price (item_id, price_list_id, uom_id);

CREATE TABLE stock_entry (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,                                     -- assigned on Submit
  docstatus INTEGER NOT NULL DEFAULT 0 CHECK (docstatus IN (0,1,2)),
  purpose TEXT NOT NULL CHECK (purpose IN ('Material Receipt','Material Issue','Material Transfer')),
  posting_datetime TEXT NOT NULL,
  from_warehouse_id INTEGER REFERENCES warehouse(id),   -- Default Source Warehouse
  to_warehouse_id INTEGER REFERENCES warehouse(id),     -- Default Target Warehouse
  is_opening INTEGER NOT NULL DEFAULT 0,
  remarks TEXT,
  total_outgoing_value REAL NOT NULL DEFAULT 0,
  total_incoming_value REAL NOT NULL DEFAULT 0,
  total_additional_costs REAL NOT NULL DEFAULT 0,
  total_amount REAL NOT NULL DEFAULT 0,
  amended_from_id INTEGER REFERENCES stock_entry(id)
);

CREATE TABLE stock_entry_item (
  id INTEGER PRIMARY KEY,
  stock_entry_id INTEGER NOT NULL REFERENCES stock_entry(id) ON DELETE CASCADE,
  idx INTEGER NOT NULL,
  item_id INTEGER NOT NULL REFERENCES item(id),
  s_warehouse_id INTEGER REFERENCES warehouse(id),      -- Source Warehouse
  t_warehouse_id INTEGER REFERENCES warehouse(id),      -- Target Warehouse
  qty REAL NOT NULL,
  uom_id INTEGER NOT NULL REFERENCES uom(id),
  conversion_factor REAL NOT NULL DEFAULT 1,
  transfer_qty REAL NOT NULL,                           -- qty in Stock UOM
  basic_rate REAL NOT NULL DEFAULT 0,                   -- per Stock UOM
  basic_amount REAL NOT NULL DEFAULT 0,
  additional_cost REAL NOT NULL DEFAULT 0,
  amount REAL NOT NULL DEFAULT 0,
  valuation_rate REAL NOT NULL DEFAULT 0,
  allow_zero_valuation_rate INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE stock_entry_additional_cost (
  id INTEGER PRIMARY KEY,
  stock_entry_id INTEGER NOT NULL REFERENCES stock_entry(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount REAL NOT NULL
);

CREATE TABLE stock_reconciliation (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,
  docstatus INTEGER NOT NULL DEFAULT 0 CHECK (docstatus IN (0,1,2)),
  purpose TEXT NOT NULL CHECK (purpose IN ('Opening Stock','Stock Reconciliation')),
  posting_datetime TEXT NOT NULL,
  set_warehouse_id INTEGER REFERENCES warehouse(id),    -- Default Warehouse
  scan_mode INTEGER NOT NULL DEFAULT 0,
  difference_amount REAL NOT NULL DEFAULT 0,
  amended_from_id INTEGER REFERENCES stock_reconciliation(id)
);

CREATE TABLE stock_reconciliation_item (
  id INTEGER PRIMARY KEY,
  stock_reconciliation_id INTEGER NOT NULL REFERENCES stock_reconciliation(id) ON DELETE CASCADE,
  idx INTEGER NOT NULL,
  item_id INTEGER NOT NULL REFERENCES item(id),
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  qty REAL NOT NULL,                                    -- counted quantity
  valuation_rate REAL NOT NULL,
  current_qty REAL NOT NULL DEFAULT 0,
  current_valuation_rate REAL NOT NULL DEFAULT 0,
  quantity_difference REAL NOT NULL DEFAULT 0,
  amount_difference REAL NOT NULL DEFAULT 0,
  UNIQUE (stock_reconciliation_id, item_id, warehouse_id)
);

-- The serial numbers and batches chosen for one transaction line.
-- The set of rows sharing (voucher_type, voucher_detail_id) is ERPNext's "Serial and Batch Bundle".
CREATE TABLE serial_and_batch_entry (
  id INTEGER PRIMARY KEY,
  voucher_type TEXT NOT NULL,           -- 'Stock Entry' or 'Sales Invoice'
  voucher_detail_id INTEGER NOT NULL,   -- id of the item row
  item_id INTEGER NOT NULL REFERENCES item(id),
  serial_no_id INTEGER REFERENCES serial_no(id),
  batch_id INTEGER REFERENCES batch(id),
  qty REAL NOT NULL,                    -- always positive; 1 for a serial number
  incoming_rate REAL NOT NULL DEFAULT 0,
  CHECK (serial_no_id IS NOT NULL OR batch_id IS NOT NULL)
);
CREATE INDEX sbe_voucher_idx ON serial_and_batch_entry (voucher_type, voucher_detail_id);
CREATE INDEX sbe_serial_idx ON serial_and_batch_entry (serial_no_id);

CREATE TABLE stock_ledger_entry (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id),
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  posting_datetime TEXT NOT NULL,
  voucher_type TEXT NOT NULL,           -- 'Stock Entry', 'Stock Reconciliation', 'Sales Invoice'
  voucher_id INTEGER NOT NULL,
  voucher_no TEXT NOT NULL,
  voucher_detail_id INTEGER NOT NULL,
  actual_qty REAL NOT NULL,             -- positive in, negative out, in Stock UOM
  qty_after_transaction REAL NOT NULL,
  incoming_rate REAL NOT NULL DEFAULT 0,
  outgoing_rate REAL NOT NULL DEFAULT 0,
  valuation_rate REAL NOT NULL DEFAULT 0,
  stock_value REAL NOT NULL DEFAULT 0,
  stock_value_difference REAL NOT NULL DEFAULT 0,
  batch_id INTEGER REFERENCES batch(id),
  is_cancelled INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX sle_chain_idx ON stock_ledger_entry (item_id, warehouse_id, posting_datetime, id);
CREATE INDEX sle_voucher_idx ON stock_ledger_entry (voucher_type, voucher_id);
CREATE INDEX sle_batch_idx ON stock_ledger_entry (batch_id, warehouse_id);

-- Running balance per item and warehouse. A cache: it can always be rebuilt from the ledger.
CREATE TABLE bin (
  item_id INTEGER NOT NULL REFERENCES item(id),
  warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
  actual_qty REAL NOT NULL DEFAULT 0,
  valuation_rate REAL NOT NULL DEFAULT 0,
  stock_value REAL NOT NULL DEFAULT 0,
  stock_queue TEXT NOT NULL DEFAULT '[]',   -- FIFO layers as JSON: [[qty, rate], ...]
  PRIMARY KEY (item_id, warehouse_id)
);
```

### Stock Settings (in `singles`)

| Label | Key | Default |
|---|---|---|
| Item Naming By | `item_naming_by` | Item Code (or Naming Series) |
| Default Item Group | `item_group` | Products |
| Default Stock UOM | `stock_uom` | Nos |
| Default Warehouse | `default_warehouse` | Stores (a non-group, enabled warehouse; the Cash Register sells from it, SET-R14) |
| Default Valuation Method | `valuation_method` | FIFO (or Moving Average) |
| Show Barcode Field | `show_barcode_field` | 1 |
| Auto insert Price List rate if missing | `auto_insert_price_list_rate_if_missing` | 1 |
| Allow Negative Stock | `allow_negative_stock` | 0 |
| Show low-stock alerts | `auto_indent` | 1 |
| Stock Frozen Upto | `stock_frozen_upto` | empty |
| Enable Serial and Batch No for Item | `enable_serial_and_batch_no_for_item` | 0 |
| Pick Serial / Batch Based On | `pick_serial_and_batch_based_on` | FIFO (or LIFO, Expiry) |
| Auto Create Serial and Batch Bundle For Outward | `auto_create_serial_and_batch_bundle_for_outward` | 1 |

## 4. Business rules

### Masters

**STK-R1 Warehouse.** Warehouses form a tree ("Warehouse > Room > Row > Shelf > Bin"). A group
warehouse holds no stock and cannot be chosen on a transaction. A warehouse can become a group only
while it has no ledger entries. A warehouse with ledger entries can be disabled, not deleted. The
Default Warehouse of Stock Settings is the Cash Register's: it cannot be made a group, disabled or
deleted while it is the default, and renaming it renames it in Stock Settings, which keeps it by name
(as SET-R13 does for the Default Price List). Stock
balance is kept "for every distinct combination of Item and Warehouse". (Warehouse.)

**STK-R2 Item Group.** A tree rooted at "All Item Groups". Names are unique across the whole tree. A
group with items or child groups cannot be deleted. (Item Group.)

**STK-R3 Whole-number units.** If a UoM has Must be Whole Number, a fractional quantity in that unit
is refused with ERPNext's message: `Quantity cannot be a fraction at row #`. The check applies to the
transaction unit and to the resulting stock quantity. (Managing Fractions in UOM.)

**STK-R4 Item Code.** Unique. With Item Naming By = Item Code the user types it and Item Name is
pre-filled with the same text. With Naming Series the code is generated on save. The item form links
to a short help text taken from Item Codification: keep code and name the same for a small catalogue;
use a meaningful code scheme for a large one. (Item; Stock Settings; Item Codification.)

**STK-R5 Creating an item.**
- **Standard Selling Rate** entered while creating the item creates an Item Price in the default
  price list. Entering it later does nothing; prices are then edited as Item Prices.
- **Opening Stock** and **Valuation Rate** entered while creating a stock item create and submit a
  Material Receipt (Is Opening) into the Default Warehouse. Not offered for batch or serial items.
- Default Unit of Measure, Item Group and Default Warehouse are pre-filled from Stock Settings.
(Item, section 2; Stock Settings.)

**STK-R6 Using an item.** A disabled item cannot be selected anywhere. An item past its End of Life
cannot be used in a transaction. An item without Is Sales Item does not appear in the Cash Register.
An item with Maintain Stock off produces no ledger entries and is sold without a stock check; use it
for services. (Item, sections 2.2, 3.3, 3.13.)

**STK-R7 Fields that freeze.** After an item's first stock ledger entry these become read-only:
Maintain Stock, Has Batch No, Has Serial No, Valuation Method and Default Unit of Measure. The form
states the reason. (Maintain Stock field Frozen; Item Valuation Setup: "once ledger entries are made
for an item, this option will no longer be visible".)

**STK-R8 Barcodes.** A barcode belongs to one item only. When Barcode Type is EAN the value must be
13 digits with a valid check digit; when UPC, 12 digits. A barcode row may name a UoM; scanning it
selects the item and that unit ("different barcode for different type of packaging of same item like
unit and box"). Scanning uses the camera, or any Bluetooth or USB scanner, which types into the
focused search field. (Item, 3.2; Track Items Using Barcode.)

**STK-R9 Units and conversion.** The Stock UOM always has factor 1. Each other unit on the item has a
conversion factor: stock units in one of that unit. `stock_qty = qty × conversion_factor`. One Carton
= 10 Units: selling 3 Cartons moves 30 Units. The ledger and all stock reports are always in the Stock
UOM. Only units listed on the item can be chosen in a transaction. A unit that appears on any
document cannot be removed from the item or have its factor changed. (Item, 3.5; Sell Items in
Different Units of Measure.)

**STK-R10 Price lookup.** For an item, price list, unit and posting date, in this order:
1. An Item Price for that exact unit, valid on the date (`valid_from` and `valid_upto` are open-ended
   when empty). A row for the selected batch beats a row without a batch.
2. If none, the Item Price stored for the Stock UOM. When the price list has Price Not UOM Dependent
   it is multiplied by the conversion factor (10 per Kilo, 1 Box = 10 Kilos, so a Box is 100). When it
   does not, the stock-unit price is used unchanged (the Box shows 10), exactly as ERPNext does. The
   item detail panel then says which unit the price was stored for, so the mismatch is visible.
3. If none and "Use prices from Default Price List as fallback" is on: repeat 1 and 2 on the default
   price list.
4. Otherwise no price; the rate is 0 and must be typed if POS Settings allows editing the rate.

Two Item Prices for the same item, price list, unit and batch must not have overlapping validity.
(Item Price; Price Lists; Selling Settings.)

**STK-R11 Auto insert price.** With "Auto insert Price List rate if missing" on, the first sale of an
item that has no Item Price creates one from the rate used. It happens once, on the first transaction
only. (Stock Settings.)

**STK-R12 Low stock.** For each `item_reorder` row, when the item's Actual Qty in that warehouse is
at or below the Re-order Level, the item is listed as low stock with the Re-order Qty as the suggested
quantity to bring in. Evaluated by query whenever the list or its badge is shown. The Re-order Qty may
be larger than the level. (Item, 3.4; Auto Creation of Material Request.)

**STK-R13 Item tax.** The template for an item on a given date is the `item_tax` row with the latest
Valid From on or before that date (an empty Valid From always qualifies). If the item has none, the
item's Item Group template is used, then the parent group's, up the tree. "An assignment on the Item
is more specific and takes precedence over a group-level default." (Item Tax Template.)

### Variants

**STK-R14 Templates.** An item with Has Variants is a template. A template cannot be used in any
transaction, holds no stock and has no price. Has Variants cannot be changed once the item has
variants or ledger entries. (Item Variants: "You cannot make Transactions against a 'Template'.")

**STK-R15 Attributes.** A text attribute lists its values, each with an abbreviation. A numeric
attribute has a range and an increment: from 1 to 5 by 1 gives 1, 2, 3, 4, 5. A template may narrow
the range. (Item Attribute.)

**STK-R16 Creating variants.** From a template, "Create > Single Variant" picks one value per
attribute; "Create > Multiple Variants" ticks values and creates every combination. Color Red, Green
and Size Small, Medium, Large gives 6 variants. A combination that already exists is skipped. A
variant's Item Code is the template code followed by each value's abbreviation (`TSHIRT-RED-S`); a
numeric value is used as it is. (Item Variants, 1.2.)

**STK-R17 Template updates.** Saving a template copies these fields to all its variants: Item Group,
Default Unit of Measure, Brand, Description, Maintain Stock, Is Sales Item, Valuation Method, Has
Batch No, Has Serial No, Default Sales Unit of Measure, Max Discount, the UoM table and the tax table.
Frozen fields (STK-R7) are skipped for variants that already have ledger entries. Image, barcodes and
prices belong to each variant. (Item Variants, section 2.)

### Batches

**STK-R18 Switching on.** Batches and serial numbers are available only when "Enable Serial and Batch
No for Item" is on in Stock Settings, and then per item through Has Batch No or Has Serial No, set
before the item has any ledger entry. (Serial and Batch; STK-R7.)

**STK-R19 Batch master.** Batch ID is unique. A batch belongs to one item. Status is derived: Not
Set when there is no expiry date, Not Expired until that date, Expired after it. When the item has
Has Expiry Date, the expiry date is mandatory and defaults to the manufacturing date (or receipt date)
plus Shelf Life In Days. (Batch, 3.1; Item, 3.3 and 3.7.)

**STK-R20 Batch on receipt.** On a Material Receipt a batch row may name an existing batch or a new
Batch ID, which is created on save. If the row is left empty and the item has Automatically Create New
Batch, a batch is created on submit from the Batch Number Series: series `5x1SCR` gives `5x1SCR00001`.
Without that setting a Batch ID must be entered. (Item, 3.7; Serial and Batch Bundle.)

**STK-R21 Batch on every movement.** Every line that moves a batched item needs batch rows whose
quantities add up to the line's stock quantity. Batches offered for an outgoing line are those of the
item with a positive balance in the source warehouse that are not expired on the posting date. (Batch,
3.2.)

**STK-R22 Expired batches.** An expired batch cannot be sold. It can leave stock only through a
Material Issue, which is how expired goods are written off.

### Serial numbers

**STK-R23 Serial master.** A serial number is unique across all items and stands for exactly one
unit. The quantity of a serialised line must be a whole number equal to the number of serial rows.
(Serial Number.)

**STK-R24 Status.**

| Status | Meaning | Set by |
|---|---|---|
| Inactive | Record exists, unit is not in stock | Creating a serial number by hand |
| Available | In a warehouse, can be sold | Material Receipt, return of a sale, transfer in |
| Delivered | Left the store | Sale, Material Issue |

A serial number's warehouse is set only by a stock transaction, never by editing the record. "Only
Serial Numbers with status 'Available' can be delivered", and only from the warehouse they are in.
(Serial Number, 2.1.)

**STK-R25 Creating serial numbers on receipt.** Three ways: type or scan them; enter a range,
`SN-01::10`, which adds SN-01 to SN-10; or leave the rows empty when the item has a Serial Number
Series, in which case submit creates them (series `PB2L.#####` gives `PB2L00001`…). A number that
already exists and is not Inactive is refused. (Serial Number, section 2; Inline Serial / Batch
Editor.)

**STK-R26 Warranty.** When a serialised unit is sold and the item has a Warranty period,
`warranty_expiry_date` = sale date + that many days. (Item, 3.3.)

### Selecting serials and batches (the inline editor)

**STK-R27.** On a draft Stock Entry or Sales Invoice, a line for a batch or serial item expands to
show its **Serial / Batch Entries**. (Use Inline Serial / Batch Editor.)
- Add, edit and delete rows. The line quantity always equals the total of its entries.
- **Auto Fetch** (outgoing lines): enter a quantity and the app picks entries using Pick Serial /
  Batch Based On: FIFO takes the oldest receipts first, LIFO the newest, Expiry the earliest expiry
  date. It replaces whatever is in the table.
- **Scan**: each scan adds an entry. Scanning the same batch again adds 1 to its quantity. Scanning
  the same serial number twice is refused.
- **Create Serial Nos from Range** (incoming serial lines).
- **Download / Upload** a CSV of entries.
- More than 10 entries are shown 10 per page.
- Entries can be changed only while the document is a draft.
- With "Auto Create Serial and Batch Bundle For Outward" on, an outgoing line submitted with no
  entries is filled by Auto Fetch at submit. With it off, submit is refused until entries are chosen.
- The entries of one line are never shared with another line or document.

### The ledger engine

**STK-R28 Posting.** Submitting a stock document writes one Stock Ledger Entry per line and warehouse
side, in the Stock UOM: negative `actual_qty` from the source, positive into the target. A Material
Transfer line writes two. A line that draws from several batches writes one entry per batch. The same
transaction updates `bin` and the serial records. Sources of ledger entries: Sales Invoice (Update
Stock), Stock Entry, Stock Reconciliation. (Stock Ledger Report.)

**STK-R29 Which valuation method.** The item's Valuation Method if set, otherwise Stock Settings'
Default Valuation Method. "The most specific setting wins." Serialised items ignore both and use
STK-R32. (FIFO and Moving Average; Serialised Item Valuation Rate calculation.)

**STK-R30 FIFO.** Each item and warehouse has a queue of `[qty, rate]` layers. A receipt appends a
layer at its incoming rate. An issue consumes from the front, each unit costed at its own layer's
rate. The valuation rate shown is the weighted average of the layers that remain.

| Step | Transaction | Queue after | Stock value |
|---|---|---|---|
| 1 | Receive 10 @ 100 | `[10 @ 100]` | 1,000 |
| 2 | Receive 10 @ 120 | `[10 @ 100], [10 @ 120]` | 2,200 |
| 3 | Issue 15 | `[5 @ 120]` | 600 |

The 15 issued cost 10 × 100 + 5 × 120 = 1,600. Second example: 10 @ 100, 20 @ 120, sell 15: cost
1,600, remaining 15 @ 120 = 1,800. (FIFO and Moving Average, 2.2; calculation difference page.)

**STK-R31 Moving Average.** One average rate per item and warehouse. On every receipt:
`new average = (existing qty × existing rate + incoming qty × incoming rate) ÷ (existing qty +
incoming qty)`. Issues are costed at the current average and do not change it.

| Step | Transaction | Qty | Average | Stock value |
|---|---|---|---|---|
| 1 | Receive 10 @ 100 | 10 | 100 | 1,000 |
| 2 | Receive 10 @ 120 | 20 | 110 | 2,200 |
| 3 | Issue 15 | 5 | 110 | 550 |

Cost of the issue: 1,650. Second example: 10 @ 100, 20 @ 120 gives 113.33…; selling 15 costs 1,700
and leaves 1,700. The average is held at 9 decimals so that 15 × 113.333… rounds to 1,700.00.
(FIFO and Moving Average, 3.2; calculation difference page.)

**STK-R32 Serial cost.** Every serial number keeps the rate it came in at. The cost of an outgoing
serial line is the sum of the rates of the serial numbers on it. LAP-001 bought at 50,000 and LAP-002
at 55,000: selling LAP-002 takes 55,000 out of stock value. (Use Serial No Wise Valuation.)

**STK-R33 Incoming rate.** What a unit is worth when it enters:

| Movement | Incoming rate |
|---|---|
| Material Receipt | Basic rate plus its share of additional costs (STK-R39) |
| Stock Reconciliation | The valuation rate on the row |
| Transfer in | The rate the same line went out at |
| Return of a sale | The rate the original sale went out at |

A Material Receipt needs a rate above zero unless the row has Allow Zero Valuation Rate. (Stock Entry
Purpose: "Item Valuation becomes a mandatory field in the Material Receipt entry"; Stock Entry, 3.1.)

**STK-R34 Negative stock.** An outgoing line is refused when it would take the item's balance in that
warehouse below zero, unless Allow Negative Stock is on in Stock Settings or on the item. Batch and
serial items can never go negative, whatever the settings say, and no single batch can go negative.
When stock does go negative, the units are costed at the last valuation rate and a negative layer is
kept, which the next receipt settles first. (Stock Settings; Item, 3.3, 3.6, 3.7.)

**STK-R35 Posting date and time.** The balance is checked as it was at the document's posting date
and time, not as it is now. A document dated before the stock arrived is refused even if stock is on
hand today. (Delivery Note Negative Stock Error.)

**STK-R36 Backdating and cancelling.** When a document is posted earlier than the latest ledger entry
of an item and warehouse, or a submitted document is cancelled, the engine recomputes that item and
warehouse from its first ledger entry: quantity, rate, value and queue for every entry in order of
posting date and time, then id. Cancelled entries are marked `is_cancelled` and skipped. If the
recomputation would leave any later entry with a negative balance that STK-R34 does not allow, the
whole action is refused and the message names the entry. (FIFO and Moving Average, section 5.)

Known ceiling: recomputing from the first entry is linear in that item's history. It is fast for one
store. If an item ever has hundreds of thousands of entries, start from the changed entry instead.

**STK-R37 Stock freeze.** No stock document can be submitted or cancelled with a posting date on or
before Stock Frozen Upto. (Stock Settings.)

### Stock Entry

**STK-R38 Purposes.**

| Purpose | Source Warehouse | Target Warehouse | Use |
|---|---|---|---|
| Material Receipt | none | required | Stock coming in; opening stock for batch and serial items |
| Material Issue | required | none | Stock going out other than by sale: consumables, damage, expiry |
| Material Transfer | required | required, different | Moving between warehouses |

The header's Default Source and Target Warehouse fill each new row; rows may differ. Issue and
Transfer show the current valuation rate as a read-only basic rate; the actual cost is taken from the
ledger at submit. (Stock Entry; Stock Entry Purpose.)

**STK-R39 Additional costs.** On an entry with incoming rows, each additional cost (a description and
an amount, such as freight) is spread over the incoming rows in proportion to their basic amounts and
added to their valuation. Rows of 600 and 400 with a cost of 50 receive 30 and 20; the first row's
valuation rate becomes (600 + 30) ÷ its quantity. (Stock Entry, 3.3.)

**STK-R40 Opening stock.** Non-batch, non-serial items: a Stock Reconciliation with purpose Opening
Stock. Batch and serial items: a Material Receipt with Is Opening ticked, one row per valuation rate.
(Opening Stock; Opening Stock Balance Entry for Serialized and Batch Item.)

**STK-R41 Changing a submitted entry.** "Once a stock entry is submitted, it can be updated by
cancelling and amending the entry." Cancel reverses its ledger entries under STK-R36; Amend opens a
copy as a new draft. A receipt cannot be cancelled if its serial numbers have since been sold.

### Stock Reconciliation

**STK-R42.** (Stock Reconciliation.)
- Purpose **Opening Stock** sets starting quantities and values. Purpose **Stock Reconciliation**
  brings the books in line with a physical count.
- Each row: Item, Warehouse, counted Quantity, Valuation Rate. The current quantity and rate as of the
  posting date and time are fetched and shown beside them.
- One row per item and warehouse. Rows whose quantity and rate both equal the current values are
  dropped on save.
- On submit each row writes a ledger entry that sets the balance to the counted quantity at the given
  rate: `quantity_difference = qty − current_qty`, `amount_difference = qty × valuation_rate −
  current stock value`. The FIFO queue becomes a single layer `[qty, rate]`.
- **Fetch items**: fill the table with every stocked item in a warehouse as of a date and time.
- **Scan Mode**: existing quantities are not fetched; each scan of an item's barcode adds 1 to its
  row (or adds the row), in the Default Warehouse.
- **CSV**: Download gives a template (Item Code, Warehouse, Quantity, Valuation Rate); Upload fills
  the table. Headers are case-sensitive and must not be changed.
- Maintain Stock must be on. Batch and serial items are refused, with a pointer to STK-R40.

### Reports

**STK-R43.** All reports read `stock_ledger_entry` where `is_cancelled = 0`.

| Report | Filters | Columns |
|---|---|---|
| Stock Ledger | Date range, Warehouse, Item, Item Group, Batch, Voucher # | Date, Item, Stock UOM, In Qty, Out Qty, Balance Qty, Warehouse, Incoming Rate, Valuation Rate, Balance Value, Value Change, Voucher Type, Voucher #, Batch. Voucher # opens the document. Balance Value = Valuation Rate × Balance Qty. |
| Stock Balance | From, To, Item Group, Item, Warehouse | Item, Warehouse, Stock UOM, Opening Qty and Value, In Qty and Value, Out Qty and Value, Balance Qty and Value, Valuation Rate. Balance = Opening + In − Out. Opening comes from entries before From. |
| Quick Stock Balance | Item or scanned barcode, Warehouse, Date | Quantity and value, with a link to Stock Balance filtered the same way |
| Batch-wise Balance History | Date range, Item, Warehouse | Item, Batch, Warehouse, Opening, In, Out, Balance, Expiry, Status |
| Serial No Ledger | Serial No or Item | Date, Voucher Type, Voucher #, Warehouse, In or Out, resulting Status |
| Item Price Stock | Item, Price List | Item, Price List, Rate, UOM, Available Qty |
| Low Stock | Warehouse, Item Group | Item, Warehouse, Actual Qty, Re-order Level, Re-order Qty, Shortage |

Every report exports to CSV.

## 5. Screens

### Stock home

Grouped cards, as ERPNext's Stock workspace:

| Group | Links |
|---|---|
| Items and Pricing | Item, Item Group, Item Price, Brand, Item Attribute |
| Stock Transactions | Stock Entry, Stock Reconciliation |
| Serial No and Batch | Serial No, Batch (shown when enabled in Stock Settings) |
| Settings | Stock Settings, Warehouse, UoM |
| Reports | The seven reports of STK-R43 |

A `Badge` on the Stock destination and on the Low Stock link shows the number of low-stock items.

### Item list

`SearchBar` (matches Item Code, Item Name, barcode) with a scan button; `FilterChip`s for Item Group,
Disabled, Has Variants. Each row: thumbnail, Item Name, Item Code, total stock with a dot (green in
stock, red out of stock), selling price. Compact: `ListView`. Expanded: list on the left, item form
on the right.

### Item form

A strip at the top shows Stock Levels (quantity per warehouse) and the Item Prices with an add
button. Then tabs:

| Tab | Fields |
|---|---|
| Details | Item Code, Item Name, Item Group, Default Unit of Measure, Disabled, Maintain Stock, Has Variants, Opening Stock, Valuation Rate, Standard Selling Rate (the last three on a new item only), image, Brand, Description, Barcodes |
| Inventory | Shelf Life In Days, End of Life, Warranty, Valuation Method, Allow negative stock, Default Warehouse, Units of Measure (table), Auto Reorder (table), Has Batch No with its options, Has Serial No with its series |
| Variants | Attributes table; on a template the list of variants and the Create menu |
| Sales | Default Sales Unit of Measure, Max Discount (%), Is Sales Item |
| Tax | Item Tax table |

Compact: tabs scroll horizontally, one column of fields. Medium and Expanded: two columns.

### Tree masters (Warehouse, Item Group)

Nested `ExpansionTile`s with "Add Child" on each group node and a switch to a flat list.

### Stock Entry form

Header: Stock Entry Type as a `SegmentedButton`; posting date and time (editable after ticking Edit
Posting Date and Time); Default Source and Target Warehouse (whichever the purpose uses). A Scan
Barcode field above the Items table adds or increments a row. Items table columns: Item, Quantity,
UOM, Basic Rate, Amount, warehouse. The row editor adds Conversion Factor, stock quantity, Allow Zero
Valuation Rate, and the Serial / Batch Entries table with its menu (STK-R27). Below: Additional Costs
table; totals; More Information (Is Opening, Remarks). Buttons: Save, Submit; after submit, Stock
Ledger, Cancel; after cancel, Amend.

### Stock Reconciliation form

Header: Purpose, posting date and time, Default Warehouse, Scan Mode switch. Actions: Fetch Items,
Download, Upload, Scan Barcode. Items table: Item, Warehouse, Quantity, Valuation Rate, Current Qty,
Current Valuation Rate, Quantity Difference, Amount Difference (differences coloured with
`ColorScheme.error` when negative). Compact shows Item, Quantity and the difference; the rest is in
the row editor.

### Batch and Serial No

List with status chips; form shows the fields plus, for a batch, its quantity per warehouse, and for a
serial number, its ledger.

### Reports

Filter bar that collapses to a filter sheet on Compact; `DataTable` with a pinned first column and
horizontal scroll; totals row; Export action.

Empty states: the Item list invites "Add Item" and "Import items"; reports show "No entries for these
filters". Errors from STK-R34 to R37 name the item, warehouse, quantity available and the date used.

## 6. Build steps

| Step | Work | Runnable result |
|---|---|---|
| STK-B1 | Warehouse and Item Group trees, UoM, Brand (STK-R1 to R3) | Masters can be created, nested, disabled |
| STK-B2 | Item list and form without variants, batches or serials: details, image, barcodes with check-digit validation, UoM table, reorder table, tax table (STK-R4 to R9, R13) | Items can be created and found by scanning a barcode |
| STK-B3 | Item Price list and form, price lookup function (STK-R10) | The item strip shows prices; lookup tests pass |
| STK-B4 | Stock Settings page | Defaults flow into new items |
| STK-B5 | Engine in `logic/`: FIFO, Moving Average, negative-stock check, chain recompute; posting in `data/` (STK-R28 to R37, without batches and serials) | Engine unit tests pass against an in-memory database |
| STK-B6 | Stock Entry: three purposes, additional costs, submit, cancel, amend; opening stock from the item form (STK-R5, R38 to R41) | Receive, issue and transfer stock; balances change |
| STK-B7 | Stock Reconciliation: both purposes, fetch items, scan mode, CSV (STK-R42) | A count corrects the balance and value |
| STK-B8 | Backdated posting and cancellation paths with refusal messages (STK-R35, R36) | Cancelling an old receipt recomputes or is refused correctly |
| STK-B9 | Stock Ledger, Stock Balance, Quick Stock Balance, Item Price Stock, Low Stock with badge (STK-R12, R43) | Reports match the ledger; CSV export works |
| STK-B10 | Item Attribute; templates; single and multiple variant creation; template propagation (STK-R14 to R17) | A T-shirt template yields 6 variants that sell individually |
| STK-B11 | Batches: master, receipt, selection on outgoing lines, expiry rules, per-batch ledger, Batch-wise Balance History (STK-R18 to R22) | A batched item is received, issued by earliest expiry, and blocked when expired |
| STK-B12 | Serial numbers: master, series, status changes, serial cost, warranty, Serial No Ledger (STK-R23 to R26, R32) | Two units received at different costs go out at their own cost |
| STK-B13 | Inline editor tools: Auto Fetch, Scan, Range, CSV, paging (STK-R27) | 50 serial numbers entered from a range in one action |

B1 to B4 are milestone M2, B5 to B9 are M3, B10 to B13 are M8.

## 7. Acceptance checks

Unit tests on `logic/`:

| Check | Expected |
|---|---|
| STK-A1 FIFO: receive 10 @ 100, receive 10 @ 120, issue 15 | Cost 1,600; queue `[5 @ 120]`; value 600 |
| STK-A2 Moving Average, same movements | Average 110; cost 1,650; value 550 |
| STK-A3 FIFO: 10 @ 100, 20 @ 120, issue 15 | Cost 1,600; value 1,800 |
| STK-A4 Moving Average: 10 @ 100, 20 @ 120, issue 15 | Rate 113.33; cost 1,700.00; value 1,700.00 |
| STK-A5 Serial: LAP-001 @ 50,000, LAP-002 @ 55,000, issue LAP-002 | Cost 55,000; value left 50,000 |
| STK-A6 3 Cartons at factor 10 | Stock quantity 30 |
| STK-A7 Quantity 1.5 in a whole-number unit | `Quantity cannot be a fraction at row 1` |
| STK-A8 Additional cost 50 over rows of 600 and 400 | 30 and 20 |
| STK-A9 Numeric attribute 1 to 5 by 1 | Values 1, 2, 3, 4, 5 |
| STK-A10 Red, Green × Small, Medium, Large | 6 variants; running it again creates none |
| STK-A11 Range `SN-01::10` | SN-01 … SN-10, ten numbers |
| STK-A12 Batch series `5x1SCR`, first batch | `5x1SCR00001` |
| STK-A13 Price lookup for a Box: Kilo price 10, Box factor 10, Price Not UOM Dependent on / off | 100 / 10 |
| STK-A14 EAN with a wrong check digit | Rejected |
| STK-A15 Item tax: item row valid from 1 March, group template otherwise; sale on 15 February and on 15 March | Group template, then item template |

Database tests:

| Check | Expected |
|---|---|
| STK-A16 Issue 5 with 3 on hand, negative stock off | Refused; nothing written |
| STK-A17 Same with Allow negative stock on the item | Allowed; balance −2 |
| STK-A18 Same for a batch item with negative stock on in settings | Refused |
| STK-A19 Receive on day 2, issue dated day 1 | Refused (STK-R35) |
| STK-A20 Receive 10 @ 100 (day 1), receive 10 @ 120 (day 3), issue 15 (day 4); then post a receipt of 10 @ 90 dated day 2, FIFO | The day-4 issue is recosted to 10 × 100 + 5 × 90 = 1,450 |
| STK-A21 Cancel the day-1 receipt in A20 while the issue exists | Refused; message names the issue |
| STK-A22 Reconciliation sets 8 @ 105 when the book shows 10 @ 100 | Quantity difference −2; amount difference −160; balance 8, value 840 |
| STK-A23 Transfer 4 from Stores to Back Room | Two ledger entries; total stock value unchanged |
| STK-A24 Sell a serial number, then try to cancel its receipt | Refused |
| STK-A25 Sell from an expired batch; issue it by Material Issue | Refused; allowed |
| STK-A26 After any sequence of the above, rebuild `bin` from the ledger | Identical to the stored `bin` |
| STK-A27 Submit on a date on or before Stock Frozen Upto | Refused |

Manual checks: the item form, Stock Entry and Stock Reconciliation on a phone and a tablet in both
orientations; scanning a barcode with the camera adds the right item and unit; a report with 5,000
ledger rows scrolls smoothly and exports.

## 8. Left out on purpose

| Not built | Add it when |
|---|---|
| Purchase Receipt, suppliers, purchase prices | The owner wants to record who stock was bought from and what is owed |
| Material Request from re-order level | Purchasing is added; until then the low-stock list is the prompt |
| Stock Reconciliation for batch and serial items | Counting serialised or batched stock through receipts and issues becomes tedious |
| Batch-wise valuation (a separate cost per batch) | Batches of the same item are bought at very different costs and margin per batch matters |
| Standard Cost and LIFO valuation | An accountant asks for them |
| Serial numbers costed at the item average | The store handles serial numbers by the thousand |
| Product Bundle, Repack | The store sells gift sets or breaks bulk into packs (the Product Bundle page is not in the merged docs) |
| Add to Transit, transit warehouses | Stock spends time travelling between sites |
| Closing Stock Balance snapshots | Stock Balance becomes slow because of ledger size |
| Global UoM Conversion Factor list | The same conversions are being retyped on many items |
| Variants by manufacturer, Manufacturer master | Identical items from different makers must be told apart |
| Stock Entry Type master | Different people need different stock permissions |
| Landed Cost Voucher | Costs arrive after the receipt; until then use Additional Costs on the receipt |
| Quality Inspection, Pick List, Putaway Rule, Packing Slip, Shipment, Stock Reservation, Inventory Dimension | Never for a single counter store |

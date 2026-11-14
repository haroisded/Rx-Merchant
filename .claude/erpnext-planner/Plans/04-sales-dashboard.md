# Plan 04: Sales Dashboard

Read `00-overview-and-foundation.md` first. This plan covers the Dashboard destination: summary
cards, the monthly sales goal, charts and the three sales reports behind them. It adds no tables. It
reads the invoices defined in `03-cash-register.md` and the stock ledger defined in `02-stock.md`.

---

## 1. Purpose and ERPNext sources

"Dashboards are useful for day-to-day monitoring, while reports and analytics pages are useful for
deeper review." The dashboard gives the owner the day's position at a glance, and every figure on it
opens the report that explains it.

| ERPNext page | Link | Line in merged doc |
|---|---|---|
| ERPNext Dashboards | https://docs.frappe.io/erpnext/erpnext-dashboards | 2054 |
| Sales Reports and Analytics | https://docs.frappe.io/erpnext/sales-analytics | 27893 |
| Setting Company Sales Goal | https://docs.frappe.io/erpnext/setting-company-sales-goal | 26446 |
| System Settings (First Day of the Week) | https://docs.frappe.io/erpnext/system-settings | 899 |

## 2. Scope

| ERPNext element | In the app | Status | Reason |
|---|---|---|---|
| Selling dashboard: trends, summary cards, report links | Same | Kept | |
| Sales Analytics by Item and Item Group; value or quantity; period grouping | Same | Kept | |
| Sales Analytics by Customer, Customer Group, Territory, Sales Person | none | Dropped | Excluded areas |
| Item-wise Sales | Same | Kept | |
| Customer-wise Sales | none | Dropped | Customers excluded |
| Gross Profit | Same, with cost taken from the stock ledger | Kept | |
| Brandwise Items and Profitability | Gross Profit grouped by Brand | Adapted | One report with a Group By covers it |
| Monthly Sales Target, Total Monthly Sales, Achievement % | Same, on the Store Profile | Kept | |
| Sales Order Analysis, order status reporting | none | Dropped | No Sales Orders |
| Sales Person-wise Transaction Summary, target variance reports | none | Dropped | Sales persons excluded |
| Accounts Receivable, Payment Terms Status | none | Dropped | Every sale is paid in full |
| Sales Pipeline, CRM Analytics | none | Dropped | No CRM |
| Report export | CSV | Kept | |
| Saved views, custom columns, Report Builder, Insights dashboards | none | Dropped | Section 8 |
| Stock dashboard | One Stock Value card and a Low Stock count, linking to the stock reports in `02-stock.md` | Adapted | The stock reports already exist there |

## 3. Data model

No new tables. Every figure is a query over:

- `sales_invoice`, `sales_invoice_item`, `sales_invoice_payment` (plan 03)
- `item`, `item_group`, `brand`, `bin`, `item_reorder` (plan 02)
- `mode_of_payment`, and `singles` for Monthly Sales Target and First Day of the Week (plan 01)

The indexes that serve these queries are already defined: `si_posting_idx` on
`sales_invoice (docstatus, posting_datetime)` and `sii_item_idx` on `sales_invoice_item (item_id)`.

Known ceiling: figures are aggregated on demand. That stays instant into the hundreds of thousands of
invoice lines. If it ever slows, add a per-day summary table filled at Submit; nothing else changes.

## 4. Business rules

**DSH-R1 What counts.** Only submitted invoices (`docstatus = 1`). Drafts and cancelled invoices
never count. Returns count, as negative amounts, so that "net sales remain meaningful". (Sales
Reports: "Reports of confirmed activity usually use submitted transactions"; Setting Company Sales
Goal.)

**DSH-R2 One date.** Every card, chart and report uses the posting date of the invoice. This is
what makes two screens agree: "Confirm both reports use the same document type, date field, status,
and return treatment." (Sales Reports, Troubleshooting.)

**DSH-R3 Period.** Today, Yesterday, This Week, This Month, This Year, or a custom range. A week
starts on the First Day of the Week from System Settings. Each card also shows the change against the
previous period of the same length.

**DSH-R4 Definitions.**

| Figure | Definition |
|---|---|
| Net Sales | Σ `net_total` |
| Taxes | Σ `total_taxes_and_charges` |
| Total Sales | Σ `grand_total` |
| Invoices | Count of invoices that are not returns |
| Returns | Count of return invoices, and −Σ of their `grand_total` |
| Average Sale | Σ `grand_total` of non-return invoices ÷ their count |
| Items Sold | Σ `qty` over invoice lines (returns are negative) |
| Cost of Goods Sold | Σ `stock_qty × incoming_rate` over invoice lines |
| Gross Profit | Net Sales − Cost of Goods Sold |
| Gross Profit % | Gross Profit ÷ Net Sales × 100 |
| Stock Value | Σ `bin.stock_value`, as of now (not tied to the period) |
| Low Stock | Number of items in the Low Stock report (STK-R12) |

`incoming_rate` is the cost per stock unit that the ledger assigned when the sale was posted
(POS-R17), so profit follows the item's valuation method. A returned line carries the cost of the
original sale, so a full return cancels both the sale and its cost. A price-only credit note has no
cost and reduces profit by its full amount. "Gross Profit compares sales value with buying or
valuation information." (Sales Reports, Gross Profit.)

**DSH-R5 Sales goal.** (Setting Company Sales Goal.)
- **Total Monthly Sales** = Σ `grand_total` of submitted invoices whose posting date is in the
  current calendar month, returns included. The docs do not say whether tax is included; ERPNext sums
  the Grand Total and the app does the same.
- **Achievement % = Total Monthly Sales ÷ Monthly Sales Target × 100.** Sales of 13,949 against a
  target of 100,000 is 13.949%.
- The target is one recurring monthly value, set on the Store Profile. It blocks nothing.
- With a target of zero the goal card is hidden.
- The goal card always shows the current month, whatever period is selected.

**DSH-R6 Charts.**

| Chart | Content |
|---|---|
| Sales Trend | Net Sales per bucket across the selected period. Buckets are days up to 31 days, weeks up to 26 weeks, months beyond that. A Value / Quantity switch changes the measure. |
| Sales by Item Group | Net Sales per Item Group, largest first, top 8 and "Other". Horizontal bars. |
| Top Items | Top 10 items by Net Sales or by quantity. Horizontal bars. |
| Payment Modes | Amount received per Mode of Payment: payments minus refunds, with change deducted from the cash mode (as in POS-R20). |

**DSH-R7 Sales Analytics report.** (Sales Reports, Sales Analytics.)
- Filters: Tree Type (Item Group or Item), Value or Quantity, date range, Range (Daily, Weekly,
  Monthly, Quarterly, Yearly).
- Rows are item groups or items; columns are the periods of the range plus a Total.
- With Tree Type Item Group the rows form the group tree and each parent shows the sum of its
  children.
- A line chart of the selected rows sits above the table.
- "Use it for trends and concentration, not as a substitute for invoice-level audit."

**DSH-R8 Item-wise Sales report.** One row per submitted invoice line: Date, Invoice, Item Code,
Item Name, Item Group, Quantity, UOM, Rate, Net Amount, Tax, Total. Filters: date range, Item, Item
Group. Totals row. The Invoice cell opens the invoice.

**DSH-R9 Gross Profit report.** Filters: date range, Group By (Invoice, Item, Item Group, Brand).
Columns: Quantity, Selling Amount (net), Buying Amount (cost), Gross Profit, Gross Profit %; when
grouped by Item also Average Selling Rate and Valuation Rate. Rows whose cost is zero for a stock item
are flagged, because the docs name "missing or unusual buying rates" as the first thing to
investigate.

**DSH-R10 Drill-down.** Tapping a card opens the report or list that explains it, with the same
period: Net Sales and Items Sold open Sales Analytics; Invoices and Returns open the invoice list with
that status filter; Gross Profit opens the Gross Profit report; a chart bar opens Item-wise Sales
filtered to that item or group; Stock Value and Low Stock open their stock reports.

**DSH-R11 Display.** Amounts follow Currency Precision, the Number Format and Hide Currency Symbol.
Percentages show one decimal. All three reports export to CSV with the filters written in the first
lines of the file.

**DSH-R12 Freshness.** The dashboard reads through drift streams, so a sale completed on the Cash
Register is reflected when the Dashboard is next shown, without a refresh button.

## 5. Screens

### Dashboard

From top to bottom:

1. **Period bar.** `FilterChip`s for the fixed periods and a "Custom" chip that opens
   `showDateRangePicker`.
2. **Number cards.** Net Sales, Invoices, Average Sale, Items Sold, Gross Profit (with the
   percentage), Taxes, Returns, Stock Value (with the Low Stock count as a `Badge`). Each is a `Card`
   with a label, the figure, and the change against the previous period in `ColorScheme.primary` when
   up and `ColorScheme.error` when down.
3. **Sales goal.** A `Card` with Monthly Sales Target, Total Monthly Sales, a
   `LinearProgressIndicator` and the Achievement %.
4. **Charts.** Four `Card`s: Sales Trend, Sales by Item Group, Top Items, Payment Modes.
5. **Reports.** `ListTile` links: Sales Analytics, Item-wise Sales, Gross Profit.

| Width class | Arrangement |
|---|---|
| Compact | Number cards 2 per row; goal and charts one per row; the period bar scrolls sideways |
| Medium | Number cards 4 per row; charts 2 per row |
| Expanded | Number cards 4 per row; goal beside the Sales Trend chart; other charts 3 per row |

Charts use `fl_chart` with colours from `ColorScheme` (`primary`, `secondary`, `tertiary` and their
containers). Each chart has a text alternative: tapping its title opens the same data as a table.

### Reports

A filter bar (a filter sheet on Compact), an optional chart, and a `DataTable` with the first column
pinned and horizontal scroll, a totals row, and an Export action in the app bar. On Compact,
Sales Analytics shows the Total column first so the main figure is visible without scrolling.

### States

- No submitted sales in the period: cards show zero and the charts show "No sales in this period".
- No sales at all yet: one card, "Complete your first sale to see your dashboard", with a button to
  the Cash Register.
- Target not set: the goal card is replaced by a small "Set a monthly sales target" link to the Store
  Profile.

## 6. Build steps

| Step | Work | Runnable result |
|---|---|---|
| DSH-B1 | Query class for DSH-R4 to R6 with period and previous-period arguments; fixture and tests | The fixture in section 7 returns the expected figures |
| DSH-B2 | Dashboard screen: period bar, number cards, states, three width classes (DSH-R3, R11, R12) | Cards change with the period and after a new sale |
| DSH-B3 | Sales goal card and the four charts (DSH-R5, R6) | Goal progress and charts match the cards |
| DSH-B4 | Sales Analytics, Item-wise Sales, Gross Profit reports (DSH-R7 to R9) | Report totals equal the card figures for the same period |
| DSH-B5 | Drill-down links and CSV export (DSH-R10, R11) | Every card opens its explanation; exports open in a spreadsheet |

All five are milestone M7.

## 7. Acceptance checks

Fixture, all in one month, one item group "Products":

| Document | Lines | Net | Tax | Grand Total | Cost | Payment |
|---|---|---|---|---|---|---|
| Invoice 1, day 1 | Item A, 2 × 100 | 200 | 16 | 216 | 2 × 60 = 120 | Cash 216 |
| Invoice 2, day 1 | Item B, 1 × 500 | 500 | 40 | 540 | 350 | Card 540 |
| Return 3, day 2, against Invoice 1 | Item A, −1 × 100 | −100 | −8 | −108 | −60 | Cash −108 |
| Draft 4 and Cancelled 5 | any | ignored | | | | |

| Check | Expected for days 1 to 2 |
|---|---|
| DSH-A1 Net Sales | 600 |
| DSH-A2 Taxes | 48 |
| DSH-A3 Total Sales | 648 |
| DSH-A4 Invoices; Returns | 2; 1 worth 108 |
| DSH-A5 Average Sale | (216 + 540) ÷ 2 = 378 |
| DSH-A6 Items Sold | 2 + 1 − 1 = 2 |
| DSH-A7 Cost of Goods Sold | 120 + 350 − 60 = 410 |
| DSH-A8 Gross Profit; Gross Profit % | 190; 31.7% |
| DSH-A9 Payment Modes | Cash 108; Card 540 |
| DSH-A10 Period = day 1 only: Net Sales | 700 |
| DSH-A11 Monthly Sales Target 1,296 | Total Monthly Sales 648; Achievement 50.0% |
| DSH-A12 Target 100,000, sales 13,949 | 13.949% |
| DSH-A13 Target 0 | Goal card hidden |
| DSH-A14 Sales Analytics, Item, Value, Daily | Item A: 200, −100, total 100. Item B: 500, 0, total 500. Column totals 700, −100, 600 |
| DSH-A15 Sales Analytics, Item Group | "Products" row equals the column totals of A14; "All Item Groups" equals it too |
| DSH-A16 Item-wise Sales totals row | Net 600; Tax 48; Total 648 |
| DSH-A17 Gross Profit by Item | A: selling 100, buying 60, profit 40. B: selling 500, buying 350, profit 150. Total 190 |
| DSH-A18 This Week with First Day of the Week Sunday and then Monday | The week boundaries move by one day |
| DSH-A19 Cancel Invoice 2 | Every figure drops by its amounts; nothing else changes |

Manual checks: the dashboard on a phone and on a tablet in both orientations; with 20,000 invoices
in the database the dashboard opens without visible delay; exported CSVs open with the right columns.

## 8. Left out on purpose

| Not built | Add it when |
|---|---|
| Sales by customer, territory or sales person; target variance | Those masters are added |
| Accounts Receivable | The store sells on credit |
| Profit and Loss, Balance Sheet, any accounting report | Accounts are added; Gross Profit is the furthest this app goes |
| Custom dashboards, Report Builder, custom columns, saved views | The fixed set stops answering the owner's questions |
| A different target for each month | The owner plans seasonally; the docs' "Monthly Distribution" is the model |
| Per-day summary table | Dashboard queries become slow (see section 3) |
| Emailed or scheduled reports | The app is allowed online |

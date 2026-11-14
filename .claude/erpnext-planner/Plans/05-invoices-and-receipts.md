# Plan 05: Invoices / Receipts

Read `00-overview-and-foundation.md` first. This plan covers everything that happens to a sale after
the Cash Register has created it: finding and viewing it, printing it as an invoice or a receipt,
returning goods against it, and cancelling it. The `sales_invoice` tables are defined in
`03-cash-register.md`.

---

## 1. Purpose and ERPNext sources

In ERPNext a receipt and an invoice are the same record, a Sales Invoice, shown through different
Print Formats. A return is also a Sales Invoice, marked Is Return, with negative quantities: "A
Credit Note records the correction while preserving the original sale and its audit trail."

| ERPNext page | Link | Line in merged doc |
|---|---|---|
| Sales Invoice | https://docs.frappe.io/erpnext/sales-invoice | 5947 |
| Credit Note | https://docs.frappe.io/erpnext/credit-note | 6132 |
| Sales Return | https://docs.frappe.io/erpnext/sales-return | 25675 |
| Terms and Conditions | https://docs.frappe.io/erpnext/terms-and-conditions | 24029 |
| POS Profile (Print Settings, Payment Methods) | https://docs.frappe.io/erpnext/pos-profile | 35585 |
| Naming Series | https://docs.frappe.io/erpnext/naming-series | 40702 |
| Printing | https://docs.frappe.io/erpnext/printing | 42784 |
| Print Format | https://docs.frappe.io/erpnext/print-format | 42790 |
| Print Settings | https://docs.frappe.io/erpnext/print-settings | 42897 |
| Printing and Branding | https://docs.frappe.io/erpnext/print | 43030 |
| Letter Head | https://docs.frappe.io/erpnext/letter-head | 43049 |
| Print Headings | https://docs.frappe.io/erpnext/print-headings | 43092 |
| Raw Printing | https://docs.frappe.io/erpnext/raw-printing | 43172 |
| Invoice rounding issue | https://docs.frappe.io/erpnext/invoice-rounding-issue | 19388 |
| Disable Rounded Total | https://docs.frappe.io/erpnext/disable-rounded-total | 42387 |

## 2. Scope

| ERPNext element | In the app | Status | Reason |
|---|---|---|---|
| Sales Invoice list and form view | Invoice list and read-only detail | Kept | |
| Creating a Sales Invoice from the desk form, from a Sales Order or a Delivery Note | none | Dropped | Every sale comes from the Cash Register |
| Statuses Draft, Paid, Credit Note Issued, Return, Cancelled | Same | Kept | |
| Statuses Unpaid, Overdue, Partly Paid | none | Dropped | Every sale is paid in full |
| Customer, addresses, Payment Due Date, Payment Terms, advances, Debit To, currency conversion | none | Dropped | Excluded areas |
| Return / Credit Note created from the original invoice; negative quantities; full and partial; Update Stock on or off | Same | Kept | |
| Cumulative returned quantity cannot exceed the invoiced quantity | Same | Kept | |
| Return through a separate return Delivery Note | none | Dropped | No Delivery Notes |
| Refund through Payment Entry; allocating a credit to another invoice; keeping credit for later | Refund paid at once on the return, through a payment mode allowed in returns | Adapted | No Payment Entry, no customer to hold a credit |
| Exchange as a return plus a new sale | Same | Kept | |
| Rate adjustment Debit Note | none | Dropped | Accounting document |
| Cancel a submitted invoice | Same, with limits | Kept | |
| Amend a cancelled invoice | none | Dropped | A cancelled sale is rung up again at the Cash Register |
| View Ledger | "Stock Ledger" link only | Adapted | No General Ledger |
| Print Format "Standard" per document | Two built-in formats: Standard (full page) and POS Receipt (roll) | Adapted | |
| Print Format Builder, custom Jinja or JS formats, Print Style | none | Dropped | Section 8 |
| Print Settings: PDF Page Size, Repeat Header and Footer, Print With Letterhead, Compact Item Print, Allow Print for Draft, Always add "Draft" Heading, Allow Print for Cancelled, Print Taxes with Zero Amount | Same | Kept | |
| Print Settings: Send Print as PDF, Network Printer / Print Server, Allow Page Break Inside Table | none | Dropped | No email; Android's print service handles network printers |
| Letter Head: name, logo image, header and footer content, default | Logo, header text, footer text | Adapted | Plain text instead of HTML |
| Print Heading | Same | Kept | |
| Terms and Conditions: Title, Disabled, text, copied into the transaction | Same | Kept | |
| Terms and Conditions: applicable modules, copy attachments | none | Dropped | One module, no attachments |
| Raw Printing to thermal printers: receipts, paper cut, cash-drawer kick | Same, over Bluetooth | Adapted | ERPNext uses the QZ Tray desktop program; a phone talks to the printer directly |
| Raw Printing: hand-written raw command formats, printer mapping per computer | One built-in receipt layout; one saved printer | Adapted | |
| Cheque Print Template | none | Dropped | Payments out are not in scope |
| Rounded Total and In Words on the print | Same | Kept | |

## 3. Data model

```sql
CREATE TABLE letter_head (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  is_default INTEGER NOT NULL DEFAULT 0,
  disabled INTEGER NOT NULL DEFAULT 0,
  image BLOB,                    -- logo
  header TEXT,                   -- lines under the logo: address, phone, tax ID
  footer TEXT
);

CREATE TABLE print_heading (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE      -- 'Invoice', 'Bill', 'Official Receipt'
);

CREATE TABLE terms_and_conditions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL UNIQUE,
  terms TEXT NOT NULL,
  disabled INTEGER NOT NULL DEFAULT 0
);
```

### Print Settings (in `singles`)

| Label | Key | Default |
|---|---|---|
| PDF Page Size | `pdf_page_size` | A4 (also A5, Letter) |
| Repeat Header and Footer in PDF | `repeat_header_footer` | 1 |
| Print With Letterhead | `with_letterhead` | 1 |
| Compact Item Print | `compact_item_print` | 1 |
| Allow Print for Draft | `allow_print_for_draft` | 1 |
| Always add "Draft" Heading for printing draft documents | `add_draft_heading` | 1 |
| Allow Print for Cancelled | `allow_print_for_cancelled` | 0 |
| Print Taxes with Zero Amount | `print_taxes_with_zero_amount` | 0 |
| Enable Raw Printing | `enable_raw_printing` | 0 |
| Receipt printer (name and Bluetooth address) | `raw_printer_name`, `raw_printer_address` | empty |
| Paper width | `raw_paper_width` | 80mm (or 58mm) |
| Characters per line | `raw_chars_per_line` | 48 for 80mm, 32 for 58mm; editable |
| Cut paper after printing | `raw_cut_paper` | 1 |
| Open cash drawer after printing | `raw_open_cash_drawer` | 0 |

The last five rows have no ERPNext field. They replace the "print format - printer mapping" that QZ
Tray keeps on each computer. Characters per line is editable because printers of the same paper width
differ.

## 4. Business rules

### Finding and viewing

**INV-R1 Invoice list.** Shows every sales invoice: drafts, sales, returns, cancelled. Newest first.
Filters: status chips, date range. Search by invoice name; scanning the barcode on a receipt
(INV-R23) opens that invoice. Each row shows the name (or "Draft"), posting date and time, Grand
Total, and the status chip.

**INV-R2 Invoice detail.** Read-only once submitted. Sections: header (name, status, posting date
and time, POS Profile, session); Items; Taxes and Charges; totals; Payments and change; Terms; links
to the original ("Return Against") or to the returns made against it. Actions: Print, Create > Return
/ Credit Note, Stock Ledger, Cancel. A draft opens in the Cash Register instead.

**INV-R3 Status.** (Sales Invoice, Status; Sales Return, Status.)

| Status | When |
|---|---|
| Draft | Saved, not submitted. No stock effect. |
| Paid | A submitted sale. |
| Credit Note Issued | A submitted sale with at least one submitted return against it. |
| Return | A submitted invoice that is itself a return. |
| Cancelled | Cancelled; its stock effects were reversed. |

If the last return against a sale is cancelled, the sale goes back to Paid.

**INV-R4 Numbering.** Sales use the Sales Invoice series and returns use the Sales Invoice Return
series (`01-setup.md`). A name is assigned on Submit and never reused; a cancelled invoice keeps its
name. Only drafts can be deleted.

### Return / Credit Note

**INV-R5 Starting a return.** From a submitted sale: Create > Return / Credit Note, or Return in the
Cash Register's recent orders. A POS session must be open, because a refund moves cash; the sale's own
session may already be closed. "Creating the Credit Note from the original invoice preserves the
reference and copies the original items, rates, taxes." The new draft has:
- Is Return on and Return Against set to the original.
- Every line of the original with quantity = −(quantity sold − quantity already returned). Lines with
  nothing left to return are omitted.
- The original's rate, unit, discount and tax rates on each line, and the original's tax rows. A
  return is taxed as the sale was, not by today's template.
- Update Stock on, and the original's warehouse as the receiving warehouse.

(Credit Note; Sales Return.)

**INV-R6 Editing the return.**
- Remove the lines that are not coming back. For a partial return reduce the quantity: if the draft
  fetches −10 and 3 units come back, enter −3.
- Quantities stay negative. No line can exceed what is still returnable, and no item can be added
  that was not on the original. "ERPNext prevents the cumulative returned quantity from exceeding the
  original invoiced quantity."
- **Update Stock on**: the goods come back into the receiving warehouse, which can be changed. The
  rate is fixed at the original rate.
- **Update Stock off**: nothing moves in stock. Use it "for price-only corrections where no goods
  move". Only then may a line's rate be lowered, to credit part of the price. As in ERPNext, the
  line's quantity still counts as returned.
- For serial items, choose which of the sold serial numbers are coming back. For batch items the
  batch is the one sold.

**INV-R7 Refund.** The totals engine (`03-cash-register.md`) runs on the negative quantities, so Net
Total, taxes and Grand Total are negative. The refund is entered as payments in modes that the POS
Profile marks Allow in Returns, and must equal the amount in full. Returning one unit of a 108 item
sold with 8% tax included: Net Total −100.00, tax −8.00, Grand Total −108.00, refund 108.00. (POS
Profile, Payment Methods; Sales Return: Mode of Payment "used when the return transaction itself
records an immediate payment or refund".)

**INV-R8 Submitting a return.** Checks: a session is open; the original is still submitted;
quantities are within what is returnable; serial and batch entries match the lines; the refund equals
the amount. Then, in one transaction:
1. The name is taken from the return series.
2. With Update Stock on, each stock-item line writes a ledger entry of +quantity into the receiving
   warehouse at the cost the original sale went out at (STK-R33). The line keeps that cost as its
   `incoming_rate`, so the dashboard's profit is reversed exactly.
3. Returned serial numbers become Available in that warehouse with their original cost; their
   warranty date is cleared.
4. The return's status is Return; the original's becomes Credit Note Issued.

**INV-R9 Exchange.** "Record the returned Item through the appropriate return document. Create a new
Sales Invoice… for the replacement Item." After a return is submitted, its summary offers New Order.
Both documents fall in the same session, so the closing entry nets the refund against the new payment.

### Cancel

**INV-R10 Cancelling a sale.** "If an… invoice was created by mistake and the entire transaction
should not exist, cancellation may be simpler. Use a Credit Note when you need to keep the original
invoice and record a partial return… or a refund after payment." A sale can be cancelled only when:
- no submitted return exists against it ("Cancel only after handling linked… returns"), and
- its POS session is still open. Once the drawer has been counted, the correction is a return.

Cancelling marks its ledger entries cancelled and recomputes the affected items (STK-R36), sets its
serial numbers back to Available, and removes its payments from the session's expected amounts.

**INV-R11 Cancelling a return.** Allowed while the session it was made in is open. The returned
stock leaves again (the recomputation refuses if it has since been sold), serial numbers go back to
Delivered, and the original's status is recalculated (INV-R3).

### Printing

**INV-R12 Two formats.** Both are built from the same invoice data through one layout step, so they
always agree on content.

| Format | For | Output |
|---|---|---|
| Standard | A full-page invoice | PDF on the PDF Page Size |
| POS Receipt | A till receipt | PDF on a 58mm or 80mm roll, or raw commands to a thermal printer |

The print screen starts on the POS Profile's Print Format and offers the other. (Print Format: "Every
transaction has a default Print Format called 'Standard'"; POS Profile, Print Settings.)

**INV-R13 What may be printed.** A draft prints only with Allow Print for Draft, and then carries the
heading "DRAFT" when the draft-heading setting is on. A cancelled invoice prints only with Allow Print
for Cancelled, marked "CANCELLED". (Print Settings, 2.3, 2.4, 2.6.)

**INV-R14 Letter Head.** With Print With Letterhead on, the print starts with the letter head: the
invoice's own, else the POS Profile's, else the default. It shows the logo, then the header text. The
footer text is printed at the bottom. In the Standard format, header and footer repeat on every page
when Repeat Header and Footer is on. The print screen has a switch to print without it. (Letter Head;
Print Settings, 1.2 and 2.1.)

**INV-R15 Print Heading.** The title of the document. Default "Sales Invoice", or "Credit Note" for a
return. A Print Heading chosen on the POS Profile replaces it for sales: "the heading can be
'Invoice', or 'Bill'." (Print Headings; POS Profile.)

**INV-R16 Terms.** When a sale is started, the text of the POS Profile's Terms and Conditions
template is copied into the invoice's `terms`. Later edits to the template do not change old invoices.
The text prints after the totals. (Terms and Conditions: "ERPNext copies the selected template into
the transaction.")

**INV-R17 Item table.** (Print Settings, 2.2.)
- **Compact Item Print on**: four columns, Description, Qty, Rate, Amount. Item name, item code,
  description, discount, and serial or batch numbers are all placed in the Description cell.
- **Off** (Standard format only): Sr, Item Code, Item Name, Description, Qty, UOM, Rate, Discount,
  Amount.
- The POS Receipt is always compact: the item name on one line, then `qty × rate` on the left and the
  amount on the right, then a discount line when there is one.
- Rate is the rate the buyer was quoted, so with tax included it is the tax-inclusive rate.

**INV-R18 Totals block.** In this order: Net Total; one line per tax row with its description and
amount, marked "(included)" for rows included in the rate; Additional Discount when present; Grand
Total; Rounding Adjustment and Rounded Total unless Disable Rounded Total is on; In Words unless
Disable In Words is on; each payment with its mode; Change. Tax rows with a zero amount are left out
unless Print Taxes with Zero Amount is on. (Print Settings, 2.7; Disable Rounded Total.)

**INV-R19 In Words.** Spells the amount to pay: the currency code, the whole part in words, then the
fractional part counted in the currency's Fraction Units with the Fraction name, then "only".
108.00 is "USD One Hundred And Eight only." 754.90 is "USD Seven Hundred And Fifty Four and Ninety
Cents only." The number format `#,##,###.##` switches the words to lakh and crore. English is the
only language built. (Invoice rounding issue; Currency.)

**INV-R20 Amount display.** The currency symbol is printed before the amount, or after it when Show
Currency Symbol on Right Side is on, and not at all with Hide Currency Symbol. Amounts use the Number
Format and Currency Precision.

**INV-R21 Output of a PDF.** The print screen shows a preview and offers Print (Android's print
dialog, which reaches Wi-Fi and USB printers through the device's print services) and Share (the PDF
file, to any app on the device).

**INV-R22 Raw printing.** "Sending a string of commands to a printer directly in its native language…
bypasses the printer's drivers… making them very fast and reliable… cutting receipt paper, kicking
out cash drawers." (Raw Printing.)
- Available when Enable Raw Printing is on and a receipt printer is saved. The printer is chosen from
  the Bluetooth printers already paired in Android's settings.
- The POS Receipt layout is turned into ESC/POS commands: initialise, centred bold store header,
  heading, name and date, the lines, a rule, the totals, payments, terms, footer, feed.
- Text is wrapped to Characters per line. Long item names wrap; amounts stay right-aligned.
- A currency symbol the printer's character set cannot print is replaced by the currency code.
- When Cut paper is on, a cut command ends the job. When Open cash drawer is on, a drawer-kick
  command is sent.
- "Test print" on the settings page prints a ruler line of the configured width and a sample receipt,
  so width and cutting can be checked without making a sale.
- If the printer cannot be reached, the app says so and offers the PDF. A print failure never affects
  the sale, which is already saved.

**INV-R23 Receipt barcode.** The POS Receipt ends with the invoice name as a Code 128 barcode. Scanning
it in the invoice list or the Cash Register's recent orders opens the invoice, which is the quickest
way to start a return.

**INV-R24 When printing happens.** With the profile's Print Receipt on Order Complete: after Submit,
a saved receipt printer prints immediately; otherwise the print preview opens. Any invoice can be
reprinted at any time from its detail screen.

## 5. Screens

### Invoice list

`SearchBar` with a scan button; status `FilterChip`s (Draft, Paid, Credit Note Issued, Return,
Cancelled); a date-range chip. Compact: `ListTile` rows. Expanded: list on the left, detail on the
right.

### Invoice detail

Header card with name, status chip, date and time. Items as rows of name, `qty × rate`, amount
(a `DataTable` on Expanded). Taxes, totals and payments as label-and-value rows. A `MenuAnchor`
"Create" with Return / Credit Note. App-bar actions: Print, and an overflow with Stock Ledger and
Cancel. Returns against the invoice are listed at the bottom as links.

### Return form

The original's lines, each with a returnable quantity and a quantity stepper that runs from 0 to that
number; lines at 0 are dropped. An Update Stock switch with the receiving warehouse under it. Rate
fields become editable only when the switch is off. Totals shown as the refund amount. Then the
payment panel from the Cash Register, restricted to modes allowed in returns. "Submit" asks for
confirmation with the refund amount in the dialog.

### Print screen

A preview that fills the screen, and a bottom bar: Print Format `SegmentedButton` (Standard, POS
Receipt), a Letter Head switch, and the buttons "Print", "Share", and "Receipt printer" when raw
printing is set up. On Expanded the controls sit in a side panel beside the preview.

### Printing setup (under Setup)

- **Print Settings**: the switches of section 3, then a "Receipt printer" section with Enable Raw
  Printing, the paired-printer picker, paper width, characters per line, the cut and drawer switches,
  and "Test print".
- **Letter Head**: list and form with name, logo picker, header text, footer text, Default, and a
  live preview of the top of an invoice.
- **Print Heading** and **Terms and Conditions**: list and form.

### States

- No invoices yet: "Sales you complete at the Cash Register appear here."
- A refused cancel or return explains which rule stopped it and what to do instead.
- Bluetooth off or permission missing: the printer picker says so and links to the system setting.

## 6. Build steps

| Step | Work | Runnable result |
|---|---|---|
| INV-B1 | Invoice list with filters and search, invoice detail, Stock Ledger link (INV-R1 to R4) | Every sale from the Cash Register can be found and read |
| INV-B2 | Letter Head, Print Heading, Terms and Conditions masters; terms copied into new sales (INV-R14 to R16) | A new sale carries the profile's terms |
| INV-B3 | Print Settings page | Settings save and reload |
| INV-B4 | Layout step in `logic/` that turns an invoice into print blocks; amount-in-words function; their tests (INV-R17 to R20) | Tests cover compact and full columns, zero-tax rows, wording |
| INV-B5 | Standard PDF, POS Receipt PDF, print screen with preview, Print and Share (INV-R12, R13, R21) | An invoice prints to a real printer or saves as a PDF |
| INV-B6 | Receipt barcode and scan-to-open (INV-R23) | Scanning a printed receipt opens its invoice |
| INV-B7 | Raw printing: choose the Bluetooth ESC/POS package, printer picker, command builder, test print, auto-print after a sale (INV-R22, R24) | A sale prints on a thermal printer, cuts, and opens the drawer |
| INV-B8 | Return / Credit Note: form, checks, stock and serial effects, statuses, exchange hand-off (INV-R5 to R9) | A partial return puts stock back and refunds the right amount |
| INV-B9 | Cancel for sales and returns (INV-R10, R11) | A mistaken sale in the open session disappears from stock, dashboard and expected cash |

All nine are milestone M6. INV-B7 needs a physical thermal printer to finish.

## 7. Acceptance checks

Unit tests:

| Check | Expected |
|---|---|
| INV-A1 In Words for 108.00 in USD | `USD One Hundred And Eight only.` |
| INV-A2 In Words for 754.90 in USD | `USD Seven Hundred And Fifty Four and Ninety Cents only.` |
| INV-A3 Layout with Compact Item Print on / off | 4 columns / 9 columns |
| INV-A4 A tax row of 0.00 with Print Taxes with Zero Amount off / on | Absent / present |
| INV-A5 Disable Rounded Total on | No Rounding Adjustment or Rounded Total lines |
| INV-A6 Receipt layout at 32 characters with a 60-character item name | No line longer than 32; amounts right-aligned |
| INV-A7 Raw commands with cut on and drawer off | Start with the initialise command, end with the cut command, no drawer command |
| INV-A8 Currency symbol the printer cannot encode | Currency code printed instead |
| INV-A9 Draft with the draft-heading setting on | Heading contains "DRAFT" |

Database tests:

| Check | Expected |
|---|---|
| INV-A10 Sale of 10 units; start a return | Draft line quantity −10 |
| INV-A11 Return 3; then start another return | Second draft offers −7 |
| INV-A12 Try to return 8 after 3 were returned | Refused |
| INV-A13 Return 1 of an item sold at 108 with 8% included | Net −100.00; tax −8.00; Grand Total −108.00 |
| INV-A14 Sale posted at cost 100; cost later changes; return it | Stock comes back at 100; dashboard profit for that unit nets to zero |
| INV-A15 Submit a return | Return has status Return and a name in the return series; the sale shows Credit Note Issued |
| INV-A16 Cancel that return | The sale shows Paid again; stock is back out |
| INV-A17 Return with Update Stock off | No ledger entry; quantity still counted as returned |
| INV-A18 Refund in a mode without Allow in Returns | Not offered |
| INV-A19 Return a serialised unit | The serial number is Available again with its original cost |
| INV-A20 Cancel a sale that has a submitted return | Refused |
| INV-A21 Cancel a sale after its session is closed | Refused, with "use a return" |
| INV-A22 Cancel a sale in the open session | Status Cancelled; ledger entries marked cancelled; balances restored; name not reused by the next sale |
| INV-A23 Print a cancelled invoice with Allow Print for Cancelled off | Refused |
| INV-A24 Edit the Terms template after a sale | The sale's printed terms are unchanged |

Manual checks: Standard PDF on A4 and A5 with a 40-line invoice (header and footer repeat); POS
Receipt at 58mm and 80mm on a real thermal printer, including cut and drawer; scan the printed
barcode to open the invoice; every screen on a phone and a tablet in both orientations.

## 8. Left out on purpose

| Not built | Add it when |
|---|---|
| Print Format Builder, custom formats, Print Styles | The two built-in formats cannot be made to fit a legal or branding requirement |
| HTML letter heads | Plain text and a logo are not enough |
| Store credit kept for a later purchase; allocating a credit to another invoice | Customers are added |
| Price reductions that do not use up returnable quantity | Price-only credits become common enough for the ERPNext behaviour to get in the way |
| Amending a cancelled invoice | Never; ring the sale up again |
| In Words in other languages | A second interface language is shipped |
| Printing Stock Entries, Stock Reconciliations and the POS Closing Entry | The owner wants paper records of stock movements or an end-of-day slip |
| Network or USB thermal printers through raw commands | The store's printer is not Bluetooth; until then Android's print dialog covers them through the PDF |
| Email or messaging a receipt from inside the app | The app is allowed online; Share already hands the PDF to any installed app |
| Cheque Print Template | Never; the app records no outgoing payments |

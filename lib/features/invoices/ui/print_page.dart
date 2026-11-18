import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/ui/pos_providers.dart';
import '../data/invoice_db.dart';
import '../logic/escpos.dart';
import '../logic/invoice.dart';
import '../logic/print_layout.dart';
import '../logic/receipt_text.dart';
import 'invoice_pdf.dart';
import 'invoice_providers.dart';
import 'raw_printer.dart';

// The print screen (05-invoices-and-receipts INV-R12, R13, R21, R22, R24).

/// Opens the print screen for invoice [id] over everything, from any
/// destination.
Future<void> openPrint(BuildContext context, int id) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => PrintPage(invoiceId: id)));

final printSettingsProvider = Provider<PrintSettings>(
  (ref) => PrintSettings(
    ref.watch(singleProvider(PrintSettings.doctype)).value ?? const {},
  ),
);

final pdfFontsProvider = FutureProvider<PdfFonts>((_) => loadPdfFonts());

/// Print Settings and Global Defaults as the layout reads them.
PrintOptions printOptions(
  PrintSettings p,
  Formats f, {
  required bool compact,
  required bool letterHead,
}) => (
  compact: compact,
  withLetterhead: letterHead,
  zeroTaxes: p.printTaxesWithZeroAmount,
  draftHeading: p.addDraftHeading,
  roundedTotal: !f.defaults.disableRoundedTotal,
  inWords: !f.defaults.disableInWords,
);

/// [inv] laid out for printing; amounts through [money] (default: the
/// Number Format and currency symbol, INV-R20).
PrintDoc layoutFor(
  Invoice inv,
  AppLocalizations l,
  Formats f,
  PrintOptions o, {
  String Function(num)? money,
}) => layoutInvoice(
  inv,
  o,
  money: money ?? f.money,
  number: f.number,
  when: (d) => '${f.date(d)} ${f.time(d)}',
  label: (p) => printLabel(l, p),
);

String printLabel(AppLocalizations l, PrintLabel p) => switch (p) {
  PrintLabel.salesInvoice => l.salesInvoice,
  PrintLabel.creditNote => l.creditNote,
  PrintLabel.draft => l.draftMark,
  PrintLabel.cancelled => l.cancelledMark,
  PrintLabel.invoiceNo => l.invoiceNo,
  PrintLabel.date => l.date,
  PrintLabel.returnAgainst => l.returnAgainst,
  PrintLabel.sr => l.serialNumberColumn,
  PrintLabel.itemCode => l.itemCode,
  PrintLabel.itemName => l.itemName,
  PrintLabel.description => l.description,
  PrintLabel.qty => l.qty,
  PrintLabel.uom => l.uom,
  PrintLabel.rate => l.rate,
  PrintLabel.discount => l.discountLabel,
  PrintLabel.amount => l.amount,
  PrintLabel.netTotal => l.netTotal,
  PrintLabel.included => l.included,
  PrintLabel.additionalDiscount => l.additionalDiscount,
  PrintLabel.grandTotal => l.grandTotal,
  PrintLabel.roundingAdjustment => l.roundingAdjustment,
  PrintLabel.roundedTotal => l.roundedTotal,
  PrintLabel.changeAmount => l.changeAmount,
};

/// INV-R22: [doc] as one raw print job with [p]'s characters per line,
/// cut and drawer, after any [lead] lines (Test print's ruler).
List<int> receiptJob(
  PrintDoc doc,
  PrintSettings p,
  Formats f, {
  List<ReceiptLine> lead = const [],
}) => escPosJob(
  [
    ...lead,
    ...receiptLines(
      doc,
      p.rawCharsPerLine,
      clean: (t) =>
          printable(t, symbol: f.currency?.symbol, code: f.currency?.code),
    ),
  ],
  barcode: doc.barcode,
  cut: p.rawCutPaper,
  drawer: p.rawOpenCashDrawer,
);

/// INV-R22: the POS Receipt of [inv] on the saved receipt printer, with
/// the letter head unless [letterHead] is false. False when the printer
/// cannot be reached.
Future<bool> printRaw(
  Invoice inv,
  PrintSettings p,
  Formats f,
  AppLocalizations l, {
  bool? letterHead,
}) async {
  final address = p.rawPrinterAddress;
  if (address == null || address.isEmpty) return false;
  final doc = layoutFor(
    inv,
    l,
    f,
    printOptions(
      p,
      f,
      compact: true,
      letterHead: letterHead ?? p.withLetterhead,
    ),
  );
  return sendRaw(address, receiptJob(doc, p, f));
}

/// Tells whether raw print [job] reached the printer.
Future<void> reportRaw(BuildContext context, Future<bool> job) async {
  final l = AppLocalizations.of(context);
  final ok = await job;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok ? l.receiptSent : l.printerUnreachable)),
  );
}

/// Raw printing is set up: on, with a saved printer (INV-R22).
bool rawReady(PrintSettings p) =>
    p.enableRawPrinting && (p.rawPrinterAddress ?? '').isNotEmpty;

/// INV-R24: after a sale, a saved receipt printer prints at once; without
/// one, or when it cannot be reached, the print preview opens.
Future<void> printAfterSale(BuildContext context, WidgetRef ref, int id) async {
  final l = AppLocalizations.of(context);
  final p = ref.read(printSettingsProvider);
  if (rawReady(p)) {
    final inv = await ref.read(appDatabaseProvider).invoiceView(id);
    if (await printRaw(inv, p, ref.read(formatsProvider), l)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.printerUnreachable)));
  }
  if (context.mounted) await openPrint(context, id);
}

class PrintPage extends ConsumerStatefulWidget {
  const PrintPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  ConsumerState<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends ConsumerState<PrintPage> {
  /// The POS Settings' Print Format, until another is chosen (INV-R12).
  late var _format = PrintFormat.of(ref.read(posSettingsProvider).printFormat);

  /// Print With Letterhead, until switched (INV-R14).
  late var _letterHead = ref.read(printSettingsProvider).withLetterhead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inv = ref.watch(invoiceViewProvider(widget.invoiceId)).value;
    final fonts = ref.watch(pdfFontsProvider).value;
    final p = ref.watch(printSettingsProvider);
    final f = ref.watch(formatsProvider);
    if (inv == null || fonts == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.print)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final title = inv.name ?? l.draftNumber(inv.id);
    if (!mayPrint(
      inv.status,
      allowDraft: p.allowPrintForDraft,
      allowCancelled: p.allowPrintForCancelled,
    )) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              inv.status == 'Draft'
                  ? l.printDraftNotAllowed
                  : l.printCancelledNotAllowed,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    // D-67: a currency symbol the font cannot draw prints as the code.
    final symbol = f.currency?.symbol ?? '';
    final drawn = symbol.runes.every(fonts.runes.contains);
    final doc = layoutFor(
      inv,
      l,
      f,
      printOptions(
        p,
        f,
        compact: _format == PrintFormat.posReceipt || p.compactItemPrint,
        letterHead: _letterHead,
      ),
      money: drawn
          ? null
          : (v) => f.money(v).replaceAll(symbol, f.currency?.code ?? ''),
    );
    Future<Uint8List> pdf() => invoiceDocument(
      doc,
      format: _format,
      fonts: fonts,
      pageSize: pageFormatOf(p.pdfPageSize),
      repeatHeader: p.repeatHeaderFooter,
      rollMm: p.rawPaperMm,
    ).save();
    final file = '${title.replaceAll(RegExp(r'[^\w-]'), '_')}.pdf';
    final controls = <Widget>[
      SegmentedButton<PrintFormat>(
        segments: [
          ButtonSegment(
            value: PrintFormat.standard,
            label: Text(l.formatStandard),
          ),
          ButtonSegment(
            value: PrintFormat.posReceipt,
            label: Text(l.formatPosReceipt),
          ),
        ],
        selected: {_format},
        onSelectionChanged: (s) => setState(() => _format = s.single),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.letterHead),
        value: _letterHead,
        onChanged: (on) => setState(() => _letterHead = on),
      ),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          FilledButton.icon(
            onPressed: () =>
                Printing.layoutPdf(name: file, onLayout: (_) => pdf()),
            icon: const Icon(Icons.print_outlined),
            label: Text(l.print),
          ),
          OutlinedButton.icon(
            onPressed: () async =>
                Printing.sharePdf(bytes: await pdf(), filename: file),
            icon: const Icon(Icons.share_outlined),
            label: Text(l.share),
          ),
          if (rawReady(p))
            OutlinedButton.icon(
              onPressed: () => reportRaw(
                context,
                printRaw(inv, p, f, l, letterHead: _letterHead),
              ),
              icon: const Icon(Icons.receipt_outlined),
              label: Text(l.receiptPrinter),
            ),
        ],
      ),
    ];
    final preview = PdfPreview(
      key: ValueKey('$_format/$_letterHead'),
      build: (_) => pdf(),
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      pdfFileName: file,
    );
    final expanded = WindowSize.of(context) == WindowSize.expanded;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: expanded
          ? Row(
              children: [
                Expanded(child: preview),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 320,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      for (final c in controls) ...[
                        c,
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(child: preview),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: controls,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

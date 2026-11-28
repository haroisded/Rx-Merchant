import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/db/singles.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/settings_pages.dart';
import '../../setup/ui/simple_masters.dart';
import '../data/print_masters.dart';
import '../logic/escpos.dart';
import '../logic/invoice.dart';
import 'print_page.dart';
import 'raw_printer.dart';

// Setup > Printing (05-invoices-and-receipts section 5): Print Settings with
// the receipt printer, Letter Head, Print Heading, Terms and Conditions.

final letterHeadsProvider = StreamProvider<List<LetterHeadData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.letterHead).watch();
});

final printHeadingsProvider = StreamProvider<List<PrintHeadingData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.printHeading).watch();
});

final termsProvider = StreamProvider<List<TermsAndCondition>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.termsAndConditions).watch();
});

const _loading = Scaffold(body: Center(child: CircularProgressIndicator()));

/// The paired Bluetooth printers, or why none can be listed (INV-R22).
final _printersProvider = FutureProvider.autoDispose((_) => pairedPrinters());

/// Print Settings (section 3): the PDF switches, then the receipt printer.
class PrintSettingsPage extends ConsumerWidget {
  const PrintSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final found = ref.watch(_printersProvider);
    if (!found.hasValue) return _loading;
    final (state, list) = found.requireValue;
    // The saved printer stays a choice while Bluetooth is off, so saving
    // another setting does not forget it.
    final saved = ref.watch(printSettingsProvider);
    final paired = [
      ...list,
      if ((saved.rawPrinterAddress ?? '').isNotEmpty &&
          !list.any((p) => p.address == saved.rawPrinterAddress))
        (name: saved.rawPrinterName ?? '', address: saved.rawPrinterAddress!),
    ];
    SingleField check(
      String key,
      String label,
      bool Function(PrintSettings) read,
    ) => SingleField(
      key,
      label,
      kind: FieldKind.check,
      read: (v) => read(PrintSettings(v)) ? '1' : '0',
    );
    return SinglesForm(
      doctype: PrintSettings.doctype,
      title: l.printSettings,
      sections: [
        (
          l.printSettings,
          [
            SingleField(
              'pdf_page_size',
              l.pdfPageSize,
              kind: FieldKind.choice,
              options: const ['A4', 'A5', 'Letter'],
              read: (v) => PrintSettings(v).pdfPageSize,
            ),
            check(
              'repeat_header_footer',
              l.repeatHeaderFooter,
              (s) => s.repeatHeaderFooter,
            ),
            check('with_letterhead', l.withLetterhead, (s) => s.withLetterhead),
            check(
              'compact_item_print',
              l.compactItemPrint,
              (s) => s.compactItemPrint,
            ),
            check(
              'allow_print_for_draft',
              l.allowPrintForDraft,
              (s) => s.allowPrintForDraft,
            ),
            check(
              'add_draft_heading',
              l.addDraftHeading,
              (s) => s.addDraftHeading,
            ),
            check(
              'allow_print_for_cancelled',
              l.allowPrintForCancelled,
              (s) => s.allowPrintForCancelled,
            ),
            check(
              'print_taxes_with_zero_amount',
              l.printTaxesWithZeroAmount,
              (s) => s.printTaxesWithZeroAmount,
            ),
          ],
        ),
        (
          l.receiptPrinter,
          [
            check(
              'enable_raw_printing',
              l.enableRawPrinting,
              (s) => s.enableRawPrinting,
            ),
            SingleField(
              'raw_printer_name',
              l.receiptPrinter,
              kind: FieldKind.choice,
              options: ['', for (final p in paired) p.name],
              optionLabel: (o) => o.isEmpty ? l.none : o,
              read: (v) => PrintSettings(v).rawPrinterName ?? '',
            ),
            SingleField(
              'raw_paper_width',
              l.paperWidth,
              kind: FieldKind.choice,
              options: const ['80mm', '58mm'],
              read: (v) => PrintSettings(v).rawPaperWidth,
            ),
            SingleField(
              'raw_chars_per_line',
              l.charsPerLine,
              kind: FieldKind.wholeNumber,
              read: (v) => '${PrintSettings(v).rawCharsPerLine}',
            ),
            check('raw_cut_paper', l.cutPaper, (s) => s.rawCutPaper),
            check(
              'raw_open_cash_drawer',
              l.openCashDrawer,
              (s) => s.rawOpenCashDrawer,
            ),
          ],
        ),
      ],
      // The printer is kept by name and Bluetooth address.
      beforeSave: (values) async {
        final name = values['raw_printer_name'];
        values['raw_printer_address'] =
            paired.where((p) => p.name == name).firstOrNull?.address ?? '';
      },
      preview: (values) => _PrinterPanel(
        state: state,
        paired: paired,
        values: values,
        onRetry: () => ref.invalidate(_printersProvider),
      ),
    );
  }
}

/// The receipt printer's state (section 5, States) and Test print.
class _PrinterPanel extends ConsumerWidget {
  const _PrinterPanel({
    required this.state,
    required this.paired,
    required this.values,
    required this.onRetry,
  });

  final PrinterState state;
  final List<Printer> paired;
  final Map<String, String> values;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final (message, bluetooth) = switch (state) {
      PrinterState.noPermission => (l.bluetoothNoPermission, false),
      PrinterState.bluetoothOff => (l.bluetoothOff, true),
      PrinterState.ready when paired.isEmpty => (l.noPairedPrinters, true),
      PrinterState.ready => (null, true),
    };
    final printer = paired
        .where((p) => p.name == values['raw_printer_name'])
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message != null) ...[
          Text(message),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: () => openSystemSettings(bluetooth: bluetooth),
                child: Text(bluetooth ? l.bluetoothSettings : l.appPermissions),
              ),
              TextButton(onPressed: onRetry, child: Text(l.refresh)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.tonalIcon(
          onPressed: printer == null
              ? null
              : () => _test(context, ref, printer),
          icon: const Icon(Icons.receipt_outlined),
          label: Text(l.testPrint),
        ),
      ],
    );
  }

  /// INV-R22: a ruler of the configured width and a sample receipt, with
  /// the edited (unsaved) width, cut and drawer settings.
  Future<void> _test(
    BuildContext context,
    WidgetRef ref,
    Printer printer,
  ) async {
    final l = AppLocalizations.of(context);
    final f = ref.read(formatsProvider);
    final p = PrintSettings(values);
    final sample = Invoice(
      id: 0,
      name: l.testPrint,
      status: 'Paid',
      docstatus: 1,
      posting: DateTime.now(),
      lines: [
        InvoiceLine(
          id: 0,
          itemCode: l.sampleItem,
          itemName: l.sampleItem,
          qty: 2,
          uom: 'Nos',
          rate: 1.5,
          amount: 3,
        ),
      ],
      payments: const [(mode: 'Cash', amount: 5)],
      netTotal: 3,
      grandTotal: 3,
      changeAmount: 2,
    );
    final doc = layoutFor(
      sample,
      l,
      f,
      printOptions(p, f, compact: true, letterHead: false),
    );
    await reportRaw(
      context,
      sendRaw(
        printer.address,
        receiptJob(doc, p, f, lead: rulerLines(p.rawCharsPerLine)),
      ),
    );
  }
}

/// INV-R14: list and form. The Default one prints on new sales.
class LetterHeadPage extends ConsumerWidget {
  const LetterHeadPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(letterHeadsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<LetterHeadData>(
        title: l.letterHead,
        rows: rows,
        labelOf: (h) => h.name,
        subtitleOf: (h) => h.isDefault == 1 ? l.isDefault : null,
        isDisabled: (h) => h.disabled == 1,
        onOpen: (h) => context.go('$path/${h.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    return _LetterHeadForm(
      key: ValueKey(id),
      path: path,
      head: recordFor(rows.value ?? [], id, (h) => h.id),
    );
  }
}

class _LetterHeadForm extends ConsumerStatefulWidget {
  const _LetterHeadForm({super.key, required this.path, this.head});

  final String path;
  final LetterHeadData? head;

  @override
  ConsumerState<_LetterHeadForm> createState() => _LetterHeadFormState();
}

class _LetterHeadFormState extends ConsumerState<_LetterHeadForm> {
  late final _name = TextEditingController(text: widget.head?.name);
  late final _header = TextEditingController(text: widget.head?.header);
  late final _footer = TextEditingController(text: widget.head?.footer);
  late Uint8List? _image = widget.head?.image;
  late var _default = widget.head?.isDefault == 1;
  late var _disabled = widget.head?.disabled == 1;

  @override
  void dispose() {
    _name.dispose();
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _image = bytes);
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = widget.head;
    final db = ref.read(appDatabaseProvider);
    final scheme = Theme.of(context).colorScheme;
    return FormPage(
      title: h?.name ?? l.newRecord(l.letterHead),
      onSave: () async {
        final ok = await attempt(
          context,
          () => db.saveLetterHead(
            LetterHeadCompanion(
              id: h == null ? const Value.absent() : Value(h.id),
              name: Value(_name.text.trim()),
              image: Value(_image),
              header: Value(_text(_header)),
              footer: Value(_text(_footer)),
              isDefault: Value(_default ? 1 : 0),
              disabled: Value(_disabled ? 1 : 0),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
        return ok;
      },
      onDelete: h == null
          ? null
          : () async {
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(h.name),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              final ok = await attempt(
                context,
                () => db.deleteMaster(db.letterHead, h.id),
              );
              if (ok && context.mounted) context.go(widget.path);
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.name} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            SwitchListTile(
              title: Text(l.isDefault),
              value: _default,
              onChanged: (on) => setState(() => _default = on),
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
        SectionHeading(l.logo),
        Row(
          spacing: AppSpacing.sm,
          children: [
            IconButton.filledTonal(
              tooltip: l.takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: () => _pick(ImageSource.camera),
            ),
            IconButton.filledTonal(
              tooltip: l.choosePhoto,
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => _pick(ImageSource.gallery),
            ),
            if (_image != null)
              IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _image = null),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _header,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: l.headerText,
            helperText: l.headerTextHelp,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _footer,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.footerText),
          onChanged: (_) => setState(() {}),
        ),
        SectionHeading(l.preview),
        // The top of an invoice as it will print.
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_image case final bytes?)
                  Image.memory(bytes, height: 64, fit: BoxFit.contain),
                for (final (i, line) in _header.text.split('\n').indexed)
                  if (line.trim().isNotEmpty)
                    Text(
                      line.trim(),
                      style: i == 0
                          ? Theme.of(context).textTheme.titleMedium
                          : null,
                    ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.salesInvoice,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Divider(color: scheme.outlineVariant),
                if (_footer.text.trim().isNotEmpty)
                  Text(
                    _footer.text.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// INV-R15: the title a sale prints under instead of "Sales Invoice".
class PrintHeadingPage extends ConsumerWidget {
  const PrintHeadingPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(printHeadingsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<PrintHeadingData>(
        title: l.printHeading,
        rows: rows,
        labelOf: (h) => h.name,
        onOpen: (h) => context.go('$path/${h.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    final h = recordFor(rows.value ?? [], id, (h) => h.id);
    final db = ref.read(appDatabaseProvider);
    return NamedMasterForm(
      key: ValueKey(id),
      title: h?.name ?? l.newRecord(l.printHeading),
      listPath: path,
      name: h?.name ?? '',
      switches: const [],
      onSave: (name, _, _, _) => db.savePrintHeading(
        PrintHeadingCompanion(
          id: h == null ? const Value.absent() : Value(h.id),
          name: Value(name),
        ),
      ),
      onDelete: h == null ? null : () => db.deleteMaster(db.printHeading, h.id),
    );
  }
}

/// INV-R16: reusable terms, copied into a sale when it starts.
class TermsPage extends ConsumerWidget {
  const TermsPage({super.key, required this.path, this.id});

  final String path;
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(termsProvider);
    final id = this.id;
    if (id == null) {
      return MasterList<TermsAndCondition>(
        title: l.termsAndConditions,
        rows: rows,
        labelOf: (t) => t.title,
        isDisabled: (t) => t.disabled == 1,
        onOpen: (t) => context.go('$path/${t.id}'),
        onAdd: () => context.go('$path/new'),
      );
    }
    if (!rows.hasValue) return _loading;
    return _TermsForm(
      key: ValueKey(id),
      path: path,
      terms: recordFor(rows.value ?? [], id, (t) => t.id),
    );
  }
}

class _TermsForm extends ConsumerStatefulWidget {
  const _TermsForm({super.key, required this.path, this.terms});

  final String path;
  final TermsAndCondition? terms;

  @override
  ConsumerState<_TermsForm> createState() => _TermsFormState();
}

class _TermsFormState extends ConsumerState<_TermsForm> {
  late final _title = TextEditingController(text: widget.terms?.title);
  late final _text = TextEditingController(text: widget.terms?.terms);
  late var _disabled = widget.terms?.disabled == 1;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.terms;
    final db = ref.read(appDatabaseProvider);
    String? mandatory(String? v) => v!.trim().isEmpty ? l.mandatoryField : null;
    return FormPage(
      title: t?.title ?? l.newRecord(l.termsAndConditions),
      onSave: () async {
        final ok = await attempt(
          context,
          () => db.saveTerms(
            TermsAndConditionsCompanion(
              id: t == null ? const Value.absent() : Value(t.id),
              title: Value(_title.text.trim()),
              terms: Value(_text.text.trim()),
              disabled: Value(_disabled ? 1 : 0),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
        return ok;
      },
      onDelete: t == null
          ? null
          : () async {
              if (!await confirm(
                    context,
                    title: l.deleteTitle,
                    body: l.deleteBody(t.title),
                    action: l.delete,
                  ) ||
                  !context.mounted) {
                return;
              }
              final ok = await attempt(
                context,
                () => db.deleteMaster(db.termsAndConditions, t.id),
              );
              if (ok && context.mounted) context.go(widget.path);
            },
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: '${l.title} *'),
              validator: mandatory,
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _text,
          minLines: 4,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: '${l.termsAndConditions} *',
            helperText: l.termsHelp,
          ),
          validator: mandatory,
        ),
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../stock/logic/stock_documents.dart';
import '../data/refusal.dart';

// The pieces every Setup page is built from (00-overview, section 7.1).

/// Blocking validation errors: an AlertDialog listing each problem. The form
/// behind it keeps its contents.
Future<void> showProblems(BuildContext context, List<String> problems) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).problemsTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in problems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text('• $p'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );

String refusalText(AppLocalizations l, RefusedException e, Formats f) {
  final d = e.detail ?? '';
  final a = e.args;
  String when(Object? at) => at == null
      ? ''
      : '${f.date(DateTime.parse('$at'))} ${f.time(DateTime.parse('$at'))}';
  return switch (e.reason) {
    Refusal.duplicateName => l.refusedDuplicateName,
    Refusal.referenced => l.refusedReferenced,
    Refusal.defaultPriceList => l.refusedDefaultPriceList,
    Refusal.seriesBelowUsed => l.refusedSeriesBelowUsed(d),
    Refusal.notABackup => l.refusedNotABackup,
    Refusal.backupTooNew => l.refusedBackupTooNew,
    Refusal.sessionOpen => l.refusedSessionOpen,
    Refusal.negativeStock => l.refusedNegativeStock(
      '${a[0]}',
      '${a[1]}',
      f.number(a[2]! as num),
      f.number(a[3]! as num),
      when(a[4]),
      '${a[5]}',
    ),
    Refusal.negativeBatch => l.refusedNegativeBatch(
      '${a[0]}',
      '${a[1]}',
      '${a[2]}',
      when(a[3]),
      '${a[4]}',
    ),
    Refusal.stockFrozen => l.refusedStockFrozen(
      d.isEmpty ? d : f.date(DateTime.parse(d)),
    ),
    Refusal.frozenField => l.lockedAfterStock,
    Refusal.hasVariantsLocked => l.refusedHasVariantsLocked,
    Refusal.template => l.refusedTemplate(d),
    Refusal.unitInUse => l.refusedUnitInUse(d),
    Refusal.barcodeTaken => l.refusedBarcodeTaken(d),
    Refusal.badBarcode => l.refusedBadBarcode(d),
    Refusal.overlappingPrice => l.importOverlappingPrice,
    Refusal.defaultWarehouse => l.refusedDefaultWarehouse,
    Refusal.warehouseHasLedger => l.refusedWarehouseHasLedger,
    Refusal.lineProblem => lineProblemMessage(
      l,
      a[0]! as int,
      a[1]! as LineProblem,
    ),
    Refusal.batchRequired => l.refusedBatchRequired(d),
    Refusal.serialRequired => l.refusedSerialRequired(d),
    Refusal.notEnoughEntries => l.refusedNotEnoughEntries(d),
    Refusal.expiredBatch => l.refusedExpiredBatch(d),
    Refusal.batchNotFound => l.refusedBatchNotFound(d),
    Refusal.expiryRequired => l.refusedExpiryRequired(d),
    Refusal.serialNotAvailable => l.refusedSerialNotAvailable(d),
    Refusal.serialExists => l.refusedSerialExists(d),
    Refusal.serialMovedSince => l.refusedSerialMovedSince(d),
    Refusal.docstatus => l.refusedDocstatus,
    Refusal.noOpenSession => l.refusedNoOpenSession,
    Refusal.anotherSessionOpen => l.refusedAnotherSessionOpen,
    Refusal.emptyCart => l.refusedEmptyCart,
    Refusal.itemUnavailable => l.refusedItemUnavailable(
      '${a[0]}',
      '${a[1]}',
      f.number(a[2]! as num),
      f.number(a[3]! as num),
    ),
    Refusal.paymentShort => l.refusedPaymentShort(
      f.money(a[0]! as num),
      f.money(a[1]! as num),
    ),
    Refusal.nonCashOverpaid => l.refusedNonCashOverpaid,
    Refusal.notLatestClosing => l.refusedNotLatestClosing,
    Refusal.returnOriginal => l.refusedReturnOriginal,
    Refusal.nothingToReturn => l.refusedNothingToReturn,
    Refusal.returnTooMuch => l.refusedReturnTooMuch(
      a[0]! as int,
      f.number(a[1]! as num),
    ),
    Refusal.returnRate => l.refusedReturnRate(a[0]! as int),
    Refusal.returnEntries => l.refusedReturnEntries(a[0]! as int),
    Refusal.refundNotEqual => l.refusedRefundNotEqual(
      f.money(a[0]! as num),
      f.money(a[1]! as num),
    ),
    Refusal.modeDisabled => l.refusedModeDisabled(d),
    Refusal.cancelSessionClosed => l.refusedCancelSessionClosed,
    Refusal.cancelHasReturns => l.refusedCancelHasReturns,
  };
}

/// A line problem with its row; a fraction in ERPNext's own words (STK-R3).
String lineProblemMessage(AppLocalizations l, int row, LineProblem p) =>
    p == LineProblem.fraction
    ? l.lineFractionAt(row)
    : l.rowProblem(row, lineProblemText(l, p));

/// STK-R3, R6, R14, R23, R33, R38, R42: what is wrong with a document line.
String lineProblemText(AppLocalizations l, LineProblem p) => switch (p) {
  LineProblem.missingItem => l.lineMissingItem,
  LineProblem.qtyNotPositive => l.lineQtyNotPositive,
  LineProblem.sourceRequired => l.lineSourceRequired,
  LineProblem.targetRequired => l.lineTargetRequired,
  LineProblem.sameWarehouse => l.lineSameWarehouse,
  LineProblem.groupWarehouse => l.lineGroupWarehouse,
  LineProblem.fraction => l.lineFraction,
  LineProblem.itemDisabled => l.lineItemDisabled,
  LineProblem.itemEndOfLife => l.lineItemEndOfLife,
  LineProblem.itemTemplate => l.lineItemTemplate,
  LineProblem.itemNotStock => l.lineItemNotStock,
  LineProblem.zeroRate => l.lineZeroRate,
  LineProblem.serialCount => l.lineSerialCount,
  LineProblem.duplicateSerial => l.lineDuplicateSerial,
  LineProblem.entriesQty => l.lineEntriesQty,
  LineProblem.batchOrSerialItem => l.lineBatchOrSerialItem,
  LineProblem.duplicateRow => l.lineDuplicateRow,
  LineProblem.notSalesItem => l.lineNotSalesItem,
  LineProblem.discountAboveMax => l.lineDiscountAboveMax,
  LineProblem.belowValuationRate => l.lineBelowValuationRate,
};

/// Runs [action]. A refusal is shown with [showProblems]; on success the
/// [done] message, if any, is shown in a SnackBar; any other error is shown
/// in the same dialog. True when it succeeded.
Future<bool> attempt(
  BuildContext context,
  Future<void> Function() action, {
  String? done,
}) async {
  final l = AppLocalizations.of(context);
  final formats = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(formatsProvider);
  try {
    await action();
  } on RefusedException catch (e) {
    if (context.mounted) {
      await showProblems(context, [refusalText(l, e, formats)]);
    }
    return false;
  } on RefusedAll catch (e) {
    if (context.mounted) {
      await showProblems(context, [
        for (final x in e.all) refusalText(l, x, formats),
      ]);
    }
    return false;
  } catch (e) {
    // Anything else is shown too, so a failed save never passes silently.
    if (context.mounted) await showProblems(context, [l.unexpectedError('$e')]);
    return false;
  }
  if (done != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }
  return true;
}

/// An AlertDialog asking to confirm [action]; true when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// A form view: the title, Delete and a Save FilledButton in the app bar, and
/// the sections in a scrolling list.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.children,
    this.onSave,
    this.onDelete,
    this.formKey,
    this.actions = const [],
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final GlobalKey<FormState>? formKey;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
            ),
          if (onSave != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilledButton(onPressed: onSave, child: Text(l.save)),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: children,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Form fields in two columns when the pane is 600dp or wider (Medium and
/// up, 00-overview 7.2), in one column otherwise.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final two = constraints.maxWidth >= 600;
      final width = two
          ? (constraints.maxWidth - AppSpacing.md) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// A locked field's reason: a lock icon and one line (01-setup, section 5).
class LockNote extends StatelessWidget {
  const LockNote(this.reason, {super.key});

  final String reason;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      children: [
        Icon(
          Icons.lock_outline,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(reason, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

/// The list view of a master: a search bar, the records, an "Add"
/// FloatingActionButton, and an empty state that offers the same action.
class MasterList<T> extends StatefulWidget {
  const MasterList({
    super.key,
    required this.title,
    required this.rows,
    required this.labelOf,
    required this.onOpen,
    required this.onAdd,
    this.subtitleOf,
    this.isDisabled,
    this.trailingOf,
  });

  final String title;
  final AsyncValue<List<T>> rows;
  final String Function(T) labelOf;
  final String? Function(T)? subtitleOf;
  final bool Function(T)? isDisabled;

  /// A trailing widget, such as a document's status chip.
  final Widget Function(T)? trailingOf;
  final ValueChanged<T> onOpen;
  final VoidCallback onAdd;

  @override
  State<MasterList<T>> createState() => _MasterListState<T>();
}

class _MasterListState<T> extends State<MasterList<T>> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = widget.rows.value ?? [];
    final shown = [
      for (final r in rows)
        if (widget.labelOf(r).toLowerCase().contains(_query.toLowerCase())) r,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAdd,
        tooltip: l.add,
        child: const Icon(Icons.add),
      ),
      body: switch (widget.rows) {
        AsyncError(:final error) => Center(
          child: Text(l.unexpectedError('$error')),
        ),
        AsyncData() when rows.isEmpty => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.emptyList),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonalIcon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add),
                label: Text(l.add),
              ),
            ],
          ),
        ),
        _ => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SearchBar(
                hintText: l.search,
                leading: const Icon(Icons.search),
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final r in shown)
                    ListTile(
                      title: Text(widget.labelOf(r)),
                      subtitle: switch (widget.subtitleOf?.call(r)) {
                        final s? => Text(s),
                        null => null,
                      },
                      trailing: (widget.isDisabled?.call(r) ?? false)
                          ? Chip(label: Text(l.disabled))
                          : widget.trailingOf?.call(r),
                      onTap: () => widget.onOpen(r),
                    ),
                ],
              ),
            ),
          ],
        ),
      },
    );
  }
}

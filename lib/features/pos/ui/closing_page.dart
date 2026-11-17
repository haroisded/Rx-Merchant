import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/data/refusal.dart';
import '../../setup/ui/form_kit.dart';
import '../data/pos_closing_db.dart';
import 'pos_providers.dart';
import 'pos_widgets.dart';

/// "Close the POS" (POS-R20): the session's period and totals, the Payment
/// Reconciliation with the counted Closing Amount per mode, Remarks and
/// Submit, which closes the session and takes a backup.
class ClosingPage extends ConsumerStatefulWidget {
  const ClosingPage({super.key});

  @override
  ConsumerState<ClosingPage> createState() => _ClosingPageState();
}

class _ClosingPageState extends ConsumerState<ClosingPage> {
  late final _draft = ref.read(appDatabaseProvider).closingDraft();
  final _counted = <int, double>{};
  var _remarks = '';

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!await confirm(
          context,
          title: l.submitTitle,
          body: l.submitBody,
          action: l.submit,
        ) ||
        !mounted) {
      return;
    }
    Object? backupError;
    final ok = await attempt(context, () async {
      final r = await ref
          .read(appDatabaseProvider)
          .submitClosing(_counted, remarks: _remarks.isEmpty ? null : _remarks);
      backupError = r.backupError;
    });
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          backupError == null
              ? l.closedWithBackup
              : l.closedBackupFailed('$backupError'),
        ),
      ),
    );
    context.go(posPath);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final error = Theme.of(context).colorScheme.error;
    final compact = WindowSize.of(context) == WindowSize.compact;
    String at(DateTime t) => '${formats.date(t)} ${formats.time(t)}';
    return FutureBuilder(
      future: _draft,
      builder: (context, snap) {
        final d = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.posClosingEntry),
            actions: [
              if (d != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(l.submit),
                  ),
                ),
            ],
          ),
          body: switch (snap) {
            AsyncSnapshot(error: RefusedException e) => Center(
              child: Text(refusalText(l, e, formats)),
            ),
            AsyncSnapshot(:final error?) => Center(
              child: Text(l.unexpectedError('$error')),
            ),
            _ when d == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FieldGrid(
                  children: [
                    TotalRow(
                      l.periodStartDate,
                      at(DateTime.parse(d.session.periodStartDatetime)),
                    ),
                    TotalRow(l.periodEndDate, at(DateTime.now())),
                    TotalRow(l.invoiceCount(d.invoices), ''),
                    TotalRow(l.totalQuantity, formats.number(d.totalQuantity)),
                    TotalRow(l.netTotal, formats.money(d.netTotal)),
                    TotalRow(
                      l.totalTaxesAndCharges,
                      formats.money(d.totalTaxes),
                    ),
                    TotalRow(
                      l.grandTotal,
                      formats.money(d.grandTotal),
                      strong: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.heldOrdersRemain(d.heldOrders)),
                SectionHeading(l.paymentReconciliation),
                for (final r in d.rows)
                  _ModeRow(
                    key: ValueKey(r.modeId),
                    row: r,
                    compact: compact,
                    counted: _counted[r.modeId] ?? 0,
                    onCounted: (v) => setState(() => _counted[r.modeId] = v),
                    errorColor: error,
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  decoration: InputDecoration(labelText: l.remarks),
                  maxLines: 3,
                  onChanged: (t) => _remarks = t,
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

/// One payment mode of the reconciliation: a card on a phone, a row of
/// columns otherwise. Difference = Closing Amount − Expected Amount.
class _ModeRow extends ConsumerWidget {
  const _ModeRow({
    super.key,
    required this.row,
    required this.compact,
    required this.counted,
    required this.onCounted,
    required this.errorColor,
  });

  final ReconciliationRow row;
  final bool compact;
  final double counted;
  final ValueChanged<double> onCounted;
  final Color errorColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final formats = ref.watch(formatsProvider);
    final difference = counted - row.expected;
    final field = LiveNumberField(
      label: l.closingAmount,
      value: counted,
      formats: formats,
      precision: formats.system.currencyPrecision,
      onChanged: onCounted,
    );
    final diff = Text(
      formats.money(difference),
      style: TextStyle(
        color: difference.abs() < 1e-9 ? null : errorColor,
        fontWeight: FontWeight.bold,
      ),
    );
    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TotalRow(row.mode, '', strong: true),
              TotalRow(l.openingAmount, formats.money(row.opening)),
              TotalRow(l.expectedAmount, formats.money(row.expected)),
              const SizedBox(height: AppSpacing.sm),
              field,
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: Text(l.difference)),
                  diff,
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(row.mode)),
          Expanded(
            child: _Labelled(l.openingAmount, formats.money(row.opening)),
          ),
          Expanded(
            child: _Labelled(l.expectedAmount, formats.money(row.expected)),
          ),
          Expanded(flex: 2, child: field),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l.difference,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                diff,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(value),
    ],
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/simple_masters.dart' show modesOfPaymentProvider;
import '../logic/sale.dart';
import '../logic/totals.dart';
import 'pos_providers.dart';
import 'pos_widgets.dart';

/// POS-R15: the Default Mode of Payment of POS Settings, else the first
/// enabled mode of Type Cash (SET-R14).
ModeOfPaymentData? defaultMode(List<ModeOfPaymentData> enabled, String name) =>
    enabled.where((m) => m.name == name).firstOrNull ??
    enabled.where((m) => m.type == 'Cash').firstOrNull ??
    enabled.firstOrNull;

/// The payment panel (POS-R15): one card per enabled Mode of Payment, a
/// number pad for the selected one, Grand Total, Paid Amount, To Be Paid or
/// Change, and Complete Order. [onDone] gets the submitted sale and name.
class PaymentPanel extends ConsumerStatefulWidget {
  const PaymentPanel({super.key, required this.onDone, this.onBack});

  final ValueChanged<Submitted> onDone;
  final VoidCallback? onBack;

  @override
  ConsumerState<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<PaymentPanel> {
  int? _mode;
  var _typed = '';
  var _prefilled = false;

  /// Set Grand Total to Default Payment Method: the default mode starts
  /// with the amount to pay, unless another mode already holds an amount.
  void _prefill(List<ModeOfPaymentData> modes, Sale sale, Totals totals) {
    if (_prefilled || modes.isEmpty) return;
    _prefilled = true;
    final mode = defaultMode(
      modes,
      ref.read(posSettingsProvider).defaultModeOfPayment,
    );
    _mode = mode?.id;
    if (mode == null ||
        !ref.read(posSettingsProvider).setGrandTotalToDefaultMop ||
        sale.payments.entries.any((p) => p.key != mode.id && p.value != 0)) {
      return;
    }
    Future.microtask(
      () => ref.read(cartProvider.notifier).setPayment(mode.id, totals.toPay),
    );
  }

  /// Selecting an empty mode fills it with what is still due.
  void _select(int id, Sale sale, double due) {
    setState(() {
      _mode = id;
      _typed = '';
    });
    if ((sale.payments[id] ?? 0) == 0 && due > 0) {
      ref.read(cartProvider.notifier).setPayment(id, due);
    }
  }

  void _key(String k) {
    final mode = _mode;
    if (mode == null) return;
    _typed = padInput(_typed, k);
    ref
        .read(cartProvider.notifier)
        .setPayment(mode, double.tryParse(_typed) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sale = ref.watch(cartProvider).value;
    final totals = ref.watch(cartTotalsProvider);
    final formats = ref.watch(formatsProvider);
    final modes = [
      for (final m
          in ref.watch(modesOfPaymentProvider).value ??
              const <ModeOfPaymentData>[])
        if (m.enabled == 1) m,
    ];
    if (sale == null || totals == null) {
      return const Center(child: CircularProgressIndicator());
    }
    _prefill(modes, sale, totals);
    final paid = settle(
      totals.toPay,
      [
        for (final m in modes)
          (amount: sale.payments[m.id] ?? 0, cash: m.type == 'Cash'),
      ],
      precision: formats.system.currencyPrecision,
      method: formats.rounding,
    );
    final due = totals.toPay - paid.paid;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            if (widget.onBack != null)
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            Text(l.checkout, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final m in modes)
          Card(
            color: m.id == _mode ? scheme.secondaryContainer : null,
            child: ListTile(
              title: Text(m.name),
              trailing: Text(
                formats.money(sale.payments[m.id] ?? 0),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => _select(m.id, sale, due),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        TotalRow(
          l.grandTotal,
          formats.money(totals.grandTotal),
          strong: !totals.rounded,
        ),
        if (totals.rounded)
          TotalRow(
            l.roundedTotal,
            formats.money(totals.roundedTotal),
            strong: true,
          ),
        TotalRow(l.paidAmount, formats.money(paid.paid)),
        if (paid.change > 0)
          TotalRow(l.changeAmount, formats.money(paid.change), strong: true)
        else
          TotalRow(l.toBePaid, formats.money(due > 0 ? due : 0)),
        if (paid.nonCashOver)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l.refusedNonCashOverpaid,
              style: TextStyle(color: scheme.error),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        NumberPad(onKey: _key, enabled: _mode != null),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: paid.short || paid.nonCashOver
              ? null
              : () async {
                  Submitted? done;
                  final ok = await attempt(context, () async {
                    done = await ref.read(cartProvider.notifier).submit();
                  });
                  if (ok && done != null) widget.onDone(done!);
                },
          child: Text(l.completeOrder),
        ),
      ],
    );
  }
}

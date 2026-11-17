import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/simple_masters.dart' show taxesProvider;
import '../logic/sale.dart';
import '../logic/totals.dart';
import 'pos_providers.dart';
import 'pos_widgets.dart';

/// The cart (section 5, POS screen): its lines, swipe to remove, the
/// totals, Add Discount and Checkout. With [numberPad], the number pad sits
/// under it and edits the [selected] line.
class CartPanel extends ConsumerWidget {
  const CartPanel({
    super.key,
    required this.onOpenLine,
    required this.onCheckout,
    this.selected,
    this.numberPad = false,
  });

  final ValueChanged<SaleLine> onOpenLine;
  final VoidCallback onCheckout;
  final SaleLine? selected;

  /// Show the number pad under the cart (Expanded windows).
  final bool numberPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sale = ref.watch(cartProvider).value;
    final totals = ref.watch(cartTotalsProvider);
    if (sale == null || totals == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final formats = ref.watch(formatsProvider);
    final pos = ref.watch(posSettingsProvider);
    final cart = ref.read(cartProvider.notifier);
    final empty = sale.lines.isEmpty;
    return Column(
      children: [
        Expanded(
          child: empty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(l.cartEmpty, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  children: [
                    for (final (i, line) in sale.lines.indexed)
                      Dismissible(
                        key: ObjectKey(line),
                        direction: DismissDirection.endToStart,
                        background: ColoredBox(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: const Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Icon(Icons.delete_outline),
                            ),
                          ),
                        ),
                        onDismissed: (_) => cart.remove(line),
                        child: ListTile(
                          selected: identical(line, selected),
                          title: Text(line.itemName),
                          subtitle: Text(
                            [
                              '${formats.number(line.qty)} × '
                                  '${formats.money(line.rate)}',
                              if (line.discountPercentage > 0)
                                '${l.discountPercentage} '
                                    '${formats.number(line.discountPercentage, 2)}',
                            ].join('  ·  '),
                          ),
                          trailing: Text(formats.money(totals.lines[i].amount)),
                          onTap: () => onOpenLine(line),
                        ),
                      ),
                  ],
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              ...totalsRows(context, ref, sale, totals),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: empty || !pos.allowDiscountChange
                          ? null
                          : () => _discountDialog(context, ref, sale),
                      child: Text(l.addDiscount),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: empty ? null : onCheckout,
                      child: Text(l.checkout),
                    ),
                  ),
                ],
              ),
              if (numberPad) _LinePad(line: selected),
            ],
          ),
        ),
      ],
    );
  }
}

/// Net Total, each tax row, the discount, Grand Total and Rounded Total.
List<Widget> totalsRows(
  BuildContext context,
  WidgetRef ref,
  Sale sale,
  Totals totals,
) {
  final l = AppLocalizations.of(context);
  final formats = ref.watch(formatsProvider);
  final taxNames = {
    for (final t in ref.watch(taxesProvider).value ?? []) t.id: t.name,
  };
  return [
    TotalRow(l.netTotal, formats.money(totals.netTotal)),
    for (final (k, row) in sale.taxes.indexed)
      TotalRow(
        row.description ?? taxNames[row.taxId] ?? l.tax,
        formats.money(totals.taxes[k].taxAmountAfterDiscount),
      ),
    if (totals.discountAmount != 0)
      TotalRow(l.additionalDiscount, formats.money(-totals.discountAmount)),
    TotalRow(l.grandTotal, formats.money(totals.grandTotal), strong: true),
    if (totals.rounded)
      TotalRow(
        l.roundedTotal,
        formats.money(totals.roundedTotal),
        strong: true,
      ),
  ];
}

/// POS-R13: an additional discount, as a percentage or an amount.
Future<void> _discountDialog(
  BuildContext context,
  WidgetRef ref,
  Sale sale,
) async {
  final l = AppLocalizations.of(context);
  final formats = ref.read(formatsProvider);
  var byPercent = sale.discountAmount == 0;
  var value = byPercent
      ? sale.additionalDiscountPercentage
      : sale.discountAmount;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.additionalDiscount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l.percentage)),
                ButtonSegment(value: false, label: Text(l.amount)),
              ],
              selected: {byPercent},
              onSelectionChanged: (s) => setState(() => byPercent = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            LiveNumberField(
              label: byPercent ? l.percentage : l.amount,
              value: value,
              formats: formats,
              precision: 2,
              onChanged: (v) => value = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  ref
      .read(cartProvider.notifier)
      .setAdditionalDiscount(
        percentage: byPercent ? value : 0,
        amount: byPercent ? 0 : value,
      );
}

enum _PadField { quantity, discount, rate }

/// The number pad under the cart on an Expanded window: Quantity, Discount
/// or Rate of the selected line, and Remove. Fields POS Settings does not
/// allow are off.
class _LinePad extends ConsumerStatefulWidget {
  const _LinePad({required this.line});

  final SaleLine? line;

  @override
  ConsumerState<_LinePad> createState() => _LinePadState();
}

class _LinePadState extends ConsumerState<_LinePad> {
  var _field = _PadField.quantity;
  var _typed = '';

  @override
  void didUpdateWidget(_LinePad old) {
    super.didUpdateWidget(old);
    if (!identical(old.line, widget.line)) _typed = '';
  }

  void _key(String k) {
    final line = widget.line;
    if (line == null) return;
    _typed = padInput(_typed, k);
    final v = double.tryParse(_typed) ?? 0;
    final cart = ref.read(cartProvider.notifier);
    if (_field == _PadField.quantity) return cart.setQty(line, v);
    final ok = _field == _PadField.discount
        ? cart.setPrice(line, percentage: v)
        : cart.setPrice(line, rate: v);
    if (!ok) {
      _typed = '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).lineDiscountAboveMax),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pos = ref.watch(posSettingsProvider);
    final line = widget.line;
    bool allowed(_PadField f) => switch (f) {
      _PadField.quantity => true,
      _PadField.discount => pos.allowDiscountChange,
      _PadField.rate => pos.allowRateChange,
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_PadField>(
                  showSelectedIcon: false,
                  segments: [
                    for (final (f, label) in [
                      (_PadField.quantity, l.quantity),
                      (_PadField.discount, l.discountPercentage),
                      (_PadField.rate, l.rate),
                    ])
                      ButtonSegment(
                        value: f,
                        label: Text(label),
                        enabled: allowed(f),
                      ),
                  ],
                  selected: {_field},
                  onSelectionChanged: (s) => setState(() {
                    _field = s.first;
                    _typed = '';
                  }),
                ),
              ),
              IconButton(
                tooltip: l.remove,
                onPressed: line == null
                    ? null
                    : () => ref.read(cartProvider.notifier).remove(line),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NumberPad(onKey: _key, enabled: line != null),
        ],
      ),
    );
  }
}

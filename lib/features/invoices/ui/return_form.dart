import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/numbers/flt.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/logic/sale.dart';
import '../../pos/logic/totals.dart';
import '../../pos/ui/cart_panel.dart' show totalsRows;
import '../../pos/ui/order_summary.dart';
import '../../pos/ui/payment_panel.dart' show defaultMode;
import '../../pos/ui/pos_providers.dart';
import '../../pos/ui/pos_widgets.dart';
import '../../pos/data/pos_db.dart' show saleSettingsOf;
import '../../setup/data/refusal.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/simple_masters.dart' show modesOfPaymentProvider;
import '../../stock/logic/stock_documents.dart';
import '../../stock/logic/stock_rules.dart';
import '../../stock/ui/stock_providers.dart';
import '../data/returns_db.dart';
import '../logic/returns.dart';

/// The Return / Credit Note form (05-invoices-and-receipts INV-R5 to R9):
/// the sale's lines with what is still returnable, Update Stock and the
/// receiving warehouse, the refund in any enabled mode, Submit; then the
/// return's summary, whose New Order starts an exchange.
class ReturnForm extends ConsumerStatefulWidget {
  const ReturnForm({super.key, required this.saleId});

  final int saleId;

  @override
  ConsumerState<ReturnForm> createState() => _ReturnFormState();
}

class _ReturnFormState extends ConsumerState<ReturnForm> {
  ReturnDraft? _draft;
  Object? _error;

  /// Every returnable line; a line at 0 is left off the return.
  late final List<SaleLine> _lines;

  /// Refund per mode, as typed (positive); null until the owner types one,
  /// so the default mode follows the amount.
  Map<int, double>? _refund;
  String? _name;

  @override
  void initState() {
    super.initState();
    ref
        .read(appDatabaseProvider)
        .returnDraft(widget.saleId)
        .then(
          (d) => setState(() {
            _draft = d;
            _lines = [...d.sale.lines];
          }),
          onError: (Object e) => setState(() => _error = e),
        );
  }

  Sale get _sale => _draft!.sale;

  /// The return as it stands: lines above 0, rescaled (D-62), refunded.
  Totals _apply() {
    final f = ref.read(formatsProvider);
    _sale.lines
      ..clear()
      ..addAll(_lines.where((l) => l.qty != 0));
    scaleReturn(
      _sale,
      _draft!.basis,
      precision: f.system.currencyPrecision,
      method: f.rounding,
    );
    return totalsOf(_sale, saleSettingsOf(f));
  }

  void _setQty(SaleLine line, double qty) => setState(() {
    final floats = ref.read(formatsProvider).system.floatPrecision;
    line.qty = -qty;
    final batches = _draft!.batches[line.againstLineId];
    if (batches != null && batches.isNotEmpty) {
      line.entries = takeBatches(batches, stockQty(qty, line.factor, floats));
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.returnCreditNote)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              error is RefusedException
                  ? refusalText(l, error, ref.watch(formatsProvider))
                  : l.unexpectedError('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (_draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_name case final name?) {
      return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: OrderSummary(
          sale: _sale,
          name: name,
          // INV-R9: the replacement is a new sale, in the same session.
          onNewOrder: () => context.go(posPath),
        ),
      );
    }
    final formats = ref.watch(formatsProvider);
    final totals = _apply();
    final modes = [
      for (final m
          in ref.watch(modesOfPaymentProvider).value ??
              const <ModeOfPaymentData>[])
        if (m.enabled == 1) m,
    ];
    final amount = -totals.toPay;
    final refund =
        _refund ??
        {
          if (defaultMode(
                modes,
                ref.watch(posSettingsProvider).defaultModeOfPayment,
              )
              case final m?)
            m.id: amount,
        };
    _sale.payments
      ..clear()
      ..addAll({
        for (final MapEntry(:key, :value) in refund.entries) key: -value,
      });
    final session = ref.watch(openSessionProvider).value;
    final warehouses = usable(ref.watch(warehousesProvider).value ?? []);
    return Scaffold(
      appBar: AppBar(title: Text(l.returnCreditNote)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (session == null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                title: Text(l.refusedNoOpenSession),
                trailing: TextButton(
                  onPressed: () => context.go(posPath),
                  child: Text(l.openCashRegister),
                ),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.updateStock),
            subtitle: Text(
              _sale.updateStock ? l.updateStockOn : l.updateStockOff,
            ),
            value: _sale.updateStock,
            onChanged: (on) => setState(() {
              _sale.updateStock = on;
              // The rate goes back to the original's (INV-R6).
              if (on) {
                for (final line in _lines) {
                  line.rate = _draft!.rates[line.againstLineId] ?? line.rate;
                }
              }
            }),
          ),
          if (_sale.updateStock)
            DropdownMenu<int>(
              label: Text(l.receivingWarehouse),
              initialSelection: _sale.warehouseId,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) =>
                  v == null ? null : setState(() => _sale.warehouseId = v),
              dropdownMenuEntries: [
                for (final w in warehouses)
                  DropdownMenuEntry(value: w.id, label: w.name),
              ],
            ),
          SectionHeading(l.items),
          if (_lines.isEmpty) Text(l.allReturned),
          for (final line in _lines) _line(l, line),
          const Divider(),
          ...totalsRows(context, ref, _sale, totals),
          TotalRow(l.refundAmount, formats.money(amount), strong: true),
          SectionHeading(l.refundPaidIn),
          for (final m in modes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LiveNumberField(
                key: ValueKey('mode-${m.id}'),
                label: m.name,
                value: refund[m.id] ?? 0,
                formats: formats,
                precision: formats.system.currencyPrecision,
                onChanged: (v) =>
                    setState(() => _refund = {...refund, m.id: v}),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _sale.lines.isEmpty ? null : () => _submit(amount),
            child: Text(l.submit),
          ),
        ],
      ),
    );
  }

  Widget _line(AppLocalizations l, SaleLine line) {
    final formats = ref.watch(formatsProvider);
    final left = _draft!.left[line.againstLineId] ?? 0;
    final qty = -line.qty;
    final serials = _draft!.serials[line.againstLineId] ?? const <String>[];
    final original = _draft!.rates[line.againstLineId] ?? line.rate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.itemName, style: Theme.of(context).textTheme.titleSmall),
            Text(l.returnable(formats.number(left))),
            if (serials.isEmpty)
              Row(
                children: [
                  IconButton(
                    tooltip: l.remove,
                    onPressed: qty <= 0
                        ? null
                        : () => _setQty(line, qty - 1 < 0 ? 0 : qty - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(formats.number(qty)),
                  IconButton(
                    tooltip: l.add,
                    onPressed: qty >= left
                        ? null
                        : () => _setQty(line, qty + 1 > left ? left : qty + 1),
                    icon: const Icon(Icons.add),
                  ),
                  const Spacer(),
                  Text('× ${formats.money(line.rate)}'),
                ],
              )
            else
              // INV-R6: which of the sold serial numbers come back.
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final s in serials)
                    FilterChip(
                      label: Text(s),
                      selected: line.entries.any((e) => e.serialNo == s),
                      onSelected: (on) => setState(() {
                        line.entries = [
                          for (final e in line.entries)
                            if (e.serialNo != s) e,
                          if (on) SbEntry(serialNo: s),
                        ];
                        line.qty = -flt(
                          line.entries.length / line.factor,
                          ref.read(formatsProvider).system.floatPrecision,
                        );
                      }),
                    ),
                ],
              ),
            if (!_sale.updateStock)
              LiveNumberField(
                label: l.rate,
                value: line.rate,
                formats: formats,
                precision: formats.system.currencyPrecision,
                // A price-only credit may only lower the rate.
                check: (v) => v < 0 || v > original
                    ? l.rateAtMost(formats.money(original))
                    : null,
                onChanged: (v) => setState(() => line.rate = v),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(double amount) async {
    final l = AppLocalizations.of(context);
    final formats = ref.read(formatsProvider);
    if (!await confirm(
          context,
          title: l.submitReturnTitle,
          body: l.submitReturnBody(formats.money(amount)),
          action: l.submit,
        ) ||
        !mounted) {
      return;
    }
    String? name;
    final ok = await attempt(context, () async {
      name = await ref.read(appDatabaseProvider).submitReturn(_sale);
    });
    if (ok && mounted) setState(() => _name = name);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/providers.dart';
import '../../../core/widgets/child_table.dart';
import '../../../core/widgets/spacing.dart';
import '../../../core/widgets/window_size.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/ui/form_kit.dart';
import '../logic/sale.dart';
import 'cart_panel.dart';
import 'closing_page.dart';
import 'item_detail.dart';
import 'item_selector.dart';
import 'opening_form.dart';
import 'order_summary.dart';
import 'payment_panel.dart';
import 'pos_providers.dart';
import 'recent_orders.dart';

/// `/pos` and `/pos/closing`.
Widget posPage(String? page) =>
    page == 'closing' ? const ClosingPage() : const PosScreen();

/// What the selector pane shows.
enum _Pane { items, orders, detail, payment }

/// The Cash Register (03-cash-register section 5): the opening dialog until
/// a session is open (POS-R1), then the item selector and the cart. Compact:
/// two steps, the detail a bottom sheet, payment and summary full screen.
/// Medium: selector and cart side by side, detail and payment as side
/// sheets. Expanded: detail and payment replace the selector, the cart
/// stays, with a number pad under it.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  var _pane = _Pane.items;
  SaleLine? _line;

  /// Compact step 2: the cart.
  var _cartOpen = false;

  /// The order summary of the sale just submitted.
  Submitted? _done;

  void _paid(Submitted done) => setState(() {
    _done = done;
    _pane = _Pane.items;
    _cartOpen = false;
    _line = null;
  });

  Future<void> _openLine(SaleLine line) async {
    if (WindowSize.of(context) == WindowSize.expanded) {
      return setState(() {
        _line = line;
        _pane = _Pane.detail;
      });
    }
    setState(() => _line = line);
    // Medium: a side sheet over the selector, so the cart stays in view.
    await showRowEditor<void>(
      context,
      (context) =>
          ItemDetail(line: line, onClose: () => Navigator.pop(context)),
      leading: true,
    );
  }

  Future<void> _checkout() async {
    if (WindowSize.of(context) != WindowSize.medium) {
      return setState(() => _pane = _Pane.payment);
    }
    final done = await showRowEditor<Submitted>(
      context,
      (context) => PaymentPanel(onDone: (d) => Navigator.pop(context, d)),
      leading: true,
    );
    if (done != null) _paid(done);
  }

  /// POS-R18, Action on New Invoice: the cart is replaced by [load] only
  /// once its unsaved changes are saved or discarded.
  Future<void> _replaceCart(Future<void> Function() load) async {
    final l = AppLocalizations.of(context);
    final sale = ref.read(cartProvider).value;
    final cart = ref.read(cartProvider.notifier);
    if (sale != null && sale.dirty && sale.lines.isNotEmpty) {
      final action = switch (ref.read(posSettingsProvider).actionOnNewInvoice) {
        'Save Changes and Load New Invoice' => true,
        'Discard Changes and Load New Invoice' => false,
        _ => await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.unsavedChangesTitle),
            content: Text(l.unsavedChangesBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.discardChanges),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.saveChanges),
              ),
            ],
          ),
        ),
      };
      if (action == null || !mounted) return;
      if (action && !await attempt(context, cart.saveDraft)) return;
    }
    if (mounted) await attempt(context, load);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(openSessionProvider);
    final cart = ref.watch(cartProvider);
    Widget scaffold(Widget body, {List<Widget> actions = const []}) => Scaffold(
      appBar: AppBar(title: Text(l.titleCashRegister), actions: actions),
      body: body,
    );
    if (session.isLoading || cart.isLoading) {
      return scaffold(const Center(child: CircularProgressIndicator()));
    }
    if (cart.error case final e?) {
      return scaffold(Center(child: Text(l.unexpectedError('$e'))));
    }
    if (session.value == null) return scaffold(const OpeningForm());
    final sale = cart.requireValue;
    // A line removed elsewhere leaves the detail pane.
    if (_line != null && !sale.lines.contains(_line)) {
      _line = null;
      if (_pane == _Pane.detail) _pane = _Pane.items;
    }
    final size = WindowSize.of(context);
    final body = switch (size) {
      WindowSize.compact => _compact(),
      WindowSize.medium => _twoPane(340, numberPad: false),
      WindowSize.expanded => _twoPane(400, numberPad: true),
    };
    return PopScope(
      canPop: _pane == _Pane.items && !_cartOpen && _done == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_pane != _Pane.items) {
            _pane = _Pane.items;
          } else if (_cartOpen) {
            _cartOpen = false;
          } else {
            _done = null;
          }
        });
      },
      child: scaffold(body, actions: [_menu(l)]),
    );
  }

  Widget _menu(AppLocalizations l) => MenuAnchor(
    builder: (context, menu, _) => IconButton(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      icon: const Icon(Icons.more_vert),
    ),
    menuChildren: [
      MenuItemButton(
        leadingIcon: const Icon(Icons.receipt_long_outlined),
        onPressed: () => setState(() {
          _pane = _pane == _Pane.orders ? _Pane.items : _Pane.orders;
          _done = null;
          _cartOpen = false;
        }),
        child: Text(l.toggleRecentOrders),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.save_outlined),
        onPressed: () => attempt(
          context,
          ref.read(cartProvider.notifier).saveDraft,
          done: l.draftSaved,
        ),
        child: Text(l.saveAsDraft),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.point_of_sale_outlined),
        onPressed: () => context.go('$posPath/closing'),
        child: Text(l.closeThePos),
      ),
    ],
  );

  void _edit(int id) => _replaceCart(() async {
    await ref.read(cartProvider.notifier).load(id);
    if (mounted) setState(() => _pane = _Pane.items);
  });

  Widget _summary() => OrderSummary(
    sale: _done!.sale,
    name: _done!.name,
    onNewOrder: () => setState(() => _done = null),
  );

  Widget _payment() => PaymentPanel(
    onDone: _paid,
    onBack: () => setState(() => _pane = _Pane.items),
  );

  Widget _compact() {
    if (_done != null) return _summary();
    if (_pane == _Pane.payment) return _payment();
    if (_pane == _Pane.orders) return RecentOrders(onEdit: _edit);
    if (_cartOpen) {
      return CartPanel(onOpenLine: _openLine, onCheckout: _checkout);
    }
    return Column(
      children: [
        const Expanded(child: ItemSelector()),
        _CartBar(onOpen: () => setState(() => _cartOpen = true)),
      ],
    );
  }

  Widget _twoPane(double cartWidth, {required bool numberPad}) {
    final line = _line;
    final left = switch (_pane) {
      _ when _done != null => _summary(),
      _Pane.orders => RecentOrders(onEdit: _edit),
      _Pane.detail when line != null => ItemDetail(
        key: ObjectKey(line),
        line: line,
        onClose: () => setState(() => _pane = _Pane.items),
      ),
      _Pane.payment => _payment(),
      _ => const ItemSelector(),
    };
    return Row(
      children: [
        Expanded(child: left),
        const VerticalDivider(width: 1),
        SizedBox(
          width: cartWidth,
          child: CartPanel(
            onOpenLine: _openLine,
            onCheckout: _checkout,
            selected: _line,
            numberPad: numberPad,
          ),
        ),
      ],
    );
  }
}

/// Compact step 1's bottom bar: the line count and Grand Total; it opens
/// the cart.
class _CartBar extends ConsumerWidget {
  const _CartBar({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sale = ref.watch(cartProvider).value;
    final totals = ref.watch(cartTotalsProvider);
    final formats = ref.watch(formatsProvider);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: const Icon(Icons.shopping_cart_outlined),
          title: Text(l.cartLines(sale?.lines.length ?? 0)),
          subtitle: Text(
            '${l.grandTotal}: ${formats.money(totals?.grandTotal ?? 0)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpen,
        ),
      ),
    );
  }
}

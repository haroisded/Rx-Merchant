import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../setup/data/setup_queries.dart';
import '../../setup/ui/form_kit.dart';
import '../../setup/ui/simple_masters.dart';
import '../../setup/ui/tax_template_pages.dart' show itemTaxTemplatesProvider;
import '../data/stock_masters.dart';
import 'stock_masters_pages.dart' show deleteAndLeave;
import 'stock_providers.dart';

// Warehouse and Item Group: trees (STK-R1, R2), shown as nested
// ExpansionTiles with Add Child on each group, or as a flat list.

typedef TreeNode = ({
  int id,
  String name,
  int? parentId,
  bool isGroup,
  bool disabled,
});

class TreeList extends StatefulWidget {
  const TreeList({
    super.key,
    required this.title,
    required this.nodes,
    required this.path,
  });

  final String title;
  final AsyncValue<List<TreeNode>> nodes;

  /// The master's route: a node opens at `path/id`, Add Child at
  /// `path/new?parent=id`.
  final String path;

  @override
  State<TreeList> createState() => _TreeListState();
}

class _TreeListState extends State<TreeList> {
  var _flat = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nodes = widget.nodes.value ?? const [];
    void open(TreeNode n) => context.go('${widget.path}/${n.id}');
    Widget? disabled(TreeNode n) =>
        n.disabled ? Chip(label: Text(l.disabled)) : null;

    Widget node(TreeNode n) {
      final children = [
        for (final c in nodes)
          if (c.parentId == n.id) node(c),
      ];
      if (!n.isGroup) {
        return ListTile(
          title: Text(n.name),
          trailing: disabled(n),
          onTap: () => open(n),
        );
      }
      return ExpansionTile(
        title: Text(n.name),
        leading: const Icon(Icons.folder_outlined),
        initiallyExpanded: n.parentId == null,
        childrenPadding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l.addChild,
              icon: const Icon(Icons.add),
              onPressed: () => context.go('${widget.path}/new?parent=${n.id}'),
            ),
            IconButton(
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => open(n),
            ),
          ],
        ),
        children: children,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: _flat ? l.treeView : l.listView,
            icon: Icon(_flat ? Icons.account_tree_outlined : Icons.list),
            onPressed: () => setState(() => _flat = !_flat),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${widget.path}/new'),
        tooltip: l.add,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: _flat
            ? [
                for (final n in [
                  ...nodes,
                ]..sort((a, b) => a.name.compareTo(b.name)))
                  ListTile(
                    title: Text(n.name),
                    subtitle: n.isGroup ? Text(l.isGroup) : null,
                    trailing: disabled(n),
                    onTap: () => open(n),
                  ),
              ]
            : [
                for (final n in nodes)
                  if (n.parentId == null) node(n),
              ],
      ),
    );
  }
}

/// A parent picker: the group nodes other than [self] and its subtree.
DropdownMenu<int?> parentMenu(
  AppLocalizations l,
  String label,
  List<TreeNode> nodes,
  int? self,
  int? value,
  ValueChanged<int?> onSelected,
) {
  bool under(TreeNode n) {
    for (
      int? p = n.id;
      p != null;
      p = nodes.firstWhere((x) => x.id == p).parentId
    ) {
      if (p == self) return true;
    }
    return false;
  }

  return DropdownMenu<int?>(
    label: Text(label),
    initialSelection: value,
    expandedInsets: EdgeInsets.zero,
    onSelected: onSelected,
    dropdownMenuEntries: [
      DropdownMenuEntry(value: null, label: l.none),
      for (final n in nodes)
        if (n.isGroup && !under(n))
          DropdownMenuEntry(value: n.id, label: n.name),
    ],
  );
}

// ---- Warehouse (STK-R1) ------------------------------------------------------

TreeNode _warehouseNode(WarehouseData w) => (
  id: w.id,
  name: w.name,
  parentId: w.parentId,
  isGroup: w.isGroup == 1,
  disabled: w.disabled == 1,
);

class WarehousePage extends ConsumerWidget {
  const WarehousePage({
    super.key,
    required this.path,
    this.id,
    this.query = const {},
  });

  final String path;
  final String? id;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(warehousesProvider);
    final id = this.id;
    if (id == null) {
      return TreeList(
        title: l.warehouse,
        path: path,
        nodes: rows.whenData((r) => r.map(_warehouseNode).toList()),
      );
    }
    if (!rows.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _WarehouseForm(
      key: ValueKey(id),
      path: path,
      all: rows.value!,
      warehouse: recordFor(rows.value!, id, (w) => w.id),
      parentId: int.tryParse(query['parent'] ?? ''),
    );
  }
}

class _WarehouseForm extends ConsumerStatefulWidget {
  const _WarehouseForm({
    super.key,
    required this.path,
    required this.all,
    this.warehouse,
    this.parentId,
  });

  final String path;
  final List<WarehouseData> all;
  final WarehouseData? warehouse;
  final int? parentId;

  @override
  ConsumerState<_WarehouseForm> createState() => _WarehouseFormState();
}

class _WarehouseFormState extends ConsumerState<_WarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.warehouse?.name);
  late final _type = TextEditingController(
    text: widget.warehouse?.warehouseType,
  );
  late int? _parent = widget.warehouse?.parentId ?? widget.parentId;
  late var _isGroup = widget.warehouse?.isGroup == 1;
  late var _disabled = widget.warehouse?.disabled == 1;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = widget.warehouse;
    final db = ref.read(appDatabaseProvider);
    return FormPage(
      title: w?.name ?? l.newRecord(l.warehouse),
      formKey: _formKey,
      actions: [
        if (w != null)
          IconButton(
            tooltip: l.reportStockBalance,
            icon: const Icon(Icons.inventory_outlined),
            onPressed: () =>
                context.go('/stock/stock-balance?warehouse=${w.id}'),
          ),
      ],
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return showProblems(context, [l.formHasErrors]);
        }
        final ok = await attempt(
          context,
          () => db.saveWarehouse(
            WarehouseCompanion(
              id: w == null ? const Value.absent() : Value(w.id),
              name: Value(_name.text.trim()),
              parentId: Value(_parent),
              isGroup: Value(_isGroup ? 1 : 0),
              warehouseType: Value(
                _type.text.trim().isEmpty ? null : _type.text.trim(),
              ),
              disabled: Value(_disabled ? 1 : 0),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
      },
      onDelete: w == null
          ? null
          : () => deleteAndLeave(
              context,
              w.name,
              widget.path,
              () => db.deleteWarehouse(w.id),
            ),
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.warehouseName} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            parentMenu(
              l,
              l.parentWarehouse,
              widget.all.map(_warehouseNode).toList(),
              w?.id,
              _parent,
              (v) => setState(() => _parent = v),
            ),
            TextFormField(
              controller: _type,
              decoration: InputDecoration(labelText: l.warehouseType),
            ),
            // STK-R1: a group holds no stock and is never chosen on a
            // transaction.
            SwitchListTile(
              title: Text(l.isGroup),
              value: _isGroup,
              onChanged: (on) => setState(() => _isGroup = on),
            ),
            SwitchListTile(
              title: Text(l.disabled),
              value: _disabled,
              onChanged: (on) => setState(() => _disabled = on),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Item Group (STK-R2) -----------------------------------------------------

TreeNode _groupNode(ItemGroupData g) => (
  id: g.id,
  name: g.name,
  parentId: g.parentId,
  isGroup: g.isGroup == 1,
  disabled: false,
);

class ItemGroupPage extends ConsumerWidget {
  const ItemGroupPage({
    super.key,
    required this.path,
    this.id,
    this.query = const {},
  });

  final String path;
  final String? id;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(itemGroupsProvider);
    final id = this.id;
    if (id == null) {
      return TreeList(
        title: l.itemGroup,
        path: path,
        nodes: rows.whenData((r) => r.map(_groupNode).toList()),
      );
    }
    if (!rows.hasValue || !ref.watch(itemTaxTemplatesProvider).hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ItemGroupForm(
      key: ValueKey(id),
      path: path,
      all: rows.value!,
      group: recordFor(rows.value!, id, (g) => g.id),
      parentId: int.tryParse(query['parent'] ?? ''),
    );
  }
}

class _ItemGroupForm extends ConsumerStatefulWidget {
  const _ItemGroupForm({
    super.key,
    required this.path,
    required this.all,
    this.group,
    this.parentId,
  });

  final String path;
  final List<ItemGroupData> all;
  final ItemGroupData? group;
  final int? parentId;

  @override
  ConsumerState<_ItemGroupForm> createState() => _ItemGroupFormState();
}

class _ItemGroupFormState extends ConsumerState<_ItemGroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.group?.name);
  late int? _parent = widget.group?.parentId ?? widget.parentId;
  late var _isGroup = widget.group?.isGroup == 1;
  late int? _template = widget.group?.itemTaxTemplateId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final g = widget.group;
    final db = ref.read(appDatabaseProvider);
    final templates = ref.watch(itemTaxTemplatesProvider).value ?? [];
    return FormPage(
      title: g?.name ?? l.newRecord(l.itemGroup),
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return showProblems(context, [l.formHasErrors]);
        }
        final ok = await attempt(
          context,
          () => db.saveItemGroup(
            ItemGroupCompanion(
              id: g == null ? const Value.absent() : Value(g.id),
              name: Value(_name.text.trim()),
              parentId: Value(_parent),
              isGroup: Value(_isGroup ? 1 : 0),
              itemTaxTemplateId: Value(_template),
            ),
          ),
          done: l.saved,
        );
        if (ok && context.mounted) context.go(widget.path);
      },
      onDelete: g == null
          ? null
          : () => deleteAndLeave(
              context,
              g.name,
              widget.path,
              () => db.deleteMaster(db.itemGroup, g.id),
            ),
      children: [
        FieldGrid(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: '${l.itemGroupName} *'),
              validator: (v) => v!.trim().isEmpty ? l.mandatoryField : null,
            ),
            parentMenu(
              l,
              l.parentItemGroup,
              widget.all.map(_groupNode).toList(),
              g?.id,
              _parent,
              (v) => setState(() => _parent = v),
            ),
            SwitchListTile(
              title: Text(l.isGroup),
              value: _isGroup,
              onChanged: (on) => setState(() => _isGroup = on),
            ),
            // STK-R13: the items' tax unless an item names its own.
            DropdownMenu<int?>(
              label: Text(l.itemTaxTemplate),
              initialSelection: _template,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) => setState(() => _template = v),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: null, label: l.none),
                for (final t in templates)
                  if (t.disabled == 0 || t.id == _template)
                    DropdownMenuEntry(value: t.id, label: t.title),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

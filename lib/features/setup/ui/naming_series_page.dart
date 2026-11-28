import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/naming/naming_series.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../data/seed.dart';
import '../data/setup_queries.dart';
import 'form_kit.dart';

// Naming Series (SET-R6, R7): the patterns of each document, and "Update
// Series" to move a counter.

final _optionsProvider =
    StreamProvider.autoDispose<List<NamingSeriesOptionData>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return (db.select(db.namingSeriesOption)..orderBy([
            (o) => OrderingTerm(expression: o.doctype),
            (o) => OrderingTerm(expression: o.idx),
          ]))
          .watch();
    });

final _seriesProvider = StreamProvider.autoDispose<List<SeriesRow>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.series).watch();
});

class NamingSeriesPage extends ConsumerStatefulWidget {
  const NamingSeriesPage({super.key});

  @override
  ConsumerState<NamingSeriesPage> createState() => _NamingSeriesPageState();
}

class _NamingSeriesPageState extends ConsumerState<NamingSeriesPage> {
  var _doctype = defaultNamingSeries.keys.first;

  /// The edited patterns of [_doctype]; null until edited.
  List<String>? _patterns;
  final _newPattern = TextEditingController();
  String? _prefix;
  final _newCurrent = TextEditingController();

  @override
  void dispose() {
    _newPattern.dispose();
    _newCurrent.dispose();
    super.dispose();
  }

  Future<bool> _save(List<String> patterns) async {
    final l = AppLocalizations.of(context);
    if (patterns.isEmpty) {
      await showProblems(context, [l.namingSeriesNeedsOne]);
      return false;
    }
    final ok = await attempt(
      context,
      () => ref.read(appDatabaseProvider).saveNamingSeries(_doctype, patterns),
      done: l.saved,
    );
    if (ok) setState(() => _patterns = null);
    return ok;
  }

  Future<void> _updateSeries() async {
    final l = AppLocalizations.of(context);
    final prefix = _prefix;
    final value = int.tryParse(_newCurrent.text.trim());
    if (prefix == null || value == null || value < 0) {
      return showProblems(context, [l.notAWholeNumber]);
    }
    await attempt(
      context,
      () => ref.read(appDatabaseProvider).updateSeries(prefix, value),
      done: l.saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = ref.watch(_optionsProvider).value ?? [];
    final series = ref.watch(_seriesProvider).value ?? [];
    final doctypes = {
      ...defaultNamingSeries.keys,
      for (final o in options) o.doctype,
    };
    final patterns =
        _patterns ??
        [
          for (final o in options)
            if (o.doctype == _doctype) o.pattern,
        ];
    final today = DateTime.now();
    // Every prefix in use, and the one each pattern gives today.
    final prefixes = {
      for (final s in series) s.name ?? '',
      for (final o in options) parseSeries(o.pattern, today).key,
    }.where((p) => p.isNotEmpty).toList()..sort();
    final current =
        series.where((s) => s.name == _prefix).firstOrNull?.current ?? 0;
    final edited = _patterns != null;

    return FormPage(
      title: l.namingSeries,
      onSave: edited ? () => _save(patterns) : null,
      children: [
        DropdownMenu<String>(
          label: Text(l.documentType),
          initialSelection: _doctype,
          expandedInsets: EdgeInsets.zero,
          onSelected: (d) => setState(() {
            _doctype = d!;
            _patterns = null;
          }),
          dropdownMenuEntries: [
            for (final d in doctypes) DropdownMenuEntry(value: d, label: d),
          ],
        ),
        SectionHeading(l.seriesList),
        Text(l.namingSeriesHelp, style: Theme.of(context).textTheme.bodySmall),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (from, to) => setState(() {
            final list = [...patterns];
            list.insert(to, list.removeAt(from));
            _patterns = list;
          }),
          children: [
            for (final (i, p) in patterns.indexed)
              ListTile(
                key: ValueKey(p),
                title: Text(p),
                subtitle: i == 0 ? Text(l.isDefault) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l.delete,
                  onPressed: () =>
                      setState(() => _patterns = [...patterns]..removeAt(i)),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newPattern,
                decoration: InputDecoration(
                  labelText: l.newPattern,
                  hintText: 'INV-.YYYY.-',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              tooltip: l.add,
              onPressed: () {
                final p = _newPattern.text.trim();
                if (p.isEmpty || patterns.contains(p)) return;
                // No Fiscal Year: series use the calendar year (01-setup, 2).
                if (p.contains('.FY.')) {
                  showProblems(context, [l.namingSeriesNoFiscalYear]);
                  return;
                }
                setState(() => _patterns = [...patterns, p]);
                _newPattern.clear();
              },
            ),
          ],
        ),
        if (patterns.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l.nextNameExample(_example(patterns.first, today, series)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SectionHeading(l.updateSeries),
        FieldGrid(
          children: [
            DropdownMenu<String>(
              label: Text(l.prefix),
              initialSelection: _prefix,
              expandedInsets: EdgeInsets.zero,
              onSelected: (p) => setState(() => _prefix = p),
              dropdownMenuEntries: [
                for (final p in prefixes) DropdownMenuEntry(value: p, label: p),
              ],
            ),
            InputDecorator(
              decoration: InputDecoration(labelText: l.currentValue),
              child: Text(_prefix == null ? '' : '$current'),
            ),
            TextField(
              controller: _newCurrent,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.newCurrentValue),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                onPressed: _prefix == null ? null : _updateSeries,
                child: Text(l.updateSeries),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The name the next document would take under [pattern] today.
String _example(String pattern, DateTime today, List<SeriesRow> series) {
  final (:key, :digits, :suffix) = parseSeries(pattern, today);
  final current = series.where((s) => s.name == key).firstOrNull?.current ?? 0;
  return '$key${'${current + 1}'.padLeft(digits, '0')}$suffix';
}

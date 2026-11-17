import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'window_size.dart';

// Material 3 modal side sheet: at most 400dp wide, large corner on its
// leading edge.
const double _sideSheetWidth = 400;
const double _sideSheetRadius = 16;

/// Opens a row editor the way ERPNext's pencil icon does (00-overview,
/// section 7.1, "Child table"): a bottom sheet on a compact window, a side
/// sheet on the trailing edge otherwise, or on the [leading] edge when what
/// stays visible is on the trailing side (the Cash Register's cart).
/// Completes with the value the editor pops, or null when dismissed.
Future<R?> showRowEditor<R>(
  BuildContext context,
  WidgetBuilder builder, {
  bool leading = false,
}) {
  if (WindowSize.of(context) == WindowSize.compact) {
    return showModalBottomSheet<R>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // Keeps the editor's fields above the on-screen keyboard.
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: builder(context),
      ),
    );
  }
  // Flutter's Material library has no side sheet widget.
  return showGeneralDialog<R>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (context, _, _) => Align(
      alignment: leading
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: leading
              ? const BorderRadiusDirectional.horizontal(
                  end: Radius.circular(_sideSheetRadius),
                )
              : const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(_sideSheetRadius),
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: SizedBox(
            width: _sideSheetWidth,
            height: double.infinity,
            child: builder(context),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(
        begin: Offset(leading ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      textDirection: Directionality.of(context),
      child: child,
    ),
  );
}

/// The rows that belong to one parent record, shown inside its form.
///
/// Tapping a row opens it in [showRowEditor]; "Add Row" opens the editor with
/// no row. The editor saves through the form's own callbacks and pops itself.
/// [readOnly] is for a submitted or cancelled document: rows still open (the
/// editor shows them read-only) but none can be added.
class ChildTable<T> extends StatelessWidget {
  const ChildTable({
    super.key,
    required this.rows,
    required this.rowBuilder,
    required this.editorBuilder,
    this.readOnly = false,
  });

  final List<T> rows;
  final Widget Function(BuildContext context, T row) rowBuilder;

  /// Builds the row editor. `row` is null for a new row.
  final Widget Function(BuildContext context, T? row) editorBuilder;
  final bool readOnly;

  void _edit(BuildContext context, T? row) =>
      showRowEditor<void>(context, (context) => editorBuilder(context, row));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          InkWell(
            onTap: () => _edit(context, row),
            child: rowBuilder(context, row),
          ),
        if (!readOnly)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _edit(context, null),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).addRow),
            ),
          ),
      ],
    );
  }
}

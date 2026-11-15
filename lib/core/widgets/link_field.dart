import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// ERPNext's Link field: picks one master record (00-overview, section 7.1).
///
/// Tapping it opens a search view listing what [search] returns for the typed
/// text, followed by a "Create new" entry when [onCreateNew] is given.
/// A [mandatory] field ends its label with `*` and cannot be cleared; pass
/// the validation message as [errorText] to show it under the field.
class LinkField<T extends Object> extends StatelessWidget {
  const LinkField({
    super.key,
    required this.label,
    this.value,
    required this.search,
    required this.labelOf,
    required this.onChanged,
    this.onCreateNew,
    this.mandatory = false,
    this.errorText,
  });

  final String label;
  final T? value;

  /// Returns the records matching the typed text; all of them for ''.
  final Future<Iterable<T>> Function(String query) search;

  /// The text shown for a record.
  final String Function(T) labelOf;

  /// Called with the picked record, or null when the field is cleared.
  final ValueChanged<T?> onChanged;
  final VoidCallback? onCreateNew;
  final bool mandatory;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final onCreateNew = this.onCreateNew;
    final canClear = value != null && !mandatory;

    return SearchAnchor(
      viewHintText: label,
      builder: (context, controller) => InkWell(
        onTap: controller.openView,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: mandatory ? '$label *' : label,
            errorText: errorText,
            suffixIcon: canClear
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: MaterialLocalizations.of(context)
                        .clearButtonTooltip,
                    onPressed: () => onChanged(null),
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
          child: value == null ? null : Text(labelOf(value)),
        ),
      ),
      suggestionsBuilder: (context, controller) async {
        // Closes the view and empties the query so the next opening lists
        // everything again.
        void close() {
          controller.closeView(null);
          controller.clear();
        }

        final matches = await search(controller.text);
        if (!context.mounted) return const [];
        return [
          for (final match in matches)
            ListTile(
              title: Text(labelOf(match)),
              onTap: () {
                close();
                onChanged(match);
              },
            ),
          if (onCreateNew != null)
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(AppLocalizations.of(context).createNew),
              onTap: () {
                close();
                onCreateNew();
              },
            ),
        ];
      },
    );
  }
}

import 'package:material_ui/material_ui.dart';

import 'window_size.dart';

const double _listWidth = 360;

/// List view and form view of one record type (00-overview, section 7.2).
///
/// On an expanded window the [list] sits on the left and the [detail] on the
/// right. On smaller windows there is one pane: the [detail] when a record is
/// open, otherwise the [list]. Pass `detail: null` when nothing is selected;
/// the route decides, so Back returns from the detail to the list.
class ListDetailPane extends StatelessWidget {
  const ListDetailPane({super.key, required this.list, this.detail});

  final Widget list;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    if (WindowSize.of(context) != WindowSize.expanded) return detail ?? list;
    return Row(
      children: [
        SizedBox(width: _listWidth, child: list),
        const VerticalDivider(width: 1),
        Expanded(child: detail ?? const SizedBox.shrink()),
      ],
    );
  }
}

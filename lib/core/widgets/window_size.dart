import 'package:material_ui/material_ui.dart';

/// The Material 3 window size classes every layout switches on
/// (00-overview, section 7.2).
enum WindowSize {
  /// Under 600dp: bottom NavigationBar, one pane.
  compact,

  /// 600 to 839dp: NavigationRail, one wide pane.
  medium,

  /// 840dp and up: NavigationRail with labels, two panes.
  expanded;

  /// Read from the app window, never from the device type or orientation.
  static WindowSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return compact;
    if (width < 840) return medium;
    return expanded;
  }
}

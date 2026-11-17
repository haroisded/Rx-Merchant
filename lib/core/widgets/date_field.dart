import 'package:material_ui/material_ui.dart';

import '../numbers/format.dart';
import '../numbers/formats.dart';

/// A date picked with `showDatePicker`, stored as `YYYY-MM-DD` and shown in
/// the Date Format. With [withTime] it also asks for the time and stores
/// `YYYY-MM-DD HH:MM:SS` (00-overview 6.4). An optional field can be cleared.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.formats,
    required this.onChanged,
    this.withTime = false,
    this.mandatory = false,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final Formats formats;
  final ValueChanged<String?> onChanged;
  final bool withTime;
  final bool mandatory;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final current = value == null ? DateTime.now() : DateTime.parse(value!);
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (day == null || !context.mounted) return;
    if (!withTime) return onChanged(toStorage(day).substring(0, 10));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    onChanged(
      toStorage(DateTime(day.year, day.month, day.day, time.hour, time.minute)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    final shown = v == null
        ? null
        : withTime
        ? '${formats.date(DateTime.parse(v))} ${formats.time(DateTime.parse(v))}'
        : formats.date(DateTime.parse(v));
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      child: InputDecorator(
        isEmpty: v == null,
        decoration: InputDecoration(
          labelText: mandatory ? '$label *' : label,
          enabled: enabled,
          suffixIcon: v != null && !mandatory && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: shown == null ? null : Text(shown),
      ),
    );
  }
}

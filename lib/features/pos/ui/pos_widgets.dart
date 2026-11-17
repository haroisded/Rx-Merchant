import 'package:material_ui/material_ui.dart';

import '../../../core/numbers/formats.dart';
import '../../../core/widgets/spacing.dart';
import '../../../l10n/app_localizations.dart';

// Small pieces the Cash Register screens share.

/// A number field that shows [value] and reports each valid edit. While it
/// has focus it keeps what is being typed; otherwise it follows [value], so
/// a change made elsewhere (another field, the number pad) shows here. Text
/// that is not a number, or a number [check] refuses, shows its error under
/// the field and is not reported.
class LiveNumberField extends StatefulWidget {
  const LiveNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.formats,
    required this.onChanged,
    this.precision,
    this.enabled = true,
    this.check,
  });

  final String label;
  final double value;
  final Formats formats;
  final ValueChanged<double> onChanged;
  final int? precision;
  final bool enabled;

  /// The error for a typed value, or null when it is accepted.
  final String? Function(double)? check;

  @override
  State<LiveNumberField> createState() => _LiveNumberFieldState();
}

class _LiveNumberFieldState extends State<LiveNumberField> {
  late final _text = TextEditingController(text: _shown);
  final _focus = FocusNode();
  String? _error;

  String get _shown => widget.formats.number(widget.value, widget.precision);

  @override
  void initState() {
    super.initState();
    // Focus can leave as the field is being disposed (a sheet closing).
    _focus.addListener(() {
      if (mounted && !_focus.hasFocus) {
        _text.text = _shown;
        setState(() => _error = null);
      }
    });
  }

  @override
  void didUpdateWidget(LiveNumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != old.value) _text.text = _shown;
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    focusNode: _focus,
    enabled: widget.enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: widget.label, errorText: _error),
    onChanged: (t) {
      final v = widget.formats.parse(t);
      final error = v == null
          ? AppLocalizations.of(context).notANumber
          : widget.check?.call(v);
      setState(() => _error = error);
      if (v != null && error == null) widget.onChanged(v);
    },
  );
}

/// One label and amount of a totals block.
class TotalRow extends StatelessWidget {
  const TotalRow(this.label, this.value, {super.key, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// The number pad of ERPNext's POS: digits, a decimal point and backspace.
/// [onKey] gets '0'-'9', '.' or '⌫'.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onKey, this.enabled = true});

  final ValueChanged<String> onKey;
  final bool enabled;

  static final _keys = '123456789.0⌫'.split('');

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    // Keys stay above 48dp high in a 360dp-wide pane or sheet.
    childAspectRatio: 2,
    mainAxisSpacing: AppSpacing.xs,
    crossAxisSpacing: AppSpacing.xs,
    children: [
      for (final k in _keys)
        FilledButton.tonal(
          onPressed: enabled ? () => onKey(k) : null,
          child: k == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  semanticLabel: AppLocalizations.of(context).remove,
                )
              : Text(k),
        ),
    ],
  );
}

/// [typed] after pad key [key].
String padInput(String typed, String key) => switch (key) {
  '⌫' => typed.isEmpty ? typed : typed.substring(0, typed.length - 1),
  '.' when typed.contains('.') => typed,
  '.' when typed.isEmpty => '0.',
  _ => typed + key,
};

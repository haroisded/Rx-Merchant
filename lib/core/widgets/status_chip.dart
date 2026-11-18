import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// The status indicator of a document (00-overview, section 7.1).
///
/// [status] is the value stored in the database, which is ERPNext's English
/// name; the chip shows its translation. A status outside the table in 7.1
/// (a POS session's "Open", "Closed") shows as is, in the neutral colour.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final neutral = (scheme.surfaceContainerHighest, scheme.onSurface);
    final positive = (scheme.primaryContainer, scheme.onPrimaryContainer);

    final (background, foreground) = switch (status) {
      'Draft' => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      'Submitted' || 'Paid' => positive,
      'Cancelled' => (scheme.errorContainer, scheme.onErrorContainer),
      _ => neutral,
    };

    return Chip(
      label: Text(statusLabel(l10n, status)),
      labelStyle: theme.textTheme.labelLarge?.copyWith(color: foreground),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// The translated name of a document status; one outside the table shows
/// as stored.
String statusLabel(AppLocalizations l, String status) => switch (status) {
  'Draft' => l.statusDraft,
  'Submitted' => l.statusSubmitted,
  'Paid' => l.statusPaid,
  'Return' => l.statusReturn,
  'Credit Note Issued' => l.statusCreditNoteIssued,
  'Cancelled' => l.statusCancelled,
  _ => status,
};

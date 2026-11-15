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

    final (label, (background, foreground)) = switch (status) {
      'Draft' => (
        l10n.statusDraft,
        (scheme.secondaryContainer, scheme.onSecondaryContainer),
      ),
      'Submitted' => (l10n.statusSubmitted, positive),
      'Paid' => (l10n.statusPaid, positive),
      'Return' => (l10n.statusReturn, neutral),
      'Credit Note Issued' => (l10n.statusCreditNoteIssued, neutral),
      'Cancelled' => (
        l10n.statusCancelled,
        (scheme.errorContainer, scheme.onErrorContainer),
      ),
      _ => (status, neutral),
    };

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelLarge?.copyWith(color: foreground),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

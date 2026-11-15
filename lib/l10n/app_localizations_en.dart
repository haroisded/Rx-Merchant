// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rx Merchant';

  @override
  String get navCashRegister => 'Register';

  @override
  String get titleCashRegister => 'Cash Register';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navStock => 'Stock';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSetup => 'Setup';

  @override
  String get comingSoon => 'This screen arrives in a later milestone.';

  @override
  String get wizardTitle => 'Welcome';

  @override
  String get wizardPlaceholder =>
      'The first-run wizard arrives in milestone M1. Until then, finish setup here to reach the app.';

  @override
  String get wizardFinish => 'Finish setup';

  @override
  String get startupError => 'The database could not be opened.';

  @override
  String get createNew => 'Create new';

  @override
  String get addRow => 'Add Row';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusReturn => 'Return';

  @override
  String get statusCreditNoteIssued => 'Credit Note Issued';

  @override
  String get statusCancelled => 'Cancelled';
}

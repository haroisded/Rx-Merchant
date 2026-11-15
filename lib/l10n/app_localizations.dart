import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Name of the app in the task switcher
  ///
  /// In en, this message translates to:
  /// **'Rx Merchant'**
  String get appTitle;

  /// Navigation destination 1: the POS screen. Kept short: a longer label wraps on a 360dp-wide bar
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get navCashRegister;

  /// Title of the POS screen
  ///
  /// In en, this message translates to:
  /// **'Cash Register'**
  String get titleCashRegister;

  /// Navigation destination 2: the Sales Invoice list
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// Navigation destination 3: items, stock transactions, stock reports
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// Navigation destination 4: Sales Dashboard and sales reports
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Navigation destination 5: every settings page
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get navSetup;

  /// Body of a destination that has not been built yet
  ///
  /// In en, this message translates to:
  /// **'This screen arrives in a later milestone.'**
  String get comingSoon;

  /// Title of the first-run wizard
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get wizardTitle;

  /// Body of the wizard placeholder; removed with milestone M1
  ///
  /// In en, this message translates to:
  /// **'The first-run wizard arrives in milestone M1. Until then, finish setup here to reach the app.'**
  String get wizardPlaceholder;

  /// Button that marks setup as complete
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get wizardFinish;

  /// Shown when settings cannot be read at startup
  ///
  /// In en, this message translates to:
  /// **'The database could not be opened.'**
  String get startupError;

  /// Last entry of a link field's list: create a new master record
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// Button under a child table
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get addRow;

  /// Tooltip of a report's export action
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// Document status: docstatus 0
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// Document status: docstatus 1
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// Sales Invoice status
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// Sales Invoice status: the invoice is a return
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get statusReturn;

  /// Sales Invoice status: a return exists against it
  ///
  /// In en, this message translates to:
  /// **'Credit Note Issued'**
  String get statusCreditNoteIssued;

  /// Document status: docstatus 2
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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

  /// The name of this file's language, in that language. Shown in the language lists
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyList;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @isDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get isDefault;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @problemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot save'**
  String get problemsTitle;

  /// No description provided for @formHasErrors.
  ///
  /// In en, this message translates to:
  /// **'Some fields need attention. Check the messages under them.'**
  String get formHasErrors;

  /// No description provided for @mandatoryField.
  ///
  /// In en, this message translates to:
  /// **'This field is mandatory.'**
  String get mandatoryField;

  /// No description provided for @notANumber.
  ///
  /// In en, this message translates to:
  /// **'Not a number.'**
  String get notANumber;

  /// No description provided for @notAWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get notAWholeNumber;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String deleteBody(String name);

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New {doctype}'**
  String newRecord(String doctype);

  /// No description provided for @fieldMissing.
  ///
  /// In en, this message translates to:
  /// **'{field} is mandatory.'**
  String fieldMissing(String field);

  /// No description provided for @rowProblem.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {problem}'**
  String rowProblem(int row, String problem);

  /// No description provided for @rowNumber.
  ///
  /// In en, this message translates to:
  /// **'Row {number}'**
  String rowNumber(int number);

  /// No description provided for @lockedAfterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Locked: documents have been submitted in this currency.'**
  String get lockedAfterSubmit;

  /// No description provided for @laterMilestone.
  ///
  /// In en, this message translates to:
  /// **'Arrives with a later milestone.'**
  String get laterMilestone;

  /// No description provided for @refusedDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'A record with this name already exists.'**
  String get refusedDuplicateName;

  /// No description provided for @refusedReferenced.
  ///
  /// In en, this message translates to:
  /// **'This record is used elsewhere. Disable it instead of deleting it.'**
  String get refusedReferenced;

  /// No description provided for @refusedLastEnabledPriceList.
  ///
  /// In en, this message translates to:
  /// **'At least one Price List must stay enabled.'**
  String get refusedLastEnabledPriceList;

  /// No description provided for @refusedSeriesBelowUsed.
  ///
  /// In en, this message translates to:
  /// **'Number {number} is already used in this series. Set {number} or higher.'**
  String refusedSeriesBelowUsed(String number);

  /// No description provided for @refusedProfileSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'This POS Profile has an open POS session. Close the session first.'**
  String get refusedProfileSessionOpen;

  /// No description provided for @refusedGroupWarehouse.
  ///
  /// In en, this message translates to:
  /// **'A group warehouse holds no stock. Choose a warehouse inside it.'**
  String get refusedGroupWarehouse;

  /// No description provided for @refusedOneDefaultPayment.
  ///
  /// In en, this message translates to:
  /// **'Exactly one payment method must be the default.'**
  String get refusedOneDefaultPayment;

  /// No description provided for @refusedOneDefaultProfile.
  ///
  /// In en, this message translates to:
  /// **'Exactly one enabled POS Profile must be the default. Make another profile the default first.'**
  String get refusedOneDefaultProfile;

  /// No description provided for @refusedDisabledChoice.
  ///
  /// In en, this message translates to:
  /// **'A disabled Price List, template or Mode of Payment cannot be chosen.'**
  String get refusedDisabledChoice;

  /// No description provided for @refusedNotABackup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a backup of this app. Nothing was changed.'**
  String get refusedNotABackup;

  /// No description provided for @refusedBackupTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup comes from a newer version of the app. Update the app first.'**
  String get refusedBackupTooNew;

  /// No description provided for @refusedSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'Close the open POS session before restoring.'**
  String get refusedSessionOpen;

  /// No description provided for @wizardLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get wizardLanguage;

  /// No description provided for @wizardRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get wizardRegion;

  /// No description provided for @wizardStore.
  ///
  /// In en, this message translates to:
  /// **'Your store'**
  String get wizardStore;

  /// No description provided for @wizardDone.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get wizardDone;

  /// No description provided for @wizardDoneBody.
  ///
  /// In en, this message translates to:
  /// **'{store} is ready to sell. Sales are tax-free until a Sales Taxes and Charges Template is chosen on the POS Profile.'**
  String wizardDoneBody(String store);

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @openCashRegister.
  ///
  /// In en, this message translates to:
  /// **'Open Cash Register'**
  String get openCashRegister;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get addFirstItem;

  /// No description provided for @groupStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get groupStore;

  /// No description provided for @groupSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get groupSelling;

  /// No description provided for @groupTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get groupTaxes;

  /// No description provided for @groupStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get groupStock;

  /// No description provided for @groupPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get groupPrinting;

  /// No description provided for @groupData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get groupData;

  /// No description provided for @storeProfile.
  ///
  /// In en, this message translates to:
  /// **'Store Profile'**
  String get storeProfile;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @globalDefaults.
  ///
  /// In en, this message translates to:
  /// **'Global Defaults'**
  String get globalDefaults;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @posProfile.
  ///
  /// In en, this message translates to:
  /// **'POS Profile'**
  String get posProfile;

  /// No description provided for @modeOfPayment.
  ///
  /// In en, this message translates to:
  /// **'Mode of Payment'**
  String get modeOfPayment;

  /// No description provided for @priceList.
  ///
  /// In en, this message translates to:
  /// **'Price List'**
  String get priceList;

  /// No description provided for @sellingSettings.
  ///
  /// In en, this message translates to:
  /// **'Selling Settings'**
  String get sellingSettings;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @salesTaxesTemplate.
  ///
  /// In en, this message translates to:
  /// **'Sales Taxes and Charges Template'**
  String get salesTaxesTemplate;

  /// No description provided for @itemTaxTemplate.
  ///
  /// In en, this message translates to:
  /// **'Item Tax Template'**
  String get itemTaxTemplate;

  /// No description provided for @stockSettings.
  ///
  /// In en, this message translates to:
  /// **'Stock Settings'**
  String get stockSettings;

  /// No description provided for @printSettings.
  ///
  /// In en, this message translates to:
  /// **'Print Settings'**
  String get printSettings;

  /// No description provided for @letterHead.
  ///
  /// In en, this message translates to:
  /// **'Letter Head'**
  String get letterHead;

  /// No description provided for @printHeading.
  ///
  /// In en, this message translates to:
  /// **'Print Heading'**
  String get printHeading;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @namingSeries.
  ///
  /// In en, this message translates to:
  /// **'Naming Series'**
  String get namingSeries;

  /// No description provided for @dataImport.
  ///
  /// In en, this message translates to:
  /// **'Data Import'**
  String get dataImport;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @backups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backups;

  /// No description provided for @sectionStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get sectionStore;

  /// No description provided for @sectionSalesGoal.
  ///
  /// In en, this message translates to:
  /// **'Sales Goal'**
  String get sectionSalesGoal;

  /// No description provided for @sectionRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get sectionRegion;

  /// No description provided for @sectionNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get sectionNumbers;

  /// No description provided for @sectionBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get sectionBackups;

  /// No description provided for @sectionDefaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get sectionDefaults;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @abbreviation.
  ///
  /// In en, this message translates to:
  /// **'Abbreviation'**
  String get abbreviation;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @monthlySalesTarget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales Target'**
  String get monthlySalesTarget;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get timeZone;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @numberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number Format'**
  String get numberFormat;

  /// No description provided for @firstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First Day of the Week'**
  String get firstDayOfWeek;

  /// No description provided for @floatPrecision.
  ///
  /// In en, this message translates to:
  /// **'Float Precision'**
  String get floatPrecision;

  /// No description provided for @currencyPrecision.
  ///
  /// In en, this message translates to:
  /// **'Currency Precision'**
  String get currencyPrecision;

  /// No description provided for @roundingMethod.
  ///
  /// In en, this message translates to:
  /// **'Rounding Method'**
  String get roundingMethod;

  /// No description provided for @numberOfBackups.
  ///
  /// In en, this message translates to:
  /// **'Number of Backups'**
  String get numberOfBackups;

  /// No description provided for @hideCurrencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Hide Currency Symbol'**
  String get hideCurrencySymbol;

  /// No description provided for @disableRoundedTotal.
  ///
  /// In en, this message translates to:
  /// **'Disable Rounded Total'**
  String get disableRoundedTotal;

  /// No description provided for @disableInWords.
  ///
  /// In en, this message translates to:
  /// **'Disable In Words'**
  String get disableInWords;

  /// No description provided for @defaultPriceList.
  ///
  /// In en, this message translates to:
  /// **'Default Price List'**
  String get defaultPriceList;

  /// No description provided for @fallbackToDefaultPriceList.
  ///
  /// In en, this message translates to:
  /// **'Use prices from Default Price List as fallback'**
  String get fallbackToDefaultPriceList;

  /// No description provided for @editablePriceListRate.
  ///
  /// In en, this message translates to:
  /// **'Allow editing Price List rate in transactions'**
  String get editablePriceListRate;

  /// No description provided for @validateSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Validate selling price against purchase or valuation rate'**
  String get validateSellingPrice;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyCode;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @fraction.
  ///
  /// In en, this message translates to:
  /// **'Fraction'**
  String get fraction;

  /// No description provided for @fractionUnits.
  ///
  /// In en, this message translates to:
  /// **'Fraction Units'**
  String get fractionUnits;

  /// No description provided for @smallestCurrencyFractionValue.
  ///
  /// In en, this message translates to:
  /// **'Smallest Currency Fraction Value'**
  String get smallestCurrencyFractionValue;

  /// No description provided for @symbolOnRight.
  ///
  /// In en, this message translates to:
  /// **'Show Currency Symbol on Right Side'**
  String get symbolOnRight;

  /// No description provided for @priceNotUomDependent.
  ///
  /// In en, this message translates to:
  /// **'Price Not UOM Dependent'**
  String get priceNotUomDependent;

  /// No description provided for @salesTaxesAndCharges.
  ///
  /// In en, this message translates to:
  /// **'Sales Taxes and Charges'**
  String get salesTaxesAndCharges;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate'**
  String get taxRate;

  /// No description provided for @taxAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get taxAmount;

  /// No description provided for @amountPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Amount per unit'**
  String get amountPerUnit;

  /// No description provided for @referenceRow.
  ///
  /// In en, this message translates to:
  /// **'Reference Row #'**
  String get referenceRow;

  /// No description provided for @includedInBasicRate.
  ///
  /// In en, this message translates to:
  /// **'Is this Tax included in Basic Rate?'**
  String get includedInBasicRate;

  /// No description provided for @tryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get tryIt;

  /// No description provided for @tryItFixRows.
  ///
  /// In en, this message translates to:
  /// **'Fix the rows above to see the amounts.'**
  String get tryItFixRows;

  /// No description provided for @netTotal.
  ///
  /// In en, this message translates to:
  /// **'Net Total'**
  String get netTotal;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get totalQuantity;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @taxRowMissingTax.
  ///
  /// In en, this message translates to:
  /// **'Tax is mandatory.'**
  String get taxRowMissingTax;

  /// No description provided for @taxRowPreviousRowInFirstRow.
  ///
  /// In en, this message translates to:
  /// **'The first row cannot be On Previous Row Amount or On Previous Row Total.'**
  String get taxRowPreviousRowInFirstRow;

  /// No description provided for @taxRowMissingReferenceRow.
  ///
  /// In en, this message translates to:
  /// **'Reference Row # is mandatory for this type.'**
  String get taxRowMissingReferenceRow;

  /// No description provided for @taxRowReferenceRowNotEarlier.
  ///
  /// In en, this message translates to:
  /// **'Reference Row # must point to an earlier row.'**
  String get taxRowReferenceRowNotEarlier;

  /// No description provided for @taxRowActualIncluded.
  ///
  /// In en, this message translates to:
  /// **'An Actual row cannot be included in the Basic Rate.'**
  String get taxRowActualIncluded;

  /// No description provided for @taxRowIncludedReferenceNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'The referenced row must also be included in the Basic Rate.'**
  String get taxRowIncludedReferenceNotIncluded;

  /// No description provided for @taxRowDuplicateTax.
  ///
  /// In en, this message translates to:
  /// **'This tax is already in another row.'**
  String get taxRowDuplicateTax;

  /// No description provided for @taxRates.
  ///
  /// In en, this message translates to:
  /// **'Tax Rates'**
  String get taxRates;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not Applicable'**
  String get notApplicable;

  /// No description provided for @itemTaxTemplateHelp.
  ///
  /// In en, this message translates to:
  /// **'A rate here replaces the rate of the same tax for the items using this template. Not Applicable removes the tax; a rate of 0 keeps the item taxable at zero.'**
  String get itemTaxTemplateHelp;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @allowInReturns.
  ///
  /// In en, this message translates to:
  /// **'Allow in Returns'**
  String get allowInReturns;

  /// No description provided for @noPaymentMethodsHint.
  ///
  /// In en, this message translates to:
  /// **'With no payment methods, Cash is used.'**
  String get noPaymentMethodsHint;

  /// No description provided for @configurations.
  ///
  /// In en, this message translates to:
  /// **'Configurations'**
  String get configurations;

  /// No description provided for @hideImages.
  ///
  /// In en, this message translates to:
  /// **'Hide images'**
  String get hideImages;

  /// No description provided for @hideUnavailableItems.
  ///
  /// In en, this message translates to:
  /// **'Hide unavailable Items'**
  String get hideUnavailableItems;

  /// No description provided for @allowRateChange.
  ///
  /// In en, this message translates to:
  /// **'Allow User to Edit Rate'**
  String get allowRateChange;

  /// No description provided for @autoAddItemToCart.
  ///
  /// In en, this message translates to:
  /// **'Automatically Add Filtered Item To Cart'**
  String get autoAddItemToCart;

  /// No description provided for @allowDiscountChange.
  ///
  /// In en, this message translates to:
  /// **'Allow User to Edit Discount'**
  String get allowDiscountChange;

  /// No description provided for @validateStockOnSave.
  ///
  /// In en, this message translates to:
  /// **'Validate Stock on Save'**
  String get validateStockOnSave;

  /// No description provided for @setGrandTotalToDefaultMop.
  ///
  /// In en, this message translates to:
  /// **'Set Grand Total to Default Payment Method'**
  String get setGrandTotalToDefaultMop;

  /// No description provided for @printReceiptOnOrderComplete.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt on Order Complete'**
  String get printReceiptOnOrderComplete;

  /// No description provided for @actionOnNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Action on New Invoice'**
  String get actionOnNewInvoice;

  /// No description provided for @itemGroups.
  ///
  /// In en, this message translates to:
  /// **'Item Groups'**
  String get itemGroups;

  /// No description provided for @itemGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Only items in the chosen groups and their sub-groups are shown. None chosen shows every item.'**
  String get itemGroupsHint;

  /// No description provided for @printFormat.
  ///
  /// In en, this message translates to:
  /// **'Print Format'**
  String get printFormat;

  /// No description provided for @pricingAndTaxes.
  ///
  /// In en, this message translates to:
  /// **'Price List and Taxes'**
  String get pricingAndTaxes;

  /// No description provided for @taxesAndCharges.
  ///
  /// In en, this message translates to:
  /// **'Taxes and Charges'**
  String get taxesAndCharges;

  /// No description provided for @applyDiscountOn.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount On'**
  String get applyDiscountOn;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentType;

  /// No description provided for @seriesList.
  ///
  /// In en, this message translates to:
  /// **'Series List'**
  String get seriesList;

  /// No description provided for @newPattern.
  ///
  /// In en, this message translates to:
  /// **'New series'**
  String get newPattern;

  /// No description provided for @namingSeriesHelp.
  ///
  /// In en, this message translates to:
  /// **'The first series is the default. .YYYY. .YY. .MM. .DD. become the posting date; ##### is the counter (five digits when left out).'**
  String get namingSeriesHelp;

  /// No description provided for @namingSeriesNeedsOne.
  ///
  /// In en, this message translates to:
  /// **'A document needs at least one series.'**
  String get namingSeriesNeedsOne;

  /// No description provided for @nextNameExample.
  ///
  /// In en, this message translates to:
  /// **'Next name: {name}'**
  String nextNameExample(String name);

  /// No description provided for @updateSeries.
  ///
  /// In en, this message translates to:
  /// **'Update Series'**
  String get updateSeries;

  /// No description provided for @prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get prefix;

  /// No description provided for @currentValue.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get currentValue;

  /// No description provided for @newCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'New Current Value'**
  String get newCurrentValue;

  /// No description provided for @recordType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get recordType;

  /// No description provided for @insertNewRecords.
  ///
  /// In en, this message translates to:
  /// **'Insert New Records'**
  String get insertNewRecords;

  /// No description provided for @updateExistingRecords.
  ///
  /// In en, this message translates to:
  /// **'Update Existing Records'**
  String get updateExistingRecords;

  /// No description provided for @mandatoryColumns.
  ///
  /// In en, this message translates to:
  /// **'Mandatory columns: {columns}'**
  String mandatoryColumns(String columns);

  /// No description provided for @importNotes.
  ///
  /// In en, this message translates to:
  /// **'Numbers use a dot for decimals; dates are YYYY-MM-DD; Maintain Stock and Is Sales Item are 1 or 0. Opening stock is entered through Stock Reconciliation.'**
  String get importNotes;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get downloadTemplate;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @startImport.
  ///
  /// In en, this message translates to:
  /// **'Start Import'**
  String get startImport;

  /// No description provided for @fileRows.
  ///
  /// In en, this message translates to:
  /// **'{file}: {count} rows'**
  String fileRows(String file, int count);

  /// No description provided for @mapColumn.
  ///
  /// In en, this message translates to:
  /// **'Column \"{header}\" is'**
  String mapColumn(String header);

  /// No description provided for @doNotImport.
  ///
  /// In en, this message translates to:
  /// **'Do not import'**
  String get doNotImport;

  /// No description provided for @importWarnings.
  ///
  /// In en, this message translates to:
  /// **'Problems ({count}). Nothing was imported; fix the file and choose it again.'**
  String importWarnings(int count);

  /// No description provided for @importLog.
  ///
  /// In en, this message translates to:
  /// **'Import log ({count})'**
  String importLog(int count);

  /// No description provided for @row.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// No description provided for @column.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get column;

  /// No description provided for @problem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get problem;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @importMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing mandatory value'**
  String get importMissing;

  /// No description provided for @importDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Name'**
  String get importDuplicate;

  /// No description provided for @importNotFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get importNotFound;

  /// No description provided for @importUnknownLink.
  ///
  /// In en, this message translates to:
  /// **'Does not exist'**
  String get importUnknownLink;

  /// No description provided for @importBadValue.
  ///
  /// In en, this message translates to:
  /// **'Not an allowed value'**
  String get importBadValue;

  /// No description provided for @importBadDate.
  ///
  /// In en, this message translates to:
  /// **'Not a valid date, or Valid Upto is before Valid From'**
  String get importBadDate;

  /// No description provided for @importBadBarcode.
  ///
  /// In en, this message translates to:
  /// **'Not a valid barcode for this Barcode Type'**
  String get importBadBarcode;

  /// No description provided for @importOverlappingPrice.
  ///
  /// In en, this message translates to:
  /// **'Overlaps another price for the same item, price list and unit'**
  String get importOverlappingPrice;

  /// No description provided for @exportedRows.
  ///
  /// In en, this message translates to:
  /// **'{count} rows exported.'**
  String exportedRows(int count);

  /// No description provided for @backupWarning.
  ///
  /// In en, this message translates to:
  /// **'Backups kept only on this device are lost with the device. Export them to another place.'**
  String get backupWarning;

  /// No description provided for @backUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backUpNow;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get restoreFromFile;

  /// No description provided for @backedUp.
  ///
  /// In en, this message translates to:
  /// **'Backup taken.'**
  String get backedUp;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet.'**
  String get noBackups;

  /// No description provided for @sizeKb.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKb(String size);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup?'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In en, this message translates to:
  /// **'The current data is backed up first and then replaced by the file you choose.'**
  String get restoreBody;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored.'**
  String get restored;

  /// No description provided for @namingSeriesNoFiscalYear.
  ///
  /// In en, this message translates to:
  /// **'There is no Fiscal Year: use .YYYY. instead of .FY.'**
  String get namingSeriesNoFiscalYear;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {detail}'**
  String unexpectedError(String detail);

  /// No description provided for @wizardRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Moving from another device? Restore a backup instead of setting up again.'**
  String get wizardRestoreHint;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;
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

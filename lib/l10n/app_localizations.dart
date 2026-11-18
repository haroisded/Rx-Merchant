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

  /// No description provided for @refusedDefaultPriceList.
  ///
  /// In en, this message translates to:
  /// **'This is the Default Price List in Selling Settings, which the Cash Register sells from. It must stay enabled. Choose another Default Price List first.'**
  String get refusedDefaultPriceList;

  /// No description provided for @refusedSeriesBelowUsed.
  ///
  /// In en, this message translates to:
  /// **'Number {number} is already used in this series. Set {number} or higher.'**
  String refusedSeriesBelowUsed(String number);

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
  /// **'{store} is ready to sell. Sales are tax-free until a Sales Taxes and Charges Template is made the Default.'**
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

  /// No description provided for @posSettings.
  ///
  /// In en, this message translates to:
  /// **'POS Settings'**
  String get posSettings;

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

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @defaultModeOfPayment.
  ///
  /// In en, this message translates to:
  /// **'Default Mode of Payment'**
  String get defaultModeOfPayment;

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

  /// No description provided for @printFormat.
  ///
  /// In en, this message translates to:
  /// **'Print Format'**
  String get printFormat;

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

  /// No description provided for @groupItemsAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Items and Pricing'**
  String get groupItemsAndPricing;

  /// No description provided for @groupStockTransactions.
  ///
  /// In en, this message translates to:
  /// **'Stock Transactions'**
  String get groupStockTransactions;

  /// No description provided for @groupSerialAndBatch.
  ///
  /// In en, this message translates to:
  /// **'Serial No and Batch'**
  String get groupSerialAndBatch;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get groupSettings;

  /// No description provided for @groupReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get groupReports;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @itemGroup.
  ///
  /// In en, this message translates to:
  /// **'Item Group'**
  String get itemGroup;

  /// No description provided for @itemPrice.
  ///
  /// In en, this message translates to:
  /// **'Item Price'**
  String get itemPrice;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @itemAttribute.
  ///
  /// In en, this message translates to:
  /// **'Item Attribute'**
  String get itemAttribute;

  /// No description provided for @stockEntry.
  ///
  /// In en, this message translates to:
  /// **'Stock Entry'**
  String get stockEntry;

  /// No description provided for @stockReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Stock Reconciliation'**
  String get stockReconciliation;

  /// No description provided for @serialNo.
  ///
  /// In en, this message translates to:
  /// **'Serial No'**
  String get serialNo;

  /// No description provided for @batch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batch;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @uom.
  ///
  /// In en, this message translates to:
  /// **'UOM'**
  String get uom;

  /// No description provided for @reportStockLedger.
  ///
  /// In en, this message translates to:
  /// **'Stock Ledger'**
  String get reportStockLedger;

  /// No description provided for @reportStockBalance.
  ///
  /// In en, this message translates to:
  /// **'Stock Balance'**
  String get reportStockBalance;

  /// No description provided for @reportQuickStockBalance.
  ///
  /// In en, this message translates to:
  /// **'Quick Stock Balance'**
  String get reportQuickStockBalance;

  /// No description provided for @reportBatchBalance.
  ///
  /// In en, this message translates to:
  /// **'Batch-wise Balance History'**
  String get reportBatchBalance;

  /// No description provided for @reportSerialNoLedger.
  ///
  /// In en, this message translates to:
  /// **'Serial No Ledger'**
  String get reportSerialNoLedger;

  /// No description provided for @reportItemPriceStock.
  ///
  /// In en, this message translates to:
  /// **'Item Price Stock'**
  String get reportItemPriceStock;

  /// No description provided for @reportLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get reportLowStock;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totals;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @moreInformation.
  ///
  /// In en, this message translates to:
  /// **'More Information'**
  String get moreInformation;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this document?'**
  String get submitTitle;

  /// No description provided for @submitBody.
  ///
  /// In en, this message translates to:
  /// **'A submitted document changes stock and cannot be edited. To change it later, cancel and amend it.'**
  String get submitBody;

  /// No description provided for @cancelDocument.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDocument;

  /// No description provided for @cancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this document?'**
  String get cancelTitle;

  /// No description provided for @cancelBody.
  ///
  /// In en, this message translates to:
  /// **'Its stock movements are reversed. The document stays, marked Cancelled.'**
  String get cancelBody;

  /// No description provided for @amend.
  ///
  /// In en, this message translates to:
  /// **'Amend'**
  String get amend;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item.'**
  String get noItems;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries for these filters'**
  String get noEntries;

  /// No description provided for @treeView.
  ///
  /// In en, this message translates to:
  /// **'Tree view'**
  String get treeView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @isGroup.
  ///
  /// In en, this message translates to:
  /// **'Is Group'**
  String get isGroup;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @chooseWarehouseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the Default Warehouse first.'**
  String get chooseWarehouseFirst;

  /// No description provided for @csvRowInvalid.
  ///
  /// In en, this message translates to:
  /// **'Item Code, Warehouse or Quantity is missing or not found.'**
  String get csvRowInvalid;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get validFrom;

  /// No description provided for @validUpto.
  ///
  /// In en, this message translates to:
  /// **'Valid Upto'**
  String get validUpto;

  /// No description provided for @validUptoBeforeFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid Upto is before Valid From.'**
  String get validUptoBeforeFrom;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @draftNumber.
  ///
  /// In en, this message translates to:
  /// **'Draft {id}'**
  String draftNumber(int id);

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'{page} of {pages}'**
  String pageOf(int page, int pages);

  /// No description provided for @barcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No item has the barcode {code}.'**
  String barcodeNotFound(String code);

  /// No description provided for @csvHeadersChanged.
  ///
  /// In en, this message translates to:
  /// **'The file must have these columns, spelled exactly: {columns}.'**
  String csvHeadersChanged(String columns);

  /// No description provided for @rowsLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} rows loaded'**
  String rowsLoaded(String count);

  /// No description provided for @itemCode.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get itemCode;

  /// No description provided for @itemCodeBySeries.
  ///
  /// In en, this message translates to:
  /// **'Item Code (set on save from the naming series)'**
  String get itemCodeBySeries;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @defaultUom.
  ///
  /// In en, this message translates to:
  /// **'Default Unit of Measure'**
  String get defaultUom;

  /// No description provided for @maintainStock.
  ///
  /// In en, this message translates to:
  /// **'Maintain Stock'**
  String get maintainStock;

  /// No description provided for @hasVariants.
  ///
  /// In en, this message translates to:
  /// **'Has Variants'**
  String get hasVariants;

  /// No description provided for @openingStock.
  ///
  /// In en, this message translates to:
  /// **'Opening Stock'**
  String get openingStock;

  /// No description provided for @valuationRate.
  ///
  /// In en, this message translates to:
  /// **'Valuation Rate'**
  String get valuationRate;

  /// No description provided for @standardSellingRate.
  ///
  /// In en, this message translates to:
  /// **'Standard Selling Rate'**
  String get standardSellingRate;

  /// No description provided for @barcodes.
  ///
  /// In en, this message translates to:
  /// **'Barcodes'**
  String get barcodes;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @barcodeType.
  ///
  /// In en, this message translates to:
  /// **'Barcode Type'**
  String get barcodeType;

  /// No description provided for @badBarcodeHelp.
  ///
  /// In en, this message translates to:
  /// **'EAN needs 13 digits with a valid check digit; UPC needs 12 digits.'**
  String get badBarcodeHelp;

  /// No description provided for @shelfLifeInDays.
  ///
  /// In en, this message translates to:
  /// **'Shelf Life In Days'**
  String get shelfLifeInDays;

  /// No description provided for @endOfLife.
  ///
  /// In en, this message translates to:
  /// **'End of Life'**
  String get endOfLife;

  /// No description provided for @warrantyPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Warranty Period (in days)'**
  String get warrantyPeriodDays;

  /// No description provided for @valuationMethod.
  ///
  /// In en, this message translates to:
  /// **'Valuation Method'**
  String get valuationMethod;

  /// No description provided for @asInStockSettings.
  ///
  /// In en, this message translates to:
  /// **'As in Stock Settings'**
  String get asInStockSettings;

  /// No description provided for @allowNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'Allow Negative Stock'**
  String get allowNegativeStock;

  /// No description provided for @defaultWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Default Warehouse'**
  String get defaultWarehouse;

  /// No description provided for @unitsOfMeasure.
  ///
  /// In en, this message translates to:
  /// **'Units of Measure'**
  String get unitsOfMeasure;

  /// No description provided for @conversionFactor.
  ///
  /// In en, this message translates to:
  /// **'Conversion Factor'**
  String get conversionFactor;

  /// No description provided for @autoReorder.
  ///
  /// In en, this message translates to:
  /// **'Auto Reorder'**
  String get autoReorder;

  /// No description provided for @reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Re-order Level'**
  String get reorderLevel;

  /// No description provided for @reorderQty.
  ///
  /// In en, this message translates to:
  /// **'Re-order Qty'**
  String get reorderQty;

  /// No description provided for @hasBatchNo.
  ///
  /// In en, this message translates to:
  /// **'Has Batch No'**
  String get hasBatchNo;

  /// No description provided for @createNewBatch.
  ///
  /// In en, this message translates to:
  /// **'Automatically Create New Batch'**
  String get createNewBatch;

  /// No description provided for @batchNumberSeries.
  ///
  /// In en, this message translates to:
  /// **'Batch Number Series'**
  String get batchNumberSeries;

  /// No description provided for @hasExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Has Expiry Date'**
  String get hasExpiryDate;

  /// No description provided for @hasSerialNo.
  ///
  /// In en, this message translates to:
  /// **'Has Serial No'**
  String get hasSerialNo;

  /// No description provided for @serialNoSeries.
  ///
  /// In en, this message translates to:
  /// **'Serial Number Series'**
  String get serialNoSeries;

  /// No description provided for @defaultSalesUom.
  ///
  /// In en, this message translates to:
  /// **'Default Sales Unit of Measure'**
  String get defaultSalesUom;

  /// No description provided for @maxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Max Discount (%)'**
  String get maxDiscount;

  /// No description provided for @isSalesItem.
  ///
  /// In en, this message translates to:
  /// **'Is Sales Item'**
  String get isSalesItem;

  /// No description provided for @tabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// No description provided for @tabInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get tabInventory;

  /// No description provided for @tabVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get tabVariants;

  /// No description provided for @tabSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get tabSales;

  /// No description provided for @tabTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tabTax;

  /// No description provided for @lockedAfterStock.
  ///
  /// In en, this message translates to:
  /// **'Read-only: this item already has stock ledger entries.'**
  String get lockedAfterStock;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @importItems.
  ///
  /// In en, this message translates to:
  /// **'Import items'**
  String get importItems;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Item Code, Item Name or barcode'**
  String get searchItems;

  /// No description provided for @addPrice.
  ///
  /// In en, this message translates to:
  /// **'Add price'**
  String get addPrice;

  /// No description provided for @stockLevels.
  ///
  /// In en, this message translates to:
  /// **'Stock Levels'**
  String get stockLevels;

  /// No description provided for @itemTaxHelp.
  ///
  /// In en, this message translates to:
  /// **'The template whose Valid From is the latest on or before the sale applies; without one, the Item Group\'s template applies.'**
  String get itemTaxHelp;

  /// No description provided for @itemCodificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Item Codification'**
  String get itemCodificationTitle;

  /// No description provided for @itemCodificationHelp.
  ///
  /// In en, this message translates to:
  /// **'For a small catalogue, keep the Item Code and Item Name the same. For a large one, use a meaningful code scheme, for example a group prefix and a running number, and keep the description in the Item Name.'**
  String get itemCodificationHelp;

  /// No description provided for @variantOf.
  ///
  /// In en, this message translates to:
  /// **'Variant Of'**
  String get variantOf;

  /// No description provided for @variants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get variants;

  /// No description provided for @attributes.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// No description provided for @singleVariant.
  ///
  /// In en, this message translates to:
  /// **'Single Variant'**
  String get singleVariant;

  /// No description provided for @multipleVariants.
  ///
  /// In en, this message translates to:
  /// **'Multiple Variants'**
  String get multipleVariants;

  /// No description provided for @variantsHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on Has Variants to make this item a template, then add its attributes.'**
  String get variantsHelp;

  /// No description provided for @variantsCreated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new variants: they all exist} =1{1 variant created} other{{count} variants created}}'**
  String variantsCreated(int count);

  /// No description provided for @variantsToCreate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Tick at least one value per attribute} =1{1 variant} other{{count} variants}}'**
  String variantsToCreate(int count);

  /// No description provided for @attributeName.
  ///
  /// In en, this message translates to:
  /// **'Attribute Name'**
  String get attributeName;

  /// No description provided for @numericValues.
  ///
  /// In en, this message translates to:
  /// **'Numeric Values'**
  String get numericValues;

  /// No description provided for @fromRange.
  ///
  /// In en, this message translates to:
  /// **'From Range'**
  String get fromRange;

  /// No description provided for @toRange.
  ///
  /// In en, this message translates to:
  /// **'To Range'**
  String get toRange;

  /// No description provided for @increment.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get increment;

  /// No description provided for @attributeValues.
  ///
  /// In en, this message translates to:
  /// **'Item Attribute Values'**
  String get attributeValues;

  /// No description provided for @attributeValue.
  ///
  /// In en, this message translates to:
  /// **'Attribute Value'**
  String get attributeValue;

  /// No description provided for @badNumericRange.
  ///
  /// In en, this message translates to:
  /// **'The range must give at least one value: Increment above 0 and To Range at or above From Range.'**
  String get badNumericRange;

  /// No description provided for @attributeNeedsValues.
  ///
  /// In en, this message translates to:
  /// **'Add at least one value.'**
  String get attributeNeedsValues;

  /// No description provided for @mustBeWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be Whole Number'**
  String get mustBeWholeNumber;

  /// No description provided for @warehouseName.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Name'**
  String get warehouseName;

  /// No description provided for @parentWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Parent Warehouse'**
  String get parentWarehouse;

  /// No description provided for @warehouseType.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Type'**
  String get warehouseType;

  /// No description provided for @itemGroupName.
  ///
  /// In en, this message translates to:
  /// **'Item Group Name'**
  String get itemGroupName;

  /// No description provided for @parentItemGroup.
  ///
  /// In en, this message translates to:
  /// **'Parent Item Group'**
  String get parentItemGroup;

  /// No description provided for @itemNamingBy.
  ///
  /// In en, this message translates to:
  /// **'Item Naming By'**
  String get itemNamingBy;

  /// No description provided for @defaultItemGroup.
  ///
  /// In en, this message translates to:
  /// **'Default Item Group'**
  String get defaultItemGroup;

  /// No description provided for @defaultStockUom.
  ///
  /// In en, this message translates to:
  /// **'Default Stock UOM'**
  String get defaultStockUom;

  /// No description provided for @defaultValuationMethod.
  ///
  /// In en, this message translates to:
  /// **'Default Valuation Method'**
  String get defaultValuationMethod;

  /// No description provided for @lockedValuationMethod.
  ///
  /// In en, this message translates to:
  /// **'Locked: items that follow this method already have stock.'**
  String get lockedValuationMethod;

  /// No description provided for @sectionStockTransactions.
  ///
  /// In en, this message translates to:
  /// **'Stock Transactions Settings'**
  String get sectionStockTransactions;

  /// No description provided for @showBarcodeField.
  ///
  /// In en, this message translates to:
  /// **'Show Barcode Field'**
  String get showBarcodeField;

  /// No description provided for @autoInsertPriceListRate.
  ///
  /// In en, this message translates to:
  /// **'Auto insert Price List rate if missing'**
  String get autoInsertPriceListRate;

  /// No description provided for @showLowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Show low-stock alerts'**
  String get showLowStockAlerts;

  /// No description provided for @stockFrozenUpto.
  ///
  /// In en, this message translates to:
  /// **'Stock Frozen Upto'**
  String get stockFrozenUpto;

  /// No description provided for @enableSerialAndBatch.
  ///
  /// In en, this message translates to:
  /// **'Enable Serial and Batch No for Item'**
  String get enableSerialAndBatch;

  /// No description provided for @pickSerialBatchBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Pick Serial / Batch Based On'**
  String get pickSerialBatchBasedOn;

  /// No description provided for @autoCreateBundleForOutward.
  ///
  /// In en, this message translates to:
  /// **'Auto Create Serial and Batch Bundle For Outward'**
  String get autoCreateBundleForOutward;

  /// No description provided for @batchId.
  ///
  /// In en, this message translates to:
  /// **'Batch ID'**
  String get batchId;

  /// No description provided for @manufacturingDate.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing Date'**
  String get manufacturingDate;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @batchNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get batchNotSet;

  /// No description provided for @batchNotExpired.
  ///
  /// In en, this message translates to:
  /// **'Not Expired'**
  String get batchNotExpired;

  /// No description provided for @batchExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get batchExpired;

  /// No description provided for @warrantyExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expiry Date'**
  String get warrantyExpiryDate;

  /// No description provided for @serialBatchEntries.
  ///
  /// In en, this message translates to:
  /// **'Serial / Batch Entries'**
  String get serialBatchEntries;

  /// No description provided for @autoFetch.
  ///
  /// In en, this message translates to:
  /// **'Auto Fetch'**
  String get autoFetch;

  /// No description provided for @createSerialsFromRange.
  ///
  /// In en, this message translates to:
  /// **'Create Serial Nos from Range'**
  String get createSerialsFromRange;

  /// No description provided for @serialRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get serialRange;

  /// No description provided for @badSerialRange.
  ///
  /// In en, this message translates to:
  /// **'Type a range such as SN-01::10.'**
  String get badSerialRange;

  /// No description provided for @serialScannedTwice.
  ///
  /// In en, this message translates to:
  /// **'{serial} is already in the list.'**
  String serialScannedTwice(String serial);

  /// No description provided for @serialStatus.
  ///
  /// In en, this message translates to:
  /// **'{status, select, Inactive{Inactive} Available{Available} Delivered{Delivered} other{{status}}}'**
  String serialStatus(String status);

  /// No description provided for @materialReceipt.
  ///
  /// In en, this message translates to:
  /// **'Material Receipt'**
  String get materialReceipt;

  /// No description provided for @materialIssue.
  ///
  /// In en, this message translates to:
  /// **'Material Issue'**
  String get materialIssue;

  /// No description provided for @materialTransfer.
  ///
  /// In en, this message translates to:
  /// **'Material Transfer'**
  String get materialTransfer;

  /// No description provided for @editPostingDateTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Posting Date and Time'**
  String get editPostingDateTime;

  /// No description provided for @postingDateTime.
  ///
  /// In en, this message translates to:
  /// **'Posting Date and Time'**
  String get postingDateTime;

  /// No description provided for @defaultSourceWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Default Source Warehouse'**
  String get defaultSourceWarehouse;

  /// No description provided for @defaultTargetWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Default Target Warehouse'**
  String get defaultTargetWarehouse;

  /// No description provided for @sourceWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Source Warehouse'**
  String get sourceWarehouse;

  /// No description provided for @targetWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Target Warehouse'**
  String get targetWarehouse;

  /// No description provided for @stockQty.
  ///
  /// In en, this message translates to:
  /// **'Qty as per Stock UOM'**
  String get stockQty;

  /// No description provided for @basicRatePerStockUom.
  ///
  /// In en, this message translates to:
  /// **'Basic Rate (as per Stock UOM)'**
  String get basicRatePerStockUom;

  /// No description provided for @allowZeroValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Allow Zero Valuation Rate'**
  String get allowZeroValuationRate;

  /// No description provided for @additionalCosts.
  ///
  /// In en, this message translates to:
  /// **'Additional Costs'**
  String get additionalCosts;

  /// No description provided for @totalOutgoingValue.
  ///
  /// In en, this message translates to:
  /// **'Total Outgoing Value'**
  String get totalOutgoingValue;

  /// No description provided for @totalIncomingValue.
  ///
  /// In en, this message translates to:
  /// **'Total Incoming Value'**
  String get totalIncomingValue;

  /// No description provided for @totalAdditionalCosts.
  ///
  /// In en, this message translates to:
  /// **'Total Additional Costs'**
  String get totalAdditionalCosts;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @isOpening.
  ///
  /// In en, this message translates to:
  /// **'Is Opening'**
  String get isOpening;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'Scan Mode'**
  String get scanMode;

  /// No description provided for @fetchItems.
  ///
  /// In en, this message translates to:
  /// **'Fetch Items from Warehouse'**
  String get fetchItems;

  /// No description provided for @currentQty.
  ///
  /// In en, this message translates to:
  /// **'Current Qty'**
  String get currentQty;

  /// No description provided for @currentValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Current Valuation Rate'**
  String get currentValuationRate;

  /// No description provided for @quantityDifference.
  ///
  /// In en, this message translates to:
  /// **'Quantity Difference'**
  String get quantityDifference;

  /// No description provided for @amountDifference.
  ///
  /// In en, this message translates to:
  /// **'Amount Difference'**
  String get amountDifference;

  /// No description provided for @differenceAmount.
  ///
  /// In en, this message translates to:
  /// **'Difference Amount'**
  String get differenceAmount;

  /// No description provided for @stockUom.
  ///
  /// In en, this message translates to:
  /// **'Stock UOM'**
  String get stockUom;

  /// No description provided for @inQty.
  ///
  /// In en, this message translates to:
  /// **'In Qty'**
  String get inQty;

  /// No description provided for @outQty.
  ///
  /// In en, this message translates to:
  /// **'Out Qty'**
  String get outQty;

  /// No description provided for @balanceQty.
  ///
  /// In en, this message translates to:
  /// **'Balance Qty'**
  String get balanceQty;

  /// No description provided for @incomingRate.
  ///
  /// In en, this message translates to:
  /// **'Incoming Rate'**
  String get incomingRate;

  /// No description provided for @balanceValue.
  ///
  /// In en, this message translates to:
  /// **'Balance Value'**
  String get balanceValue;

  /// No description provided for @valueChange.
  ///
  /// In en, this message translates to:
  /// **'Value Change'**
  String get valueChange;

  /// No description provided for @voucherType.
  ///
  /// In en, this message translates to:
  /// **'Voucher Type'**
  String get voucherType;

  /// No description provided for @voucherNo.
  ///
  /// In en, this message translates to:
  /// **'Voucher #'**
  String get voucherNo;

  /// No description provided for @openingQty.
  ///
  /// In en, this message translates to:
  /// **'Opening Qty'**
  String get openingQty;

  /// No description provided for @openingValue.
  ///
  /// In en, this message translates to:
  /// **'Opening Value'**
  String get openingValue;

  /// No description provided for @inValue.
  ///
  /// In en, this message translates to:
  /// **'In Value'**
  String get inValue;

  /// No description provided for @outValue.
  ///
  /// In en, this message translates to:
  /// **'Out Value'**
  String get outValue;

  /// No description provided for @inOrOut.
  ///
  /// In en, this message translates to:
  /// **'In / Out'**
  String get inOrOut;

  /// No description provided for @availableQty.
  ///
  /// In en, this message translates to:
  /// **'Available Qty'**
  String get availableQty;

  /// No description provided for @actualQty.
  ///
  /// In en, this message translates to:
  /// **'Actual Qty'**
  String get actualQty;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @lineMissingItem.
  ///
  /// In en, this message translates to:
  /// **'Item is missing.'**
  String get lineMissingItem;

  /// No description provided for @lineQtyNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be above zero.'**
  String get lineQtyNotPositive;

  /// No description provided for @lineSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Source Warehouse is mandatory.'**
  String get lineSourceRequired;

  /// No description provided for @lineTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Target Warehouse is mandatory.'**
  String get lineTargetRequired;

  /// No description provided for @lineSameWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Source and Target Warehouse cannot be the same.'**
  String get lineSameWarehouse;

  /// No description provided for @lineGroupWarehouse.
  ///
  /// In en, this message translates to:
  /// **'A group or disabled warehouse cannot be used in a transaction.'**
  String get lineGroupWarehouse;

  /// No description provided for @lineFraction.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot be a fraction.'**
  String get lineFraction;

  /// No description provided for @lineItemDisabled.
  ///
  /// In en, this message translates to:
  /// **'Item is disabled.'**
  String get lineItemDisabled;

  /// No description provided for @lineItemEndOfLife.
  ///
  /// In en, this message translates to:
  /// **'Item has reached its End of Life.'**
  String get lineItemEndOfLife;

  /// No description provided for @lineItemTemplate.
  ///
  /// In en, this message translates to:
  /// **'Item is a template: choose one of its variants.'**
  String get lineItemTemplate;

  /// No description provided for @lineItemNotStock.
  ///
  /// In en, this message translates to:
  /// **'Item does not maintain stock.'**
  String get lineItemNotStock;

  /// No description provided for @lineZeroRate.
  ///
  /// In en, this message translates to:
  /// **'Valuation Rate is mandatory. Tick Allow Zero Valuation Rate to receive at zero.'**
  String get lineZeroRate;

  /// No description provided for @lineSerialCount.
  ///
  /// In en, this message translates to:
  /// **'The quantity must be a whole number equal to the number of serial numbers.'**
  String get lineSerialCount;

  /// No description provided for @lineEntriesQty.
  ///
  /// In en, this message translates to:
  /// **'The Serial / Batch Entries must add up to the quantity.'**
  String get lineEntriesQty;

  /// No description provided for @lineBatchOrSerialItem.
  ///
  /// In en, this message translates to:
  /// **'Batch and serial items are counted with a Stock Entry (Material Receipt or Issue), not here.'**
  String get lineBatchOrSerialItem;

  /// No description provided for @lineDuplicateRow.
  ///
  /// In en, this message translates to:
  /// **'This item and warehouse are already on another row.'**
  String get lineDuplicateRow;

  /// No description provided for @lineFractionAt.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot be a fraction at row {row}'**
  String lineFractionAt(int row);

  /// No description provided for @refusedNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'{needed} units of {item} needed in {warehouse} on {date} for {voucher} to complete this transaction. Available then: {available}.'**
  String refusedNegativeStock(
    String item,
    String warehouse,
    String available,
    String needed,
    String date,
    String voucher,
  );

  /// No description provided for @refusedNegativeBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch} of {item} would go below zero in {warehouse} on {date} for {voucher}.'**
  String refusedNegativeBatch(
    String batch,
    String item,
    String warehouse,
    String date,
    String voucher,
  );

  /// No description provided for @refusedStockFrozen.
  ///
  /// In en, this message translates to:
  /// **'Stock is frozen up to {date}: nothing on or before it can be submitted or cancelled.'**
  String refusedStockFrozen(String date);

  /// No description provided for @refusedHasVariantsLocked.
  ///
  /// In en, this message translates to:
  /// **'Has Variants cannot change once the item has variants or stock.'**
  String get refusedHasVariantsLocked;

  /// No description provided for @refusedTemplate.
  ///
  /// In en, this message translates to:
  /// **'{item} is a template: it has no price and cannot be moved.'**
  String refusedTemplate(String item);

  /// No description provided for @refusedUnitInUse.
  ///
  /// In en, this message translates to:
  /// **'{uom} is used on a document: it cannot be removed or have its Conversion Factor changed.'**
  String refusedUnitInUse(String uom);

  /// No description provided for @refusedBarcodeTaken.
  ///
  /// In en, this message translates to:
  /// **'This barcode belongs to item {item}.'**
  String refusedBarcodeTaken(String item);

  /// No description provided for @refusedBadBarcode.
  ///
  /// In en, this message translates to:
  /// **'{barcode} is not a valid barcode for its type.'**
  String refusedBadBarcode(String barcode);

  /// No description provided for @refusedDefaultWarehouse.
  ///
  /// In en, this message translates to:
  /// **'This is the Default Warehouse in Stock Settings, which the Cash Register sells from. It must stay enabled and cannot be a group. Choose another Default Warehouse first.'**
  String get refusedDefaultWarehouse;

  /// No description provided for @refusedWarehouseHasLedger.
  ///
  /// In en, this message translates to:
  /// **'A warehouse with stock ledger entries cannot become a group.'**
  String get refusedWarehouseHasLedger;

  /// No description provided for @refusedBatchRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a Batch for {item}, or turn on Automatically Create New Batch.'**
  String refusedBatchRequired(String item);

  /// No description provided for @refusedSerialRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the serial numbers of {item}, or set its Serial Number Series.'**
  String refusedSerialRequired(String item);

  /// No description provided for @refusedNotEnoughEntries.
  ///
  /// In en, this message translates to:
  /// **'Not enough serial numbers or batches of {item} in the source warehouse. Choose them in Serial / Batch Entries.'**
  String refusedNotEnoughEntries(String item);

  /// No description provided for @refusedExpiredBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch} has expired: it can leave stock only through a Material Issue.'**
  String refusedExpiredBatch(String batch);

  /// No description provided for @refusedBatchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch} does not exist for this item.'**
  String refusedBatchNotFound(String batch);

  /// No description provided for @refusedSerialNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Serial No {serial} is not Available in the source warehouse.'**
  String refusedSerialNotAvailable(String serial);

  /// No description provided for @refusedSerialExists.
  ///
  /// In en, this message translates to:
  /// **'Serial No {serial} already exists in stock.'**
  String refusedSerialExists(String serial);

  /// No description provided for @refusedSerialMovedSince.
  ///
  /// In en, this message translates to:
  /// **'Serial No {serial} has moved since this entry. Cancel the later documents first.'**
  String refusedSerialMovedSince(String serial);

  /// No description provided for @refusedDocstatus.
  ///
  /// In en, this message translates to:
  /// **'This document has changed since it was opened. Open it again.'**
  String get refusedDocstatus;

  /// No description provided for @lineDuplicateSerial.
  ///
  /// In en, this message translates to:
  /// **'A serial number is listed twice. Each serial number is one unit and can be on one line only.'**
  String get lineDuplicateSerial;

  /// No description provided for @refusedExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch} needs an Expiry Date: its item has Has Expiry Date and no Shelf Life In Days to work it out from.'**
  String refusedExpiryRequired(String batch);

  /// No description provided for @posOpeningEntry.
  ///
  /// In en, this message translates to:
  /// **'POS Opening Entry'**
  String get posOpeningEntry;

  /// No description provided for @posClosingEntry.
  ///
  /// In en, this message translates to:
  /// **'POS Closing Entry'**
  String get posClosingEntry;

  /// No description provided for @openingAmount.
  ///
  /// In en, this message translates to:
  /// **'Opening Amount'**
  String get openingAmount;

  /// No description provided for @openingHelp.
  ///
  /// In en, this message translates to:
  /// **'Count what is in the drawer for each payment mode, then open the session to start selling.'**
  String get openingHelp;

  /// No description provided for @openSession.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSession;

  /// No description provided for @cancelLastClosing.
  ///
  /// In en, this message translates to:
  /// **'Cancel {name}'**
  String cancelLastClosing(String name);

  /// No description provided for @cancelClosingBody.
  ///
  /// In en, this message translates to:
  /// **'The session it closed opens again.'**
  String get cancelClosingBody;

  /// No description provided for @searchItemHint.
  ///
  /// In en, this message translates to:
  /// **'Search by item code, serial number or barcode'**
  String get searchItemHint;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Scan or tap an item to start a sale.'**
  String get cartEmpty;

  /// No description provided for @addDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add Discount'**
  String get addDiscount;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @roundedTotal.
  ///
  /// In en, this message translates to:
  /// **'Rounded Total'**
  String get roundedTotal;

  /// No description provided for @roundingAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Rounding Adjustment'**
  String get roundingAdjustment;

  /// No description provided for @discountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountPercentage;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// No description provided for @additionalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Additional Discount'**
  String get additionalDiscount;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @priceListRate.
  ///
  /// In en, this message translates to:
  /// **'Price List Rate'**
  String get priceListRate;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @toBePaid.
  ///
  /// In en, this message translates to:
  /// **'To Be Paid'**
  String get toBePaid;

  /// No description provided for @changeAmount.
  ///
  /// In en, this message translates to:
  /// **'Change Amount'**
  String get changeAmount;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get completeOrder;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @inWords.
  ///
  /// In en, this message translates to:
  /// **'In Words'**
  String get inWords;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @toggleRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Toggle Recent Orders'**
  String get toggleRecentOrders;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveAsDraft;

  /// No description provided for @closeThePos.
  ///
  /// In en, this message translates to:
  /// **'Close the POS'**
  String get closeThePos;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'The current sale has changes that are not saved.'**
  String get unsavedChangesBody;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @cartLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String cartLines(int count);

  /// No description provided for @heldOrdersRemain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No held orders.} =1{1 held order remains; closing does not change it.} other{{count} held orders remain; closing does not change them.}}'**
  String heldOrdersRemain(int count);

  /// No description provided for @invoiceCount.
  ///
  /// In en, this message translates to:
  /// **'Invoices: {count}'**
  String invoiceCount(int count);

  /// No description provided for @periodStartDate.
  ///
  /// In en, this message translates to:
  /// **'Period Start Date'**
  String get periodStartDate;

  /// No description provided for @periodEndDate.
  ///
  /// In en, this message translates to:
  /// **'Period End Date'**
  String get periodEndDate;

  /// No description provided for @paymentReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Payment Reconciliation'**
  String get paymentReconciliation;

  /// No description provided for @expectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Expected Amount'**
  String get expectedAmount;

  /// No description provided for @closingAmount.
  ///
  /// In en, this message translates to:
  /// **'Closing Amount'**
  String get closingAmount;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @totalTaxesAndCharges.
  ///
  /// In en, this message translates to:
  /// **'Total Taxes and Charges'**
  String get totalTaxesAndCharges;

  /// No description provided for @closedWithBackup.
  ///
  /// In en, this message translates to:
  /// **'Session closed. Backup saved.'**
  String get closedWithBackup;

  /// No description provided for @closedBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Session closed, but the backup failed: {error}'**
  String closedBackupFailed(String error);

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as draft.'**
  String get draftSaved;

  /// No description provided for @draftName.
  ///
  /// In en, this message translates to:
  /// **'Draft {id}'**
  String draftName(int id);

  /// No description provided for @lineNeedsEntries.
  ///
  /// In en, this message translates to:
  /// **'Serial / batch entries are picked at Submit.'**
  String get lineNeedsEntries;

  /// No description provided for @refusedNoOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Open a POS session (POS Opening Entry) first.'**
  String get refusedNoOpenSession;

  /// No description provided for @refusedAnotherSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'A POS session is already open. Close it before opening another.'**
  String get refusedAnotherSessionOpen;

  /// No description provided for @refusedEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item to the cart.'**
  String get refusedEmptyCart;

  /// No description provided for @refusedItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Item is unavailable: {needed} of {item} needed in {warehouse}; available: {available}.'**
  String refusedItemUnavailable(
    String item,
    String warehouse,
    String available,
    String needed,
  );

  /// No description provided for @refusedPaymentShort.
  ///
  /// In en, this message translates to:
  /// **'Partial payment is not allowed: paid {paid} of {toPay}.'**
  String refusedPaymentShort(String toPay, String paid);

  /// No description provided for @refusedNonCashOverpaid.
  ///
  /// In en, this message translates to:
  /// **'Change is given in cash only: a card or bank payment cannot be more than the amount due.'**
  String get refusedNonCashOverpaid;

  /// No description provided for @refusedNotLatestClosing.
  ///
  /// In en, this message translates to:
  /// **'Only the latest POS Closing Entry can be cancelled, and only while no newer session exists.'**
  String get refusedNotLatestClosing;

  /// No description provided for @lineNotSalesItem.
  ///
  /// In en, this message translates to:
  /// **'Item is not a sales item.'**
  String get lineNotSalesItem;

  /// No description provided for @lineDiscountAboveMax.
  ///
  /// In en, this message translates to:
  /// **'Discount is above the item\'s Max Discount (%).'**
  String get lineDiscountAboveMax;

  /// No description provided for @lineBelowValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Selling rate is below the item\'s valuation rate.'**
  String get lineBelowValuationRate;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get periodYesterday;

  /// No description provided for @periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodThisMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get periodThisYear;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net Sales'**
  String get netSales;

  /// No description provided for @averageSale.
  ///
  /// In en, this message translates to:
  /// **'Average Sale'**
  String get averageSale;

  /// No description provided for @itemsSold.
  ///
  /// In en, this message translates to:
  /// **'Items Sold'**
  String get itemsSold;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get grossProfit;

  /// No description provided for @grossProfitPercent.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit %'**
  String get grossProfitPercent;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxes;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stockValue;

  /// No description provided for @totalMonthlySales.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Sales'**
  String get totalMonthlySales;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @setSalesTarget.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly sales target'**
  String get setSalesTarget;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales Trend'**
  String get salesTrend;

  /// No description provided for @salesByItemGroup.
  ///
  /// In en, this message translates to:
  /// **'Sales by Item Group'**
  String get salesByItemGroup;

  /// No description provided for @topItems.
  ///
  /// In en, this message translates to:
  /// **'Top Items'**
  String get topItems;

  /// No description provided for @paymentModes.
  ///
  /// In en, this message translates to:
  /// **'Payment Modes'**
  String get paymentModes;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noSalesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get noSalesInPeriod;

  /// No description provided for @firstSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your first sale to see your dashboard'**
  String get firstSaleHint;

  /// No description provided for @reportSalesAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Sales Analytics'**
  String get reportSalesAnalytics;

  /// No description provided for @reportItemWiseSales.
  ///
  /// In en, this message translates to:
  /// **'Item-wise Sales'**
  String get reportItemWiseSales;

  /// No description provided for @treeType.
  ///
  /// In en, this message translates to:
  /// **'Tree Type'**
  String get treeType;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get rangeLabel;

  /// No description provided for @rangeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get rangeDaily;

  /// No description provided for @rangeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get rangeWeekly;

  /// No description provided for @rangeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get rangeMonthly;

  /// No description provided for @rangeQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get rangeQuarterly;

  /// No description provided for @rangeYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get rangeYearly;

  /// No description provided for @quarterOf.
  ///
  /// In en, this message translates to:
  /// **'Q{quarter} {year}'**
  String quarterOf(int quarter, int year);

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group By'**
  String get groupBy;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @sellingAmount.
  ///
  /// In en, this message translates to:
  /// **'Selling Amount'**
  String get sellingAmount;

  /// No description provided for @buyingAmount.
  ///
  /// In en, this message translates to:
  /// **'Buying Amount'**
  String get buyingAmount;

  /// No description provided for @averageSellingRate.
  ///
  /// In en, this message translates to:
  /// **'Average Selling Rate'**
  String get averageSellingRate;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @costMissing.
  ///
  /// In en, this message translates to:
  /// **'No buying or valuation rate'**
  String get costMissing;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmount;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @valueOrQty.
  ///
  /// In en, this message translates to:
  /// **'Value or Qty'**
  String get valueOrQty;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'The sales figures could not be read.'**
  String get dashboardLoadError;

  /// No description provided for @refusedReturnOriginal.
  ///
  /// In en, this message translates to:
  /// **'Only a submitted sale can be returned, and a return cannot be returned again.'**
  String get refusedReturnOriginal;

  /// No description provided for @refusedNothingToReturn.
  ///
  /// In en, this message translates to:
  /// **'Nothing is coming back. Set the quantity of at least one line.'**
  String get refusedNothingToReturn;

  /// No description provided for @refusedReturnTooMuch.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: at most {left} can still be returned.'**
  String refusedReturnTooMuch(int row, String left);

  /// No description provided for @refusedReturnRate.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: a return keeps the original rate. To credit part of the price, turn Update Stock off and lower the rate.'**
  String refusedReturnRate(int row);

  /// No description provided for @refusedReturnEntries.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: choose one serial number or batch quantity per unit, from those sold on this line and not yet returned.'**
  String refusedReturnEntries(int row);

  /// No description provided for @refusedRefundNotEqual.
  ///
  /// In en, this message translates to:
  /// **'The refund must be {amount} in full; {entered} is entered.'**
  String refusedRefundNotEqual(String amount, String entered);

  /// No description provided for @refusedModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'{mode} is disabled.'**
  String refusedModeDisabled(String mode);

  /// No description provided for @refusedCancelSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Its POS session is closed, so the drawer has been counted. Make a return instead.'**
  String get refusedCancelSessionClosed;

  /// No description provided for @refusedCancelHasReturns.
  ///
  /// In en, this message translates to:
  /// **'A return has been made against this sale. Cancel the return first, or make another return.'**
  String get refusedCancelHasReturns;

  /// No description provided for @invoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sales you complete at the Cash Register appear here.'**
  String get invoicesEmpty;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @noInvoiceNamed.
  ///
  /// In en, this message translates to:
  /// **'No invoice is named {name}.'**
  String noInvoiceNamed(String name);

  /// No description provided for @returnAgainst.
  ///
  /// In en, this message translates to:
  /// **'Return Against'**
  String get returnAgainst;

  /// No description provided for @returnCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Return / Credit Note'**
  String get returnCreditNote;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @priceOnlyCredit.
  ///
  /// In en, this message translates to:
  /// **'Price-only credit: no goods came back.'**
  String get priceOnlyCredit;

  /// No description provided for @cancelInvoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Its stock movements are reversed and its payments leave the session\'s expected amounts. The invoice keeps its name, marked Cancelled.'**
  String get cancelInvoiceBody;

  /// No description provided for @included.
  ///
  /// In en, this message translates to:
  /// **'included'**
  String get included;

  /// No description provided for @salesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales Invoice'**
  String get salesInvoice;

  /// No description provided for @creditNote.
  ///
  /// In en, this message translates to:
  /// **'Credit Note'**
  String get creditNote;

  /// No description provided for @draftMark.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draftMark;

  /// No description provided for @cancelledMark.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelledMark;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No.'**
  String get invoiceNo;

  /// No description provided for @serialNumberColumn.
  ///
  /// In en, this message translates to:
  /// **'Sr'**
  String get serialNumberColumn;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @formatStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get formatStandard;

  /// No description provided for @formatPosReceipt.
  ///
  /// In en, this message translates to:
  /// **'POS Receipt'**
  String get formatPosReceipt;

  /// No description provided for @receiptPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get receiptPrinter;

  /// No description provided for @printerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The receipt printer could not be reached. The sale is saved; print the PDF instead.'**
  String get printerUnreachable;

  /// No description provided for @receiptSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the receipt printer.'**
  String get receiptSent;

  /// No description provided for @printDraftNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Drafts cannot be printed. Turn on Allow Print for Draft in Print Settings.'**
  String get printDraftNotAllowed;

  /// No description provided for @printCancelledNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Cancelled invoices cannot be printed. Turn on Allow Print for Cancelled in Print Settings.'**
  String get printCancelledNotAllowed;

  /// No description provided for @pdfPageSize.
  ///
  /// In en, this message translates to:
  /// **'PDF Page Size'**
  String get pdfPageSize;

  /// No description provided for @repeatHeaderFooter.
  ///
  /// In en, this message translates to:
  /// **'Repeat Header and Footer in PDF'**
  String get repeatHeaderFooter;

  /// No description provided for @withLetterhead.
  ///
  /// In en, this message translates to:
  /// **'Print With Letterhead'**
  String get withLetterhead;

  /// No description provided for @compactItemPrint.
  ///
  /// In en, this message translates to:
  /// **'Compact Item Print'**
  String get compactItemPrint;

  /// No description provided for @allowPrintForDraft.
  ///
  /// In en, this message translates to:
  /// **'Allow Print for Draft'**
  String get allowPrintForDraft;

  /// No description provided for @addDraftHeading.
  ///
  /// In en, this message translates to:
  /// **'Always add \"Draft\" Heading for printing draft documents'**
  String get addDraftHeading;

  /// No description provided for @allowPrintForCancelled.
  ///
  /// In en, this message translates to:
  /// **'Allow Print for Cancelled'**
  String get allowPrintForCancelled;

  /// No description provided for @printTaxesWithZeroAmount.
  ///
  /// In en, this message translates to:
  /// **'Print Taxes with Zero Amount'**
  String get printTaxesWithZeroAmount;

  /// No description provided for @enableRawPrinting.
  ///
  /// In en, this message translates to:
  /// **'Enable Raw Printing'**
  String get enableRawPrinting;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get paperWidth;

  /// No description provided for @charsPerLine.
  ///
  /// In en, this message translates to:
  /// **'Characters per line'**
  String get charsPerLine;

  /// No description provided for @cutPaper.
  ///
  /// In en, this message translates to:
  /// **'Cut paper after printing'**
  String get cutPaper;

  /// No description provided for @openCashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Open cash drawer after printing'**
  String get openCashDrawer;

  /// No description provided for @bluetoothNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Rx Merchant may not use Bluetooth. Allow Nearby devices for the app to list the receipt printer.'**
  String get bluetoothNoPermission;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to use the receipt printer.'**
  String get bluetoothOff;

  /// No description provided for @noPairedPrinters.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth printer is paired. Pair the printer in Android\'s Bluetooth settings first.'**
  String get noPairedPrinters;

  /// No description provided for @bluetoothSettings.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth settings'**
  String get bluetoothSettings;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App permissions'**
  String get appPermissions;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @testPrint.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get testPrint;

  /// No description provided for @sampleItem.
  ///
  /// In en, this message translates to:
  /// **'Sample item'**
  String get sampleItem;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @headerText.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get headerText;

  /// No description provided for @headerTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Lines under the logo: store name, address, phone, tax ID'**
  String get headerTextHelp;

  /// No description provided for @footerText.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get footerText;

  /// No description provided for @termsHelp.
  ///
  /// In en, this message translates to:
  /// **'Copied into each sale when it starts; printed after the totals.'**
  String get termsHelp;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @updateStockOn.
  ///
  /// In en, this message translates to:
  /// **'The goods come back into stock.'**
  String get updateStockOn;

  /// No description provided for @updateStockOff.
  ///
  /// In en, this message translates to:
  /// **'Nothing moves in stock: a price-only credit.'**
  String get updateStockOff;

  /// No description provided for @receivingWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Receiving warehouse'**
  String get receivingWarehouse;

  /// No description provided for @refundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundAmount;

  /// No description provided for @refundPaidIn.
  ///
  /// In en, this message translates to:
  /// **'Refund paid in'**
  String get refundPaidIn;

  /// No description provided for @returnable.
  ///
  /// In en, this message translates to:
  /// **'Still returnable: {qty}'**
  String returnable(String qty);

  /// No description provided for @rateAtMost.
  ///
  /// In en, this message translates to:
  /// **'At most {rate}'**
  String rateAtMost(String rate);

  /// No description provided for @submitReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this return?'**
  String get submitReturnTitle;

  /// No description provided for @submitReturnBody.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount} now. The return is numbered and cannot be edited; it can be cancelled while this session is open.'**
  String submitReturnBody(String amount);

  /// No description provided for @allReturned.
  ///
  /// In en, this message translates to:
  /// **'Everything on this sale has been returned.'**
  String get allReturned;
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

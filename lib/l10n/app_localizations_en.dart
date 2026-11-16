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

  @override
  String get languageName => 'English';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get none => 'None';

  @override
  String get export => 'Export';

  @override
  String get emptyList => 'Nothing here yet.';

  @override
  String get disabled => 'Disabled';

  @override
  String get enabled => 'Enabled';

  @override
  String get isDefault => 'Default';

  @override
  String get name => 'Name';

  @override
  String get title => 'Title';

  @override
  String get type => 'Type';

  @override
  String get description => 'Description';

  @override
  String get preview => 'Preview';

  @override
  String get problemsTitle => 'Cannot save';

  @override
  String get formHasErrors =>
      'Some fields need attention. Check the messages under them.';

  @override
  String get mandatoryField => 'This field is mandatory.';

  @override
  String get notANumber => 'Not a number.';

  @override
  String get notAWholeNumber => 'Enter a whole number.';

  @override
  String get deleteTitle => 'Delete?';

  @override
  String deleteBody(String name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String newRecord(String doctype) {
    return 'New $doctype';
  }

  @override
  String fieldMissing(String field) {
    return '$field is mandatory.';
  }

  @override
  String rowProblem(int row, String problem) {
    return 'Row $row: $problem';
  }

  @override
  String rowNumber(int number) {
    return 'Row $number';
  }

  @override
  String get lockedAfterSubmit =>
      'Locked: documents have been submitted in this currency.';

  @override
  String get laterMilestone => 'Arrives with a later milestone.';

  @override
  String get refusedDuplicateName => 'A record with this name already exists.';

  @override
  String get refusedReferenced =>
      'This record is used elsewhere. Disable it instead of deleting it.';

  @override
  String get refusedLastEnabledPriceList =>
      'At least one Price List must stay enabled.';

  @override
  String refusedSeriesBelowUsed(String number) {
    return 'Number $number is already used in this series. Set $number or higher.';
  }

  @override
  String get refusedProfileSessionOpen =>
      'This POS Profile has an open POS session. Close the session first.';

  @override
  String get refusedGroupWarehouse =>
      'A group warehouse holds no stock. Choose a warehouse inside it.';

  @override
  String get refusedOneDefaultPayment =>
      'Exactly one payment method must be the default.';

  @override
  String get refusedOneDefaultProfile =>
      'Exactly one enabled POS Profile must be the default. Make another profile the default first.';

  @override
  String get refusedDisabledChoice =>
      'A disabled Price List, template or Mode of Payment cannot be chosen.';

  @override
  String get refusedNotABackup =>
      'This file is not a backup of this app. Nothing was changed.';

  @override
  String get refusedBackupTooNew =>
      'This backup comes from a newer version of the app. Update the app first.';

  @override
  String get refusedSessionOpen =>
      'Close the open POS session before restoring.';

  @override
  String get wizardLanguage => 'Language';

  @override
  String get wizardRegion => 'Region';

  @override
  String get wizardStore => 'Your store';

  @override
  String get wizardDone => 'All set';

  @override
  String wizardDoneBody(String store) {
    return '$store is ready to sell. Sales are tax-free until a Sales Taxes and Charges Template is chosen on the POS Profile.';
  }

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get openCashRegister => 'Open Cash Register';

  @override
  String get addFirstItem => 'Add your first item';

  @override
  String get groupStore => 'Store';

  @override
  String get groupSelling => 'Selling';

  @override
  String get groupTaxes => 'Taxes';

  @override
  String get groupStock => 'Stock';

  @override
  String get groupPrinting => 'Printing';

  @override
  String get groupData => 'Data';

  @override
  String get storeProfile => 'Store Profile';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get globalDefaults => 'Global Defaults';

  @override
  String get currency => 'Currency';

  @override
  String get posProfile => 'POS Profile';

  @override
  String get modeOfPayment => 'Mode of Payment';

  @override
  String get priceList => 'Price List';

  @override
  String get sellingSettings => 'Selling Settings';

  @override
  String get tax => 'Tax';

  @override
  String get salesTaxesTemplate => 'Sales Taxes and Charges Template';

  @override
  String get itemTaxTemplate => 'Item Tax Template';

  @override
  String get stockSettings => 'Stock Settings';

  @override
  String get printSettings => 'Print Settings';

  @override
  String get letterHead => 'Letter Head';

  @override
  String get printHeading => 'Print Heading';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get namingSeries => 'Naming Series';

  @override
  String get dataImport => 'Data Import';

  @override
  String get dataExport => 'Data Export';

  @override
  String get backups => 'Backups';

  @override
  String get sectionStore => 'Store';

  @override
  String get sectionSalesGoal => 'Sales Goal';

  @override
  String get sectionRegion => 'Region';

  @override
  String get sectionNumbers => 'Numbers';

  @override
  String get sectionBackups => 'Backups';

  @override
  String get sectionDefaults => 'Defaults';

  @override
  String get storeName => 'Store Name';

  @override
  String get abbreviation => 'Abbreviation';

  @override
  String get country => 'Country';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get monthlySalesTarget => 'Monthly Sales Target';

  @override
  String get language => 'Language';

  @override
  String get timeZone => 'Time Zone';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get numberFormat => 'Number Format';

  @override
  String get firstDayOfWeek => 'First Day of the Week';

  @override
  String get floatPrecision => 'Float Precision';

  @override
  String get currencyPrecision => 'Currency Precision';

  @override
  String get roundingMethod => 'Rounding Method';

  @override
  String get numberOfBackups => 'Number of Backups';

  @override
  String get hideCurrencySymbol => 'Hide Currency Symbol';

  @override
  String get disableRoundedTotal => 'Disable Rounded Total';

  @override
  String get disableInWords => 'Disable In Words';

  @override
  String get defaultPriceList => 'Default Price List';

  @override
  String get fallbackToDefaultPriceList =>
      'Use prices from Default Price List as fallback';

  @override
  String get editablePriceListRate =>
      'Allow editing Price List rate in transactions';

  @override
  String get validateSellingPrice =>
      'Validate selling price against purchase or valuation rate';

  @override
  String get currencyCode => 'Currency';

  @override
  String get symbol => 'Symbol';

  @override
  String get fraction => 'Fraction';

  @override
  String get fractionUnits => 'Fraction Units';

  @override
  String get smallestCurrencyFractionValue =>
      'Smallest Currency Fraction Value';

  @override
  String get symbolOnRight => 'Show Currency Symbol on Right Side';

  @override
  String get priceNotUomDependent => 'Price Not UOM Dependent';

  @override
  String get salesTaxesAndCharges => 'Sales Taxes and Charges';

  @override
  String get taxRate => 'Tax Rate';

  @override
  String get taxAmount => 'Tax Amount';

  @override
  String get amountPerUnit => 'Amount per unit';

  @override
  String get referenceRow => 'Reference Row #';

  @override
  String get includedInBasicRate => 'Is this Tax included in Basic Rate?';

  @override
  String get tryIt => 'Try it';

  @override
  String get tryItFixRows => 'Fix the rows above to see the amounts.';

  @override
  String get netTotal => 'Net Total';

  @override
  String get totalQuantity => 'Total Quantity';

  @override
  String get amount => 'Amount';

  @override
  String get total => 'Total';

  @override
  String get taxRowMissingTax => 'Tax is mandatory.';

  @override
  String get taxRowPreviousRowInFirstRow =>
      'The first row cannot be On Previous Row Amount or On Previous Row Total.';

  @override
  String get taxRowMissingReferenceRow =>
      'Reference Row # is mandatory for this type.';

  @override
  String get taxRowReferenceRowNotEarlier =>
      'Reference Row # must point to an earlier row.';

  @override
  String get taxRowActualIncluded =>
      'An Actual row cannot be included in the Basic Rate.';

  @override
  String get taxRowIncludedReferenceNotIncluded =>
      'The referenced row must also be included in the Basic Rate.';

  @override
  String get taxRowDuplicateTax => 'This tax is already in another row.';

  @override
  String get taxRates => 'Tax Rates';

  @override
  String get notApplicable => 'Not Applicable';

  @override
  String get itemTaxTemplateHelp =>
      'A rate here replaces the rate of the same tax for the items using this template. Not Applicable removes the tax; a rate of 0 keeps the item taxable at zero.';

  @override
  String get warehouse => 'Warehouse';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get allowInReturns => 'Allow in Returns';

  @override
  String get noPaymentMethodsHint => 'With no payment methods, Cash is used.';

  @override
  String get configurations => 'Configurations';

  @override
  String get hideImages => 'Hide images';

  @override
  String get hideUnavailableItems => 'Hide unavailable Items';

  @override
  String get allowRateChange => 'Allow User to Edit Rate';

  @override
  String get autoAddItemToCart => 'Automatically Add Filtered Item To Cart';

  @override
  String get allowDiscountChange => 'Allow User to Edit Discount';

  @override
  String get validateStockOnSave => 'Validate Stock on Save';

  @override
  String get setGrandTotalToDefaultMop =>
      'Set Grand Total to Default Payment Method';

  @override
  String get printReceiptOnOrderComplete => 'Print Receipt on Order Complete';

  @override
  String get actionOnNewInvoice => 'Action on New Invoice';

  @override
  String get itemGroups => 'Item Groups';

  @override
  String get itemGroupsHint =>
      'Only items in the chosen groups and their sub-groups are shown. None chosen shows every item.';

  @override
  String get printFormat => 'Print Format';

  @override
  String get pricingAndTaxes => 'Price List and Taxes';

  @override
  String get taxesAndCharges => 'Taxes and Charges';

  @override
  String get applyDiscountOn => 'Apply Discount On';

  @override
  String get documentType => 'Document';

  @override
  String get seriesList => 'Series List';

  @override
  String get newPattern => 'New series';

  @override
  String get namingSeriesHelp =>
      'The first series is the default. .YYYY. .YY. .MM. .DD. become the posting date; ##### is the counter (five digits when left out).';

  @override
  String get namingSeriesNeedsOne => 'A document needs at least one series.';

  @override
  String nextNameExample(String name) {
    return 'Next name: $name';
  }

  @override
  String get updateSeries => 'Update Series';

  @override
  String get prefix => 'Prefix';

  @override
  String get currentValue => 'Current Value';

  @override
  String get newCurrentValue => 'New Current Value';

  @override
  String get recordType => 'Document Type';

  @override
  String get insertNewRecords => 'Insert New Records';

  @override
  String get updateExistingRecords => 'Update Existing Records';

  @override
  String mandatoryColumns(String columns) {
    return 'Mandatory columns: $columns';
  }

  @override
  String get importNotes =>
      'Numbers use a dot for decimals; dates are YYYY-MM-DD; Maintain Stock and Is Sales Item are 1 or 0. Opening stock is entered through Stock Reconciliation.';

  @override
  String get downloadTemplate => 'Download Template';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get startImport => 'Start Import';

  @override
  String fileRows(String file, int count) {
    return '$file: $count rows';
  }

  @override
  String mapColumn(String header) {
    return 'Column \"$header\" is';
  }

  @override
  String get doNotImport => 'Do not import';

  @override
  String importWarnings(int count) {
    return 'Problems ($count). Nothing was imported; fix the file and choose it again.';
  }

  @override
  String importLog(int count) {
    return 'Import log ($count)';
  }

  @override
  String get row => 'Row';

  @override
  String get column => 'Column';

  @override
  String get problem => 'Problem';

  @override
  String get value => 'Value';

  @override
  String get created => 'Created';

  @override
  String get updated => 'Updated';

  @override
  String get importMissing => 'Missing mandatory value';

  @override
  String get importDuplicate => 'Duplicate Name';

  @override
  String get importNotFound => 'Record not found';

  @override
  String get importUnknownLink => 'Does not exist';

  @override
  String get importBadValue => 'Not an allowed value';

  @override
  String get importBadDate =>
      'Not a valid date, or Valid Upto is before Valid From';

  @override
  String get importBadBarcode => 'Not a valid barcode for this Barcode Type';

  @override
  String get importOverlappingPrice =>
      'Overlaps another price for the same item, price list and unit';

  @override
  String exportedRows(int count) {
    return '$count rows exported.';
  }

  @override
  String get backupWarning =>
      'Backups kept only on this device are lost with the device. Export them to another place.';

  @override
  String get backUpNow => 'Back up now';

  @override
  String get restoreFromFile => 'Restore from file';

  @override
  String get backedUp => 'Backup taken.';

  @override
  String get noBackups => 'No backups yet.';

  @override
  String sizeKb(String size) {
    return '$size KB';
  }

  @override
  String get restore => 'Restore';

  @override
  String get restoreTitle => 'Restore from a backup?';

  @override
  String get restoreBody =>
      'The current data is backed up first and then replaced by the file you choose.';

  @override
  String get restored => 'Restored.';

  @override
  String get namingSeriesNoFiscalYear =>
      'There is no Fiscal Year: use .YYYY. instead of .FY.';

  @override
  String unexpectedError(String detail) {
    return 'Something went wrong: $detail';
  }

  @override
  String get wizardRestoreHint =>
      'Moving from another device? Restore a backup instead of setting up again.';

  @override
  String get restoreFromBackup => 'Restore from backup';
}

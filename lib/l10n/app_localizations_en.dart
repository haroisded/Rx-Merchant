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
  String get refusedDefaultPriceList =>
      'This is the Default Price List in Selling Settings, which the Cash Register sells from. It must stay enabled. Choose another Default Price List first.';

  @override
  String refusedSeriesBelowUsed(String number) {
    return 'Number $number is already used in this series. Set $number or higher.';
  }

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
    return '$store is ready to sell. Sales are tax-free until a Sales Taxes and Charges Template is made the Default.';
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
  String get posSettings => 'POS Settings';

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
  String get paymentMethods => 'Payment Methods';

  @override
  String get defaultModeOfPayment => 'Default Mode of Payment';

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
  String get printFormat => 'Print Format';

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

  @override
  String get groupItemsAndPricing => 'Items and Pricing';

  @override
  String get groupStockTransactions => 'Stock Transactions';

  @override
  String get groupSerialAndBatch => 'Serial No and Batch';

  @override
  String get groupSettings => 'Settings';

  @override
  String get groupReports => 'Reports';

  @override
  String get item => 'Item';

  @override
  String get itemGroup => 'Item Group';

  @override
  String get itemPrice => 'Item Price';

  @override
  String get brand => 'Brand';

  @override
  String get itemAttribute => 'Item Attribute';

  @override
  String get stockEntry => 'Stock Entry';

  @override
  String get stockReconciliation => 'Stock Reconciliation';

  @override
  String get serialNo => 'Serial No';

  @override
  String get batch => 'Batch';

  @override
  String get warehouse => 'Warehouse';

  @override
  String get uom => 'UOM';

  @override
  String get reportStockLedger => 'Stock Ledger';

  @override
  String get reportStockBalance => 'Stock Balance';

  @override
  String get reportQuickStockBalance => 'Quick Stock Balance';

  @override
  String get reportBatchBalance => 'Batch-wise Balance History';

  @override
  String get reportSerialNoLedger => 'Serial No Ledger';

  @override
  String get reportItemPriceStock => 'Item Price Stock';

  @override
  String get reportLowStock => 'Low Stock';

  @override
  String get all => 'All';

  @override
  String get edit => 'Edit';

  @override
  String get create => 'Create';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get scan => 'Scan';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get filters => 'Filters';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get note => 'Note';

  @override
  String get rate => 'Rate';

  @override
  String get qty => 'Qty';

  @override
  String get quantity => 'Quantity';

  @override
  String get items => 'Items';

  @override
  String get totals => 'Totals';

  @override
  String get purpose => 'Purpose';

  @override
  String get remarks => 'Remarks';

  @override
  String get moreInformation => 'More Information';

  @override
  String get submit => 'Submit';

  @override
  String get submitTitle => 'Submit this document?';

  @override
  String get submitBody =>
      'A submitted document changes stock and cannot be edited. To change it later, cancel and amend it.';

  @override
  String get cancelDocument => 'Cancel';

  @override
  String get cancelTitle => 'Cancel this document?';

  @override
  String get cancelBody =>
      'Its stock movements are reversed. The document stays, marked Cancelled.';

  @override
  String get amend => 'Amend';

  @override
  String get noItems => 'Add at least one item.';

  @override
  String get noEntries => 'No entries for these filters';

  @override
  String get treeView => 'Tree view';

  @override
  String get listView => 'List view';

  @override
  String get addChild => 'Add Child';

  @override
  String get isGroup => 'Is Group';

  @override
  String get image => 'Image';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get chooseWarehouseFirst => 'Choose the Default Warehouse first.';

  @override
  String get csvRowInvalid =>
      'Item Code, Warehouse or Quantity is missing or not found.';

  @override
  String get validFrom => 'Valid From';

  @override
  String get validUpto => 'Valid Upto';

  @override
  String get validUptoBeforeFrom => 'Valid Upto is before Valid From.';

  @override
  String get inLabel => 'In';

  @override
  String get outLabel => 'Out';

  @override
  String draftNumber(int id) {
    return 'Draft $id';
  }

  @override
  String pageOf(int page, int pages) {
    return '$page of $pages';
  }

  @override
  String barcodeNotFound(String code) {
    return 'No item has the barcode $code.';
  }

  @override
  String csvHeadersChanged(String columns) {
    return 'The file must have these columns, spelled exactly: $columns.';
  }

  @override
  String rowsLoaded(String count) {
    return '$count rows loaded';
  }

  @override
  String get itemCode => 'Item Code';

  @override
  String get itemCodeBySeries =>
      'Item Code (set on save from the naming series)';

  @override
  String get itemName => 'Item Name';

  @override
  String get defaultUom => 'Default Unit of Measure';

  @override
  String get maintainStock => 'Maintain Stock';

  @override
  String get hasVariants => 'Has Variants';

  @override
  String get openingStock => 'Opening Stock';

  @override
  String get valuationRate => 'Valuation Rate';

  @override
  String get standardSellingRate => 'Standard Selling Rate';

  @override
  String get barcodes => 'Barcodes';

  @override
  String get barcode => 'Barcode';

  @override
  String get barcodeType => 'Barcode Type';

  @override
  String get badBarcodeHelp =>
      'EAN needs 13 digits with a valid check digit; UPC needs 12 digits.';

  @override
  String get shelfLifeInDays => 'Shelf Life In Days';

  @override
  String get endOfLife => 'End of Life';

  @override
  String get warrantyPeriodDays => 'Warranty Period (in days)';

  @override
  String get valuationMethod => 'Valuation Method';

  @override
  String get asInStockSettings => 'As in Stock Settings';

  @override
  String get allowNegativeStock => 'Allow Negative Stock';

  @override
  String get defaultWarehouse => 'Default Warehouse';

  @override
  String get unitsOfMeasure => 'Units of Measure';

  @override
  String get conversionFactor => 'Conversion Factor';

  @override
  String get autoReorder => 'Auto Reorder';

  @override
  String get reorderLevel => 'Re-order Level';

  @override
  String get reorderQty => 'Re-order Qty';

  @override
  String get hasBatchNo => 'Has Batch No';

  @override
  String get createNewBatch => 'Automatically Create New Batch';

  @override
  String get batchNumberSeries => 'Batch Number Series';

  @override
  String get hasExpiryDate => 'Has Expiry Date';

  @override
  String get hasSerialNo => 'Has Serial No';

  @override
  String get serialNoSeries => 'Serial Number Series';

  @override
  String get defaultSalesUom => 'Default Sales Unit of Measure';

  @override
  String get maxDiscount => 'Max Discount (%)';

  @override
  String get isSalesItem => 'Is Sales Item';

  @override
  String get tabDetails => 'Details';

  @override
  String get tabInventory => 'Inventory';

  @override
  String get tabVariants => 'Variants';

  @override
  String get tabSales => 'Sales';

  @override
  String get tabTax => 'Tax';

  @override
  String get lockedAfterStock =>
      'Read-only: this item already has stock ledger entries.';

  @override
  String get addItem => 'Add Item';

  @override
  String get importItems => 'Import items';

  @override
  String get searchItems => 'Item Code, Item Name or barcode';

  @override
  String get addPrice => 'Add price';

  @override
  String get stockLevels => 'Stock Levels';

  @override
  String get itemTaxHelp =>
      'The template whose Valid From is the latest on or before the sale applies; without one, the Item Group\'s template applies.';

  @override
  String get itemCodificationTitle => 'Item Codification';

  @override
  String get itemCodificationHelp =>
      'For a small catalogue, keep the Item Code and Item Name the same. For a large one, use a meaningful code scheme, for example a group prefix and a running number, and keep the description in the Item Name.';

  @override
  String get variantOf => 'Variant Of';

  @override
  String get variants => 'Variants';

  @override
  String get attributes => 'Attributes';

  @override
  String get singleVariant => 'Single Variant';

  @override
  String get multipleVariants => 'Multiple Variants';

  @override
  String get variantsHelp =>
      'Turn on Has Variants to make this item a template, then add its attributes.';

  @override
  String variantsCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variants created',
      one: '1 variant created',
      zero: 'No new variants: they all exist',
    );
    return '$_temp0';
  }

  @override
  String variantsToCreate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variants',
      one: '1 variant',
      zero: 'Tick at least one value per attribute',
    );
    return '$_temp0';
  }

  @override
  String get attributeName => 'Attribute Name';

  @override
  String get numericValues => 'Numeric Values';

  @override
  String get fromRange => 'From Range';

  @override
  String get toRange => 'To Range';

  @override
  String get increment => 'Increment';

  @override
  String get attributeValues => 'Item Attribute Values';

  @override
  String get attributeValue => 'Attribute Value';

  @override
  String get badNumericRange =>
      'The range must give at least one value: Increment above 0 and To Range at or above From Range.';

  @override
  String get attributeNeedsValues => 'Add at least one value.';

  @override
  String get mustBeWholeNumber => 'Must be Whole Number';

  @override
  String get warehouseName => 'Warehouse Name';

  @override
  String get parentWarehouse => 'Parent Warehouse';

  @override
  String get warehouseType => 'Warehouse Type';

  @override
  String get itemGroupName => 'Item Group Name';

  @override
  String get parentItemGroup => 'Parent Item Group';

  @override
  String get itemNamingBy => 'Item Naming By';

  @override
  String get defaultItemGroup => 'Default Item Group';

  @override
  String get defaultStockUom => 'Default Stock UOM';

  @override
  String get defaultValuationMethod => 'Default Valuation Method';

  @override
  String get lockedValuationMethod =>
      'Locked: items that follow this method already have stock.';

  @override
  String get sectionStockTransactions => 'Stock Transactions Settings';

  @override
  String get showBarcodeField => 'Show Barcode Field';

  @override
  String get autoInsertPriceListRate =>
      'Auto insert Price List rate if missing';

  @override
  String get showLowStockAlerts => 'Show low-stock alerts';

  @override
  String get stockFrozenUpto => 'Stock Frozen Upto';

  @override
  String get enableSerialAndBatch => 'Enable Serial and Batch No for Item';

  @override
  String get pickSerialBatchBasedOn => 'Pick Serial / Batch Based On';

  @override
  String get autoCreateBundleForOutward =>
      'Auto Create Serial and Batch Bundle For Outward';

  @override
  String get batchId => 'Batch ID';

  @override
  String get manufacturingDate => 'Manufacturing Date';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get batchNotSet => 'Not Set';

  @override
  String get batchNotExpired => 'Not Expired';

  @override
  String get batchExpired => 'Expired';

  @override
  String get warrantyExpiryDate => 'Warranty Expiry Date';

  @override
  String get serialBatchEntries => 'Serial / Batch Entries';

  @override
  String get autoFetch => 'Auto Fetch';

  @override
  String get createSerialsFromRange => 'Create Serial Nos from Range';

  @override
  String get serialRange => 'Range';

  @override
  String get badSerialRange => 'Type a range such as SN-01::10.';

  @override
  String serialScannedTwice(String serial) {
    return '$serial is already in the list.';
  }

  @override
  String serialStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'Inactive': 'Inactive',
      'Available': 'Available',
      'Delivered': 'Delivered',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get materialReceipt => 'Material Receipt';

  @override
  String get materialIssue => 'Material Issue';

  @override
  String get materialTransfer => 'Material Transfer';

  @override
  String get editPostingDateTime => 'Edit Posting Date and Time';

  @override
  String get postingDateTime => 'Posting Date and Time';

  @override
  String get defaultSourceWarehouse => 'Default Source Warehouse';

  @override
  String get defaultTargetWarehouse => 'Default Target Warehouse';

  @override
  String get sourceWarehouse => 'Source Warehouse';

  @override
  String get targetWarehouse => 'Target Warehouse';

  @override
  String get stockQty => 'Qty as per Stock UOM';

  @override
  String get basicRatePerStockUom => 'Basic Rate (as per Stock UOM)';

  @override
  String get allowZeroValuationRate => 'Allow Zero Valuation Rate';

  @override
  String get additionalCosts => 'Additional Costs';

  @override
  String get totalOutgoingValue => 'Total Outgoing Value';

  @override
  String get totalIncomingValue => 'Total Incoming Value';

  @override
  String get totalAdditionalCosts => 'Total Additional Costs';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get isOpening => 'Is Opening';

  @override
  String get scanMode => 'Scan Mode';

  @override
  String get fetchItems => 'Fetch Items from Warehouse';

  @override
  String get currentQty => 'Current Qty';

  @override
  String get currentValuationRate => 'Current Valuation Rate';

  @override
  String get quantityDifference => 'Quantity Difference';

  @override
  String get amountDifference => 'Amount Difference';

  @override
  String get differenceAmount => 'Difference Amount';

  @override
  String get stockUom => 'Stock UOM';

  @override
  String get inQty => 'In Qty';

  @override
  String get outQty => 'Out Qty';

  @override
  String get balanceQty => 'Balance Qty';

  @override
  String get incomingRate => 'Incoming Rate';

  @override
  String get balanceValue => 'Balance Value';

  @override
  String get valueChange => 'Value Change';

  @override
  String get voucherType => 'Voucher Type';

  @override
  String get voucherNo => 'Voucher #';

  @override
  String get openingQty => 'Opening Qty';

  @override
  String get openingValue => 'Opening Value';

  @override
  String get inValue => 'In Value';

  @override
  String get outValue => 'Out Value';

  @override
  String get inOrOut => 'In / Out';

  @override
  String get availableQty => 'Available Qty';

  @override
  String get actualQty => 'Actual Qty';

  @override
  String get shortage => 'Shortage';

  @override
  String get lineMissingItem => 'Item is missing.';

  @override
  String get lineQtyNotPositive => 'Quantity must be above zero.';

  @override
  String get lineSourceRequired => 'Source Warehouse is mandatory.';

  @override
  String get lineTargetRequired => 'Target Warehouse is mandatory.';

  @override
  String get lineSameWarehouse =>
      'Source and Target Warehouse cannot be the same.';

  @override
  String get lineGroupWarehouse =>
      'A group or disabled warehouse cannot be used in a transaction.';

  @override
  String get lineFraction => 'Quantity cannot be a fraction.';

  @override
  String get lineItemDisabled => 'Item is disabled.';

  @override
  String get lineItemEndOfLife => 'Item has reached its End of Life.';

  @override
  String get lineItemTemplate =>
      'Item is a template: choose one of its variants.';

  @override
  String get lineItemNotStock => 'Item does not maintain stock.';

  @override
  String get lineZeroRate =>
      'Valuation Rate is mandatory. Tick Allow Zero Valuation Rate to receive at zero.';

  @override
  String get lineSerialCount =>
      'The quantity must be a whole number equal to the number of serial numbers.';

  @override
  String get lineEntriesQty =>
      'The Serial / Batch Entries must add up to the quantity.';

  @override
  String get lineBatchOrSerialItem =>
      'Batch and serial items are counted with a Stock Entry (Material Receipt or Issue), not here.';

  @override
  String get lineDuplicateRow =>
      'This item and warehouse are already on another row.';

  @override
  String lineFractionAt(int row) {
    return 'Quantity cannot be a fraction at row $row';
  }

  @override
  String refusedNegativeStock(
    String item,
    String warehouse,
    String available,
    String needed,
    String date,
    String voucher,
  ) {
    return '$needed units of $item needed in $warehouse on $date for $voucher to complete this transaction. Available then: $available.';
  }

  @override
  String refusedNegativeBatch(
    String batch,
    String item,
    String warehouse,
    String date,
    String voucher,
  ) {
    return 'Batch $batch of $item would go below zero in $warehouse on $date for $voucher.';
  }

  @override
  String refusedStockFrozen(String date) {
    return 'Stock is frozen up to $date: nothing on or before it can be submitted or cancelled.';
  }

  @override
  String get refusedHasVariantsLocked =>
      'Has Variants cannot change once the item has variants or stock.';

  @override
  String refusedTemplate(String item) {
    return '$item is a template: it has no price and cannot be moved.';
  }

  @override
  String refusedUnitInUse(String uom) {
    return '$uom is used on a document: it cannot be removed or have its Conversion Factor changed.';
  }

  @override
  String refusedBarcodeTaken(String item) {
    return 'This barcode belongs to item $item.';
  }

  @override
  String refusedBadBarcode(String barcode) {
    return '$barcode is not a valid barcode for its type.';
  }

  @override
  String get refusedDefaultWarehouse =>
      'This is the Default Warehouse in Stock Settings, which the Cash Register sells from. It must stay enabled and cannot be a group. Choose another Default Warehouse first.';

  @override
  String get refusedWarehouseHasLedger =>
      'A warehouse with stock ledger entries cannot become a group.';

  @override
  String refusedBatchRequired(String item) {
    return 'Enter a Batch for $item, or turn on Automatically Create New Batch.';
  }

  @override
  String refusedSerialRequired(String item) {
    return 'Enter the serial numbers of $item, or set its Serial Number Series.';
  }

  @override
  String refusedNotEnoughEntries(String item) {
    return 'Not enough serial numbers or batches of $item in the source warehouse. Choose them in Serial / Batch Entries.';
  }

  @override
  String refusedExpiredBatch(String batch) {
    return 'Batch $batch has expired: it can leave stock only through a Material Issue.';
  }

  @override
  String refusedBatchNotFound(String batch) {
    return 'Batch $batch does not exist for this item.';
  }

  @override
  String refusedSerialNotAvailable(String serial) {
    return 'Serial No $serial is not Available in the source warehouse.';
  }

  @override
  String refusedSerialExists(String serial) {
    return 'Serial No $serial already exists in stock.';
  }

  @override
  String refusedSerialMovedSince(String serial) {
    return 'Serial No $serial has moved since this entry. Cancel the later documents first.';
  }

  @override
  String get refusedDocstatus =>
      'This document has changed since it was opened. Open it again.';

  @override
  String get lineDuplicateSerial =>
      'A serial number is listed twice. Each serial number is one unit and can be on one line only.';

  @override
  String refusedExpiryRequired(String batch) {
    return 'Batch $batch needs an Expiry Date: its item has Has Expiry Date and no Shelf Life In Days to work it out from.';
  }
}

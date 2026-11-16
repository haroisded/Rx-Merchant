/// STK-R8: an EAN barcode is 13 digits with a valid check digit, a UPC
/// barcode 12 digits. Any other non-empty value is accepted when the Barcode
/// Type is blank.
bool validBarcode(String? type, String value) {
  final digitsOnly = RegExp(r'^\d+$').hasMatch(value);
  return switch (type) {
    'EAN' => value.length == 13 && digitsOnly && _checkDigitOk(value),
    'UPC' => value.length == 12 && digitsOnly,
    _ => value.isNotEmpty,
  };
}

/// GTIN check digit: from the right, excluding the check digit, weights
/// alternate 3, 1, 3, …
bool _checkDigitOk(String code) {
  var sum = 0;
  for (var i = code.length - 2, w = 3; i >= 0; i--, w = 4 - w) {
    sum += int.parse(code[i]) * w;
  }
  return (10 - sum % 10) % 10 == int.parse(code[code.length - 1]);
}

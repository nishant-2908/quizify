import 'package:flutter/services.dart';

/// Allows only non-negative numbers with up to [decimalRange] decimal places.
///
/// Permits intermediate editing states like "" and "12.".
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // Disallow negative sign explicitly.
    if (text.contains('-')) return oldValue;

    // Only digits and at most one dot.
    final dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) return oldValue;
    if (!RegExp(r'^[0-9.]*$').hasMatch(text)) return oldValue;

    if (decimalRange == 0) {
      if (text.contains('.')) return oldValue;
      return newValue;
    }

    // Enforce up to decimalRange digits after dot.
    final dotIndex = text.indexOf('.');
    if (dotIndex >= 0) {
      final decimals = text.substring(dotIndex + 1);
      if (decimals.length > decimalRange) return oldValue;
    }

    return newValue;
  }
}


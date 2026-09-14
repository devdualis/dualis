import 'dart:math';
import 'package:flutter/services.dart';

/// Formats numeric input into Brazilian standard date mask: DD/MM/AAAA.
///
/// Automatically inserts slashes as the user types, supports direct typing,
/// copy-paste of 8 digits, and handles backspacing cleanly without cursor trapping.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Extract only digits from new input
    String digitsOnly = newText.replaceAll(RegExp(r'\D'), '');

    // Handle backspace when user deletes a slash
    if (oldText.length > newText.length) {
      final selectionOffset = newValue.selection.baseOffset;
      if (selectionOffset >= 0 &&
          selectionOffset < oldText.length &&
          oldText[selectionOffset] == '/') {
        // Find which digit index preceded this slash and remove it
        int digitIndex = 0;
        for (int i = 0; i < selectionOffset; i++) {
          if (RegExp(r'\d').hasMatch(oldText[i])) {
            digitIndex++;
          }
        }
        final oldDigits = oldText.replaceAll(RegExp(r'\D'), '');
        if (digitIndex > 0 && digitIndex <= oldDigits.length) {
          digitsOnly = oldDigits.substring(0, digitIndex - 1) +
              oldDigits.substring(digitIndex);
        }
      }
    }

    // Limit to max 8 digits (DDMMAAAA)
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    // Count how many digits were before the cursor in newValue
    int targetDigitCount = 0;
    for (int i = 0; i < min(newValue.selection.end, newText.length); i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        targetDigitCount++;
      }
    }
    if (targetDigitCount > digitsOnly.length) {
      targetDigitCount = digitsOnly.length;
    }

    // Build the formatted string
    final buffer = StringBuffer();
    int selectionIndex = 0;
    int digitCount = 0;

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
        if (digitCount == targetDigitCount && selectionIndex == 0) {
          selectionIndex = buffer.length - 1;
        }
      }
      buffer.write(digitsOnly[i]);
      digitCount++;
      if (digitCount == targetDigitCount) {
        selectionIndex = buffer.length;
      }
    }

    // If cursor was at the end of input or past it
    if (newValue.selection.end >= newText.length) {
      selectionIndex = buffer.length;
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: min(selectionIndex, formatted.length),
      ),
    );
  }
}

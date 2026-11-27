import '../../../l10n/app_localizations.dart';

class FormValidators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',
  );

  /// Validates Full Name: must be at least 3 characters and contain at least two words.
  static String? validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.formErrorName;
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return l10n.formErrorName;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 2 || words.any((w) => w.isEmpty)) {
      return l10n.formErrorName;
    }
    return null;
  }

  /// Validates Email: standard RFC 5322 format.
  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.formErrorEmail;
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return l10n.formErrorEmail;
    }
    return null;
  }

  /// Validates Password: >= 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char.
  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.formErrorPassword;
    }
    if (value.length < 8 || !_passwordRegExp.hasMatch(value)) {
      return l10n.formErrorPassword;
    }
    return null;
  }

  /// Validates Date of Birth: must be in past, user age between 13 and 120 years.
  static String? validateDateOfBirth(dynamic date, AppLocalizations l10n) {
    DateTime? parsedDate;
    if (date is DateTime) {
      parsedDate = date;
    } else if (date is String) {
      final trimmed = date.trim();
      if (trimmed.isEmpty) {
        return l10n.addDependentDobInvalid;
      }
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            final candidate = DateTime.tryParse(
              '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
            );
            if (candidate != null && candidate.day == day && candidate.month == month) {
              parsedDate = candidate;
            }
          }
        }
      } else if (trimmed.length == 8 && RegExp(r'^\d{8}$').hasMatch(trimmed)) {
        final day = int.tryParse(trimmed.substring(0, 2));
        final month = int.tryParse(trimmed.substring(2, 4));
        final year = int.tryParse(trimmed.substring(4, 8));
        if (day != null && month != null && year != null) {
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            final candidate = DateTime.tryParse(
              '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
            );
            if (candidate != null && candidate.day == day && candidate.month == month) {
              parsedDate = candidate;
            }
          }
        }
      } else {
        parsedDate = DateTime.tryParse(trimmed);
      }
    }

    if (parsedDate == null) {
      return l10n.addDependentDobInvalid;
    }

    final now = DateTime.now();
    if (parsedDate.isAfter(now)) {
      return l10n.addDependentDobFuture;
    }

    int age = now.year - parsedDate.year;
    if (now.month < parsedDate.month ||
        (now.month == parsedDate.month && now.day < parsedDate.day)) {
      age--;
    }

    if (age < 13) {
      return l10n.formErrorMinAge;
    }
    if (age > 120) {
      return l10n.addDependentDobInvalid;
    }

    return null;
  }
}

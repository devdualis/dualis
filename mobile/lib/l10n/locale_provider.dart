import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const supportedLocales = [
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('en'),
  ];

  static const _supportedLanguageCodes = ['pt', 'es', 'en'];

  @override
  Locale build() {
    return const Locale('pt', 'BR');
  }

  void setLocale(Locale locale) {
    if (_supportedLanguageCodes.contains(locale.languageCode)) {
      state = locale;
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

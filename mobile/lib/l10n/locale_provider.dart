import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/secure_storage_service.dart';

/// Replaces the device's preferred languages in tests
/// (see test/flutter_test_config.dart). Null reads the real ones.
@visibleForTesting
List<Locale>? debugDeviceLocales;

const _byLanguageCode = {
  'pt': Locale('pt', 'BR'),
  'es': Locale('es'),
  'en': Locale('en'),
};

List<Locale> _platformLocales() {
  try {
    return WidgetsBinding.instance.platformDispatcher.locales;
  } catch (_) {
    return PlatformDispatcher.instance.locales; // background isolate
  }
}

/// The app language for the device's preferred languages: the first supported
/// one, or English (like the iOS permission prompts).
Locale resolveSystemLocale() {
  final preferred = debugDeviceLocales ?? _platformLocales();
  for (final locale in preferred) {
    final match = _byLanguageCode[locale.languageCode];
    if (match != null) return match;
  }
  return const Locale('en');
}

/// The language chosen in the app, or null when none was saved. Never throws
/// and never waits long: startup must not depend on the keychain.
Future<Locale?> loadSavedLocale(
  SecureStorageService storage, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final code = await storage
        .read(key: SecureStorageService.keyAppLanguage)
        .timeout(timeout);
    return _byLanguageCode[code];
  } catch (_) {
    return null;
  }
}

/// The saved choice read before the first frame (overridden in main).
final savedLocaleProvider = Provider<Locale?>((ref) => null);

/// The effective app language: the person's choice when there is one,
/// otherwise the system language, followed while the app runs.
class LocaleNotifier extends Notifier<Locale> {
  static const supportedLocales = [
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('en'),
  ];

  Locale? _choice;

  @override
  Locale build() {
    _choice ??= ref.watch(savedLocaleProvider);

    // Unit tests without a widgets binding have no system changes to follow.
    try {
      final binding = WidgetsBinding.instance;
      final observer = _SystemLocaleObserver(() {
        if (_choice == null) state = resolveSystemLocale();
      });
      binding.addObserver(observer);
      ref.onDispose(() => binding.removeObserver(observer));
    } catch (_) {}

    return _choice ?? resolveSystemLocale();
  }

  /// Applies and remembers the person's choice.
  Future<void> setLocale(Locale locale) async {
    final choice = _byLanguageCode[locale.languageCode];
    if (choice == null) return;
    _choice = choice;
    state = choice;
    try {
      await ref.read(secureStorageServiceProvider).write(
            key: SecureStorageService.keyAppLanguage,
            value: choice.languageCode,
          );
    } catch (_) {
      // The choice still applies until the app is closed.
    }
  }
}

class _SystemLocaleObserver with WidgetsBindingObserver {
  _SystemLocaleObserver(this.onChange);

  final VoidCallback onChange;

  @override
  void didChangeLocales(List<Locale>? locales) => onChange();
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

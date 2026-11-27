import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/l10n/locale_provider.dart';
import 'package:dualis_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStorage extends SecureStorageService {
  @override
  Future<String?> read({required String key}) => throw Exception('keychain');

  @override
  Future<void> write({required String key, required String value}) =>
      throw Exception('keychain');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Locale>? configured;

  setUp(() {
    configured = debugDeviceLocales;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => debugDeviceLocales = configured);

  ProviderContainer container({Locale? saved}) {
    final c = ProviderContainer(
      overrides: [savedLocaleProvider.overrideWithValue(saved)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('follows the first supported system language', () {
    debugDeviceLocales = const [Locale('fr'), Locale('es', 'MX'), Locale('pt')];
    expect(container().read(localeProvider), const Locale('es'));

    debugDeviceLocales = const [Locale('pt', 'PT')];
    expect(container().read(localeProvider), const Locale('pt', 'BR'));
  });

  test('uses English when no system language is supported', () {
    debugDeviceLocales = const [Locale('de'), Locale('fr')];
    expect(container().read(localeProvider), const Locale('en'));
  });

  test('a choice is persisted and restored on the next launch', () async {
    final first = container();
    await first.read(localeProvider.notifier).setLocale(const Locale('es'));

    final saved = await loadSavedLocale(SecureStorageService());
    expect(saved, const Locale('es'));
    expect(container(saved: saved).read(localeProvider), const Locale('es'));
  });

  test('the choice survives the logout wipe', () async {
    final storage = SecureStorageService();
    await container()
        .read(localeProvider.notifier)
        .setLocale(const Locale('en'));
    await storage.clearSession();

    expect(await loadSavedLocale(storage), const Locale('en'));
  });

  test('a storage failure neither blocks startup nor the choice', () async {
    expect(await loadSavedLocale(_BrokenStorage()), isNull);

    final c = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(_BrokenStorage()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(localeProvider.notifier).setLocale(const Locale('es'));
    expect(c.read(localeProvider), const Locale('es'));
  });

  testWidgets('a system change applies only without a saved choice',
      (tester) async {
    debugDeviceLocales = null;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];

    await tester.pumpWidget(const ProviderScope(child: DualisApp()));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(DualisApp)));
    expect(c.read(localeProvider), const Locale('en'));

    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    await tester.pumpAndSettle();
    expect(c.read(localeProvider), const Locale('es'));

    await c.read(localeProvider.notifier).setLocale(const Locale('pt'));
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    await tester.pumpAndSettle();
    expect(c.read(localeProvider), const Locale('pt', 'BR'));
  });
}

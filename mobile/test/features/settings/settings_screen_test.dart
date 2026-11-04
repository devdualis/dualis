import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/biometric_lock_controller.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dualis_mobile/features/settings/presentation/widgets/avatar_selector_sheet.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeSecureStorageService extends SecureStorageService {
  String? persistedAccessToken;
  final Map<String, String> _mem = {};

  @override
  Future<String?> read({required String key}) async => _mem[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _mem[key] = value;
  }

  @override
  Future<bool> isPhotoFramingAdjusted() async =>
      _mem[SecureStorageService.keyPhotoFramingAdjusted] == 'true';

  @override
  Future<void> setPhotoFramingAdjusted([bool adjusted = true]) async {
    _mem[SecureStorageService.keyPhotoFramingAdjusted] = adjusted ? 'true' : 'false';
  }

  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    persistedAccessToken = accessToken;
  }

  @override
  Future<String?> getAccessToken() async => 'mock-jwt-token';

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> saveUserProfile(UserProfile user) async {}

  @override
  Future<UserProfile?> getUserProfile() async => null;
}

class FakeAuthRepository implements AuthRepository {
  bool updateProfileCalled = false;
  bool changePasswordCalled = false;
  String? lastUpdatedName;
  String? lastUpdatedDob;
  String? lastUpdatedPicture;
  String? lastCurrentPassword;
  String? lastNewPassword;

  final UserProfile mockUser;

  FakeAuthRepository({required this.mockUser});

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    return {'user': mockUser.toJson(), 'accessToken': 'mock-access', 'refreshToken': 'mock-refresh'};
  }

  @override
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return {};
  }

  @override
  Future<UserProfile> getProfile({required String token}) async {
    return mockUser;
  }

  @override
  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) async {
    updateProfileCalled = true;
    lastUpdatedName = name;
    lastUpdatedDob = dateOfBirth;
    lastUpdatedPicture = picture;
    return mockUser.copyWith(
      name: name ?? mockUser.name,
      dateOfBirth: dateOfBirth ?? mockUser.dateOfBirth,
      picture: picture ?? mockUser.picture,
    );
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return {
      'success': true,
      'accessToken': 'jwt-access-after-change',
      'refreshToken': 'jwt-refresh-after-change',
    };
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async =>
      {};
}

class _TestAuthController extends AuthController {
  final AuthState _initial;
  _TestAuthController(this._initial);

  @override
  AuthState build() => _initial;
}

List<Override> _settingsOverrides({
  required FakeAuthRepository repository,
  required UserProfile user,
  FakeSecureStorageService? storage,
  bool premium = false,
}) {
  final authState = AuthState(
    isAuthenticated: true,
    user: user,
    accessToken: 'mock-jwt-token',
  );
  return [
    authRepositoryProvider.overrideWithValue(repository),
    secureStorageServiceProvider.overrideWithValue(storage ?? FakeSecureStorageService()),
    authControllerProvider.overrideWith(() => _TestAuthController(authState)),
    premiumProfilesEnabledProvider.overrideWithValue(premium),
    // Keeps the Premium-only BiometricLockTile off the device channel.
    biometricSupportedProvider.overrideWith((ref) async => false),
  ];
}

Widget createSettingsTestApp({
  required FakeAuthRepository repository,
  required UserProfile user,
  FakeSecureStorageService? storage,
  bool premium = false,
}) {
  return ProviderScope(
    overrides: _settingsOverrides(
      repository: repository,
      user: user,
      storage: storage,
      premium: premium,
    ),
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('pt', 'BR'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: Locale('pt', 'BR'),
      home: SettingsScreen(),
    ),
  );
}

/// Same overrides as [createSettingsTestApp], under a GoRouter so
/// `context.push` from the settings screen can be exercised.
Widget createSettingsRouterTestApp({
  required FakeAuthRepository repository,
  required UserProfile user,
  FakeSecureStorageService? storage,
  bool premium = false,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.settings,
    routes: [
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.premiumPromo,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Premium Promo Screen')),
        ),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: _settingsOverrides(
      repository: repository,
      user: user,
      storage: storage,
      premium: premium,
    ),
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('pt', 'BR'),
    ),
  );
}

void main() {
  group('SettingsScreen Widget Tests', () {
    late UserProfile testUser;
    late FakeAuthRepository fakeRepo;

    setUp(() {
      testUser = const UserProfile(
        id: 'usr-1234',
        name: 'Ricardo Rincon',
        email: 'ricardo@dualis.com.br',
        gender: Gender.masculino,
        dateOfBirth: '1990-05-15',
        picture: 'avatar_doctor',
      );
      fakeRepo = FakeAuthRepository(mockUser: testUser);
    });

    testWidgets('1. Renders profile fields, avatar, age badge, and security section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Perfil e Identificação'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byKey(const Key('settings_name_input')), findsOneWidget);
      expect(find.text('Ricardo Rincon'), findsOneWidget);
      expect(find.byKey(const Key('settings_dob_picker')), findsOneWidget);
      expect(find.byKey(const Key('settings_age_badge')), findsOneWidget);
      expect(find.byKey(const Key('settings_save_profile_button')), findsOneWidget);
      expect(find.text('Segurança e Acesso'), findsOneWidget);
      expect(find.byKey(const Key('settings_current_password_input')), findsOneWidget);
      expect(find.byKey(const Key('settings_new_password_input')), findsOneWidget);
      expect(find.byKey(const Key('settings_confirm_password_input')), findsOneWidget);
      expect(find.byKey(const Key('settings_change_password_button')), findsOneWidget);
    });

    testWidgets('2. Alterar Foto offers camera, gallery and avatars', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      final changeAvatarBtn = find.text('Alterar Foto');
      await tester.ensureVisible(changeAvatarBtn);
      await tester.tap(changeAvatarBtn);
      await tester.pumpAndSettle();

      expect(find.text('Câmera'), findsOneWidget);
      expect(find.text('Galeria'), findsOneWidget);
      await tester.tap(find.text('Avatares'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarSelectorSheet), findsOneWidget);
      expect(find.text('Escolha seu Avatar'), findsOneWidget);
      expect(find.text('Confirmar Avatar'), findsOneWidget);

      await tester.tap(find.text('Confirmar Avatar'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarSelectorSheet), findsNothing);
    });

    testWidgets('3. Updating name calls updateProfile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      final nameInput = find.byKey(const Key('settings_name_input'));
      await tester.ensureVisible(nameInput);
      await tester.enterText(nameInput, 'Ricardo Rincon Silva');

      final saveButton = find.byKey(const Key('settings_save_profile_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.updateProfileCalled, isTrue);
      expect(fakeRepo.lastUpdatedName, 'Ricardo Rincon Silva');
    });

    testWidgets('4. Password validation fails when passwords mismatch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      final curPass = find.byKey(const Key('settings_current_password_input'));
      await tester.ensureVisible(curPass);
      await tester.enterText(curPass, 'OldPass123!');

      final newPass = find.byKey(const Key('settings_new_password_input'));
      await tester.ensureVisible(newPass);
      await tester.enterText(newPass, 'NewPass123!');

      final confPass = find.byKey(const Key('settings_confirm_password_input'));
      await tester.ensureVisible(confPass);
      await tester.enterText(confPass, 'DifferentPass123!');

      final changeBtn = find.byKey(const Key('settings_change_password_button'));
      await tester.ensureVisible(changeBtn);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(find.text('As novas senhas não coincidem.'), findsOneWidget);
      expect(fakeRepo.changePasswordCalled, isFalse);
    });

    testWidgets('5. Changing password successfully invokes changePassword', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final storage = FakeSecureStorageService();
      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser, storage: storage));
      await tester.pumpAndSettle();

      final curPass = find.byKey(const Key('settings_current_password_input'));
      await tester.ensureVisible(curPass);
      await tester.enterText(curPass, 'OldPass123!');

      final newPass = find.byKey(const Key('settings_new_password_input'));
      await tester.ensureVisible(newPass);
      await tester.enterText(newPass, 'BrandNewPass123!');

      final confPass = find.byKey(const Key('settings_confirm_password_input'));
      await tester.ensureVisible(confPass);
      await tester.enterText(confPass, 'BrandNewPass123!');

      final changeBtn = find.byKey(const Key('settings_change_password_button'));
      await tester.ensureVisible(changeBtn);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.changePasswordCalled, isTrue);
      expect(fakeRepo.lastCurrentPassword, 'OldPass123!');
      expect(fakeRepo.lastNewPassword, 'BrandNewPass123!');
      // The server ends every session on a password change: this device keeps the new tokens.
      expect(storage.persistedAccessToken, 'jwt-access-after-change');
    });

    testWidgets('6. Renders Seus registros e hábitos section with plain subtitles and Privacy separately', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      // Section "Seus registros e hábitos"
      expect(find.text('Seus registros e hábitos'), findsOneWidget);

      final historyTile = find.byKey(const Key('settings_history_tile'));
      await tester.ensureVisible(historyTile);
      expect(find.text('Histórico e Tendências'), findsOneWidget);
      expect(find.text('Veja tudo o que você registrou, dia a dia'), findsOneWidget);

      final hydrationTile = find.byKey(const Key('settings_hydration_tile'));
      await tester.ensureVisible(hydrationTile);
      expect(find.text('Lembretes e Hidratação'), findsOneWidget);
      expect(find.text('Escolha quando lembrar de beber água'), findsOneWidget);

      // Section "Privacidade e Dados"
      final privacySection = find.text('Privacidade e Dados');
      await tester.ensureVisible(privacySection);
      expect(privacySection, findsOneWidget);

      final privacyTile = find.byKey(const Key('settings_privacy_tile'));
      await tester.ensureVisible(privacyTile);
      expect(find.text('Central de Privacidade e LGPD'), findsOneWidget);
      expect(find.text('Veja, baixe ou apague seus dados'), findsOneWidget);
    });

    testWidgets('7. Shows one-time photo adjust hint for custom photo when not yet adjusted', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const customPhotoUser = UserProfile(
        id: 'usr-custom',
        name: 'Maria Silva',
        email: 'maria@dualis.com.br',
        gender: Gender.feminino,
        picture: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      final repo = FakeAuthRepository(mockUser: customPhotoUser);
      final storage = FakeSecureStorageService();

      await tester.pumpWidget(createSettingsTestApp(repository: repo, user: customPhotoUser, storage: storage));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photo_adjust_hint')), findsOneWidget);
      expect(find.text('Toque para ajustar sua foto'), findsOneWidget);
    });

    testWidgets('8. Does not show photo adjust hint if already adjusted or preset avatar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Case A: Preset avatar does not show hint
      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo_adjust_hint')), findsNothing);

      // Case B: Custom photo that has already been adjusted does not show hint
      const customPhotoUser = UserProfile(
        id: 'usr-custom',
        name: 'Maria Silva',
        email: 'maria@dualis.com.br',
        gender: Gender.feminino,
        picture: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      final repo = FakeAuthRepository(mockUser: customPhotoUser);
      final storage = FakeSecureStorageService();
      await storage.setPhotoFramingAdjusted(true);

      await tester.pumpWidget(createSettingsTestApp(repository: repo, user: customPhotoUser, storage: storage));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo_adjust_hint')), findsNothing);
    });

    testWidgets('9. Free build shows "Plano: Gratuito" with a Ver Premium link to the promo page',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsRouterTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      final planTile = find.byKey(const Key('settings_plan_tile'));
      await tester.ensureVisible(planTile);
      await tester.pumpAndSettle();
      expect(planTile, findsOneWidget);
      expect(find.text('Plano: Gratuito'), findsOneWidget);
      expect(find.text('Plano: Premium'), findsNothing);

      final cta = find.byKey(const Key('settings_plan_see_premium'));
      expect(cta, findsOneWidget);
      expect(find.text('Ver Premium'), findsOneWidget);

      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('Premium Promo Screen'), findsOneWidget);
    });

    testWidgets('10. Premium build shows "Plano: Premium" with no CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        createSettingsRouterTestApp(repository: fakeRepo, user: testUser, premium: true),
      );
      await tester.pumpAndSettle();

      final planTile = find.byKey(const Key('settings_plan_tile'));
      await tester.ensureVisible(planTile);
      await tester.pumpAndSettle();
      expect(planTile, findsOneWidget);
      expect(find.text('Plano: Premium'), findsOneWidget);
      expect(find.text('Plano: Gratuito'), findsNothing);
      expect(find.byKey(const Key('settings_plan_see_premium')), findsNothing);
      expect(find.text('Ver Premium'), findsNothing);
    });
  });
}

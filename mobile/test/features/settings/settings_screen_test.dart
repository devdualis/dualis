import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/auth_state.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dualis_mobile/features/settings/presentation/widgets/avatar_selector_sheet.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'mock-jwt-token';

  @override
  Future<void> clearAll() async {}
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
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }
}

class _TestAuthController extends AuthController {
  final AuthState _initial;
  _TestAuthController(this._initial);

  @override
  AuthState build() => _initial;
}

Widget createSettingsTestApp({
  required FakeAuthRepository repository,
  required UserProfile user,
}) {
  final authState = AuthState(
    isAuthenticated: true,
    user: user,
    accessToken: 'mock-jwt-token',
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      secureStorageServiceProvider.overrideWithValue(FakeSecureStorageService()),
      authControllerProvider.overrideWith(() => _TestAuthController(authState)),
    ],
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

    testWidgets('2. Tapping avatar opens AvatarSelectorSheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
      await tester.pumpAndSettle();

      final changeAvatarBtn = find.text('Alterar Foto');
      await tester.ensureVisible(changeAvatarBtn);
      await tester.tap(changeAvatarBtn);
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

      await tester.pumpWidget(createSettingsTestApp(repository: fakeRepo, user: testUser));
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
    });
  });
}

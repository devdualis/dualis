import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import 'package:dualis_mobile/features/privacy/data/privacy_remote_data_source.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/privacy_center_screen.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class MockSecureStorageService extends SecureStorageService {
  String? token = 'valid-jwt-token';

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<String?> getRefreshToken() async => 'valid-refresh-token';

  @override
  Future<String?> getUserId() async => 'test-patient-uuid';

  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    token = accessToken;
  }

  @override
  Future<void> clearAll() async {
    token = null;
  }
}

class MockAuthRepository implements AuthRepository {
  final UserProfile mockUser = const UserProfile(
    id: 'test-patient-uuid',
    name: 'Ricardo Jose',
    email: 'rinconrj@gmail.com',
    gender: Gender.masculino,
    dateOfBirth: '1990-01-01',
    isEmailVerified: true,
  );

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return {
      'user': mockUser.toJson(),
      'accessToken': 'valid-jwt-token',
      'refreshToken': 'valid-refresh-token',
    };
  }

  @override
  Future<UserProfile> getProfile({required String token}) async => mockUser;

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async =>
      {};

  @override
  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) async =>
      mockUser.copyWith(
        name: name ?? mockUser.name,
        dateOfBirth: dateOfBirth ?? mockUser.dateOfBirth,
      );

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class MockPrivacyRemoteDataSource implements PrivacyRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> exportUserData({required String token}) async {
    return {
      'metadata': {'formatVersion': '1.0'},
      'profile': {'name': 'Ricardo Jose', 'email': 'rinconrj@gmail.com'},
    };
  }

  @override
  Future<Map<String, dynamic>> deleteUserAccount({
    required String token,
    required String password,
  }) async {
    return {'success': true};
  }
}

class MockTriageHistoryDataSource implements TriageHistoryRemoteDataSource {
  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async {
    return TriageHistoryResponse(
      logs: [],
      physicalSummary: {},
      emotionalSummary: [],
      criticalRecurrences: [],
    );
  }

  @override
  Future<bool> deleteHistoryItem(String id) async => true;
}

Widget createFullAppWalkthrough({
  required AppDatabase db,
  required MockSecureStorageService storage,
  required MockAuthRepository authRepo,
  required MockPrivacyRemoteDataSource privacyDs,
  required MockTriageHistoryDataSource historyDs,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.onboarding,
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyCenter,
        builder: (context, state) => const PrivacyCenterScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        builder: (context, state) => const HistoricalDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.hydration,
        builder: (context, state) => const HydrationDashboardScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
      appDatabaseProvider.overrideWithValue(db),
      secureStorageServiceProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(authRepo),
      privacyRemoteDataSourceProvider.overrideWithValue(privacyDs),
      triageHistoryDataSourceProvider.overrideWithValue(historyDs),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Full Application Navigation & Interactive Clicking E2E Walkthrough', () {
    late AppDatabase db;
    late MockSecureStorageService storage;
    late MockAuthRepository authRepo;
    late MockPrivacyRemoteDataSource privacyDs;
    late MockTriageHistoryDataSource historyDs;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      storage = MockSecureStorageService();
      authRepo = MockAuthRepository();
      privacyDs = MockPrivacyRemoteDataSource();
      historyDs = MockTriageHistoryDataSource();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Complete user journey clicking through all screens and features',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createFullAppWalkthrough(
        db: db,
        storage: storage,
        authRepo: authRepo,
        privacyDs: privacyDs,
        historyDs: historyDs,
      ));
      await tester.pumpAndSettle();

      // =========================================================================
      // 1. ONBOARDING SCREEN
      // =========================================================================
      expect(find.text('Triagem Preventiva Unificada'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);

      // Click "Entrar" to navigate to Login
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      // =========================================================================
      // 2. LOGIN SCREEN
      // =========================================================================
      expect(find.text('Entrar no DualisCheckUp'), findsOneWidget);
      expect(find.byKey(const Key('loginEmailField')), findsOneWidget);
      expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);

      // Click "Entrar" with empty fields -> should trigger form errors
      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();
      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);
      expect(find.text('Senha é obrigatória.'), findsOneWidget);

      // Click "Criar Conta" link -> navigates to Register
      await tester.tap(find.byKey(const Key('goToRegisterButton')));
      await tester.pumpAndSettle();

      // =========================================================================
      // 3. REGISTER SCREEN
      // =========================================================================
      expect(find.byKey(const Key('fullNameField')), findsOneWidget);

      // Click "Entrar" link at bottom -> back to Login
      await tester.tap(find.byKey(const Key('goToLoginButton')));
      await tester.pumpAndSettle();

      // Now fill in credentials and login
      await tester.enterText(
        find.byKey(const Key('loginEmailField')),
        'rinconrj@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'SenhaSegura123!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      // =========================================================================
      // 4. HOME SCREEN & BOTTOM NAVIGATION
      // =========================================================================
      expect(find.byKey(const Key('home_profile_card')), findsOneWidget);
      expect(find.text('Como você está hoje?'), findsOneWidget);

      // Verify Stage Action Cards
      expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);

      // Verify Hydration Navigation from Bottom Navigation
      final hydrationNavBtn = find.byKey(const Key('nav_destination_hydration'));
      expect(hydrationNavBtn, findsOneWidget);
      await tester.tap(hydrationNavBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HydrationDashboardScreen), findsOneWidget);

      // Return to Tab 1: "Início"
      final navHomeFromHydration = find.byKey(const Key('nav_destination_home'));
      await tester.tap(navHomeFromHydration);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Click Bottom Navigation Tab 2: "Resultado do Dia"
      final tabResultado = find.byKey(const Key('nav_destination_today_outcome'));
      expect(tabResultado, findsOneWidget);
      await tester.tap(tabResultado);
      await tester.pumpAndSettle();

      // Click Bottom Navigation Tab 3: "Histórico & Mapa"
      final tabHistorico = find.byKey(const Key('nav_destination_history'));
      expect(tabHistorico, findsOneWidget);
      await tester.tap(tabHistorico);
      await tester.pumpAndSettle();

      // Return to Tab 1: "Início"
      final tabInicio = find.byKey(const Key('nav_destination_home'));
      expect(tabInicio, findsOneWidget);
      await tester.tap(tabInicio);
      await tester.pumpAndSettle();

      // =========================================================================
      // 5. SETTINGS SCREEN
      // =========================================================================
      final settingsIcon = find.byKey(const Key('home_settings_button'));
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      // Verify profile name input is present
      final nameInput = find.byKey(const Key('settings_name_input'));
      expect(nameInput, findsOneWidget);

      // Click Change Password section
      final curPass = find.byKey(const Key('settings_current_password_input'));
      if (curPass.evaluate().isNotEmpty) {
        await tester.ensureVisible(curPass);
        await tester.enterText(curPass, 'OldPassword123!');

        final newPass = find.byKey(const Key('settings_new_password_input'));
        await tester.ensureVisible(newPass);
        await tester.enterText(newPass, 'NewPassword123!');

        final confPass = find.byKey(const Key('settings_confirm_password_input'));
        await tester.ensureVisible(confPass);
        await tester.enterText(confPass, 'MismatchPassword123!');

        final changeBtn = find.byKey(const Key('settings_change_password_button'));
        await tester.ensureVisible(changeBtn);
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        // Verifies friendly localized mismatch message
        expect(find.text('As novas senhas não coincidem.'), findsOneWidget);
      }

      // Click Privacy Center navigation tile in Settings
      final privacyTile = find.byKey(const Key('settings_privacy_tile'));
      if (privacyTile.evaluate().isNotEmpty) {
        await tester.ensureVisible(privacyTile);
        await tester.tap(privacyTile);
        await tester.pumpAndSettle();

        // =======================================================================
        // 6. PRIVACY CENTER SCREEN
        // =======================================================================
        expect(find.byType(PrivacyCenterScreen), findsOneWidget);

        // Click "Exportar Dados"
        final exportBtn = find.byKey(const Key('export_data_button'));
        expect(exportBtn, findsOneWidget);
        await tester.tap(exportBtn);
        await tester.pumpAndSettle();

        expect(find.text('Prévia dos Dados Exportados'), findsOneWidget);
        // Click "Fechar"
        await tester.tap(find.text('Fechar'));
        await tester.pumpAndSettle();

        // Click "Solicitar Exclusão da Conta"
        final deleteBtn = find.byKey(const Key('delete_account_button'));
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(find.text('Confirmar Exclusão Definitiva'), findsOneWidget);

        // Click "Cancelar"
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}

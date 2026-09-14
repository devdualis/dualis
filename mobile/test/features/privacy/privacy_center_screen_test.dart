import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/privacy/data/privacy_remote_data_source.dart';
import 'package:dualis_mobile/features/privacy/presentation/screens/privacy_center_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakePrivacyRemoteDataSource implements PrivacyRemoteDataSource {
  final Map<String, dynamic> exportResponse;
  final Map<String, dynamic> deleteResponse;
  bool exportCalled = false;
  bool deleteCalled = false;
  String? lastPassword;

  FakePrivacyRemoteDataSource({
    this.exportResponse = const {
      'metadata': {
        'formatVersion': '1.0',
        'legalBasis': 'LGPD Art. 18, V',
      },
      'profile': {
        'id': 'test-id',
        'name': 'Usuário de Teste',
        'email': 'teste@exemplo.com.br',
      },
      'consents': [],
      'symptomLogs': [],
      'emergencyEvents': [],
    },
    this.deleteResponse = const {
      'success': true,
      'message': 'Conta excluída.',
    },
  });

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> exportUserData({required String token}) async {
    exportCalled = true;
    return exportResponse;
  }

  @override
  Future<Map<String, dynamic>> deleteUserAccount({
    required String token,
    required String password,
  }) async {
    deleteCalled = true;
    lastPassword = password;
    return deleteResponse;
  }
}

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'mock-access-token';

  @override
  Future<void> clearAll() async {}
}

Widget createTestWidget({
  required Widget child,
  required List<dynamic> overrides,
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
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
      home: child,
    ),
  );
}

void main() {
  group('PrivacyCenterScreen Widget Tests (SEC-03 / LGPD)', () {
    late AppDatabase db;
    late FakePrivacyRemoteDataSource mockRemoteDataSource;
    late FakeSecureStorageService mockSecureStorage;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockRemoteDataSource = FakePrivacyRemoteDataSource();
      mockSecureStorage = FakeSecureStorageService();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders Privacy Center screen with both Data Export and Account Deletion cards',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PrivacyCenterScreen(),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            privacyRemoteDataSourceProvider.overrideWithValue(mockRemoteDataSource),
            secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacidade & Dados (LGPD)'), findsOneWidget);
      expect(find.text('Exportação de Dados'), findsOneWidget);
      expect(find.byKey(const Key('export_data_button')), findsOneWidget);
      expect(find.text('Exclusão Permanente da Conta'), findsOneWidget);
      expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
    });

    testWidgets('tapping export data triggers export call and shows JSON preview dialog',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PrivacyCenterScreen(),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            privacyRemoteDataSourceProvider.overrideWithValue(mockRemoteDataSource),
            secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export_data_button')));
      await tester.pumpAndSettle();

      expect(mockRemoteDataSource.exportCalled, isTrue);
      expect(find.text('Prévia dos Dados Exportados'), findsOneWidget);
      expect(find.textContaining('LGPD Art. 18, V'), findsOneWidget);
      expect(find.textContaining('Usuário de Teste'), findsOneWidget);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Prévia dos Dados Exportados'), findsNothing);
    });

    testWidgets('tapping delete account shows confirmation dialog with disabled button until password entered',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PrivacyCenterScreen(),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            privacyRemoteDataSourceProvider.overrideWithValue(mockRemoteDataSource),
            secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_account_button')));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar Exclusão Definitiva'), findsOneWidget);

      final confirmBtnFinder = find.byKey(const Key('confirm_permanent_deletion_button'));
      expect(confirmBtnFinder, findsOneWidget);

      FilledButton confirmBtn = tester.widget<FilledButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('delete_account_password_field')),
        'short',
      );
      await tester.pumpAndSettle();

      confirmBtn = tester.widget<FilledButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('delete_account_password_field')),
        'ValidPassword123!',
      );
      await tester.pumpAndSettle();

      confirmBtn = tester.widget<FilledButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNotNull);

      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      expect(mockRemoteDataSource.deleteCalled, isTrue);
      expect(mockRemoteDataSource.lastPassword, 'ValidPassword123!');
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// In-memory storage; like the real one, clearSession keeps only the owner
/// and the hydration settings.
class _MemoryStorage extends SecureStorageService {
  String? owner;
  final Map<String, String> values = {};
  @override
  Future<String?> read({required String key}) async => values[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<void> delete({required String key}) async => values.remove(key);
  @override
  Future<String?> getLocalDataOwnerId() async => owner;
  @override
  Future<void> saveLocalDataOwnerId(String userId) async => owner = userId;
  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {}
  @override
  Future<void> saveUserProfile(UserProfile user) async {}
  @override
  Future<void> clearPendingVerificationEmail() async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> clearSession() async => values.removeWhere(
        (k, _) => k != SecureStorageService.keyHydrationSettings,
      );
}

UserProfile _user(String id) => UserProfile(
      id: id,
      name: 'Pessoa',
      email: '$id@dualis.test',
      gender: Gender.masculino,
      dateOfBirth: '1990-01-01',
      isEmailVerified: true,
    );

void main() {
  late AppDatabase db;
  late _MemoryStorage storage;
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = _MemoryStorage();
    repository = _MockAuthRepository();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      secureStorageServiceProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repository),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> loginAs(String id) async {
    when(() => repository.login(email: '$id@dualis.test', password: 'x'))
        .thenAnswer((_) async => {
              'user': _user(id).toJson(),
              'accessToken': 'a-$id',
              'refreshToken': 'r-$id',
            });
    await container
        .read(authControllerProvider.notifier)
        .login(email: '$id@dualis.test', password: 'x');
  }

  Future<void> queueEntry() => db.into(db.journalOutbox).insert(
        JournalOutboxCompanion.insert(clientId: 'c-${DateTime.now().microsecondsSinceEpoch}', payloadJson: '{}'),
      );

  test('another account signing in on the device wipes unsent entries', () async {
    await loginAs('user-a');
    await queueEntry();
    await container.read(authControllerProvider.notifier).logout();
    expect(storage.owner, 'user-a');

    await loginAs('user-b');
    expect(await db.select(db.journalOutbox).get(), isEmpty);
    expect(storage.owner, 'user-b');
  });

  test('the same person signing back in keeps their unsent entries', () async {
    await loginAs('user-a');
    await queueEntry();
    await container.read(authControllerProvider.notifier).logout();

    await loginAs('user-a');
    expect(await db.select(db.journalOutbox).get(), hasLength(1));
  });

  test('hydration settings survive logout for the same person only', () async {
    const key = SecureStorageService.keyHydrationSettings;
    await loginAs('user-a');
    storage.values[key] = '{"dailyTargetMl":2600,"reminderEnabled":false}';
    storage.values['other'] = 'x';
    await container.read(authControllerProvider.notifier).logout();
    expect(storage.values.containsKey('other'), isFalse);

    await loginAs('user-a');
    expect(storage.values[key], contains('2600'));

    await container.read(authControllerProvider.notifier).logout();
    await loginAs('user-b');
    expect(storage.values.containsKey(key), isFalse);
  });
}

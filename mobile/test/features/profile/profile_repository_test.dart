import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Answers every request with the next queued response and records requests.
class FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];
  final _responses = <(int, Object?)>[];

  void enqueue(int status, [Object? body]) => _responses.add((status, body));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(options.data);
    final (status, body) = _responses.removeAt(0);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeAdapter adapter;
  late MockSecureStorageService storage;
  late ProfileRepository repository;

  const profileJson = {
    'id': 'p1',
    'name': 'Ana',
    'profileType': 'dependent_minor',
    'ownership': 'dependent',
    'accessLevel': 'OWNER',
    'dateOfBirth': '2018-03-09',
    'gender': 'feminino',
    'avatarUrl': null,
  };

  setUp(() {
    adapter = FakeAdapter();
    storage = MockSecureStorageService();
    when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    repository = ProfileRepository(
      apiClient: ApiClient(customDio: dio, secureStorage: storage),
      secureStorage: storage,
    );
  });

  test('fetchProfiles maps the camelCase API payload and sends the token',
      () async {
    adapter.enqueue(200, [
      profileJson,
      {
        'id': 'p2',
        'name': 'Bia',
        'profileType': 'primary',
        'ownership': 'shared',
        'accessLevel': 'CO_MANAGE',
        'dateOfBirth': null,
        'gender': null,
        'avatarUrl': null,
      },
    ]);

    final profiles = await repository.fetchProfiles();

    expect(adapter.requests.single.path, '/v1/profiles');
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok');
    final ana = profiles[0];
    expect(ana.profileType, ProfileType.dependentMinor);
    expect(ana.ownership, ProfileOwnership.dependent);
    expect(ana.accessLevel, ProfileAccessLevel.owner);
    expect(ana.dateOfBirth, DateTime(2018, 3, 9));
    expect(ana.canDelete, isTrue);
    final bia = profiles[1];
    expect(bia.isShared, isTrue);
    expect(bia.accessLevel, ProfileAccessLevel.coManage);
    expect(bia.canEdit, isTrue);
    expect(bia.canDelete, isFalse);
  });

  test('createDependent posts the DTO with a yyyy-MM-dd date', () async {
    adapter.enqueue(201, profileJson);

    final profile = await repository.createDependent(
      name: 'Ana',
      dateOfBirth: DateTime(2018, 3, 9),
      gender: 'feminino',
      relationshipType: 'parent',
      lgpdConsent: true,
    );

    expect(adapter.requests.single.path, '/v1/profiles/dependents');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.bodies.single, {
      'name': 'Ana',
      'dateOfBirth': '2018-03-09',
      'gender': 'feminino',
      'relationshipType': 'parent',
      'lgpdConsent': true,
    });
    expect(profile.id, 'p1');
  });

  test('updateProfileName uses PUT and deleteProfile uses DELETE', () async {
    adapter.enqueue(200, {...profileJson, 'name': 'Ana Clara'});
    adapter.enqueue(204);

    final updated = await repository.updateProfileName('p1', 'Ana Clara');
    await repository.deleteProfile('p1');

    expect(updated.name, 'Ana Clara');
    expect(adapter.requests[0].method, 'PUT');
    expect(adapter.requests[0].path, '/v1/profiles/p1');
    expect(adapter.bodies[0], {'name': 'Ana Clara'});
    expect(adapter.requests[1].method, 'DELETE');
    expect(adapter.requests[1].path, '/v1/profiles/p1');
  });

  test('fetchGrants splits outgoing and incoming grants', () async {
    adapter.enqueue(200, {
      'outgoing': [
        {
          'id': 'g1',
          'targetProfileId': 'p1',
          'targetProfileName': 'Ana',
          'accessLevel': 'VIEW_ONLY',
          'status': 'PENDING',
          'inviteCode': 'ABC123',
          'granteeUserId': null,
          'expiresAt': '2026-10-16T12:00:00.000Z',
          'acceptedAt': null,
        },
      ],
      'incoming': [
        {
          'id': 'g2',
          'granterUserId': 'u9',
          'targetProfileId': 'p9',
          'targetProfileName': 'Vovó',
          'accessLevel': 'CO_MANAGE',
          'status': 'ACCEPTED',
          'expiresAt': '2026-10-16T12:00:00.000Z',
          'acceptedAt': '2026-10-15T12:00:00.000Z',
        },
      ],
    });

    final grants = await repository.fetchGrants();

    expect(adapter.requests.single.path, '/v1/family-sharing/grants');
    final out = grants.outgoing.single;
    expect(out.direction, GrantDirection.outgoing);
    expect(out.status, GrantStatus.pending);
    expect(out.inviteCode, 'ABC123');
    expect(out.accessLevel, ProfileShareLevel.viewOnly);
    expect(out.expiresAt, DateTime.utc(2026, 10, 16, 12).toLocal());
    final inc = grants.incoming.single;
    expect(inc.direction, GrantDirection.incoming);
    expect(inc.isActive, isTrue);
    expect(inc.accessLevel, ProfileShareLevel.coManage);
    expect(inc.inviteCode, isNull);
  });

  test('fetchGrants reads who accepted an outgoing invite', () async {
    adapter.enqueue(200, {
      'outgoing': [
        {
          'id': 'g1',
          'targetProfileId': 'p1',
          'targetProfileName': 'Ana',
          'accessLevel': 'VIEW_ONLY',
          'status': 'ACCEPTED',
          'inviteCode': 'ABC234DEF5',
          'granteeUserId': 'u2',
          'granteeName': 'Maria Souza',
          'granteeEmail': 'maria@example.com',
          'expiresAt': '2026-10-16T12:00:00.000Z',
          'acceptedAt': '2026-10-15T12:00:00.000Z',
        },
      ],
      'incoming': [],
    });

    final out = (await repository.fetchGrants()).outgoing.single;
    expect(out.granteeName, 'Maria Souza');
    expect(out.granteeEmail, 'maria@example.com');
    expect(out.granteeLabel, 'Maria Souza (maria@example.com)');
  });

  test('createInvite, acceptInvite and revokeGrant hit the sharing routes',
      () async {
    adapter.enqueue(201, {
      'id': 'g1',
      'inviteCode': 'XYZ789',
      'accessLevel': 'CO_MANAGE',
      'targetProfileId': 'p1',
      'expiresAt': '2026-10-16T12:00:00.000Z',
    });
    adapter.enqueue(200, {'id': 'g1', 'status': 'ACCEPTED'});
    adapter.enqueue(200, {'id': 'g1', 'status': 'REVOKED'});

    final grant = await repository.createInvite(
      targetProfileId: 'p1',
      accessLevel: ProfileShareLevel.coManage,
      targetProfileName: 'Ana',
    );
    await repository.acceptInvite('XYZ789');
    await repository.revokeGrant('g1');

    expect(adapter.requests[0].path, '/v1/family-sharing/invite');
    expect(adapter.bodies[0],
        {'targetProfileId': 'p1', 'accessLevel': 'CO_MANAGE'});
    expect(grant.status, GrantStatus.pending);
    expect(grant.inviteCode, 'XYZ789');
    expect(grant.targetProfileName, 'Ana');
    expect(adapter.requests[1].path, '/v1/family-sharing/accept');
    expect(adapter.bodies[1], {'inviteCode': 'XYZ789'});
    expect(adapter.requests[2].path, '/v1/family-sharing/revoke/g1');
    expect(adapter.requests[2].method, 'POST');
  });

  test('surfaces the backend message of a 403 as ProfileApiException',
      () async {
    adapter.enqueue(403, {
      'statusCode': 403,
      'message': 'Somente o titular da conta pode excluir este perfil.',
      'error': 'Forbidden',
    });

    await expectLater(
      repository.deleteProfile('p1'),
      throwsA(isA<ProfileApiException>()
          .having((e) => e.statusCode, 'statusCode', 403)
          .having((e) => e.message, 'message',
              'Somente o titular da conta pode excluir este perfil.')),
    );
  });

  test('joins validation message arrays from a 400', () async {
    adapter.enqueue(400, {
      'statusCode': 400,
      'message': ['Consentimento LGPD Art. 14 é obrigatório.', 'Outro erro'],
    });

    await expectLater(
      repository.acceptInvite('bad'),
      throwsA(isA<ProfileApiException>().having((e) => e.message, 'message',
          'Consentimento LGPD Art. 14 é obrigatório.\nOutro erro')),
    );
  });

  test('throws a 401 ProfileApiException without a stored token', () async {
    when(() => storage.getAccessToken()).thenAnswer((_) async => null);

    await expectLater(
      repository.fetchProfiles(),
      throwsA(isA<ProfileApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
    expect(adapter.requests, isEmpty);
  });

  test('stores the active profile id per user', () async {
    when(() => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => storage.read(key: 'dualis_active_profile_u1'))
        .thenAnswer((_) async => 'p1');
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    await repository.saveActiveProfileId('u1', 'p1');
    await repository.saveActiveProfileId('u1', null);

    expect(await repository.readActiveProfileId('u1'), 'p1');
    verify(() => storage.write(key: 'dualis_active_profile_u1', value: 'p1'))
        .called(1);
    verify(() => storage.delete(key: 'dualis_active_profile_u1')).called(1);
  });
}

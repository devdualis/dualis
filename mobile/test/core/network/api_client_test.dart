import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class _ScriptedAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody> Function(RequestOptions) responder;

  _ScriptedAdapter(this.responder);

  final Map<String, int> _callCounts = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = options.path;
    final index = _callCounts[key] ?? 0;
    _callCounts[key] = index + 1;
    final scripted = responder(options);
    return scripted[index < scripted.length ? index : scripted.length - 1];
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MockSecureStorageService storage;

  setUp(() {
    storage = MockSecureStorageService();
    when(() => storage.getRefreshToken()).thenAnswer((_) async => 'stale-refresh-token');
    when(() => storage.getUserId()).thenAnswer((_) async => 'user-1');
    when(() => storage.persistTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});
  });

  test('retries the original request with a refreshed token after a 401', () async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/v1/triage/history') {
        return [
          _jsonResponse({'message': 'Unauthorized'}, 401),
          _jsonResponse({'ok': true}, 200),
        ];
      }
      if (options.path == '/v1/auth/refresh') {
        return [
          _jsonResponse({
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
            'user': {'id': 'user-1'},
          }, 200),
        ];
      }
      throw StateError('Unexpected path ${options.path}');
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(customDio: dio, secureStorage: storage);

    final response = await client.get<Map<String, dynamic>>(
      '/v1/triage/history',
      options: Options(headers: {'Authorization': 'Bearer expired-token'}),
    );

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});

    final retriedRequest = adapter.requests.firstWhere(
      (r) => r.path == '/v1/triage/history' && r.headers['Authorization'] == 'Bearer new-access-token',
    );
    expect(retriedRequest.extra['isAuthRetry'], true);

    verify(() => storage.persistTokens(
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
          userId: 'user-1',
        )).called(1);
  });

  test('coalesces concurrent refreshes into a single call to /v1/auth/refresh', () async {
    var refreshCalls = 0;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/v1/triage/history') {
        return [_jsonResponse({'message': 'Unauthorized'}, 401), _jsonResponse({'ok': true}, 200)];
      }
      if (options.path == '/v1/auth/emergency-event') {
        return [_jsonResponse({'message': 'Unauthorized'}, 401), _jsonResponse({'ok': true}, 200)];
      }
      if (options.path == '/v1/auth/refresh') {
        refreshCalls++;
        return [
          _jsonResponse({
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
            'user': {'id': 'user-1'},
          }, 200),
        ];
      }
      throw StateError('Unexpected path ${options.path}');
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(customDio: dio, secureStorage: storage);

    await Future.wait([
      client.get<Map<String, dynamic>>(
        '/v1/triage/history',
        options: Options(headers: {'Authorization': 'Bearer expired-token'}),
      ),
      client.get<Map<String, dynamic>>(
        '/v1/auth/emergency-event',
        options: Options(headers: {'Authorization': 'Bearer expired-token'}),
      ),
    ]);

    expect(refreshCalls, 1);
  });

  test('propagates the original 401 and clears storage when the refresh token is also invalid', () async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/v1/triage/history') {
        return [_jsonResponse({'message': 'Unauthorized'}, 401)];
      }
      if (options.path == '/v1/auth/refresh') {
        return [_jsonResponse({'message': 'Token de atualização inválido ou expirado.'}, 401)];
      }
      throw StateError('Unexpected path ${options.path}');
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(customDio: dio, secureStorage: storage);

    await expectLater(
      client.get<Map<String, dynamic>>(
        '/v1/triage/history',
        options: Options(headers: {'Authorization': 'Bearer expired-token'}),
      ),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
    );

    verify(() => storage.clearAll()).called(1);
    verifyNever(() => storage.persistTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          userId: any(named: 'userId'),
        ));
  });

  test('does not attempt refresh for requests explicitly marked to skip it', () async {
    var refreshCalls = 0;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/v1/auth/refresh') {
        refreshCalls++;
        return [_jsonResponse({'message': 'Invalid'}, 401)];
      }
      throw StateError('Unexpected path ${options.path}');
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(customDio: dio, secureStorage: storage);

    await expectLater(
      client.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': 'whatever'},
        options: Options(extra: {'skipAuthRefresh': true}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 1);
  });
}

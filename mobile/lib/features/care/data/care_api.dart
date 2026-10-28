import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/care_models.dart';

/// "Meus cuidados" API (`backend/src/modules/care`). The active profile goes in
/// `X-Profile-Id` through [ProfileHeaderInterceptor].
class CareEndpoints {
  CareEndpoints._();

  static const String records = '/v1/care/records';
  static String record(String id) => '/v1/care/records/$id';
  static String intakes(String medicationId) => '/v1/care/medications/$medicationId/intakes';
  static const String documents = '/v1/care/documents';
  static String document(String id) => '/v1/care/documents/$id';
  static String documentFile(String id) => '/v1/care/documents/$id/file';
  static String review(String id) => '/v1/care/documents/$id/review';
}

final careApiProvider = Provider<CareApi>((ref) {
  return CareApi(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class CareApi {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  CareApi({required ApiClient apiClient, required SecureStorageService secureStorage})
      : _apiClient = apiClient,
        _secureStorage = secureStorage;

  Future<Options> _options({Duration? timeout, ResponseType? responseType}) async {
    final token = await _secureStorage.getAccessToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      sendTimeout: timeout,
      receiveTimeout: timeout,
      responseType: responseType,
    );
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected care response.');
  }

  List<Map<String, dynamic>> _list(Object? data) =>
      data is List ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList() : const [];

  Future<List<CareRecord>> list(CareKind kind, {String? parentId}) async {
    final response = await _apiClient.get(
      CareEndpoints.records,
      queryParameters: {'kind': kind.apiName, if (parentId != null) 'parentId': parentId},
      options: await _options(),
    );
    return _list(response.data).map(CareRecord.fromJson).toList();
  }

  Future<CareRecord> create(CareKind kind, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      CareEndpoints.records,
      data: {'kind': kind.apiName, 'data': data},
      options: await _options(),
    );
    return CareRecord.fromJson(_map(response.data));
  }

  Future<CareRecord> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      CareEndpoints.record(id),
      data: {'data': data},
      options: await _options(),
    );
    return CareRecord.fromJson(_map(response.data));
  }

  Future<void> delete(String id) async {
    await _apiClient.delete(CareEndpoints.record(id), options: await _options());
  }

  /// Returns the updated medication (stock lowered when [action] is `taken`).
  Future<CareRecord> logIntake(String medicationId, DateTime scheduledFor, IntakeAction action) async {
    final response = await _apiClient.post(
      CareEndpoints.intakes(medicationId),
      data: {'scheduledFor': scheduledFor.toUtc().toIso8601String(), 'action': action.name},
      options: await _options(),
    );
    return CareRecord.fromJson(_map(_map(response.data)['medication']));
  }

  Future<List<CareDocument>> documents({DocumentKind? kind}) async {
    final response = await _apiClient.get(
      CareEndpoints.documents,
      queryParameters: {if (kind != null) 'kind': kind.name},
      options: await _options(),
    );
    return _list(response.data).map(CareDocument.fromJson).toList();
  }

  Future<CareDocument> document(String id) async {
    final response = await _apiClient.get(CareEndpoints.document(id), options: await _options());
    return CareDocument.fromJson(_map(response.data));
  }

  Future<CareDocument> upload({
    required DocumentKind kind,
    required String mime,
    required Uint8List bytes,
    required bool read,
    String? title,
  }) async {
    final response = await _apiClient.post(
      CareEndpoints.documents,
      data: {
        'kind': kind.name,
        'mime': mime,
        'fileBase64': base64Encode(bytes),
        'read': read,
        if (title != null && title.isNotEmpty) 'title': title,
      },
      options: await _options(timeout: const Duration(seconds: 90)),
    );
    return CareDocument.fromJson(_map(response.data));
  }

  Future<Uint8List> file(String id) async {
    final response = await _apiClient.get<List<int>>(
      CareEndpoints.documentFile(id),
      options: await _options(timeout: const Duration(seconds: 60), responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<CareDocument> review(String id, Map<String, dynamic> body) async {
    final response = await _apiClient.put(CareEndpoints.review(id), data: body, options: await _options());
    return CareDocument.fromJson(_map(response.data));
  }

  Future<void> deleteDocument(String id) async {
    await _apiClient.delete(CareEndpoints.document(id), options: await _options());
  }
}

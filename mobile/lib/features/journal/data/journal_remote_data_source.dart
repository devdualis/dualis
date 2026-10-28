import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/journal_models.dart';

/// Journal v2 API paths (`docs/bienestar/CONTRATO-JOURNAL-V2.md`).
class JournalEndpoints {
  JournalEndpoints._();

  static const String entries = '/v1/journal/entries';
  static String entry(String id) => '/v1/journal/entries/$id';
  static const String conditions = '/v1/journal/conditions';
  static String condition(String id) => '/v1/journal/conditions/$id';
  static const String suggestOption = '/v1/journal/suggest-option';
}

final journalRemoteDataSourceProvider = Provider<JournalRemoteDataSource>((
  ref,
) {
  return JournalRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class JournalRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  JournalRemoteDataSource({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;

  Future<Options> _options({String? profileId}) async {
    final token = await _secureStorage.getAccessToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        if (profileId != null && profileId.isNotEmpty)
          'X-Profile-Id': profileId,
      },
    );
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected journal response.');
  }

  Future<JournalEntry> createEntry(
    JournalEntry entry, {
    String? profileId,
  }) async {
    final response = await _apiClient.post(
      JournalEndpoints.entries,
      data: entry.toRequestJson(),
      options: await _options(profileId: profileId),
    );
    return JournalEntry.fromJson(_map(response.data));
  }

  Future<List<JournalEntry>> listEntries({int days = 30}) async {
    final response = await _apiClient.get(
      JournalEndpoints.entries,
      queryParameters: {'days': days},
      options: await _options(),
    );
    final raw = _map(response.data)['entries'] as List? ?? const [];
    return [
      for (final e in raw)
        if (e is Map) JournalEntry.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  Future<void> deleteEntry(String id) async {
    await _apiClient.delete(
      JournalEndpoints.entry(id),
      options: await _options(),
    );
  }

  Future<List<UserCondition>> listConditions() async {
    final response = await _apiClient.get(
      JournalEndpoints.conditions,
      options: await _options(),
    );
    final raw = _map(response.data)['conditions'] as List? ?? const [];
    return [
      for (final c in raw)
        if (c is Map) UserCondition.fromJson(Map<String, dynamic>.from(c)),
    ];
  }

  Future<UserCondition> createCondition(String label) async {
    final response = await _apiClient.post(
      JournalEndpoints.conditions,
      data: {'label': label},
      options: await _options(),
    );
    return UserCondition.fromJson(_map(response.data));
  }

  Future<void> archiveCondition(String id) async {
    await _apiClient.delete(
      JournalEndpoints.condition(id),
      options: await _options(),
    );
  }

  /// Maps free text onto one existing chip, or null. The person confirms.
  Future<String?> suggestOption({
    required String text,
    required String kind,
  }) async {
    final response = await _apiClient.post(
      JournalEndpoints.suggestOption,
      data: {'text': text, 'kind': kind},
      options: await _options(),
    );
    final key = _map(response.data)['optionKey'];
    if (key is! String || key.isEmpty) return null;
    return key;
  }
}

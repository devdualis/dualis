import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/symptom_classification.dart';

class SymptomClassificationRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  SymptomClassificationRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<SymptomClassification> classify(String text) async {
    final authToken = await _secureStorage.getAccessToken();
    final response = await _apiClient.post(
      ApiEndpoints.classifySymptom,
      data: {
        'text': text,
        'language': 'pt',
      },
      options: authToken != null
          ? Options(headers: {'Authorization': 'Bearer $authToken'})
          : null,
    );

    if (response.data is Map<String, dynamic>) {
      return SymptomClassification.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Formato de resposta de classificação inesperado.');
  }
}

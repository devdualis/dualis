import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({ApiClient? client})
      : apiClient = client ?? ApiClient();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email.toLowerCase().trim(),
        'password': password,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'lgpdConsent': lgpdConsent,
        if (disclaimerVersion != null) 'disclaimerVersion': disclaimerVersion,
      },
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email.toLowerCase().trim(),
        'password': password,
      },
    );

    return response.data ?? {};
  }

  Future<UserProfile> getProfile({required String token}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.me,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return UserProfile.fromJson(response.data ?? {});
  }

  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.updateProfile,
      data: {
        if (name != null) 'name': name,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (picture != null) 'picture': picture,
        if (gender != null) 'gender': gender,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return UserProfile.fromJson(response.data ?? {});
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}

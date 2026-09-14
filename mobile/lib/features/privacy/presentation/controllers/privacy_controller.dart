import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/privacy_remote_data_source.dart';

class PrivacyState {
  final bool isExporting;
  final bool isDeleting;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic>? exportedData;
  final bool isAccountDeleted;

  const PrivacyState({
    this.isExporting = false,
    this.isDeleting = false,
    this.errorMessage,
    this.successMessage,
    this.exportedData,
    this.isAccountDeleted = false,
  });

  PrivacyState copyWith({
    bool? isExporting,
    bool? isDeleting,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? exportedData,
    bool? isAccountDeleted,
  }) {
    return PrivacyState(
      isExporting: isExporting ?? this.isExporting,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      successMessage: successMessage,
      exportedData: exportedData ?? this.exportedData,
      isAccountDeleted: isAccountDeleted ?? this.isAccountDeleted,
    );
  }
}

class PrivacyController extends Notifier<PrivacyState> {
  @override
  PrivacyState build() => const PrivacyState();

  PrivacyRemoteDataSource get _remoteDataSource =>
      ref.read(privacyRemoteDataSourceProvider);
  SecureStorageService get _secureStorage =>
      ref.read(secureStorageServiceProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      final response = e.response;
      if (response != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final message = data['message'];
        if (message is List) {
          return message.join('\n');
        } else if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      return e.message ?? 'Erro na comunicação com o servidor.';
    }
    return e.toString();
  }

  Future<Map<String, dynamic>?> exportData() async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final token = await _secureStorage.getAccessToken() ??
          ref.read(authControllerProvider).accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      final data = await _remoteDataSource.exportUserData(token: token);
      state = state.copyWith(
        isExporting: false,
        exportedData: data,
        successMessage: 'Dados exportados com sucesso.',
      );
      return data;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: _extractErrorMessage(e),
      );
      return null;
    }
  }

  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(
      isDeleting: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final token = await _secureStorage.getAccessToken() ??
          ref.read(authControllerProvider).accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      await _remoteDataSource.deleteUserAccount(
        token: token,
        password: password,
      );
      await _db.wipeAllLocalData();
      await ref.read(authControllerProvider.notifier).logout();
      state = state.copyWith(
        isDeleting: false,
        isAccountDeleted: true,
        successMessage: 'Conta e dados excluídos com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    }
  }
}

final privacyControllerProvider =
    NotifierProvider<PrivacyController, PrivacyState>(PrivacyController.new);

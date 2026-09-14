import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState.initial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SecureStorageService get _secureStorage => ref.read(secureStorageServiceProvider);

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
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet ou se o backend está em execução.';
      }
      return e.message ?? 'Erro inesperado na comunicação com o servidor.';
    }
    return e.toString();
  }

  Future<void> restoreSession() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) return;

      final profile = await _repository.getProfile(token: token);
      state = state.copyWith(
        isAuthenticated: true,
        user: profile,
        accessToken: token,
      );
    } catch (_) {
      await _secureStorage.clearAll();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.register(
        name: name,
        email: email,
        password: password,
        gender: gender,
        dateOfBirth: dateOfBirth,
        lgpdConsent: lgpdConsent,
        disclaimerVersion: disclaimerVersion,
      );

      final userJson = res['user'] as Map<String, dynamic>? ?? {};
      final user = UserProfile.fromJson(userJson);
      final accessToken = res['accessToken'] as String?;
      final refreshToken = res['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null && user.id.isNotEmpty) {
        await _secureStorage.persistTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: user.id,
        );
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.login(email: email, password: password);
      final userJson = res['user'] as Map<String, dynamic>? ?? {};
      final user = UserProfile.fromJson(userJson);
      final accessToken = res['accessToken'] as String?;
      final refreshToken = res['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null && user.id.isNotEmpty) {
        await _secureStorage.persistTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: user.id,
        );
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
    state = const AuthState.initial();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        errorMessage: e.toString(),
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
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState.initial();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

import 'user_profile.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfile? user;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;

  /// Email registered but not yet verified. While set (and logged out), the
  /// app keeps sending the user back to the verification screen.
  final String? pendingVerificationEmail;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.accessToken,
    this.refreshToken,
    this.pendingVerificationEmail,
  });

  const AuthState.initial()
      : isLoading = false,
        isAuthenticated = false,
        user = null,
        errorMessage = null,
        accessToken = null,
        refreshToken = null,
        pendingVerificationEmail = null;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? user,
    String? errorMessage,
    String? accessToken,
    String? refreshToken,
    String? pendingVerificationEmail,
    bool clearPendingVerification = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      pendingVerificationEmail: clearPendingVerification
          ? null
          : pendingVerificationEmail ?? this.pendingVerificationEmail,
    );
  }
}

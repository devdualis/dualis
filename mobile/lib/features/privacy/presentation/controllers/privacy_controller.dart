import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/privacy_remote_data_source.dart';
import '../../../../core/notifications/app_notification_center.dart';

class PrivacyState {
  final bool isExporting;
  final bool isDeleting;
  /// Raw failure; the screen turns it into localized text with
  /// ErrorMessageResolver, so no fixed language lives here.
  final Object? error;
  final Map<String, dynamic>? exportedData;
  final bool isAccountDeleted;

  const PrivacyState({
    this.isExporting = false,
    this.isDeleting = false,
    this.error,
    this.exportedData,
    this.isAccountDeleted = false,
  });

  PrivacyState copyWith({
    bool? isExporting,
    bool? isDeleting,
    Object? error,
    Map<String, dynamic>? exportedData,
    bool? isAccountDeleted,
  }) {
    return PrivacyState(
      isExporting: isExporting ?? this.isExporting,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
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

  Future<Map<String, dynamic>?> exportData() async {
    state = state.copyWith(
      isExporting: true,
      error: null,
    );
    try {
      final token = await _secureStorage.getAccessToken() ??
          ref.read(authControllerProvider).accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('session expired');
      }
      final data = await _remoteDataSource.exportUserData(token: token);
      state = state.copyWith(
        isExporting: false,
        exportedData: data,
      );
      return data;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e,
      );
      return null;
    }
  }

  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(
      isDeleting: true,
      error: null,
    );
    try {
      final token = await _secureStorage.getAccessToken() ??
          ref.read(authControllerProvider).accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('session expired');
      }
      await _remoteDataSource.deleteUserAccount(
        token: token,
        password: password,
      );
      await _db.wipeAllLocalData();
      // Queued notification taps go with the rest of the local data.
      await ref.read(notificationActionQueueProvider).clear();
      try {
        await _secureStorage.deleteHabitsData();
      } catch (_) {}
      await ref.read(authControllerProvider.notifier).logout();
      state = state.copyWith(
        isDeleting: false,
        isAccountDeleted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e,
      );
      return false;
    }
  }
}

final privacyControllerProvider =
    NotifierProvider.autoDispose<PrivacyController, PrivacyState>(PrivacyController.new);

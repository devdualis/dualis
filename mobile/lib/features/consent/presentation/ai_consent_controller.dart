import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_storage_service.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/ai_consent_repository.dart';

final aiConsentControllerProvider =
    AsyncNotifierProvider<AiConsentController, AiConsentStatus>(
      AiConsentController.new,
      // No automatic retries: offline is answered at once with a calm
      // message, and the next use or a Settings visit reads it again.
      retry: _noRetry,
    );

Duration? _noRetry(int retryCount, Object error) => null;

/// The person's AI-processing consent as last read from the server.
///
/// Reloads when the signed-in account changes. A failed grant or revoke
/// leaves the state as it was.
class AiConsentController extends AsyncNotifier<AiConsentStatus> {
  /// Secure-storage key of the device decline flag for a consent version.
  static String declineKey(String version) =>
      'dualis_ai_consent_declined_$version';

  AiConsentRepository get _repo => ref.read(aiConsentRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);

  @override
  Future<AiConsentStatus> build() {
    ref.watch(authControllerProvider.select((s) => s.user?.id));
    return ref.read(aiConsentRepositoryProvider).status();
  }

  /// Current status, loading it again when the last read failed.
  /// Null when the server cannot be reached.
  Future<AiConsentStatus?> load() async {
    final current = state.asData?.value;
    if (current != null && !state.isLoading) return current;
    try {
      return await future;
    } catch (_) {
      await refresh();
      return state.asData?.value;
    }
  }

  /// Reads the status from the server. On failure keeps the last known
  /// status, or records the error when there is none.
  Future<void> refresh() async {
    try {
      state = AsyncData(await _repo.status());
    } catch (e, st) {
      if (state.asData == null) state = AsyncError(e, st);
    }
  }

  /// Records the consent for the server's current version. True on success.
  ///
  /// Throws [AiConsentVersionMismatch] after reloading the status when the
  /// server's version changed, so the caller can ask again.
  Future<bool> grant() async {
    final current = await load();
    if (current == null) return false;
    try {
      state = AsyncData(await _repo.grant(current.currentVersion));
      try {
        await _storage.delete(key: declineKey(current.currentVersion));
      } catch (_) {}
      return true;
    } on AiConsentVersionMismatch {
      await refresh();
      rethrow;
    } catch (_) {
      return false;
    }
  }

  /// Revokes the consent. True on success.
  Future<bool> revoke() async {
    try {
      state = AsyncData(await _repo.revoke());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the person said "Agora não" on this device for the server's
  /// current consent version.
  Future<bool> declinedOnDevice() async {
    final current = await load();
    if (current == null) return false;
    try {
      return await _storage.read(key: declineKey(current.currentVersion)) ==
          'yes';
    } catch (_) {
      return false;
    }
  }

  /// Remembers a decline on this device for the current consent version,
  /// so features that ask only once do not ask again. No personal data.
  Future<void> rememberDecline() async {
    final current = await load();
    if (current == null) return;
    try {
      await _storage.write(
        key: declineKey(current.currentVersion),
        value: 'yes',
      );
    } catch (_) {}
  }
}

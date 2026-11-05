import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/ai_consent_repository.dart';

final aiConsentControllerProvider =
    AsyncNotifierProvider<AiConsentController, AiConsentStatus>(
      AiConsentController.new,
    );

/// The person's AI-processing consent as last read from the server.
///
/// Reloads when the signed-in account changes. A failed grant or revoke
/// leaves the state as it was.
class AiConsentController extends AsyncNotifier<AiConsentStatus> {
  AiConsentRepository get _repo => ref.read(aiConsentRepositoryProvider);

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
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../config/feature_flags.dart';
import 'biometric_service.dart';
import 'secure_storage_service.dart';

/// Overridable in tests with a mock.
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// Whether this device can ask for a fingerprint, face or device PIN.
/// Only read on Premium builds (the settings switch is hidden otherwise).
final biometricSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricServiceProvider).isHardwareSupported(),
);

@immutable
class BiometricLockState {
  /// The person turned on "unlock with biometrics" in Settings.
  final bool enabled;

  /// The app content is hidden until the person unlocks.
  final bool locked;

  /// The saved setting has not been read yet (cold start only).
  final bool checking;

  const BiometricLockState({
    this.enabled = false,
    this.locked = false,
    this.checking = false,
  });

  BiometricLockState copyWith({bool? enabled, bool? locked, bool? checking}) {
    return BiometricLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      checking: checking ?? this.checking,
    );
  }
}

/// Premium-only app lock. Locks on cold start and after the app spent at
/// least [backgroundLimit] in the background. Free builds always get an
/// empty, never-locked state and never touch biometrics or storage.
class BiometricLockController extends Notifier<BiometricLockState> {
  static const backgroundLimit = Duration(seconds: 60);

  /// Replaced in tests to simulate time spent in the background.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  DateTime? _pausedAt;
  bool _authInProgress = false;
  bool _autoPromptPending = false;

  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);

  @override
  BiometricLockState build() {
    if (!ref.watch(premiumProfilesEnabledProvider)) {
      return const BiometricLockState();
    }
    ref.listen<bool>(authControllerProvider.select((s) => s.isAuthenticated), (
      previous,
      next,
    ) {
      if (previous == true && !next) _onLoggedOut();
    });
    _loadSavedSetting();
    return const BiometricLockState(checking: true);
  }

  Future<void> _loadSavedSetting() async {
    bool? shouldLock;
    // One retry: a keychain read can fail once right after boot.
    for (var attempt = 0; attempt < 2 && shouldLock == null; attempt++) {
      try {
        shouldLock = await _readShouldLock();
      } catch (_) {}
    }
    if (!state.checking) return;
    if (shouldLock == null) {
      // The saved setting cannot be read: fail closed. The device passcode,
      // the account password and "Sair da conta" all still get past it.
      _autoPromptPending = true;
      state = const BiometricLockState(locked: true);
      return;
    }
    _autoPromptPending = shouldLock;
    state = BiometricLockState(enabled: shouldLock, locked: shouldLock);
  }

  /// True when the lock is on and there is a stored session to protect.
  Future<bool> _readShouldLock() async {
    if (!await _storage.isBiometricEnabled()) return false;
    final tokens = await Future.wait([
      _storage.getAccessToken(),
      _storage.getRefreshToken(),
    ]);
    if (tokens.any((t) => t != null && t.isNotEmpty)) return true;
    // A flag with no session: iOS keeps the keychain across reinstalls.
    // Nothing to protect, and locking would trap the person, so drop it.
    try {
      await _storage.setBiometricEnabled(false);
    } catch (_) {}
    return false;
  }

  /// Escape hatch on the lock screen: ends the session (which shows
  /// nothing) so nobody is ever stuck behind the lock.
  Future<void> signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (_) {}
    _onLoggedOut();
  }

  void _onLoggedOut() {
    _pausedAt = null;
    _autoPromptPending = false;
    state = const BiometricLockState();
    // clearSession already deletes the flag; this keeps it off even if a
    // future change keeps more keys across logout.
    _storage.setBiometricEnabled(false).catchError((_) {});
  }

  /// Returns true once per lock, so the lock screen asks for biometrics by
  /// itself only the first time it shows (not again after visiting help).
  bool takeAutoPrompt() {
    final pending = _autoPromptPending;
    _autoPromptPending = false;
    return pending;
  }

  Future<bool> _authenticate(String reason) async {
    _authInProgress = true;
    try {
      return await ref
          .read(biometricServiceProvider)
          .authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    } finally {
      _authInProgress = false;
    }
  }

  /// Turns the lock on. Needs one successful check first, so nobody turns
  /// it on with a fingerprint or face the device does not accept.
  Future<bool> enable(String reason) async {
    if (!ref.read(premiumProfilesEnabledProvider)) return false;
    final ok = await _authenticate(reason);
    if (!ok) return false;
    try {
      await _storage.setBiometricEnabled(true);
    } catch (_) {
      return false;
    }
    state = state.copyWith(enabled: true, checking: false);
    return true;
  }

  Future<void> disable() async {
    try {
      await _storage.setBiometricEnabled(false);
    } catch (_) {}
    state = state.copyWith(enabled: false, locked: false, checking: false);
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    final ok = await _authenticate(reason);
    if (ok) _unlock();
    return ok;
  }

  /// Fallback when biometrics fail: checks the account password with the
  /// login API for the signed-in email. A successful login only renews this
  /// account's tokens; local entries and offline data stay untouched. On
  /// failure the reason is in the auth state's errorMessage.
  Future<PasswordUnlockResult> unlockWithPassword(String password) async {
    final auth = ref.read(authControllerProvider.notifier);
    var email = ref.read(authControllerProvider).user?.email;
    if (email == null || email.isEmpty) {
      try {
        email = (await _storage.getUserProfile())?.email;
      } catch (_) {}
    }
    if (email == null || email.isEmpty) return PasswordUnlockResult.noAccount;
    final ok = await auth.login(email: email, password: password);
    if (!ok) return PasswordUnlockResult.failed;
    _unlock();
    return PasswordUnlockResult.success;
  }

  void _unlock() {
    _pausedAt = null;
    _autoPromptPending = false;
    state = state.copyWith(locked: false, checking: false);
  }

  /// Only `paused` counts as background. `inactive` also fires during the
  /// Face ID / fingerprint dialog and the notification shade, which used to
  /// cause lock loops.
  void onPaused() {
    if (_authInProgress || !state.enabled) return;
    _pausedAt ??= clock();
  }

  void onResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || !state.enabled || state.locked) return;
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    if (clock().difference(pausedAt) >= backgroundLimit) {
      _autoPromptPending = true;
      state = state.copyWith(locked: true);
    }
  }
}

enum PasswordUnlockResult { success, failed, noAccount }

final biometricLockControllerProvider =
    NotifierProvider<BiometricLockController, BiometricLockState>(
      BiometricLockController.new,
    );

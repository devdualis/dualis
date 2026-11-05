import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/user_profile.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const String _keyAccessToken = 'dualis_access_token';
  static const String _keyRefreshToken = 'dualis_refresh_token';
  static const String _keyUserId = 'dualis_user_id';
  static const String _keyUserProfile = 'dualis_user_profile';
  static const String _keyBiometricEnabled = 'dualis_biometric_enabled';
  static const String _keyPendingVerificationEmail =
      'dualis_pending_verification_email';
  static const String _prefixDailyCheckIn = 'dualis_daily_checkin_';
  static const String _keyLocalDataOwner = 'dualis_local_data_owner';

  /// The person's water goal and reminder choices. Kept on logout for the
  /// same account (it has no server copy); dropped when another account
  /// signs in on this device.
  static const String keyHydrationSettings = 'dualis_hydration_settings';

  /// "Ler as perguntas em voz alta" (voice check-in). A device preference,
  /// not personal data: kept on logout.
  static const String keyVoiceReadAloud = 'dualis_voice_read_aloud';

  /// Set while a settings change has not reached the server yet.
  static const String keyHydrationSettingsPending =
      'dualis_hydration_settings_pending';

  /// Daily habits of each profile: answers, the queue of answers not sent yet
  /// and the cycle setting. Like the journal outbox, kept on logout for the
  /// same account and wiped when another account signs in on this device.
  static const String habitsKeyPrefix = 'dualis_habits_';

  /// Set once the profile photo framing has been confirmed or adjusted with
  /// the top-third rule, dismissing the one-time adjustment hint.
  static const String keyPhotoFramingAdjusted =
      'dualis_photo_framing_adjusted_v2';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  /// User whose entries are in the local database (kept across logout).
  Future<String?> getLocalDataOwnerId() =>
      _storage.read(key: _keyLocalDataOwner);

  Future<void> saveLocalDataOwnerId(String userId) =>
      _storage.write(key: _keyLocalDataOwner, value: userId);

  Future<void> saveUserProfile(UserProfile user) async {
    try {
      await _storage.write(
        key: _keyUserProfile,
        value: jsonEncode(user.toJson()),
      );
    } catch (_) {}
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final raw = await _storage.read(key: _keyUserProfile);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Email of an account registered but not yet verified. Survives app
  /// restarts so the verification screen can come back until it is verified.
  Future<void> savePendingVerificationEmail(String email) =>
      _storage.write(key: _keyPendingVerificationEmail, value: email);

  Future<String?> getPendingVerificationEmail() =>
      _storage.read(key: _keyPendingVerificationEmail);

  Future<void> clearPendingVerificationEmail() =>
      _storage.delete(key: _keyPendingVerificationEmail);

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isPhotoFramingAdjusted() async {
    final val = await _storage.read(key: keyPhotoFramingAdjusted);
    return val == 'true';
  }

  Future<void> setPhotoFramingAdjusted([bool adjusted = true]) =>
      _storage.write(key: keyPhotoFramingAdjusted, value: adjusted ? 'true' : 'false');

  Future<void> saveDailyCheckIn({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final key = '$_prefixDailyCheckIn$userId';
    await _storage.write(key: key, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async {
    final key = '$_prefixDailyCheckIn$userId';
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDailyCheckIn(String userId) async {
    final key = '$_prefixDailyCheckIn$userId';
    await _storage.delete(key: key);
  }

  // v2: wellness labels (outcomes cached before the repositioning carry clinical text).
  static const String _prefixTodayTriageOutcome = 'dualis_today_triage_outcome_v2_';

  Future<void> saveTodayTriageOutcome({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final key = '$_prefixTodayTriageOutcome$userId';
    await _storage.write(key: key, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getTodayTriageOutcome(String userId) async {
    final key = '$_prefixTodayTriageOutcome$userId';
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTodayTriageOutcome(String userId) async {
    final key = '$_prefixTodayTriageOutcome$userId';
    await _storage.delete(key: key);
  }

  Future<String?> read({required String key}) => _storage.read(key: key);

  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  Future<void> delete({required String key}) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();

  /// Ends the session: wipes tokens and session data but keeps the local
  /// data owner, the hydration settings and the daily habits, which belong to
  /// the device's last account and are checked again on the next login.
  Future<void> clearSession() async {
    const kept = [
      _keyLocalDataOwner,
      keyHydrationSettings,
      keyHydrationSettingsPending,
      keyVoiceReadAloud,
    ];
    final saved = <String, String>{};
    for (final key in kept) {
      try {
        final value = await _storage.read(key: key);
        if (value != null) saved[key] = value;
      } catch (_) {}
    }
    try {
      final all = await _storage.readAll();
      for (final entry in all.entries) {
        if (entry.key.startsWith(habitsKeyPrefix)) saved[entry.key] = entry.value;
      }
    } catch (_) {}
    await _storage.deleteAll();
    for (final entry in saved.entries) {
      try {
        await _storage.write(key: entry.key, value: entry.value);
      } catch (_) {}
    }
  }

  /// Removes every profile's daily habits from this device.
  Future<void> deleteHabitsData() async {
    final all = await _storage.readAll();
    for (final key in all.keys.toList()) {
      if (key.startsWith(habitsKeyPrefix)) await _storage.delete(key: key);
    }
  }
}

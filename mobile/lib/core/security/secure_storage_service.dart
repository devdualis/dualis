import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const String _keyAccessToken = 'dualis_access_token';
  static const String _keyRefreshToken = 'dualis_refresh_token';
  static const String _keyUserId = 'dualis_user_id';
  static const String _keyBiometricEnabled = 'dualis_biometric_enabled';
  static const String _prefixDailyCheckIn = 'dualis_daily_checkin_';

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

  static const String _prefixTodayTriageOutcome = 'dualis_today_triage_outcome_';

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
}

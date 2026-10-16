import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

/// Minimal safety audit endpoint (optional auth, never fails server-side).
const String safetyEventPath = '/v1/journal/safety-event';

/// What the user did with the help resources. Nothing about their entries.
enum SafetyEventAction {
  openedResources('opened_resources'),
  callStarted('call_started');

  final String wireValue;
  const SafetyEventAction(this.wireValue);
}

/// Records "help resources opened" / "call started" events (LGPD data
/// minimisation: no symptoms, levels or categories).
///
/// Fire-and-forget: never blocks or throws into the UI, works offline and
/// without a session.
class EmergencyAuditService {
  final ApiClient _apiClient;

  EmergencyAuditService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void reportFireAndForget(SafetyEventAction action, {String? channel}) {
    unawaited(report(action, channel: channel).catchError((Object err) {
      debugPrint('Safety event not sent: $err');
      return false;
    }));
  }

  Future<bool> report(SafetyEventAction action, {String? channel}) async {
    try {
      final response = await _apiClient.post(
        safetyEventPath,
        data: {
          'action': action.wireValue,
          if (channel != null) 'channel': channel,
          'clientTimestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Safety event not sent: $e');
      return false;
    }
  }
}

final emergencyAuditServiceProvider = Provider<EmergencyAuditService>((ref) {
  return EmergencyAuditService(apiClient: ref.watch(apiClientProvider));
});

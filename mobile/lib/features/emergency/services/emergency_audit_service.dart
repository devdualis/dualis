import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/emergency_context.dart';

/// Asynchronous client service responsible for transmitting emergency risk events
/// to the backend for regulatory compliance and clinical auditability (LGPD Art. 11).
///
/// Dispatches telemetry via unawaited fire-and-forget requests so client-side life safety
/// flows are never blocked or throttled by network conditions.
class EmergencyAuditService {
  final ApiClient _apiClient;

  EmergencyAuditService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Transmits the emergency event payload in a non-blocking, fire-and-forget pattern.
  void reportEventFireAndForget(
    EmergencyContext context, {
    String? actionTaken,
  }) {
    unawaited(
      reportEvent(context, actionTaken: actionTaken).then((_) {}).catchError((err) {
        debugPrint('EmergencyAuditService telemetry failed non-critically: $err');
      }),
    );
  }

  /// Sends the structured emergency event payload to the backend audit endpoint.
  Future<bool> reportEvent(
    EmergencyContext context, {
    String? actionTaken,
  }) async {
    try {
      final payload = {
        'triggerCategory': context.category.name,
        'severityLevel': context.severityLevel,
        'sourceVertical': context.isEmotional ? 'EMOTIONAL' : 'PHYSICAL',
        'clientTimestamp': context.detectedAt.toIso8601String(),
        if (actionTaken != null) 'actionTaken': actionTaken,
      };

      final response = await _apiClient.post(
        ApiEndpoints.emergencyEvent,
        data: payload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Emergency audit reporting encountered exception: $e');
      return false;
    }
  }
}

/// Riverpod provider for [EmergencyAuditService].
final emergencyAuditServiceProvider = Provider<EmergencyAuditService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmergencyAuditService(apiClient: apiClient);
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/feature_flags.dart';
import '../../features/profile/presentation/controllers/active_profile_controller.dart';

/// Dio interceptor that injects the active profile ID into the `X-Profile-Id`
/// header when premium profiles are enabled and the request doesn't already
/// specify one explicitly.
class ProfileHeaderInterceptor extends Interceptor {
  final Ref? _ref;
  final ProviderContainer? _container;
  final bool Function()? _isEnabled;
  final String? Function()? _getActiveProfileId;

  ProfileHeaderInterceptor({
    Ref? ref,
    ProviderContainer? container,
    bool Function()? isEnabled,
    String? Function()? getActiveProfileId,
  })  : _ref = ref,
        _container = container,
        _isEnabled = isEnabled,
        _getActiveProfileId = getActiveProfileId;

  bool _isFeatureEnabled() {
    final isEnabled = _isEnabled;
    if (isEnabled != null) return isEnabled();
    final ref = _ref;
    if (ref != null) return ref.read(premiumProfilesEnabledProvider);
    final container = _container;
    if (container != null) return container.read(premiumProfilesEnabledProvider);
    return false;
  }

  String? _getActiveProfileIdValue() {
    final getActiveProfileId = _getActiveProfileId;
    if (getActiveProfileId != null) return getActiveProfileId();
    final ref = _ref;
    if (ref != null) {
      return ref.read(activeProfileControllerProvider).activeProfile?.id;
    }
    final container = _container;
    if (container != null) {
      return container.read(activeProfileControllerProvider).activeProfile?.id;
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final hasProfileHeader = options.headers.keys.any(
      (k) => k.toLowerCase() == 'x-profile-id',
    );

    final isEnabled = _isFeatureEnabled();

    if (isEnabled && !hasProfileHeader) {
      final activeProfileId = _getActiveProfileIdValue();
      if (activeProfileId != null && activeProfileId.isNotEmpty) {
        options.headers['X-Profile-Id'] = activeProfileId;
      }
    }

    handler.next(options);
  }
}

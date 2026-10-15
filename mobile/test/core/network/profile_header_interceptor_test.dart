import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/network/profile_header_interceptor.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';

void main() {
  group('ProfileHeaderInterceptor', () {
    test('adds X-Profile-Id when premium is enabled and request has no header', () {
      final interceptor = ProfileHeaderInterceptor(
        isEnabled: () => true,
        getActiveProfileId: () => 'profile-123',
      );

      final options = RequestOptions(path: '/v1/triage/history');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['X-Profile-Id'], 'profile-123');
    });

    test('does NOT overwrite existing X-Profile-Id header', () {
      final interceptor = ProfileHeaderInterceptor(
        isEnabled: () => true,
        getActiveProfileId: () => 'profile-123',
      );

      final options = RequestOptions(
        path: '/v1/triage/outcome',
        headers: {'X-Profile-Id': 'explicit-profile-999'},
      );
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['X-Profile-Id'], 'explicit-profile-999');
    });

    test('does NOT overwrite existing lowercase x-profile-id header', () {
      final interceptor = ProfileHeaderInterceptor(
        isEnabled: () => true,
        getActiveProfileId: () => 'profile-123',
      );

      final options = RequestOptions(
        path: '/v1/triage/outcome',
        headers: {'x-profile-id': 'explicit-profile-888'},
      );
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      // Value remains the explicit one, not overwritten with 'profile-123'
      expect(options.headers['x-profile-id'], 'explicit-profile-888');
      expect(options.headers['X-Profile-Id'], 'explicit-profile-888');
    });

    test('does NOT add X-Profile-Id when premium is disabled', () {
      final interceptor = ProfileHeaderInterceptor(
        isEnabled: () => false,
        getActiveProfileId: () => 'profile-123',
      );

      final options = RequestOptions(path: '/v1/triage/history');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('X-Profile-Id'), isFalse);
    });

    test('does NOT add header when activeProfileId is null', () {
      final interceptor = ProfileHeaderInterceptor(
        isEnabled: () => true,
        getActiveProfileId: () => null,
      );

      final options = RequestOptions(path: '/v1/triage/history');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('X-Profile-Id'), isFalse);
    });

    test('reads from Ref and activeProfileControllerProvider properly', () {
      final container = ProviderContainer(
        overrides: [
          premiumProfilesEnabledProvider.overrideWithValue(true),
          activeProfileControllerProvider.overrideWith(() => _FakeActiveProfileController(
                const Profile(
                  id: 'prof-ref-1',
                  name: 'Ana',
                  profileType: ProfileType.primary,
                  ownership: ProfileOwnership.own,
                  accessLevel: ProfileAccessLevel.owner,
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final interceptor = ProfileHeaderInterceptor(container: container);
      final options = RequestOptions(path: '/v1/hydration/today');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['X-Profile-Id'], 'prof-ref-1');
    });
  });
}

class _FakeActiveProfileController extends ActiveProfileController {
  final Profile _profile;
  _FakeActiveProfileController(this._profile);

  @override
  ActiveProfileState build() {
    return ActiveProfileState(
      profiles: [_profile],
      activeProfileId: _profile.id,
    );
  }
}

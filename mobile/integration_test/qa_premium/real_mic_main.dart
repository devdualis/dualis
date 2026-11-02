// QA only: the Premium app with the REAL speech engine (speech_to_text),
// a fake signed-in account and no network. Starts voice commands by itself
// every few seconds (nobody can tap the simulator from automation) and
// reports what the engine heard to host_helper.py (/log).
//
//   flutter run -d <udid> --dart-define=PREMIUM_FEATURES=true \
//     -t integration_test/qa_premium/real_mic_main.dart
// then on the Mac: say -v Luciana "histórico"
import 'dart:async';
import 'dart:io';

import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/notifications/app_notification_center.dart';
import 'package:dualis_mobile/core/router/app_router.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
import 'package:dualis_mobile/features/voice/presentation/voice_controller.dart';
import 'package:dualis_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/profile_fakes.dart';

Future<void> _log(String msg) async {
  try {
    final c = HttpClient();
    final r = await (await c.getUrl(
            Uri.http('127.0.0.1:8999', '/log', {'msg': 'real-mic: $msg'})))
        .close();
    await r.drain<void>();
    c.close();
  } catch (_) {}
}

class _NoPromptCenter extends AppNotificationCenter {
  _NoPromptCenter()
      : super(
          plugin: FlutterLocalNotificationsPlugin(),
          permissionPromptStore: AlreadyPromptedStore(),
        );

  @override
  Future<bool> requestPermissions() async => true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = FakeProfileBackend();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    apiClientProvider.overrideWith(
        (ref) => offlineApiClient(ref.watch(secureStorageServiceProvider))),
    profileRepositoryProvider.overrideWith((ref) => backend.repositoryFor(
        ref.watch(authControllerProvider
            .select((s) => s.isAuthenticated ? s.user?.id : null)))),
    appNotificationCenterProvider.overrideWith((ref) => _NoPromptCenter()),
  ]);
  await container
      .read(authControllerProvider.notifier)
      .login(email: userA.email, password: 'x');
  runApp(UncontrolledProviderScope(container: container, child: const DualisApp()));

  container.listen<VoiceState>(voiceControllerProvider, (prev, next) {
    if (next.partial.isNotEmpty && next.partial != prev?.partial) {
      _log('partial "${next.partial}"');
    }
    final f = next.feedback;
    if (f != null && f.id != prev?.feedback?.id) {
      final router = container.read(appRouterProvider);
      _log('feedback ${f.kind.name} "${f.text}" '
          'location=${router.state.matchedLocation}');
    }
    if (prev?.listening != next.listening) _log('listening=${next.listening}');
  });

  await Future<void>.delayed(const Duration(seconds: 5));
  await _log('started');
  Timer.periodic(const Duration(seconds: 3), (_) {
    final s = container.read(voiceControllerProvider);
    if (!s.listening) container.read(voiceControllerProvider.notifier).startCommands();
  });
}

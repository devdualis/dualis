import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_context.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_trigger_category.dart';
import 'package:dualis_mobile/features/emergency/presentation/controllers/emergency_controller.dart';
import 'package:dualis_mobile/features/emergency/services/telephony_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  LaunchOptions? lastLaunchOptions;
  bool canLaunchReturnValue = true;
  bool launchUrlReturnValue = true;
  Future<bool> Function(String url)? canLaunchHandler;

  @override
  Future<bool> canLaunch(String url) async {
    if (canLaunchHandler != null) {
      return canLaunchHandler!(url);
    }
    return canLaunchReturnValue;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastLaunchOptions = options;
    return launchUrlReturnValue;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUrlLauncherPlatform mockPlatform;
  late TelephonyService telephonyService;

  setUp(() {
    mockPlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockPlatform;
    telephonyService = const TelephonyService();
  });

  group('TelephonyService - External Intents', () {
    test('canMakeCalls returns true when platform supports tel URI scheme', () async {
      mockPlatform.canLaunchReturnValue = true;
      final result = await telephonyService.canMakeCalls();
      expect(result, isTrue);
    });

    test('canMakeCalls returns false when platform cannot handle telephony (e.g. Wi-Fi tablet)', () async {
      mockPlatform.canLaunchReturnValue = false;
      final result = await telephonyService.canMakeCalls();
      expect(result, isFalse);
    });

    test('callSamu formats and dispatches tel:192 intent', () async {
      mockPlatform.canLaunchReturnValue = true;
      mockPlatform.launchUrlReturnValue = true;

      final success = await telephonyService.callSamu();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'tel:192');
      expect(mockPlatform.lastLaunchOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('callCvv formats and dispatches tel:188 intent', () async {
      mockPlatform.canLaunchReturnValue = true;
      mockPlatform.launchUrlReturnValue = true;

      final success = await telephonyService.callCvv();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'tel:188');
      expect(mockPlatform.lastLaunchOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('callBombeiros formats and dispatches tel:193 intent', () async {
      mockPlatform.canLaunchReturnValue = true;
      mockPlatform.launchUrlReturnValue = true;

      final success = await telephonyService.callBombeiros();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'tel:193');
      expect(mockPlatform.lastLaunchOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('callPolicia formats and dispatches tel:190 intent', () async {
      mockPlatform.canLaunchReturnValue = true;
      mockPlatform.launchUrlReturnValue = true;

      final success = await telephonyService.callPolicia();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'tel:190');
      expect(mockPlatform.lastLaunchOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('openNearestEmergencyRoom dispatches geo intent when supported', () async {
      mockPlatform.canLaunchReturnValue = true;
      mockPlatform.launchUrlReturnValue = true;

      final success = await telephonyService.openNearestEmergencyRoom();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'geo:0,0?q=pronto+socorro');
      expect(mockPlatform.lastLaunchOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('openNearestEmergencyRoom falls back to maps web URL if geo intent is unsupported', () async {
      int callCount = 0;
      mockPlatform.canLaunchHandler = (url) async {
        callCount++;
        if (url.startsWith('geo:')) return false;
        if (url.startsWith('https://')) return true;
        return false;
      };

      final success = await telephonyService.openNearestEmergencyRoom();

      expect(success, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'https://www.google.com/maps/search/pronto+socorro');
      expect(callCount, 2);
    });

    test('call returns false gracefully if canLaunch returns false', () async {
      mockPlatform.canLaunchReturnValue = false;

      final success = await telephonyService.callSamu();

      expect(success, isFalse);
      expect(mockPlatform.lastLaunchedUrl, isNull);
    });
  });

  group('EmergencyController - State Management', () {
    test('initial state is AsyncValue.data(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(emergencyControllerProvider);
      expect(state.value, isNull);
    });

    test('clearEmergency resets state to AsyncValue.data(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(emergencyControllerProvider.notifier);
      final emergencyContext = EmergencyContext(
        category: EmergencyTriggerCategory.chestPain,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
      );

      controller.state = AsyncValue.data(emergencyContext);
      expect(container.read(emergencyControllerProvider).value, emergencyContext);

      controller.clearEmergency();
      expect(container.read(emergencyControllerProvider).value, isNull);
    });

    test('recordExitConfirmed resets state to AsyncValue.data(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(emergencyControllerProvider.notifier);
      final emergencyContext = EmergencyContext(
        category: EmergencyTriggerCategory.suicidalCrisis,
        severityLevel: 5,
        isEmotional: true,
        detectedAt: DateTime.now(),
      );

      controller.state = AsyncValue.data(emergencyContext);
      controller.recordExitConfirmed();
      expect(container.read(emergencyControllerProvider).value, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:dualis_mobile/features/emergency/services/telephony_service.dart';
import 'emergency_test_helpers.dart';

void main() {
  late FakeUrlLauncherPlatform platform;
  const service = TelephonyService();

  setUp(() {
    platform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
  });

  test('callNumber dials a tel: URI without spaces', () async {
    expect(await service.callNumber('808 24 24 24'), isTrue);
    expect(platform.launched.single, 'tel:808242424');
  });

  test('callNumber returns false when the device cannot call', () async {
    platform.canLaunchReturnValue = false;
    expect(await service.callNumber('192'), isFalse);
    expect(platform.launched, isEmpty);
  });

  test('openNearestEmergencyRoom searches the given query', () async {
    expect(await service.openNearestEmergencyRoom('pronto-socorro'), isTrue);
    expect(platform.launched.single, contains('pronto-socorro'));
  });
}

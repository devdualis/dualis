import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/app_config/app_semver.dart';

void main() {
  group('isAppVersionBelowMinimum', () {
    test('detects older patch/minor/major', () {
      expect(isAppVersionBelowMinimum('0.9.9', '1.0.0'), isTrue);
      expect(isAppVersionBelowMinimum('1.0.0', '1.0.0'), isFalse);
      expect(isAppVersionBelowMinimum('1.1.0', '1.0.5'), isFalse);
      expect(isAppVersionBelowMinimum('1.0', '1.0.1'), isTrue);
    });
  });
}

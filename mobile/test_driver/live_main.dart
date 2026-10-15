// Entry point for live e2e sessions driven through the Flutter Driver
// extension (Phase 11 Wave 3). Run with:
// flutter run -t test_driver/live_main.dart --dart-define=PREMIUM_FEATURES=true
import 'package:flutter_driver/driver_extension.dart';
import 'package:dualis_mobile/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}

// Temporary: boots the real app signed in (fake account, no network) and
// keeps it live so the redesign can be viewed and tapped. Not committed.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  binding.shouldPropagateDevicePointerEvents = true;

  testWidgets('preview hold', (tester) async {
    resetKeychain();
    await bootApp(tester);
    for (var i = 0; i < 1800; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

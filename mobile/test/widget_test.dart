import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/main.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';

void main() {
  testWidgets('DualisApp smoke test initializes to OnboardingScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DualisApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DualisLogo), findsOneWidget);
  });
}

import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async => null;
}

class _EmptyHistoryDataSource extends TriageHistoryRemoteDataSource {
  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async =>
      const TriageHistoryResponse(
        logs: [],
        physicalSummary: {},
        emotionalSummary: [],
        journalPatterns: [],
      );
}

class _TestActiveProfileController extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState();
}

Widget _harness({required bool premium}) {
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(premium),
      secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
      triageHistoryDataSourceProvider.overrideWithValue(_EmptyHistoryDataSource()),
      activeProfileControllerProvider.overrideWith(_TestActiveProfileController.new),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: DualAxisTriggerCard()),
      ),
    ),
  );
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _emotionalButton = Key('start_psicoemocional_triage_button');
const _physicalButton = Key('start_fisica_triage_button');

/// The badge icon is the match that is not inside the start button.
Finder _badge(IconData icon, Key buttonKey) {
  final all = find.byIcon(icon);
  final inButton = find.descendant(of: find.byKey(buttonKey), matching: all);
  return find.byWidgetPredicate((widget) {
    if (widget is! Icon || widget.icon != icon) return false;
    return !inButton.evaluate().any((e) => identical(e.widget, widget));
  });
}

void main() {
  testWidgets('Premium: the two badge icons get the gradient, buttons stay plain',
      (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_harness(premium: true));
    await tester.pumpAndSettle();

    expect(find.byKey(_emotionalButton), findsOneWidget);
    expect(find.byKey(_physicalButton), findsOneWidget);

    final card = find.byType(DualAxisTriggerCard);
    expect(find.descendant(of: card, matching: find.byType(ShaderMask)), findsNWidgets(2));
    expect(find.byKey(const Key('premium_active_dot')), findsNothing);

    for (final (icon, button, color) in [
      (Icons.psychology_rounded, _emotionalButton, AppColors.dualisSymbolGreen),
      (Icons.accessibility_new_rounded, _physicalButton, AppColors.dualisSymbolBlue),
    ]) {
      final badge = _badge(icon, button);
      expect(badge, findsOneWidget);
      expect(find.ancestor(of: badge, matching: find.byType(ShaderMask)), findsOneWidget);
      final glyph = tester.widget<Icon>(badge);
      expect(glyph.size, 22);
      expect(glyph.color, color);

      final buttonIcon = find.descendant(of: find.byKey(button), matching: find.byIcon(icon));
      expect(buttonIcon, findsOneWidget);
      expect(find.ancestor(of: buttonIcon, matching: find.byType(ShaderMask)), findsNothing);
    }
  });

  testWidgets('Free: no gradient anywhere in the card', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_harness(premium: false));
    await tester.pumpAndSettle();

    expect(find.byKey(_emotionalButton), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byKey(const Key('premium_active_dot')), findsNothing);
  });

  testWidgets('badge icon keeps the same rect in Free and Premium', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_harness(premium: false));
    await tester.pumpAndSettle();
    final freeRect = tester.getRect(_badge(Icons.psychology_rounded, _emotionalButton));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_harness(premium: true));
    await tester.pumpAndSettle();
    expect(tester.getRect(_badge(Icons.psychology_rounded, _emotionalButton)), freeRect);
  });
}

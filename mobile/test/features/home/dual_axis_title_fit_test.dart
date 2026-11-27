import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/core/config/feature_flags.dart';
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

Widget _harness(double textScale) {
  return ProviderScope(
    overrides: [
      premiumProfilesEnabledProvider.overrideWithValue(false),
      secureStorageServiceProvider.overrideWithValue(_FakeSecureStorage()),
      triageHistoryDataSourceProvider.overrideWithValue(
        _EmptyHistoryDataSource(),
      ),
      activeProfileControllerProvider.overrideWith(
        _TestActiveProfileController.new,
      ),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const Scaffold(
        body: SingleChildScrollView(child: DualAxisTriggerCard()),
      ),
    ),
  );
}

const _emotionalTile = Key('start_psicoemocional_triage_button');
const _physicalTile = Key('start_fisica_triage_button');

void _phoneView(WidgetTester tester) {
  // iPhone 17e: 390 pt wide, logical pixels at 1x for simple assertions.
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectTitleOnOneLine(
  WidgetTester tester,
  String title,
  Key tile,
  double textScale,
) {
  final text = find.text(title);
  expect(text, findsOneWidget, reason: 'title "$title" is shown once');

  final style = tester.widget<Text>(text).style!;
  final size = tester.getSize(text);
  // Rendered size is font size x text scale. One line is about 1.2 x that;
  // a mid-word break makes two lines (about 2.4 x). Under 1.8 x means no break.
  expect(
    size.height,
    lessThan(style.fontSize! * textScale * 1.8),
    reason: '"$title" wrapped onto a second line',
  );

  // The shrink-to-fit box stays inside its tile, so nothing overflows.
  final fitted = find.ancestor(of: text, matching: find.byType(FittedBox));
  expect(fitted, findsWidgets);
  expect(
    tester.getSize(fitted.first).width,
    lessThanOrEqualTo(tester.getSize(find.byKey(tile)).width),
    reason: '"$title" is wider than its tile',
  );
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'axis titles stay on one line at 390 pt, text scale $scale',
      (tester) async {
        _phoneView(tester);
        await tester.pumpWidget(_harness(scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no overflow');
        _expectTitleOnOneLine(tester, 'Psicoemocional', _emotionalTile, scale);
        _expectTitleOnOneLine(tester, 'Físico', _physicalTile, scale);

        // Both tiles share one title size, so they read as a pair.
        final emotionalSize =
            tester.widget<Text>(find.text('Psicoemocional')).style!.fontSize;
        final physicalSize =
            tester.widget<Text>(find.text('Físico')).style!.fontSize;
        expect(emotionalSize, physicalSize);
      },
    );
  }
}

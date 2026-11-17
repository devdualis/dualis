import 'package:dualis_mobile/core/config/feature_flags.dart';
import 'package:dualis_mobile/core/notifications/notifications_blocked_notice.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/care/presentation/care_routes.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/reminders_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records toggleReminders calls; loads nothing.
class _RecordingHydrationController extends HydrationController {
  _RecordingHydrationController(this._initial, {this.saveOk = true});

  final HydrationState _initial;
  final bool saveOk;
  final List<bool> toggles = [];

  @override
  HydrationState build() => _initial;

  @override
  Future<void> loadData() async {}

  @override
  Future<bool> toggleReminders(bool enabled) async {
    toggles.add(enabled);
    if (!saveOk) return false;
    state = HydrationState(
      settings: state.settings.copyWith(reminderEnabled: enabled),
    );
    return true;
  }
}

class _TestActiveProfileController extends ActiveProfileController {
  _TestActiveProfileController([this._initial = const ActiveProfileState()]);

  final ActiveProfileState _initial;

  @override
  ActiveProfileState build() => _initial;
}

const _primary = Profile(
  id: 'p-1',
  name: 'Maria Silva',
  profileType: ProfileType.primary,
  ownership: ProfileOwnership.own,
  accessLevel: ProfileAccessLevel.owner,
);

final _viewOnlyShared = Profile.fromJson(const {
  'id': 'shared-1',
  'name': 'Carlos Oliveira',
  'profileType': 'primary',
  'ownership': 'shared',
  'accessLevel': 'VIEW_ONLY',
});

class _Harness {
  _Harness({
    HydrationState? state,
    bool saveOk = true,
    this.allowed = true,
    this.premium = false,
    this.profiles,
  }) : controller = _RecordingHydrationController(
          state ?? const HydrationState(),
          saveOk: saveOk,
        );

  final _RecordingHydrationController controller;
  bool allowed;
  final bool premium;
  final ActiveProfileState? profiles;
  int allowedReads = 0;
  int openSettingsCalls = 0;

  Widget build() {
    final router = GoRouter(
      initialLocation: RoutePaths.reminders,
      routes: [
        GoRoute(
          path: RoutePaths.reminders,
          builder: (_, __) => const RemindersScreen(),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder: (_, __) => const Scaffold(body: Text('Emergency Screen')),
        ),
        GoRoute(
          path: CarePaths.medications,
          builder: (_, __) => const Scaffold(body: Text('Medications Screen')),
        ),
        GoRoute(
          path: CarePaths.appointments,
          builder: (_, __) => const Scaffold(body: Text('Appointments Screen')),
        ),
        GoRoute(
          path: CarePaths.vaccines,
          builder: (_, __) => const Scaffold(body: Text('Vaccines Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        hydrationControllerProvider.overrideWith(() => controller),
        notificationsAllowedProvider.overrideWith((ref) async {
          allowedReads++;
          return allowed;
        }),
        openNotificationSettingsProvider
            .overrideWithValue(() async => openSettingsCalls++),
        premiumProfilesEnabledProvider.overrideWithValue(premium),
        activeProfileControllerProvider.overrideWith(
          () => profiles == null
              ? _TestActiveProfileController()
              : _TestActiveProfileController(profiles!),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
        routerConfig: router,
        builder: (context, child) => UrgentHelpOverlay(
          router: router,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

const _waterSwitch = Key('settings_water_reminder_switch');

void main() {
  // Tall enough that every row and sheet fits without scrolling.
  Future<_Harness> pump(WidgetTester tester, _Harness h) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    return h;
  }

  group('RemindersScreen rows', () {
    testWidgets('shows check-in, water and no care row in Free builds',
        (tester) async {
      await pump(tester, _Harness());

      expect(find.text('Lembretes'), findsOneWidget);
      expect(find.text('Veja quando o DualisCheckUp avisa você.'), findsOneWidget);
      expect(find.byKey(const Key('reminders_checkin_row')), findsOneWidget);
      expect(find.text('Check-in diário'), findsOneWidget);
      expect(
        find.text(
          'A cada 2 horas, das 08:00 às 22:00, até você fazer o check-in do dia',
        ),
        findsOneWidget,
      );
      expect(find.byKey(_waterSwitch), findsOneWidget);
      expect(find.text('Água'), findsOneWidget);
      // Defaults: on, scheduled 08..20.
      expect(find.text('Ligado, das 08:00 às 20:00'), findsOneWidget);
      expect(find.byKey(const Key('reminders_care_row')), findsNothing);
      expect(
        find.text(
          'Os avisos usam textos gerais. Nomes de medicamentos, vacinas e consultas só aparecem dentro do app.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Premium builds show the care row', (tester) async {
      await pump(tester, _Harness(premium: true));

      expect(find.byKey(const Key('reminders_care_row')), findsOneWidget);
      expect(find.text('Cuidados'), findsOneWidget);
      expect(find.text('Medicamentos, consultas e vacinas'), findsOneWidget);
    });

    testWidgets('water off shows "Desligado"', (tester) async {
      await pump(
        tester,
        _Harness(
          state: const HydrationState(
            settings: HydrationSettings(reminderEnabled: false),
          ),
        ),
      );
      expect(find.text('Desligado'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byKey(_waterSwitch)).value,
          isFalse);
    });
  });

  group('Water switch', () {
    testWidgets('turning it off calls toggleReminders(false)', (tester) async {
      final h = await pump(tester, _Harness());

      await tester.tap(find.byKey(_waterSwitch));
      await tester.pumpAndSettle();

      expect(h.controller.toggles, [false]);
      expect(tester.widget<SwitchListTile>(find.byKey(_waterSwitch)).value,
          isFalse);
      expect(find.text('Desligado'), findsOneWidget);
    });

    testWidgets('a failing save says so and keeps its value', (tester) async {
      final h = await pump(tester, _Harness(saveOk: false));

      await tester.tap(find.byKey(_waterSwitch));
      await tester.pumpAndSettle();

      expect(h.controller.toggles, [false]);
      expect(find.byKey(const Key('save_failed_snack')), findsOneWidget);
      // Reminders start on; turning them off failed, so they stay on.
      expect(tester.widget<SwitchListTile>(find.byKey(_waterSwitch)).value,
          isTrue);
    });

    testWidgets('is disabled for a view-only shared profile', (tester) async {
      final h = await pump(
        tester,
        _Harness(
          premium: true,
          profiles: ActiveProfileState(
            profiles: [_primary, _viewOnlyShared],
            activeProfileId: _viewOnlyShared.id,
          ),
        ),
      );

      final tile = tester.widget<SwitchListTile>(find.byKey(_waterSwitch));
      expect(tile.onChanged, isNull);
      await tester.tap(find.byKey(_waterSwitch));
      await tester.pumpAndSettle();
      expect(h.controller.toggles, isEmpty);
    });

    testWidgets('is enabled on the own primary profile', (tester) async {
      await pump(
        tester,
        _Harness(
          premium: true,
          profiles: const ActiveProfileState(
            profiles: [_primary],
            activeProfileId: 'p-1',
          ),
        ),
      );
      final tile = tester.widget<SwitchListTile>(find.byKey(_waterSwitch));
      expect(tile.onChanged, isNotNull);
    });
  });

  group('Help', () {
    testWidgets('urgent help is one tap away', (tester) async {
      await pump(tester, _Harness());

      final help = find.byKey(const Key('urgent_help_button'));
      expect(help, findsOneWidget);
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(find.text('Emergency Screen'), findsOneWidget);
    });
  });
}

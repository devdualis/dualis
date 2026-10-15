import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/domain/models/shared_access_grant.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/features/profile/presentation/screens/add_dependent_modal.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeActiveProfileController extends ActiveProfileController {
  FakeActiveProfileController({this.failWithMessage});

  final String? failWithMessage;

  String? lastName;
  DateTime? lastDateOfBirth;
  String? lastGender;
  String? lastRelationshipType;
  bool? lastLgpdConsent;
  int createDependentCallCount = 0;

  @override
  ActiveProfileState build() => const ActiveProfileState();

  @override
  Future<void> refresh() async {}

  @override
  void selectProfile(String profileId) {}

  @override
  Future<Profile> createDependent({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String relationshipType,
    required bool lgpdConsent,
  }) async {
    createDependentCallCount++;
    lastName = name;
    lastDateOfBirth = dateOfBirth;
    lastGender = gender;
    lastRelationshipType = relationshipType;
    lastLgpdConsent = lgpdConsent;

    if (failWithMessage != null) {
      state = state.copyWith(errorMessage: failWithMessage);
      throw Exception(failWithMessage);
    }

    return Profile(
      id: 'dep-test-1',
      name: name,
      profileType: ProfileType.dependentMinor,
      ownership: ProfileOwnership.dependent,
      accessLevel: ProfileAccessLevel.owner,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
  }

  @override
  Future<void> updateProfileName(String profileId, String name) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> acceptInvite(String inviteCode) async {}

  @override
  Future<void> revokeGrant(String grantId) async {}
}

Widget _host(FakeActiveProfileController fake, {Locale locale = const Locale('pt')}) {
  return ProviderScope(
    overrides: [
      activeProfileControllerProvider.overrideWith(() => fake),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddDependentModal(context),
              child: const Text('Open modal'),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openModal(WidgetTester tester, FakeActiveProfileController fake) async {
  await tester.pumpWidget(_host(fake));
  await tester.tap(find.text('Open modal'));
  await tester.pumpAndSettle();
}

Future<void> _fillValidForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Maria Silva');
  await tester.enterText(fields.at(1), '15012015');
  await tester.pump();

  await tester.tap(
    find.text('Filho(a) menor de idade (Poder Familiar)'),
  );
  await tester.pumpAndSettle();
}

FilledButton _submitButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const ValueKey('add-dependent-submit')),
      matching: find.byType(FilledButton),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddDependentModal', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('exposes driver ValueKeys', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openModal(tester, FakeActiveProfileController());

      expect(find.byKey(const ValueKey('lgpd-art14-consent')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-dependent-submit')), findsOneWidget);
    });

    testWidgets('submit stays disabled until LGPD consent when form is valid',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openModal(tester, FakeActiveProfileController());
      await _fillValidForm(tester);

      expect(_submitButton(tester).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('lgpd-art14-consent')));
      await tester.pumpAndSettle();

      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('submit calls createDependent and closes on success',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fake = FakeActiveProfileController();
      await _openModal(tester, fake);
      await _fillValidForm(tester);

      await tester.tap(find.byKey(const ValueKey('lgpd-art14-consent')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.tap(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.pumpAndSettle();

      expect(fake.createDependentCallCount, 1);
      expect(fake.lastName, 'Maria Silva');
      expect(fake.lastGender, 'masculino');
      expect(fake.lastRelationshipType, 'parent');
      expect(fake.lastLgpdConsent, isTrue);
      expect(fake.lastDateOfBirth, DateTime(2015, 1, 15));

      expect(find.text('Cadastrar Dependente Legal'), findsNothing);
      expect(find.text('Dependente cadastrado com sucesso.'), findsOneWidget);
    });

    testWidgets('error keeps modal open', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fake = FakeActiveProfileController(
        failWithMessage: 'Falha de rede',
      );
      await _openModal(tester, fake);
      await _fillValidForm(tester);

      await tester.tap(find.byKey(const ValueKey('lgpd-art14-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.tap(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Cadastrar Dependente Legal'), findsOneWidget);
      expect(find.text('Falha de rede'), findsOneWidget);
      expect(fake.createDependentCallCount, 1);
    });
  });
}

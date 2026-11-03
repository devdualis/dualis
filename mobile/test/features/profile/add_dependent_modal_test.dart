import 'package:dualis_mobile/features/profile/data/profile_repository.dart';
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
  FakeActiveProfileController({this.failWithMessage, this.apiError});

  final String? failWithMessage;

  /// Thrown as-is, like the real controller rethrowing a backend 400.
  final ProfileApiException? apiError;

  String? lastName;
  DateTime? lastDateOfBirth;
  String? lastGender;
  String? lastRelationshipType;
  bool? lastLgpdConsent;
  String? lastLgpdLegalBasisNotes;
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
    String? lgpdLegalBasisNotes,
  }) async {
    createDependentCallCount++;
    lastLgpdLegalBasisNotes = lgpdLegalBasisNotes;
    lastName = name;
    lastDateOfBirth = dateOfBirth;
    lastGender = gender;
    lastRelationshipType = relationshipType;
    lastLgpdConsent = lgpdConsent;

    if (apiError != null) throw apiError!;
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

/// ddMMyyyy digits for a date [years] years before today (DateInputFormatter
/// adds the slashes).
String _dobDigitsYearsAgo(int years) {
  final now = DateTime.now();
  final d = DateTime(now.year - years, now.month, now.day);
  return '${d.day.toString().padLeft(2, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.year}';
}

Future<void> _enterDob(WidgetTester tester, String digits) async {
  await tester.enterText(find.byType(TextFormField).at(1), digits);
  await tester.pumpAndSettle();
}

Finder _tile(String relationship) =>
    find.byKey(ValueKey('relationship-$relationship'));

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
      expect(find.byKey(const ValueKey('add-dependent-notes')), findsOneWidget);
      await _fillValidForm(tester);

      expect(find.byKey(const ValueKey('lgpd-art14-consent')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-dependent-submit')), findsOneWidget);
    });

    testWidgets(
        'adult under supported decision: only adult tiles, Art. 11 consent, '
        'notes sent', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fake = FakeActiveProfileController();
      await _openModal(tester, fake);
      await tester.enterText(find.byType(TextFormField).at(0), 'João Souza');
      await _enterDob(tester, _dobDigitsYearsAgo(40));

      expect(_tile('curator'), findsOneWidget);
      expect(_tile('supported_decision'), findsOneWidget);
      expect(_tile('parent'), findsNothing);
      expect(_tile('legal_guardian'), findsNothing);
      expect(
        find.text(
            'Para maiores de 18 anos: curatela ou tomada de decisão apoiada.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lgpd-art11-consent')), findsOneWidget);
      expect(find.byKey(const ValueKey('lgpd-art14-consent')), findsNothing);
      expect(find.textContaining('Artigo 11, inciso I'), findsOneWidget);

      await tester.tap(_tile('supported_decision'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lgpd-art11-consent')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('add-dependent-notes')),
        'Termo de apoio 0001234-56.2025.8.26.0100',
      );
      await tester.pump();

      expect(_submitButton(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.tap(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.pumpAndSettle();

      expect(fake.createDependentCallCount, 1);
      expect(fake.lastRelationshipType, 'supported_decision');
      expect(fake.lastLgpdConsent, isTrue);
      expect(fake.lastLgpdLegalBasisNotes,
          'Termo de apoio 0001234-56.2025.8.26.0100');
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

    testWidgets(
        'minor: only parent and legal_guardian tiles with the Art. 14 consent',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openModal(tester, FakeActiveProfileController());

      expect(
        find.text('Informe a data de nascimento para ver os vínculos possíveis.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lgpd-art14-consent')), findsNothing);
      expect(find.byKey(const ValueKey('lgpd-art11-consent')), findsNothing);

      await _enterDob(tester, _dobDigitsYearsAgo(10));

      expect(_tile('parent'), findsOneWidget);
      expect(_tile('legal_guardian'), findsOneWidget);
      expect(_tile('curator'), findsNothing);
      expect(_tile('supported_decision'), findsNothing);
      expect(find.text('Para menores de 18 anos: poder familiar ou tutela.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('lgpd-art14-consent')), findsOneWidget);
      expect(find.byKey(const ValueKey('lgpd-art11-consent')), findsNothing);
      expect(find.textContaining('Artigo 14 da LGPD'), findsOneWidget);
    });

    testWidgets('18th birthday today counts as adult', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openModal(tester, FakeActiveProfileController());
      await _enterDob(tester, _dobDigitsYearsAgo(18));

      expect(_tile('curator'), findsOneWidget);
      expect(_tile('parent'), findsNothing);
    });

    testWidgets(
        'switching from adult to minor resets the relationship and the consent',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openModal(tester, FakeActiveProfileController());
      await tester.enterText(find.byType(TextFormField).at(0), 'Maria Silva');
      await _enterDob(tester, _dobDigitsYearsAgo(40));
      await tester.tap(_tile('curator'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lgpd-art11-consent')));
      await tester.pumpAndSettle();
      expect(_submitButton(tester).onPressed, isNotNull);

      await _enterDob(tester, _dobDigitsYearsAgo(10));

      expect(_tile('curator'), findsNothing);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      final consent = tester.widget<Checkbox>(
          find.byKey(const ValueKey('lgpd-art14-consent')));
      expect(consent.value, isFalse);
      expect(_submitButton(tester).onPressed, isNull);

      // Back to adult: the earlier choice is not restored.
      await _enterDob(tester, _dobDigitsYearsAgo(40));
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('lgpd-art11-consent')))
            .value,
        isFalse,
      );
    });

    testWidgets('notes are optional: empty notes send nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fake = FakeActiveProfileController();
      await _openModal(tester, fake);
      await _fillValidForm(tester);
      await tester.enterText(
          find.byKey(const ValueKey('add-dependent-notes')), '   ');
      await tester.tap(find.byKey(const ValueKey('lgpd-art14-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.tap(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.pumpAndSettle();

      expect(fake.createDependentCallCount, 1);
      expect(fake.lastLgpdLegalBasisNotes, isNull);
    });

    testWidgets('backend 400 message is shown unchanged', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const backendMessage =
          'O vínculo escolhido não corresponde à idade informada.';
      final fake = FakeActiveProfileController(
        apiError: const ProfileApiException(backendMessage, statusCode: 400),
      );
      await _openModal(tester, fake);
      await _fillValidForm(tester);
      await tester.tap(find.byKey(const ValueKey('lgpd-art14-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.tap(find.byKey(const ValueKey('add-dependent-submit')));
      await tester.pumpAndSettle();

      expect(find.text(backendMessage), findsOneWidget);
      expect(find.text('Cadastrar Dependente Legal'), findsOneWidget);
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

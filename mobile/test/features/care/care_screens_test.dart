import 'dart:typed_data';

import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/care/data/care_api.dart';
import 'package:dualis_mobile/features/care/data/care_notifications.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/features/care/domain/pni_calendar.dart';
import 'package:dualis_mobile/features/care/presentation/screens/allergies_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/care_hub_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/exam_review_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/medications_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/vaccines_screen.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dualis_bottom_nav_bar.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory "Meus cuidados" API.
class FakeCareApi implements CareApi {
  final Map<CareKind, List<CareRecord>> records = {for (final k in CareKind.values) k: []};
  final List<CareDocument> docs = [];
  final List<(String, DateTime, IntakeAction)> intakes = [];
  final List<Map<String, dynamic>> reviews = [];
  int _n = 0;

  CareRecord add(CareKind kind, Map<String, dynamic> data, {DateTime? occursAt}) {
    final r = CareRecord(id: 'r${++_n}', kind: kind, data: data, createdAt: DateTime(2026, 10, 1), occursAt: occursAt);
    records[kind]!.insert(0, r);
    return r;
  }

  @override
  Future<List<CareRecord>> list(CareKind kind, {String? parentId}) async =>
      records[kind]!.where((r) => parentId == null || r.parentId == parentId).toList();

  @override
  Future<CareRecord> create(CareKind kind, Map<String, dynamic> data) async => add(kind, data);

  @override
  Future<CareRecord> update(String id, Map<String, dynamic> data) async => add(CareKind.allergy, data);

  @override
  Future<void> delete(String id) async {
    for (final l in records.values) {
      l.removeWhere((r) => r.id == id);
    }
  }

  @override
  Future<CareRecord> logIntake(String medicationId, DateTime scheduledFor, IntakeAction action) async {
    intakes.add((medicationId, scheduledFor, action));
    records[CareKind.medicationIntake]!.insert(
      0,
      CareRecord(
        id: 'i${++_n}',
        kind: CareKind.medicationIntake,
        parentId: medicationId,
        occursAt: scheduledFor,
        data: {'action': action.name, 'scheduledFor': scheduledFor.toIso8601String()},
        createdAt: DateTime.now(),
      ),
    );
    return records[CareKind.medication]!.firstWhere((m) => m.id == medicationId);
  }

  @override
  Future<List<CareDocument>> documents({DocumentKind? kind}) async => docs;

  @override
  Future<CareDocument> document(String id) async => docs.firstWhere((d) => d.id == id);

  @override
  Future<CareDocument> upload({required DocumentKind kind, required String mime, required Uint8List bytes, required bool read, String? title}) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> file(String id) async => Uint8List(0);

  @override
  Future<CareDocument> review(String id, Map<String, dynamic> body) async {
    reviews.add(body);
    return docs.firstWhere((d) => d.id == id);
  }

  final List<String> reprocessed = [];

  @override
  Future<CareDocument> reprocess(String id) async {
    reprocessed.add(id);
    return docs.firstWhere((d) => d.id == id);
  }

  @override
  Future<void> deleteDocument(String id) async {}
}

class _NoopNotifications implements CareNotificationService {
  @override
  Future<void> reschedule({required List<Medication> medications, required List<CareRecord> appointments, required List<CareRecord> vaccineDoses}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ActiveProfileController {
  _Profile(this.profile);
  final Profile profile;

  @override
  ActiveProfileState build() => ActiveProfileState(profiles: [profile], activeProfileId: profile.id);
}

Profile _me({ProfileAccessLevel access = ProfileAccessLevel.owner, DateTime? birth}) => Profile(
      id: 'p1',
      name: 'Ana',
      profileType: ProfileType.primary,
      ownership: ProfileOwnership.own,
      accessLevel: access,
      dateOfBirth: birth ?? DateTime(1990, 5, 1),
    );

void main() {
  final pt = AppLocalizationsPt();

  Future<FakeCareApi> pump(WidgetTester tester, Widget screen, {FakeCareApi? api, Profile? profile}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = api ?? FakeCareApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        careApiProvider.overrideWithValue(fake),
        careNotificationServiceProvider.overrideWithValue(_NoopNotifications()),
        activeProfileControllerProvider.overrideWith(() => _Profile(profile ?? _me())),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: screen),
      ),
    ));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('hub lists every care area of the active profile', (tester) async {
    final api = FakeCareApi()..add(CareKind.allergy, {'type': 'food', 'name': 'Camarão', 'showOnProfile': true});
    await pump(tester, const CareHubScreen(), api: api);
    for (final key in ['vaccines', 'allergies', 'medications', 'appointments', 'exams', 'summary']) {
      expect(find.byKey(Key('care_hub_$key')), findsOneWidget);
    }
    expect(find.text('Camarão'), findsOneWidget);
  });

  testWidgets('vaccine calendar only counts registered doses and never says "atrasada"', (tester) async {
    final api = FakeCareApi()
      ..add(CareKind.vaccineDose, {'vaccineKey': 'hepatite_b', 'doseLabel': '1ª dose', 'appliedOn': '2020-01-01'}, occursAt: DateTime(2020));
    await pump(tester, const VaccinesScreen(), api: api);
    expect(find.text(pt.careVaccineCount(1, 3)), findsOneWidget);
    expect(find.text(pt.careVaccineNoRecord), findsWidgets);
    expect(find.textContaining(RegExp('atrasad|vencid', caseSensitive: false)), findsNothing);
  });

  test('booster date comes only from the published interval', () {
    expect(pniBoosterDate('dt', DateTime(2017, 3, 10)), DateTime(2027, 3, 10));
    expect(pniBoosterDate('febre_amarela', DateTime(2017, 3, 10)), isNull);
    expect(pniStageFor(DateTime(2020, 1, 1), today: DateTime(2026, 10, 28)), PniStage.child);
    expect(pniStageFor(DateTime(1950, 1, 1), today: DateTime(2026, 10, 28)), PniStage.elderly);
  });

  testWidgets('allergies screen shows the fixed no-cross-check note', (tester) async {
    await pump(tester, const AllergiesScreen());
    expect(find.text(pt.careAllergiesNoCrossCheck), findsOneWidget);
    expect(find.text(pt.careAllergiesEmpty), findsOneWidget);
  });

  testWidgets('view-only profile cannot add records', (tester) async {
    await pump(tester, const AllergiesScreen(), profile: _me(access: ProfileAccessLevel.viewOnly));
    expect(find.byKey(const Key('allergies_add')), findsNothing);
  });

  testWidgets('"Tomei" logs the intake for that scheduled time', (tester) async {
    final api = FakeCareApi()
      ..add(CareKind.medication, {
        'name': 'Losartana',
        'strength': '50 mg',
        'amountPerIntake': '1 comprimido',
        'times': ['23:59'],
        'weekdays': <int>[],
        'active': true,
      });
    await pump(tester, const MedicationsScreen(), api: api);
    expect(find.text('Losartana 50 mg'), findsOneWidget);
    await tester.tap(find.byKey(const Key('slot_taken_r1_2359')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(api.intakes.single, ('r1', DateTime(now.year, now.month, now.day, 23, 59), IntakeAction.taken));
  });

  testWidgets('exam values save only after every row is confirmed', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(
      id: 'd1',
      kind: DocumentKind.lab,
      mime: 'image/jpeg',
      status: DocumentStatus.review,
      createdAt: DateTime(2026, 10, 15),
      data: {
        'title': 'Perfil lipídico',
        'values': [
          {'item': 'LDL', 'value': '138', 'unit': 'mg/dL', 'reference': 'até 130', 'confirmed': false},
          {'item': 'HDL', 'value': '48', 'unit': 'mg/dL', 'reference': 'acima de 40', 'confirmed': false},
        ],
      },
    ));
    await pump(tester, const ExamReviewScreen(documentId: 'd1'), api: api);

    FilledButton save() => tester.widget<FilledButton>(find.byKey(const Key('exam_save')));
    expect(save().onPressed, isNull);
    expect(find.text(pt.careExamSavePending(2)), findsOneWidget);

    await tester.tap(find.byKey(const Key('row_confirm_0')));
    await tester.tap(find.byKey(const Key('row_confirm_1')));
    await tester.pumpAndSettle();
    expect(save().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('exam_save')));
    await tester.pumpAndSettle();
    final values = api.reviews.single['values'] as List;
    expect(values.every((v) => v['confirmed'] == true), isTrue);
    expect(values.first, {'item': 'LDL', 'value': '138', 'unit': 'mg/dL', 'reference': 'até 130', 'confirmed': true});
  });

  testWidgets('a failed exam can be read again; a confirmed one cannot', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(id: 'd1', kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.failed, createdAt: DateTime(2026, 10, 28), data: const {}));
    await pump(tester, const ExamReviewScreen(documentId: 'd1'), api: api);
    await tester.tap(find.byKey(const Key('document_reprocess')));
    await tester.pumpAndSettle();
    expect(api.reprocessed, ['d1']);

    api.docs
      ..clear()
      ..add(CareDocument(id: 'd2', kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.ready, createdAt: DateTime(2026, 10, 28), data: const {}));
    await pump(tester, const ExamReviewScreen(documentId: 'd2'), api: api);
    expect(find.byKey(const Key('document_reprocess')), findsNothing);
  });

  testWidgets('premium nav bar adds the care tab before the help button', (tester) async {
    var tapped = -1;
    var help = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: DualisBottomNavBar(currentIndex: 0, showCare: true, onTap: (i) => tapped = i, onEmergencyTap: () => help = true),
      ),
    ));
    await tester.tap(find.byKey(const Key('nav_destination_care')));
    expect(tapped, 3);
    await tester.tap(find.byKey(const Key('nav_destination_emergency')));
    expect(help, isTrue);
  });
}

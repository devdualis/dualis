import 'dart:typed_data';

import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/care/data/care_api.dart';
import 'package:dualis_mobile/features/care/data/care_notifications.dart';
import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:dualis_mobile/features/care/domain/pni_calendar.dart';
import 'package:dualis_mobile/features/care/presentation/screens/allergies_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/appointments_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/care_hub_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/exam_item_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/exam_review_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/exams_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/medications_screen.dart';
import 'package:dualis_mobile/features/care/presentation/screens/place_picker_screen.dart';
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
  Future<void> deleteDocument(String id) async => docs.removeWhere((d) => d.id == id);
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

  Future<FakeCareApi> pump(WidgetTester tester, Widget screen, {FakeCareApi? api, Profile? profile, PlacePicker? placePicker}) async {
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
        if (placePicker != null) placePickerProvider.overrideWithValue(placePicker),
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

  testWidgets('a report with several exams shows each heading once and keeps it on save', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(
      id: 'd1',
      kind: DocumentKind.lab,
      mime: 'application/pdf',
      status: DocumentStatus.review,
      createdAt: DateTime(2026, 10, 28),
      data: {
        'values': [
          {'section': 'HEMOGRAMA COMPLETO', 'item': 'SEGMENTADOS', 'value': '38', 'unit': '%', 'confirmed': true},
          {'section': 'HEMOGRAMA COMPLETO', 'item': 'SEGMENTADOS', 'value': '1.938', 'unit': '/mm³', 'confirmed': true},
          {'section': 'FERRITINA', 'item': 'FERRITINA', 'value': '447,6', 'unit': 'ng/mL', 'confirmed': true},
        ],
      },
    ));
    await pump(tester, const ExamReviewScreen(documentId: 'd1'), api: api);

    expect(find.byKey(const Key('exam_section_0')), findsOneWidget);
    expect(find.byKey(const Key('exam_section_1')), findsNothing);
    expect(find.byKey(const Key('exam_section_2')), findsOneWidget);
    // Several exams: the title is suggested and each exam has a chip.
    expect(find.text(pt.careExamTitleMany('Hemograma completo', 1)), findsOneWidget);
    expect(find.text(pt.careExamSections(2)), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Ferritina'), findsOneWidget);
    // % and /mm³ of one item: the name once, a remove button per result.
    expect(find.text('Segmentados'), findsOneWidget);
    expect(find.byKey(const Key('row_remove_0')), findsOneWidget);
    expect(find.byKey(const Key('row_remove_1')), findsOneWidget);
    expect(find.byKey(const Key('row_remove_2')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('exam_save')));
    await tester.tap(find.byKey(const Key('exam_save')));
    await tester.pumpAndSettle();
    final values = api.reviews.single['values'] as List;
    expect(values.map((v) => v['section']), ['Hemograma completo', 'Hemograma completo', 'Ferritina']);
    expect(api.reviews.single['title'], 'Hemograma completo + 1 exame');
  });

  testWidgets('removing one of two results keeps only the chosen one', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(
      id: 'd1',
      kind: DocumentKind.lab,
      mime: 'application/pdf',
      status: DocumentStatus.review,
      createdAt: DateTime(2026, 10, 28),
      data: {
        'values': [
          {'section': 'HEMOGRAMA COMPLETO', 'item': 'SEGMENTADOS', 'value': '38', 'unit': '%', 'confirmed': true},
          {'section': 'HEMOGRAMA COMPLETO', 'item': 'SEGMENTADOS', 'value': '1.938', 'unit': '/mm³', 'confirmed': true},
        ],
      },
    ));
    await pump(tester, const ExamReviewScreen(documentId: 'd1'), api: api);
    await tester.tap(find.byKey(const Key('row_remove_1')));
    await tester.pumpAndSettle();
    // A single result goes back to a plain row with the item name.
    expect(find.byKey(const Key('row_remove_0')), findsNothing);
    expect(find.text('Segmentados'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exam_save')));
    await tester.pumpAndSettle();
    final values = api.reviews.single['values'] as List;
    expect(values.map((v) => v['value']), ['38']);
  });

  testWidgets('item history lists one unit at a time', (tester) async {
    final api = FakeCareApi();
    for (final (id, day, pct, abs) in [('d1', '2026-05-21', '38', '1.938'), ('d2', '2026-01-10', '52', '2.700')]) {
      api.docs.add(CareDocument(
        id: id,
        kind: DocumentKind.lab,
        mime: 'application/pdf',
        status: DocumentStatus.ready,
        createdAt: DateTime(2026, 10, 28),
        data: {
          'collectedOn': day,
          'values': [
            {'item': 'SEGMENTADOS', 'value': pct, 'unit': '%', 'confirmed': true},
            {'item': 'SEGMENTADOS', 'value': abs, 'unit': id == 'd1' ? '/mm³' : '/mm 3', 'confirmed': true},
          ],
        },
      ));
    }
    await pump(tester, const ExamItemScreen(item: 'SEGMENTADOS'), api: api);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('38 %'), findsOneWidget);
    expect(find.text('52 %'), findsOneWidget);
    expect(find.textContaining('1.938'), findsNothing);

    await tester.tap(find.byKey(const Key('exam_unit_/mm3')));
    await tester.pumpAndSettle();
    expect(find.text('1.938 /mm³'), findsOneWidget);
    expect(find.text('2.700 /mm 3'), findsOneWidget);
    expect(find.text('38 %'), findsNothing);
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

    await tester.tap(find.byKey(const Key('document_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pt.careDelete).last);
    await tester.pumpAndSettle();
    expect(api.docs, isEmpty);
  });

  testWidgets('a reading with the same exams as another document asks to discard or keep both', (tester) async {
    final api = FakeCareApi();
    CareDocument lab(String id, DocumentStatus status, [Map<String, dynamic> extra = const {}]) => CareDocument(
          id: id,
          kind: DocumentKind.lab,
          mime: 'application/pdf',
          status: status,
          createdAt: DateTime(2026, 10, 28),
          data: {
            'values': [
              {'item': 'LDL', 'value': '138', 'confirmed': false},
            ],
            ...extra,
          },
        );
    api.docs.addAll([lab('old', DocumentStatus.ready), lab('new', DocumentStatus.review, {'possibleDuplicateOf': 'old'})]);
    await pump(tester, const ExamReviewScreen(documentId: 'new'), api: api);
    expect(find.text(pt.careExamPossibleDuplicate), findsOneWidget);

    // Keep both: the question goes away and nothing is deleted.
    await tester.tap(find.byKey(const Key('duplicate_keep')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam_possible_duplicate')), findsNothing);
    expect(api.docs, hasLength(2));

    // Discard this one (after confirming): only the new document is removed.
    await pump(tester, ExamReviewScreen(key: UniqueKey(), documentId: 'new'), api: api);
    await tester.tap(find.byKey(const Key('duplicate_discard')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pt.careDelete).last);
    await tester.pumpAndSettle();
    expect(api.docs.map((d) => d.id), ['old']);
  });

  testWidgets('the possible-duplicate question is not asked once the other document is gone', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(
      id: 'new',
      kind: DocumentKind.lab,
      mime: 'application/pdf',
      status: DocumentStatus.review,
      createdAt: DateTime(2026, 10, 28),
      data: const {'possibleDuplicateOf': 'deleted'},
    ));
    await pump(tester, const ExamReviewScreen(documentId: 'new'), api: api);
    expect(find.byKey(const Key('exam_possible_duplicate')), findsNothing);
  });

  testWidgets('a document with several exams is named after the first one plus the count', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(id: 'd1', kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.review, createdAt: DateTime(2026, 10, 28), data: {
      'values': [
        for (final s in ['HEMOGRAMA COMPLETO', 'FERRITINA', 'T4 LIVRE']) {'section': s, 'item': s, 'value': '1', 'confirmed': false},
      ],
    }));
    await pump(tester, const ExamsScreen(), api: api);
    expect(find.text(pt.careExamTitleMany('Hemograma completo', 2)), findsOneWidget);
  });

  testWidgets('values over time are grouped by exam with the latest value and a search', (tester) async {
    final api = FakeCareApi();
    for (final (id, day, hb) in [('d1', '2026-06-04', '13,1'), ('d2', '2026-10-21', '13,8')]) {
      api.docs.add(CareDocument(id: id, kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.ready, createdAt: DateTime(2026, 10, 28), data: {
        'collectedOn': day,
        'values': [
          {'section': 'HEMOGRAMA COMPLETO', 'item': 'Hemoglobina', 'value': hb, 'unit': 'g/dL', 'confirmed': true},
          for (var i = 0; i < 6; i++) {'section': 'HEMOGRAMA COMPLETO', 'item': i == 0 ? 'Hematócrito' : 'Item $i', 'value': '1', 'confirmed': true},
          for (var i = 0; i < 10; i++) {'section': 'Bioquímica', 'item': 'Dosagem $i', 'value': '2', 'confirmed': true},
        ],
      }));
    }
    await pump(tester, const ExamsScreen(), api: api);
    await tester.scrollUntilVisible(find.text('Hemograma completo'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('13,8 g/dL'), findsOneWidget);
    expect(find.text('13,1 g/dL'), findsNothing);
    expect(find.text(pt.careExamValuesItemCount(7)), findsOneWidget);
    expect(find.text(pt.careExamValuesShowMore(3)), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);

    await tester.enterText(find.byKey(const Key('exam_values_search')), 'hemo');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam_values_Hemoglobina')), findsOneWidget);
    expect(find.text('Bioquímica'), findsNothing);

    await tester.enterText(find.byKey(const Key('exam_values_search')), 'HEMATOCRITO');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam_values_Hematócrito')), findsOneWidget);
  });

  testWidgets('prescriptions have their own list, apart from exams', (tester) async {
    final api = FakeCareApi();
    api.docs
      ..add(CareDocument(id: 'lab1', kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.ready, createdAt: DateTime(2026, 10, 28), data: const {'title': 'Hemograma'}))
      ..add(CareDocument(id: 'rx1', kind: DocumentKind.prescription, mime: 'application/pdf', status: DocumentStatus.ready, createdAt: DateTime(2026, 10, 28), data: const {'title': 'Receita Dr. Silva'}));

    await pump(tester, const ExamsScreen(), api: api);
    expect(find.text('Hemograma'), findsOneWidget);
    expect(find.text('Receita Dr. Silva'), findsNothing);
    expect(find.text(pt.careExamSectionPrescriptions), findsNothing);

    await pump(tester, const ExamsScreen(prescriptions: true), api: api);
    expect(find.text('Receita Dr. Silva'), findsOneWidget);
    expect(find.text('Hemograma'), findsNothing);
    expect(find.text(pt.careRxListAdd), findsOneWidget);
  });

  testWidgets('adding an exam no longer offers the prescription kind', (tester) async {
    await pump(tester, const ExamsScreen(), api: FakeCareApi());
    await tester.tap(find.byKey(const Key('exams_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exam_source_pdf')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam_kind_lab')), findsOneWidget);
    expect(find.byKey(const Key('exam_kind_archive')), findsOneWidget);
    expect(find.byKey(const Key('exam_kind_prescription')), findsNothing);
  });

  testWidgets('a file stuck while being read can be swiped away', (tester) async {
    final api = FakeCareApi();
    api.docs.add(CareDocument(id: 'd1', kind: DocumentKind.lab, mime: 'application/pdf', status: DocumentStatus.processing, createdAt: DateTime(2026, 10, 28), data: const {}));
    await pump(tester, const ExamsScreen(), api: api);
    await tester.drag(find.byKey(const Key('doc_swipe_d1')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pt.careDelete).last);
    await tester.pumpAndSettle();
    expect(api.docs, isEmpty);
    expect(find.text(pt.careExamReading), findsNothing);
  });

  testWidgets('appointment specialty is searchable without accents and place links to Maps', (tester) async {
    await pump(tester, const AppointmentsScreen());
    await tester.tap(find.byKey(const Key('appointments_add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appt_specialty')), 'nutricao');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrição'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Nutrição'), findsOneWidget);
    await tester.tap(find.byKey(const Key('appt_place')));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.descendant(of: find.byKey(const Key('appt_place')), matching: find.byType(EditableText))).focusNode.hasFocus, isTrue);
    await tester.enterText(find.byKey(const Key('appt_specialty')), 'Homeopatia');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Homeopatia'), findsOneWidget);
    await tester.tap(find.byKey(const Key('appt_place')));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.descendant(of: find.byKey(const Key('appt_place')), matching: find.byType(EditableText))).focusNode.hasFocus, isTrue);
  });

  testWidgets('place picked on the map is saved with its point, and dropped once the text changes', (tester) async {
    const paulista = 'Av. Paulista, 1578 – Bela Vista, São Paulo';
    final queries = <String>[];
    final api = FakeCareApi()
      ..add(CareKind.appointment, {'specialty': 'Cardiologia', 'place': 'Hospital', 'reminder': '1d'}, occursAt: DateTime(2030, 1, 10, 9));
    await pump(tester, const AppointmentsScreen(), api: api, placePicker: (context, {query = '', initial}) async {
      queries.add(query);
      return const PickedPlace(paulista, -23.5614, -46.6559);
    });
    await tester.tap(find.text('Cardiologia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appt_place_map')));
    await tester.pumpAndSettle();
    expect(queries, ['Hospital']);
    expect(find.widgetWithText(TextFormField, paulista), findsOneWidget);
    await tester.tap(find.byKey(const Key('appt_save')));
    await tester.pumpAndSettle();
    expect(api.records[CareKind.allergy]!.first.data, containsPair('placeLat', -23.5614));
    expect(api.records[CareKind.allergy]!.first.data, containsPair('placeLng', -46.6559));

    await tester.tap(find.text('Cardiologia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appt_place_map')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appt_place')), 'Outro lugar');
    await tester.tap(find.byKey(const Key('appt_save')));
    await tester.pumpAndSettle();
    expect(api.records[CareKind.allergy]!.first.data.containsKey('placeLat'), isFalse);
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

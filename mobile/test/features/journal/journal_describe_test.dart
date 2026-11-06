import 'package:dio/dio.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_controller.dart';
import 'package:dualis_mobile/features/journal/presentation/controllers/journal_flow_state.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/journal_flow_screen.dart';
import 'package:dualis_mobile/features/profile/domain/models/profile.dart';
import 'package:dualis_mobile/features/profile/presentation/controllers/active_profile_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

/// "Descrever com minhas palavras" (phase 17, D3): a free description gives
/// existing options, every one OFF, and only the ones the person turns on
/// reach the entry.
void main() {
  final pt = AppLocalizationsPt();
  const physical = JournalFlowArgs(initialArea: JournalArea.physical);
  const text = 'Hoje acordei assim';

  // The consent gate reads and writes a device flag.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  JournalFlowState flowState(WidgetTester tester) =>
      containerOf(tester).read(journalFlowControllerProvider);

  bool switchOn(WidgetTester tester, String key) => tester
      .widget<SwitchListTile>(find.byKey(Key('jv2_describe_option_$key')))
      .value;

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(find.byKey(Key(key))).onPressed != null;

  group('emotional describe flow', () {
    testWidgets(
        'describe -> review with every option OFF -> turn one on -> '
        '"Usar as selecionadas" -> persistence; Back returns to the time step',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [
        'presente.sobrecarga.aperto',
        'futuro.mente.antecipar',
      ];
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_nao_tao_bem');

      expect(find.byKey(const Key('jv2_describe')), findsOneWidget);
      await tapKey(tester, 'jv2_describe');
      expect(find.byKey(const Key('jv2_describe_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('jv2_describe_field')),
        'Estou com o peito apertado pensando na semana',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_describe_suggest');

      expect(find.byKey(const Key('jv2_describe_review')), findsOneWidget);
      expect(switchOn(tester, 'presente.sobrecarga.aperto'), isFalse);
      expect(switchOn(tester, 'futuro.mente.antecipar'), isFalse);
      expect(enabled(tester, 'jv2_describe_use'), isFalse);

      await tapKey(tester, 'jv2_describe_option_presente.sobrecarga.aperto');
      expect(switchOn(tester, 'presente.sobrecarga.aperto'), isTrue);
      expect(enabled(tester, 'jv2_describe_use'), isTrue);
      await tapKey(tester, 'jv2_describe_use');

      expect(find.byKey(const Key('jv2_describe_sheet')), findsNothing);
      final state = flowState(tester);
      expect(state.step, JournalStep.persistence);
      expect(state.items, hasLength(1));
      expect(state.items.single.kind, JournalKeys.kindEmotional);
      expect(state.items.single.optionKey, 'presente.sobrecarga.aperto');
      expect(find.byKey(const Key('jv2_persistence_0_hoje')), findsOneWidget);

      expect(h.remote.suggestEntryRequests, [
        {
          'text': 'Estou com o peito apertado pensando na semana',
          'area': 'emotional',
        },
      ]);
      // The description is not the note unless the person asked.
      expect(state.note, isEmpty);

      await tapKey(tester, 'jv2_back');
      expect(flowState(tester).step, JournalStep.time);
      expect(flowState(tester).items, isEmpty);
      expect(find.byKey(const Key('jv2_describe')), findsOneWidget);
    });
  });

  /// Opens the sheet on the first step of the axis, types [text] and asks
  /// for suggestions.
  Future<void> describe(
    WidgetTester tester, {
    String typed = text,
    bool keepNote = false,
  }) async {
    await tapKey(tester, 'jv2_mood_nao_tao_bem');
    await tapKey(tester, 'jv2_describe');
    await tester.enterText(find.byKey(const Key('jv2_describe_field')), typed);
    await tester.pumpAndSettle();
    if (keepNote) await tapKey(tester, 'jv2_describe_keep_note');
    await tapKey(tester, 'jv2_describe_suggest');
  }

  Iterable<String> listedKeys(WidgetTester tester) => [
        for (final w in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)))
          (w.key! as ValueKey<String>).value.replaceFirst('jv2_describe_option_', ''),
      ];

  group('physical describe flow', () {
    testWidgets(
        'body step offers it; turned-on keys carry front, back and no side',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [
        'cabeca.sentidos.olhos',
        'costas.rigidez.lombar',
        'hormonios.apetite.sede',
      ];
      await pumpJournalFlow(tester, h, args: physical);
      await describe(tester);

      expect(h.remote.suggestEntryRequests.single['area'], 'physical');
      for (final key in h.remote.suggestedEntryKeys) {
        expect(switchOn(tester, key), isFalse);
        await tapKey(tester, 'jv2_describe_option_$key');
      }
      await tapKey(tester, 'jv2_describe_use');

      final state = flowState(tester);
      expect(state.step, JournalStep.persistence);
      final sides = {for (final i in state.items) i.optionKey: i.bodySide};
      expect(sides, {
        'cabeca.sentidos.olhos': JournalKeys.sideFront,
        'costas.rigidez.lombar': JournalKeys.sideBack,
        'hormonios.apetite.sede': null,
      });
      expect(state.items.every((i) => i.kind == JournalKeys.kindPhysical), isTrue);

      await tapKey(tester, 'jv2_back');
      expect(flowState(tester).step, JournalStep.body);
      expect(flowState(tester).items, isEmpty);
    });

    testWidgets('a male profile never sees a menstrual key in the list',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [
        'barriga.colica.menstrual',
        'pelve.baixo_ventre.menstrual',
        'barriga.colica.gases',
      ];
      await pumpJournalFlow(
        tester,
        h,
        args: physical,
        extraOverrides: [
          activeProfileControllerProvider.overrideWith(_Male.new),
        ],
      );
      await describe(tester);

      expect(listedKeys(tester), ['barriga.colica.gases']);
    });

    testWidgets(
        'keys of the other area, custom and unknown keys are dropped; '
        'at most 4 are listed', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [
        'presente.sobrecarga.aperto',
        'cabeca.custom',
        'cabeca.pressao.inventada',
        'diagnostico',
        'cabeca.pressao.temporas',
        'cabeca.pressao.temporas',
        'peito.respiracao.curta',
        'barriga.queimacao.enjoo',
        'membros.cansaco.juntas',
        'pele.coceira.coceira',
      ];
      await pumpJournalFlow(tester, h, args: physical);
      await describe(tester);

      expect(listedKeys(tester), [
        'cabeca.pressao.temporas',
        'peito.respiracao.curta',
        'barriga.queimacao.enjoo',
        'membros.cansaco.juntas',
      ]);
    });
  });

  group('keep as note', () {
    testWidgets('checked: the entry note is the typed text', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await describe(tester, keepNote: true);
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');

      final entry =
          containerOf(tester).read(journalFlowControllerProvider.notifier).buildEntry();
      expect(entry.note, text);
    });

    testWidgets('kept twice: the second text is added after the first, never in its place',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await describe(tester, typed: 'Primeiro texto', keepNote: true);
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');
      await tapKey(tester, 'jv2_back');
      expect(flowState(tester).step, JournalStep.time);

      await tapKey(tester, 'jv2_describe');
      await tester.enterText(find.byKey(const Key('jv2_describe_field')), 'Segundo texto');
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_describe_keep_note');
      await tapKey(tester, 'jv2_describe_suggest');
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');

      final entry =
          containerOf(tester).read(journalFlowControllerProvider.notifier).buildEntry();
      expect(entry.note, 'Primeiro texto\n\nSegundo texto');
    });

    testWidgets('kept after a long note: the note stays within its length limit',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      final long = 'a' * (JournalKeys.noteMaxLength - 5);
      await describe(tester, typed: long, keepNote: true);
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');
      await tapKey(tester, 'jv2_back');

      await tapKey(tester, 'jv2_describe');
      await tester.enterText(find.byKey(const Key('jv2_describe_field')), 'Segundo texto');
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_describe_keep_note');
      await tapKey(tester, 'jv2_describe_suggest');
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');

      final note = containerOf(tester)
          .read(journalFlowControllerProvider.notifier)
          .buildEntry()
          .note!;
      expect(note.length, JournalKeys.noteMaxLength);
      expect(note, startsWith(long));
    });

    testWidgets('unchecked (the default): the note stays empty', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_nao_tao_bem');
      await tapKey(tester, 'jv2_describe');
      final box = tester.widget<CheckboxListTile>(
        find.byKey(const Key('jv2_describe_keep_note')),
      );
      expect(box.value, isFalse);
      await tester.enterText(find.byKey(const Key('jv2_describe_field')), text);
      await tester.pumpAndSettle();
      await tapKey(tester, 'jv2_describe_suggest');
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_use');

      final entry =
          containerOf(tester).read(journalFlowControllerProvider.notifier).buildEntry();
      expect(entry.note, isNull);
    });
  });

  group('who sees it', () {
    testWidgets('Free build: no tile on the time step', (tester) async {
      final h = JournalHarness()..premium = false;
      await pumpJournalFlow(tester, h);
      await tapKey(tester, 'jv2_mood_nao_tao_bem');
      expect(find.byKey(const Key('jv2_time_presente')), findsOneWidget);
      expect(find.byKey(const Key('jv2_describe')), findsNothing);
    });

    testWidgets('Free build: no tile on the body step', (tester) async {
      final p = JournalHarness()..premium = false;
      await pumpJournalFlow(tester, p, args: physical);
      await tapKey(tester, 'jv2_mood_nao_tao_bem');
      expect(find.byKey(const Key('jv2_topic_whole_body')), findsOneWidget);
      expect(find.byKey(const Key('jv2_describe')), findsNothing);
    });

    testWidgets('a profile shared by another account: no tile', (tester) async {
      final h = JournalHarness()..premium = true;
      await pumpJournalFlow(
        tester,
        h,
        extraOverrides: [
          activeProfileControllerProvider.overrideWith(_SharedActive.new),
        ],
      );
      await tapKey(tester, 'jv2_mood_nao_tao_bem');
      expect(find.byKey(const Key('jv2_time_presente')), findsOneWidget);
      expect(find.byKey(const Key('jv2_describe')), findsNothing);
    });

    testWidgets('a dependent the holder manages: the tile is there',
        (tester) async {
      final h = JournalHarness()..premium = true;
      await pumpJournalFlow(
        tester,
        h,
        args: physical,
        extraOverrides: [
          activeProfileControllerProvider.overrideWith(_DependentActive.new),
        ],
      );
      await tapKey(tester, 'jv2_mood_nao_tao_bem');
      expect(find.byKey(const Key('jv2_describe')), findsOneWidget);
    });
  });

  group('consent', () {
    testWidgets('declined: the sheet closes, nothing is sent, flow unchanged',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.consent.granted = false;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await describe(tester);

      expect(find.byKey(const Key('ai_consent_dialog')), findsOneWidget);
      await tapKey(tester, 'ai_consent_decline');

      expect(find.byKey(const Key('jv2_describe_sheet')), findsNothing);
      expect(h.remote.suggestEntryRequests, isEmpty);
      expect(h.consent.calls.where((c) => c.startsWith('grant')), isEmpty);
      expect(flowState(tester).step, JournalStep.time);
      expect(flowState(tester).items, isEmpty);
    });

    testWidgets('accepted: the consent is granted, then the request is sent',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.consent.granted = false;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await describe(tester);

      await tapKey(tester, 'ai_consent_accept');
      expect(h.consent.calls, contains('grant:2026.1'));
      expect(h.remote.suggestEntryRequests, hasLength(1));
      expect(find.byKey(const Key('jv2_describe_review')), findsOneWidget);
    });
  });

  group('calm fallbacks', () {
    /// The message is on screen; "Seguir sem sugestões" returns to the
    /// same step with nothing selected.
    Future<void> expectFallback(
      WidgetTester tester,
      String message, {
      JournalStep step = JournalStep.time,
    }) async {
      expect(
        tester.widget<Text>(find.byKey(const Key('jv2_describe_message'))).data,
        message,
      );
      await tapKey(tester, 'jv2_describe_manual');
      expect(find.byKey(const Key('jv2_describe_sheet')), findsNothing);
      expect(flowState(tester).step, step);
      expect(flowState(tester).items, isEmpty);
      expect(flowState(tester).note, isEmpty);
    }

    testWidgets('offline: nothing is sent and no consent dialog opens',
        (tester) async {
      final h = JournalHarness(online: false)..premium = true;
      h.consent.granted = false;
      await pumpJournalFlow(tester, h);
      await describe(tester);

      expect(find.byKey(const Key('ai_consent_dialog')), findsNothing);
      expect(h.remote.suggestEntryRequests, isEmpty);
      await expectFallback(tester, pt.jv2DescribeOffline);
    });

    testWidgets('timeout', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestEntryError =
          suggestEntryFailure(type: DioExceptionType.receiveTimeout);
      await pumpJournalFlow(tester, h);
      await describe(tester);
      await expectFallback(tester, pt.jv2DescribeFailed);
    });

    testWidgets('server error (500)', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestEntryError = suggestEntryFailure(status: 500);
      await pumpJournalFlow(tester, h, args: physical);
      await describe(tester);
      await expectFallback(tester, pt.jv2DescribeFailed, step: JournalStep.body);
    });

    testWidgets('busy (429 AI_BUSY)', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestEntryError =
          suggestEntryFailure(status: 429, code: 'AI_BUSY');
      await pumpJournalFlow(tester, h);
      await describe(tester);
      await expectFallback(tester, pt.jv2DescribeBusy);
    });

    testWidgets('403 AI_CONSENT_REQUIRED reads the consent again',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestEntryError =
          suggestEntryFailure(status: 403, code: 'AI_CONSENT_REQUIRED');
      await pumpJournalFlow(tester, h);
      await describe(tester);
      final reads = h.consent.calls.where((c) => c == 'status').length;
      expect(reads, greaterThanOrEqualTo(2));
      await expectFallback(tester, pt.jv2DescribeFailed);
    });

    testWidgets('403 AI_PROFILE_NOT_ALLOWED', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestEntryError =
          suggestEntryFailure(status: 403, code: 'AI_PROFILE_NOT_ALLOWED');
      await pumpJournalFlow(tester, h);
      await describe(tester);
      await expectFallback(tester, pt.jv2DescribeProfileNotAllowed);
    });

    testWidgets('empty answer', (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const [];
      await pumpJournalFlow(tester, h);
      await describe(tester);
      await expectFallback(tester, pt.jv2DescribeEmpty);
    });

    testWidgets('"Seguir sem sugestões" from the review list selects nothing',
        (tester) async {
      final h = JournalHarness()..premium = true;
      h.remote.suggestedEntryKeys = const ['passado.tristeza.saudade'];
      await pumpJournalFlow(tester, h);
      await describe(tester);
      await tapKey(tester, 'jv2_describe_option_passado.tristeza.saudade');
      await tapKey(tester, 'jv2_describe_manual');
      expect(flowState(tester).step, JournalStep.time);
      expect(flowState(tester).items, isEmpty);
    });
  });

  testWidgets('empty text keeps "Ver sugestões" disabled', (tester) async {
    final h = JournalHarness()..premium = true;
    await pumpJournalFlow(tester, h);
    await tapKey(tester, 'jv2_mood_nao_tao_bem');
    await tapKey(tester, 'jv2_describe');
    expect(enabled(tester, 'jv2_describe_suggest'), isFalse);
    await tester.enterText(find.byKey(const Key('jv2_describe_field')), '   ');
    await tester.pumpAndSettle();
    expect(enabled(tester, 'jv2_describe_suggest'), isFalse);
    await tester.enterText(find.byKey(const Key('jv2_describe_field')), text);
    await tester.pumpAndSettle();
    expect(enabled(tester, 'jv2_describe_suggest'), isTrue);
    expect(h.remote.suggestEntryRequests, isEmpty);
  });
}

class _Male extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState(
        profiles: [
          Profile(
            id: 'p-male',
            name: 'Carlos',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
            gender: 'masculino',
          ),
        ],
      );
}

/// Ana is signed in and has Carlos's profile, shared by Carlos, active.
class _SharedActive extends ActiveProfileController {
  @override
  ActiveProfileState build() => ActiveProfileState(
        profiles: [
          const Profile(
            id: 'p1',
            name: 'Ana',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
          ),
          Profile.fromJson(const {
            'id': 'shared-1',
            'name': 'Carlos',
            'profileType': 'primary',
            'ownership': 'shared',
            'accessLevel': 'CO_MANAGE',
            'readableCategories': ['journal'],
            'writableCategories': ['journal'],
          }),
        ],
        activeProfileId: 'shared-1',
      );
}

/// Ana manages her son's dependent profile, which is active.
class _DependentActive extends ActiveProfileController {
  @override
  ActiveProfileState build() => const ActiveProfileState(
        profiles: [
          Profile(
            id: 'p1',
            name: 'Ana',
            profileType: ProfileType.primary,
            ownership: ProfileOwnership.own,
            accessLevel: ProfileAccessLevel.owner,
          ),
          Profile(
            id: 'dep-1',
            name: 'Leo',
            profileType: ProfileType.dependentMinor,
            ownership: ProfileOwnership.dependent,
            accessLevel: ProfileAccessLevel.owner,
          ),
        ],
        activeProfileId: 'dep-1',
      );
}

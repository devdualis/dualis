import 'dart:convert';
import 'dart:io';

import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/journal_labels.dart';
import 'package:dualis_mobile/l10n/app_localizations_en.dart';
import 'package:dualis_mobile/l10n/app_localizations_es.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `docs/bienestar/CONTRATO-JOURNAL-V2.md`.
void main() {
  group('keys mirror the contract', () {
    test('20 emotional and 41 physical options (v2.2), plus one custom key per root', () {
      final keys = JournalKeys.allOptionKeys;
      final emotional = keys.where(
        (k) => JournalKeys.times.contains(JournalKeys.rootOf(k)) && !JournalKeys.isCustomKey(k),
      );
      final physical = keys.where(
        (k) => JournalKeys.regions.contains(JournalKeys.rootOf(k)) && !JournalKeys.isCustomKey(k),
      );
      expect(emotional, hasLength(20));
      expect(physical, hasLength(41));
      expect(keys.where(JournalKeys.isCustomKey), hasLength(11));
      expect(keys, containsAll(['passado.tristeza.culpa', 'futuro.medo.desanimo', 'costas.fisgada.ao_mexer', 'membros.custom']));
      expect(keys, containsAll([
        'cabeca.nuca.rigida', 'cabeca.nuca.pontada',
        'pele.coceira.coceira', 'pele.coceira.ardencia', 'pele.aparencia.vermelhidao', 'pele.aparencia.manchas',
        'musculos.tensao.rigidez', 'musculos.tensao.caibra', 'musculos.cansaco.fraqueza', 'musculos.cansaco.dolorido',
        'hormonios.temperatura.calorao', 'hormonios.temperatura.frio', 'hormonios.apetite.sede', 'hormonios.apetite.fome',
        'pele.custom', 'musculos.custom', 'hormonios.custom',
      ]));
    });

    test('branches follow the side rules (v2.1)', () {
      Set<String> b(String region, String? side) =>
          JournalKeys.branchesFor(region, side).keys.toSet();
      expect(b('cabeca', 'front'), {'pressao', 'sentidos', 'rosto'});
      expect(b('barriga', 'front'), {'queimacao', 'colica', 'intestino'});
      expect(b('cabeca', 'back'), {'pressao', 'nuca'});
      expect(b('costas', 'back'), {'rigidez', 'fisgada'});
      expect(b('membros', 'front'), {'cansaco', 'formigamento'});
      expect(b('pele', null), {'coceira', 'aparencia'});
      expect(b('musculos', null), {'tensao', 'cansaco'});
      expect(b('hormonios', null), {'temperatura', 'apetite'});
      expect(JournalKeys.wholeBodyAreas, ['pele', 'musculos', 'hormonios']);
      expect(JournalKeys.bodyRegions, ['cabeca', 'peito', 'barriga', 'costas', 'membros']);
    });

    test('moods, persistence and triggers', () {
      expect(JournalKeys.moods, ['bem', 'normal', 'nao_tao_bem']);
      expect(JournalKeys.newEntryMoods, ['bem', 'nao_tao_bem']);
      expect(JournalKeys.sensations, ['dor', 'incomodo']);
      expect(JournalKeys.persistences, ['hoje', 'dias_semanas', 'meses_anos']);
      expect(JournalKeys.triggers, [
        'trabalho', 'familia', 'sono', 'dinheiro', 'telas', 'ciclo', 'alimentacao',
        'esforco', 'queda', 'medicamento', 'clima', 'nao_sei', 'outro',
      ]);
      expect(JournalKeys.physicalOnlyTriggers,
          {'alimentacao', 'esforco', 'queda', 'medicamento', 'clima'});
      expect(JournalKeys.triggersFor(hasPhysicalItem: false),
          ['trabalho', 'familia', 'sono', 'dinheiro', 'telas', 'ciclo', 'nao_sei', 'outro']);
    });

    test('v2.2 emotional tree, positive tree and closing keys match the contract', () {
      expect(JournalKeys.emotionalTree, {
        'passado': {
          'tristeza': ['culpa', 'saudade'],
          'memoria': ['lembranca', 'magoa', 'vergonha'],
        },
        'presente': {
          'energia': ['corpo', 'desligado', 'concentracao'],
          'sobrecarga': ['paciencia', 'aperto', 'muita_coisa', 'inquieto'],
          'solidao': ['sozinho', 'menos'],
        },
        'futuro': {
          'mente': ['antecipar', 'cobranca', 'indecisao'],
          'medo': ['julgamento', 'desanimo', 'evitar'],
        },
      });
      expect(JournalKeys.physicalTree['cabeca']!['rosto'],
          ['tontura', 'nariz', 'ouvido', 'mandibula']);
      expect(JournalKeys.physicalTree['barriga']!['colica'], ['gases', 'pontadas', 'menstrual']);
      expect(JournalKeys.physicalTree['barriga']!['intestino'], ['preso', 'solto']);
      expect(JournalKeys.positiveTree, {
        'passado': {
          'gratidao': ['alguem', 'algo'],
          'orgulho': ['conquista', 'resolvi'],
        },
        'presente': {
          'calma': ['paz', 'descansado'],
          'conexao': ['pessoas', 'foco'],
        },
        'futuro': {
          'animo': ['planos', 'esperanca'],
          'confianca': ['confiante', 'preparado'],
        },
      });
      // Positive branch names never repeat an emotional branch.
      for (final time in JournalKeys.times) {
        expect(
          JournalKeys.positiveTree[time]!.keys.toSet()
              .intersection(JournalKeys.emotionalTree[time]!.keys.toSet()),
          isEmpty,
        );
      }
      // Max 4 options per screen.
      for (final tree in [JournalKeys.emotionalTree, JournalKeys.physicalTree, JournalKeys.positiveTree]) {
        for (final branches in tree.values) {
          for (final options in branches.values) {
            expect(options.length, lessThanOrEqualTo(4));
          }
        }
      }
      expect(JournalKeys.positiveOptionKeys, hasLength(15));
      expect(JournalKeys.positiveOptionKeys, containsAll(['passado.custom', 'futuro.confianca.preparado']));
      expect(JournalKeys.allOptionKeys.intersection(
          {for (final k in JournalKeys.positiveOptionKeys) if (!JournalKeys.isCustomKey(k)) k}), isEmpty);
      expect(JournalKeys.kindPositive, 'positive');
      expect(JournalKeys.copings, ['consegui', 'esperei', 'dificil']);
      expect(JournalKeys.helpers,
          ['mexer_corpo', 'conversar', 'pausa', 'lazer', 'descansar', 'nada_ainda']);
      expect(JournalKeys.helperNadaAinda, 'nada_ainda');
      expect(JournalKeys.maxHelpers, 6);
    });

    test('v2.2 labels use the exact contract texts', () {
      final pt = AppLocalizationsPt();
      final en = AppLocalizationsEn();
      final es = AppLocalizationsEs();
      expect(JournalLabels.branch(pt, 'presente.solidao'), 'Sozinho(a) ou inseguro(a)');
      expect(JournalLabels.option(en, 'futuro.medo.evitar'), 'I want to avoid or get away from something');
      expect(JournalLabels.option(es, 'cabeca.rosto.nariz'), 'Nariz tapada o que gotea');
      expect(JournalLabels.option(pt, 'passado.gratidao.algo'), 'Grato(a) por algo que aconteceu');
      expect(JournalLabels.branch(en, 'futuro.animo'), 'Looking forward');
      expect(JournalLabels.trigger(pt, 'telas'), 'Telas ou redes sociais');
      expect(JournalLabels.coping(es, 'consegui'), 'Pude manejarlo');
      expect(JournalLabels.helper(pt, 'pausa'), 'Uma pausa para respirar');
      expect(pt.jv22CopingQuestion, 'Como foi lidar com isso?');
      expect(en.jv22HelpersQuestion, 'What helped you today?');
      expect(pt.jv22PositiveQuestion, 'Que bom! Quer anotar o que fez seu dia bom?');
      expect(pt.jv22JustSave, 'Só registrar');
    });

    test('coping, helpers and positive items survive the outbox JSON', () {
      final entry = JournalEntry(
        clientId: 'x',
        recordedAt: DateTime.utc(2026, 10, 31, 12),
        mood: 'nao_tao_bem',
        area: 'emotional',
        items: const [
          JournalItem(kind: 'emotional', optionKey: 'presente.solidao.sozinho', persistence: 'hoje', intensity: 2),
        ],
        coping: 'dificil',
        helpers: const ['conversar', 'descansar'],
      );
      final round = JournalEntry.fromJson(
        jsonDecode(jsonEncode(entry.toLocalJson())) as Map<String, dynamic>,
      );
      expect(round.coping, 'dificil');
      expect(round.helpers, ['conversar', 'descansar']);
      expect(entry.toRequestJson()['coping'], 'dificil');
      expect(entry.toRequestJson()['helpers'], ['conversar', 'descansar']);

      final good = JournalEntry(
        clientId: 'g',
        recordedAt: DateTime.utc(2026, 10, 31, 12),
        mood: 'bem',
        area: 'emotional',
        items: const [
          JournalItem(kind: 'positive', optionKey: 'passado.orgulho.resolvi'),
          JournalItem(kind: 'positive', optionKey: 'passado.custom', customLabel: 'Terminei o curso'),
        ],
      );
      final body = good.toRequestJson();
      expect(body.containsKey('coping'), isFalse);
      expect(body.containsKey('helpers'), isFalse);
      expect(body['items'], [
        {'kind': 'positive', 'optionKey': 'passado.orgulho.resolvi'},
        {'kind': 'positive', 'optionKey': 'passado.custom', 'customLabel': 'Terminei o curso'},
      ]);
      final back = JournalEntry.fromJson(
        jsonDecode(jsonEncode(good.toLocalJson())) as Map<String, dynamic>,
      );
      expect(back.hasPositiveItem, isTrue);
      expect(back.items.last.customLabel, 'Terminei o curso');
      expect(back.items.every((i) => i.intensity == null && i.persistence == null), isTrue);
    });

    test('older entries read as coping null and helpers []', () {
      final old = JournalEntry.fromJson({
        'clientId': 'o',
        'recordedAt': '2026-10-01T12:00:00Z',
        'mood': 'nao_tao_bem',
        'items': const [],
      });
      expect(old.coping, isNull);
      expect(old.helpers, isEmpty);
    });

    test('every key has a text in pt, en and es', () {
      for (final l10n in [AppLocalizationsPt(), AppLocalizationsEn(), AppLocalizationsEs()]) {
        for (final tree in [JournalKeys.emotionalTree, JournalKeys.physicalTree, JournalKeys.positiveTree]) {
          for (final root in tree.entries) {
            expect(JournalLabels.root(l10n, root.key), isNot(root.key));
            for (final branch in root.value.entries) {
              final b = '${root.key}.${branch.key}';
              expect(JournalLabels.branch(l10n, b), isNot(b));
              for (final o in branch.value) {
                expect(JournalLabels.option(l10n, '$b.$o'), isNot('$b.$o'));
              }
            }
          }
        }
        for (final t in JournalKeys.triggers) {
          expect(JournalLabels.trigger(l10n, t), isNot(t));
        }
        for (final c in JournalKeys.copings) {
          expect(JournalLabels.coping(l10n, c), isNot(c));
        }
        for (final x in JournalKeys.helpers) {
          expect(JournalLabels.helper(l10n, x), isNot(x));
        }
        for (final p in JournalKeys.persistences) {
          expect(JournalLabels.persistence(l10n, p), isNot(p));
        }
        for (final x in JournalKeys.sensations) {
          expect(JournalLabels.sensation(l10n, x), isNot(x));
        }
        for (final a in ['emotional', 'physical']) {
          expect(JournalLabels.axis(l10n, a), isNot(a));
        }
      }
    });

    test('request body has only contract fields and no condition label', () {
      final entry = JournalEntry(
        clientId: 'abc',
        recordedAt: DateTime.utc(2026, 10, 27, 12),
        mood: 'nao_tao_bem',
        area: 'physical',
        triggers: const ['outro'],
        triggerNote: 'x',
        transitionVariantIds: const ['time.1'],
        items: const [
          JournalItem(kind: 'condition', conditionId: 'c1', conditionLabel: 'Enxaqueca', intensity: 3),
          JournalItem(kind: 'physical', optionKey: 'peito.respiracao.curta', bodySide: 'front', sensation: 'dor', persistence: 'hoje', intensity: 2),
        ],
      );
      final body = entry.toRequestJson();
      expect(body.keys.toSet(), {'clientId', 'recordedAt', 'mood', 'area', 'triggers', 'triggerNote', 'transitionVariantIds', 'items'});
      expect(jsonEncode(body), isNot(contains('Enxaqueca')));
      final itemKeys = {
        for (final i in body['items'] as List) ...(i as Map).keys,
      };
      expect(itemKeys.difference({'kind', 'optionKey', 'customLabel', 'conditionId', 'bodySide', 'sensation', 'persistence', 'intensity'}), isEmpty);
      expect((body['items'] as List).last['sensation'], 'dor');
    });

    test('old entries without area or sensation stay readable', () {
      final old = JournalEntry.fromJson({
        'clientId': 'old',
        'recordedAt': '2026-10-01T12:00:00Z',
        'mood': 'normal',
        'items': [
          {'kind': 'physical', 'optionKey': 'cabeca.pressao.temporas', 'bodySide': 'front', 'intensity': 2},
        ],
      });
      expect(old.area, isNull);
      expect(old.mood, 'normal');
      expect(old.items.single.sensation, isNull);
      expect(old.toRequestJson().containsKey('area'), isFalse);
      expect((old.toRequestJson()['items'] as List).single.containsKey('sensation'), isFalse);
      final round = JournalEntry.fromJson(
        jsonDecode(jsonEncode(JournalEntry(
          clientId: 'n',
          recordedAt: DateTime.utc(2026, 10, 28),
          mood: 'bem',
          area: 'emotional',
        ).toLocalJson())) as Map<String, dynamic>,
      );
      expect(round.area, 'emotional');
    });
  });

  group('journal code uses neutral identifiers only', () {
    // Contract "Hard rules": no clinical grouping anywhere in the feature.
    final banned = RegExp(
      r'group|clinical|cl[ií]nic|diagnos|symptom|sphere|esfera|anatomical system|treatment|'
      r'tratamento|urgency|severity|\brisk\b|careDisposition|isCritical|transtorno|\bTAG\b|\bTOC\b|'
      r'\bTEPT\b|bipolar|ciclotim|borderline|anedonia|radiculopatia|costocondrite|isquemia|'
      r'cardiovascular|neurologic|endocrin|depressiv|ansios|mentionsSelfHarm',
      caseSensitive: false,
    );

    test('lib/features/journal', () {
      final offenders = <String>[];
      for (final f in Directory('lib/features/journal').listSync(recursive: true).whereType<File>()) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trimLeft().startsWith('import ')) continue;
          if (banned.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('transition phrases follow the editorial rules (strategy §7)', () {
    final forbidden = RegExp(
      r'geralmente|costuma|sinaliza|pedindo|sinal de alerta|s[ée]rio|perigo|urgente|explod|fantasma|'
      r'investigar|ressignific|forma l[óo]gica|c[ée]rebro|ritmos vitais|diagn|'
      r'usually|signals?|warning|serious|danger|urgent|explod|ghost|investigat|brain|'
      r'suele|se[ñn]al|grave|peligro|explot|fantasma|investig|cerebro',
      caseSensitive: false,
    );

    for (final lang in ['pt', 'en', 'es']) {
      test('$lang: max 90 characters, no interpretation or alarm', () {
        final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
        final phrases = {
          for (final e in arb.entries)
            if (e.key.startsWith('jv2Phrase') || e.key.startsWith('jv22Phrase'))
              e.key: e.value as String,
        };
        final expected = JournalLabels.phrasePools.values.fold<int>(0, (a, b) => a + b);
        expect(phrases, hasLength(expected));
        for (final pool in JournalLabels.phrasePools.entries) {
          expect(pool.value, inInclusiveRange(3, 4), reason: pool.key);
        }
        for (final e in phrases.entries) {
          expect(e.value.length, lessThanOrEqualTo(90), reason: e.key);
          expect(forbidden.hasMatch(e.value), isFalse, reason: '${e.key}: ${e.value}');
        }
      });
    }
  });

  test('intensity texts match strategy §8 and have no skull or urgent wording', () {
    final pt = AppLocalizationsPt();
    expect(pt.jv2IntensityEmotional1, 'Passa rápido, sigo meu dia normalmente.');
    expect(pt.jv2IntensityPhysical4, 'Não consigo fazer direito o que preciso.');
    expect(pt.jv2EmergencyLine, 'Se for uma emergência, use o botão Ajuda ou ligue 192.');
    final arb = File('lib/l10n/app_pt.arb').readAsStringSync();
    expect(arb.contains('☠'), isFalse);
    expect(RegExp(r'"jv2Intensity[^"]*":\s*"[^"]*(Paralisante|Incapacitante|urgente)').hasMatch(arb), isFalse);
  });
}

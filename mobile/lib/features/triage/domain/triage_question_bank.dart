import 'triage_question.dart';
import 'triage_vertical.dart';

class TriageQuestionBank {
  const TriageQuestionBank._();

  static const List<TriageQuestion> psicoEmocional = [
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Emotional',
      options: [
        TriageOption(
          key: 'ansiosa_agitacao',
          labelKey: 'triageOptAnsiosaAgitacao',
          systemKey: 'ansiosa_agitacao',
        ),
        TriageOption(
          key: 'depressiva_desanimo',
          labelKey: 'triageOptDepressivaDesanimo',
          systemKey: 'depressiva_desanimo',
        ),
        TriageOption(
          key: 'estresse_burnout',
          labelKey: 'triageOptEstresseBurnout',
          systemKey: 'estresse_burnout',
        ),
        TriageOption(
          key: 'somatica',
          labelKey: 'triageOptSomatica',
          systemKey: 'somatica',
        ),
        TriageOption(
          key: 'sono',
          labelKey: 'triageOptSono',
          systemKey: 'sono',
        ),
        TriageOption(
          key: 'cognitiva_foco',
          labelKey: 'triageOptCognitivaFoco',
          systemKey: 'cognitiva_foco',
        ),
        TriageOption(
          key: 'autoestima',
          labelKey: 'triageOptAutoestima',
          systemKey: 'autoestima',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 1,
      questionKey: 'triageQ2Emotional',
      options: [
        TriageOption(key: 'comecou_hoje', labelKey: 'triageOptComecouHoje'),
        TriageOption(key: 'ja_faz_alguns_dias', labelKey: 'triageOptJaFazDias'),
        TriageOption(
          key: 'algo_constante_semanas',
          labelKey: 'triageOptConstanteSemanas',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 2,
      questionKey: 'triageQ3Emotional',
      options: [
        TriageOption(
          key: 'leve_controlavel',
          labelKey: 'triageOptLeveControlavel',
          intensityValue: 2,
        ),
        TriageOption(
          key: 'moderada',
          labelKey: 'triageOptModerada',
          intensityValue: 3,
        ),
        TriageOption(
          key: 'muito_forte',
          labelKey: 'triageOptMuitoForte',
          intensityValue: 4,
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 3,
      questionKey: 'triageQ4Emotional',
      options: [
        TriageOption(key: 'trabalho_estudos', labelKey: 'triageOptTrabalho'),
        TriageOption(
          key: 'familia_relacionamentos',
          labelKey: 'triageOptFamilia',
        ),
        TriageOption(key: 'noite_ruim_sono', labelKey: 'triageOptNoiteRuim'),
        TriageOption(key: 'nao_sei_dizer', labelKey: 'triageOptNaoSei'),
      ],
    ),
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewEmotional',
      options: [],
      isPreview: true,
    ),
  ];

  static const List<TriageQuestion> fisica = [
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Physical',
      options: [
        TriageOption(
          key: 'cabeca_pescoco',
          labelKey: 'triageOptCabecaPescoco',
          systemKey: 'cabeca_pescoco',
        ),
        TriageOption(
          key: 'cardiovascular_torax',
          labelKey: 'triageOptCardiovascularTorax',
          systemKey: 'cardiovascular_torax',
        ),
        TriageOption(
          key: 'respiratorio',
          labelKey: 'triageOptRespiratorio',
          systemKey: 'respiratorio',
        ),
        TriageOption(
          key: 'gastrointestinal_abdomen',
          labelKey: 'triageOptGastrointestinalAbdomen',
          systemKey: 'gastrointestinal_abdomen',
        ),
        TriageOption(
          key: 'coluna_dor_dorsal',
          labelKey: 'triageOptColunaDorDorsal',
          systemKey: 'coluna_dor_dorsal',
        ),
        TriageOption(
          key: 'membros_superiores',
          labelKey: 'triageOptMembrosSuperiores',
          systemKey: 'membros_superiores',
        ),
        TriageOption(
          key: 'membros_inferiores',
          labelKey: 'triageOptMembrosInferiores',
          systemKey: 'membros_inferiores',
        ),
        TriageOption(
          key: 'neurologico',
          labelKey: 'triageOptNeurologico',
          systemKey: 'neurologico',
        ),
        TriageOption(
          key: 'geniturinario_pelvico',
          labelKey: 'triageOptGeniturinarioPelvico',
          systemKey: 'geniturinario_pelvico',
        ),
        TriageOption(
          key: 'dermatologico',
          labelKey: 'triageOptDermatologico',
          systemKey: 'dermatologico',
        ),
        TriageOption(
          key: 'muscular_geral_sistemico',
          labelKey: 'triageOptMuscularGeralSistemico',
          systemKey: 'muscular_geral_sistemico',
        ),
        TriageOption(
          key: 'endocrino_metabolico',
          labelKey: 'triageOptEndocrinoMetabolico',
          systemKey: 'endocrino_metabolico',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 1,
      questionKey: 'triageQ2Physical',
      options: [
        TriageOption(key: 'comecou_agora', labelKey: 'triageOptComecouAgora'),
        TriageOption(
          key: 'ha_alguns_dias',
          labelKey: 'triageOptHaAlgunsDias',
        ),
        TriageOption(key: 'e_cronica', labelKey: 'triageOptCronica'),
      ],
    ),
    TriageQuestion(
      stepIndex: 2,
      questionKey: 'triageQ3Physical',
      options: [],
      isNumericScale: true,
    ),
    TriageQuestion(
      stepIndex: 3,
      questionKey: 'triageQ4Physical',
      options: [
        TriageOption(
          key: 'sim_exercicio_intenso',
          labelKey: 'triageOptSimExercicio',
        ),
        TriageOption(key: 'sim_sofri_queda', labelKey: 'triageOptSimQueda'),
        TriageOption(
          key: 'nao_comecou_do_nada',
          labelKey: 'triageOptNaoComecouNada',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewPhysical',
      options: [],
      isPreview: true,
    ),
  ];

  static List<TriageQuestion> forVertical(TriageVertical v) =>
      v == TriageVertical.psicoEmocional ? psicoEmocional : fisica;
}

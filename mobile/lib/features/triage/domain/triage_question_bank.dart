import 'triage_question.dart';
import 'triage_vertical.dart';

/// Static registry of all 10 questions (5 per vertical).
/// Question text and labels are referenced by ARB localization keys.
class TriageQuestionBank {
  const TriageQuestionBank._();

  /// Vertical A — Psico-Emocional: 5 clinical steps.
  static const List<TriageQuestion> psicoEmocional = [
    // Step 0: Nature of emotional state
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Emotional',
      options: [
        TriageOption(
          key: 'ansiedade_agitacao',
          labelKey: 'triageOptAnsiedade',
          systemKey: 'anxious_agitation',
        ),
        TriageOption(
          key: 'tristeza_desanimo',
          labelKey: 'triageOptTristeza',
          systemKey: 'depressive_hopelessness',
        ),
        TriageOption(
          key: 'estresse_irritabilidade',
          labelKey: 'triageOptEstresse',
          systemKey: 'stress_burnout',
        ),
        TriageOption(
          key: 'cansaco_mental',
          labelKey: 'triageOptCansaco',
          systemKey: 'emotional_general',
        ),
      ],
    ),
    // Step 1: Persistence / duration
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
    // Step 2: Intensity — emergency gate fires here
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
    // Step 3: Triggers / context
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
    // Step 4: Preview / confirmation (no selection required)
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewEmotional',
      options: [],
      isPreview: true,
    ),
  ];

  /// Vertical B — Física: 5 clinical steps.
  static const List<TriageQuestion> fisica = [
    // Step 0: Location / anatomical system
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Physical',
      options: [
        TriageOption(
          key: 'cabeca',
          labelKey: 'triageOptCabeca',
          systemKey: 'head_neck',
        ),
        TriageOption(
          key: 'costas_coluna',
          labelKey: 'triageOptCostas',
          systemKey: 'musculoskeletal_back',
        ),
        TriageOption(
          key: 'articulacoes',
          labelKey: 'triageOptArticulacoes',
          systemKey: 'musculoskeletal_joints',
        ),
        TriageOption(
          key: 'abdomen_estomago',
          labelKey: 'triageOptAbdomen',
          systemKey: 'gastrointestinal',
        ),
      ],
    ),
    // Step 1: Duration / persistence
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
    // Step 2: Intensity scale 1-5 (numeric selector, emergency gate fires here)
    TriageQuestion(
      stepIndex: 2,
      questionKey: 'triageQ3Physical',
      options: [],
      isNumericScale: true,
    ),
    // Step 3: Triggers / context
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
    // Step 4: Preview / confirmation (no selection required)
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewPhysical',
      options: [],
      isPreview: true,
    ),
  ];

  /// Returns the question list for the given vertical.
  static List<TriageQuestion> forVertical(TriageVertical v) =>
      v == TriageVertical.psicoEmocional ? psicoEmocional : fisica;
}

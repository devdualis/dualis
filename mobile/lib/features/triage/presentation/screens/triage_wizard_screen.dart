import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/triage_question.dart';
import '../../domain/triage_question_bank.dart';
import '../../domain/triage_vertical.dart';
import '../../domain/triage_wizard_state.dart';
import '../controllers/triage_wizard_notifier.dart';
import '../widgets/triage_intensity_selector.dart';
import '../widgets/triage_option_chip.dart';
import '../widgets/triage_preview_card.dart';
import '../widgets/triage_step_banner.dart';
import '../widgets/antiburla_verification_bottom_sheet.dart';
import '../../data/antiburla_remote_data_source.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/sync/data/triage_outbox_repository.dart';
import 'package:dualis_mobile/features/home/domain/axis_intensity_resolver.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import '../../domain/symptom_classification.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../l10n/locale_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../emergency/domain/red_flag_evaluator.dart';
import '../../../emergency/presentation/widgets/safety_notice_banner.dart';

class TriageWizardScreen extends ConsumerStatefulWidget {
  final TriageVertical vertical;
  final bool isDual;
  final String? naturalLanguageText;
  final String? preselectedCategoryKey;
  final bool mentionsSelfHarm;

  const TriageWizardScreen({
    super.key,
    this.vertical = TriageVertical.psicoEmocional,
    this.isDual = false,
    this.naturalLanguageText,
    this.preselectedCategoryKey,
    this.mentionsSelfHarm = false,
  });

  @override
  ConsumerState<TriageWizardScreen> createState() => _TriageWizardScreenState();
}

class _TriageWizardScreenState extends ConsumerState<TriageWizardScreen> {
  Color _prevColor = AppColors.softIndigo;
  TriageOutcome? _physicalOutcome;
  late final TextEditingController _narrativeController;
  late final TextEditingController _stepZeroFreeTextController;
  Timer? _stepZeroClassificationDebounce;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initialNarrative = (widget.naturalLanguageText != null &&
            int.tryParse(widget.naturalLanguageText!.trim()) == null)
        ? widget.naturalLanguageText!
        : '';
    _narrativeController = TextEditingController(text: initialNarrative);
    _stepZeroFreeTextController = TextEditingController();
    _prevColor = widget.vertical == TriageVertical.psicoEmocional
        ? AppColors.softIndigo
        : AppColors.clinicalTeal;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(widget.vertical);
      final categoryKey = widget.preselectedCategoryKey;
      if (categoryKey != null && categoryKey.isNotEmpty) {
        notifier.presetCategoryAndSkip(categoryKey);
      }
      // Safety net: text typed on Home (local patterns) or flagged by the AI.
      if (!mounted) return;
      if (widget.mentionsSelfHarm) {
        SafetyNotice.show(context, SafetyNoticeKind.selfHarm);
      } else if (initialNarrative.trim().isNotEmpty) {
        notifier.checkFreeText(context, initialNarrative);
      }
    });
  }

  @override
  void dispose() {
    _stepZeroClassificationDebounce?.cancel();
    _narrativeController.dispose();
    _stepZeroFreeTextController.dispose();
    super.dispose();
  }

  /// Debounces the step-0 free-text input (~600ms) and, on a successful,
  /// non-off-topic classification, highlights the matching icon tile via the
  /// same `selectOption` mechanism tapping a tile uses. This is a convenience
  /// layer only: the user still taps "Next" themselves and can tap a
  /// different tile afterward to override the suggestion. Errors, offline
  /// failures, and off-topic results are swallowed silently — the icon grid
  /// remains the fallback.
  void _onStepZeroFreeTextChanged(String text) {
    _stepZeroClassificationDebounce?.cancel();
    if (text.trim().isEmpty) return;
    _stepZeroClassificationDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      SymptomClassification classification;
      try {
        classification =
            await ref.read(symptomClassificationDataSourceProvider).classify(text);
      } catch (_) {
        return;
      }
      if (!mounted) return;
      if (classification.mentionsSelfHarm) {
        SafetyNotice.show(context, SafetyNoticeKind.selfHarm);
        return;
      }
      if (classification.isOffTopic) return;
      ref.read(triageWizardNotifierProvider.notifier).selectOption(
            context,
            0,
            classification.wizardCategoryKey,
          );
    });
  }

  Color _getActiveColor(TriageVertical vertical) {
    switch (vertical) {
      case TriageVertical.psicoEmocional:
        return AppColors.softIndigo;
      case TriageVertical.fisica:
        return AppColors.clinicalTeal;
    }
  }

  String _resolveQuestionText(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'triageQ1Emotional':
        return l10n.triageQ1Emotional;
      case 'triageQ2Emotional':
        return l10n.triageQ2Emotional;
      case 'triageQ3Emotional':
        return l10n.triageQ3Emotional;
      case 'triageQ4Emotional':
        return l10n.triageQ4Emotional;
      case 'triageQ4Ansiedade':
        return l10n.triageQ4Ansiedade;
      case 'triageQ4Depressao':
        return l10n.triageQ4Depressao;
      case 'triageQ4EstresseBurnout':
        return l10n.triageQ4EstresseBurnout;
      case 'triageQ4Somatica':
        return l10n.triageQ4Somatica;
      case 'triageQ4Sono':
        return l10n.triageQ4Sono;
      case 'triageQ4CognitivaFoco':
        return l10n.triageQ4CognitivaFoco;
      case 'triageQ4Autoestima':
        return l10n.triageQ4Autoestima;
      case 'triagePreviewEmotional':
        return l10n.triagePreviewEmotional;
      case 'triageQ1Physical':
        return l10n.triageQ1Physical;
      case 'triageQ2Physical':
        return l10n.triageQ2Physical;
      case 'triageQ3Physical':
        return l10n.triageQ3Physical;
      case 'triageQ4Physical':
        return l10n.triageQ4Physical;
      case 'triageQ4CabecaPescoco':
        return l10n.triageQ4CabecaPescoco;
      case 'triageQ4CardiovascularTorax':
        return l10n.triageQ4CardiovascularTorax;
      case 'triageQ4Respiratorio':
        return l10n.triageQ4Respiratorio;
      case 'triageQ4Gastrointestinal':
        return l10n.triageQ4Gastrointestinal;
      case 'triageQ4ColunaDorDorsal':
        return l10n.triageQ4ColunaDorDorsal;
      case 'triageQ4MembrosSuperiores':
        return l10n.triageQ4MembrosSuperiores;
      case 'triageQ4MembrosInferiores':
        return l10n.triageQ4MembrosInferiores;
      case 'triageQ4Neurologico':
        return l10n.triageQ4Neurologico;
      case 'triageQ4Geniturinario':
        return l10n.triageQ4Geniturinario;
      case 'triageQ4Dermatological':
        return l10n.triageQ4Dermatological;
      case 'triageQ4MuscularGeral':
        return l10n.triageQ4MuscularGeral;
      case 'triageQ4EndocrinoMetabolico':
        return l10n.triageQ4EndocrinoMetabolico;
      case 'triagePreviewPhysical':
        return l10n.triagePreviewPhysical;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(triageWizardNotifierProvider);
    final questions = TriageQuestionBank.forVertical(
      state.activeVertical,
      systemKey: state.answers[0],
    );
    final currentQuestion = state.currentStep < questions.length
        ? questions[state.currentStep]
        : questions.last;

    final targetColor = _getActiveColor(state.activeVertical);

    final bannerTitle = state.activeVertical == TriageVertical.psicoEmocional
        ? l10n.triageBannerEmotional
        : l10n.triageBannerPhysical;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: _prevColor, end: targetColor),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      onEnd: () {
        _prevColor = targetColor;
      },
      builder: (context, animatedColor, child) {
        final activeColor = animatedColor ?? targetColor;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          appBar: TriageStepBanner(
            title: bannerTitle,
            currentStep: state.currentStep,
            totalSteps: questions.length,
            activeColor: activeColor,
            onBack: () {
              if (state.currentStep > 0) {
                ref.read(triageWizardNotifierProvider.notifier).goBack();
              } else {
                context.pop();
              }
            },
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey<int>(state.currentStep),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.currentStep == 1 &&
                          widget.preselectedCategoryKey != null) ...[
                        _buildDetectedCategoryBanner(
                          context,
                          activeColor,
                          state.answers[0] ?? widget.preselectedCategoryKey!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!currentQuestion.isPreview) ...[
                        Text(
                          _resolveQuestionText(context, currentQuestion.questionKey),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildStepContent(
                            context,
                            state,
                            currentQuestion,
                            activeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBottomBar(
                        context,
                        state,
                        currentQuestion,
                        activeColor,
                        l10n,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetectedCategoryBanner(
    BuildContext context,
    Color activeColor,
    String categoryKey,
  ) {
    final label = TriagePreviewCard.resolveAnswerLabel(context, categoryKey);
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 16, color: activeColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Detectamos: $label',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              ref.read(triageWizardNotifierProvider.notifier).goBack(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Trocar categoria',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              color: activeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    TriageWizardState state,
    TriageQuestion question,
    Color activeColor,
  ) {
    if (question.isPreview) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TriagePreviewCard(
            vertical: state.activeVertical,
            answers: state.answers,
            activeColor: activeColor,
          ),
          const SizedBox(height: 16),
          Card(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: activeColor.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 20, color: activeColor),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).wizardNarrativeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('triageOptionalNarrativeInput'),
                    controller: _narrativeController,
                    maxLines: 3,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).wizardNarrativeHint,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: activeColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (question.isNumericScale) {
      final selectedInt = int.tryParse(state.answers[state.currentStep] ?? '');
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TriageIntensitySelector(
          selectedValue: selectedInt,
          activeColor: activeColor,
          onSelect: (value) {
            ref.read(triageWizardNotifierProvider.notifier).selectOption(
                  context,
                  state.currentStep,
                  '$value',
                );
          },
        ),
      );
    }

    if (state.currentStep == 0 && question.stepIndex == 0) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            // 'normal' stays a valid, fully-functional answer key (see
            // _handleNormalCompletion / isNormalSelection in this file and
            // TriageQuestionBank) — it is just not rendered as a grid tile,
            // since the home screen's big icon buttons already cover that
            // meaning. Only the visual option is removed here.
            children: question.options
                .where((option) => option.key != 'normal')
                .map((option) {
              final isSelected = state.answers[state.currentStep] == option.key;
              final label = TriagePreviewCard.resolveAnswerLabel(context, option.key);

              return _IconOptionTile(
                optionKey: option.key,
                label: label,
                isSelected: isSelected,
                activeColor: activeColor,
                onTap: () {
                  ref.read(triageWizardNotifierProvider.notifier).selectOption(
                        context,
                        state.currentStep,
                        option.key,
                      );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).wizardStepZeroFreeTextLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('triageStepZeroFreeTextInput'),
            controller: _stepZeroFreeTextController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onChanged: _onStepZeroFreeTextChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).wizardStepZeroFreeTextHint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: activeColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    }

    return Column(
      children: question.options.map((option) {
        final isSelected = state.answers[state.currentStep] == option.key;
        final label = TriagePreviewCard.resolveAnswerLabel(context, option.key);

        return TriageOptionChip(
          label: label,
          isSelected: isSelected,
          activeColor: activeColor,
          onTap: () {
            ref.read(triageWizardNotifierProvider.notifier).selectOption(
                  context,
                  state.currentStep,
                  option.key,
                );
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    TriageWizardState state,
    TriageQuestion question,
    Color activeColor,
    AppLocalizations l10n,
  ) {
    final canAdvance = state.canAdvance;

    if (question.isPreview) {
      final isTransitionToEmotional =
          widget.isDual && state.activeVertical == TriageVertical.fisica;
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: !_isSubmitting ? activeColor : activeColor.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting
            ? null
            : () async {
                setState(() {
                  _isSubmitting = true;
                });
                try {
                  final answers = Map<int, String>.from(state.answers);
                  final verticalStr =
                      state.activeVertical == TriageVertical.fisica ? 'physical' : 'emotional';
                  final narrativeInput = _narrativeController.text.trim();
                  final effectiveNarrative = (narrativeInput.isNotEmpty &&
                          int.tryParse(narrativeInput) == null)
                      ? narrativeInput
                      : ((widget.naturalLanguageText != null &&
                              widget.naturalLanguageText!.trim().isNotEmpty &&
                              int.tryParse(widget.naturalLanguageText!.trim()) == null)
                          ? widget.naturalLanguageText!.trim()
                          : null);

                  // Safety net for the text written in the wizard itself. The
                  // notice lives on the root messenger, so it stays visible
                  // after navigating home.
                  if (narrativeInput.isNotEmpty &&
                      narrativeInput != (widget.naturalLanguageText ?? '').trim()) {
                    ref
                        .read(triageWizardNotifierProvider.notifier)
                        .checkFreeText(context, narrativeInput);
                  }

                  ref.read(triageWizardNotifierProvider.notifier).advance();

                  final dataSource = ref.read(triageOutcomeDataSourceProvider);
                  final connectivity = ref.read(connectivityServiceProvider);
                  final isOnline = await connectivity.checkOnline();
                  final clientSessionId = const Uuid().v4();

                  final langCode = ref.read(localeProvider).languageCode;
                  TriageOutcome outcome;
                  if (isOnline) {
                    try {
                      outcome = await dataSource.submitTriage(
                        vertical: verticalStr,
                        answers: answers,
                        narrative: effectiveNarrative,
                        clientSessionId: clientSessionId,
                        language: langCode,
                      );
                    } catch (_) {
                      await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
                        vertical: verticalStr,
                        answers: answers,
                        clientSessionId: clientSessionId,
                      );
                      outcome = dataSource.generateOfflineFallback(
                        verticalStr,
                        answers,
                        effectiveNarrative,
                        language: langCode,
                      );
                    }
                  } else {
                    await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
                      vertical: verticalStr,
                      answers: answers,
                      clientSessionId: clientSessionId,
                    );
                    outcome = dataSource.generateOfflineFallback(
                      verticalStr,
                      answers,
                      effectiveNarrative,
                      language: langCode,
                    );
                  }

                  if (isTransitionToEmotional) {
                    setState(() {
                      _physicalOutcome = outcome;
                      _isSubmitting = false;
                    });
                    ref
                        .read(triageWizardNotifierProvider.notifier)
                        .setVertical(TriageVertical.psicoEmocional);
                    return;
                  }

                  var finalOutcome = outcome;
                  final currentTrigger = ref.read(triggerCheckInProvider);
                  final existingOutcome = ref.read(triageOutcomeProvider).outcome;

                  if (widget.isDual && _physicalOutcome != null) {
                    finalOutcome = _physicalOutcome!.copyWith(
                      secondaryCategoryLabel: outcome.categoryLabel,
                      secondarySomaticMapping: outcome.somaticMapping,
                      secondaryIntensityScore: outcome.intensityScore,
                    );
                  } else if (outcome.vertical == 'physical' &&
                      (currentTrigger.isEmotionalCompleted ||
                          (existingOutcome != null && existingOutcome.vertical == 'emotional'))) {
                    final emoOutcome =
                        existingOutcome?.vertical == 'emotional' ? existingOutcome : null;
                    final emoLabel = currentTrigger.emotionalSummary ?? emoOutcome?.categoryLabel;
                    final emoMapping = currentTrigger.emotionalNarrative ??
                        emoOutcome?.somaticMapping ??
                        'Registro emocional salvo';
                    final emoScore = AxisIntensityResolver.resolveDisplayIntensity(
                      axis: CheckInAxis.emotional,
                      state: currentTrigger,
                      outcome: existingOutcome,
                    );
                    finalOutcome = outcome.copyWith(
                      secondaryCategoryLabel: emoLabel,
                      secondarySomaticMapping: emoMapping,
                      secondaryIntensityScore: emoScore,
                    );
                  } else if (outcome.vertical == 'emotional' &&
                      (currentTrigger.isPhysicalCompleted ||
                          (existingOutcome != null && existingOutcome.vertical == 'physical'))) {
                    final physOutcome =
                        existingOutcome?.vertical == 'physical' ? existingOutcome : null;
                    final physLabel = currentTrigger.physicalSummary ?? physOutcome?.categoryLabel;
                    final physMapping = currentTrigger.physicalNarrative ??
                        physOutcome?.somaticMapping ??
                        'Registro físico salvo';
                    final physScore = AxisIntensityResolver.resolveDisplayIntensity(
                      axis: CheckInAxis.physical,
                      state: currentTrigger,
                      outcome: existingOutcome,
                    );
                    finalOutcome = outcome.copyWith(
                      secondaryCategoryLabel: physLabel,
                      secondarySomaticMapping: physMapping,
                      secondaryIntensityScore: physScore,
                    );
                  }
                  ref.read(triageOutcomeProvider.notifier).setOutcome(finalOutcome);
                  ref.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(
                    finalOutcome,
                    narrative: effectiveNarrative,
                  );

                  if (context.mounted) {
                    ref.read(triageWizardNotifierProvider.notifier).reset();
                    context.go(RoutePaths.home);
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSubmitting = false;
                    });
                  }
                }
              },
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isTransitionToEmotional
                    ? 'Concluir Física e Iniciar Psico-Emocional'
                    : l10n.triagePreviewSubmit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    final isNormalSelection = state.currentStep == 0 &&
        (state.answers[0] == 'normal' || state.answers[0] == 'bem_normal');
    final isTransitionToEmotional =
        widget.isDual && state.activeVertical == TriageVertical.fisica;

    final String buttonLabel;
    if (isNormalSelection) {
      buttonLabel = isTransitionToEmotional
          ? 'Concluir Física e Iniciar Psico-Emocional'
          : l10n.triageSaveNormal;
    } else {
      buttonLabel = l10n.triageNext;
    }

    final isButtonEnabled = canAdvance && !_isSubmitting;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: isButtonEnabled ? activeColor : activeColor.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isButtonEnabled ? () => _handleNext(context, state) : null,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              buttonLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _handleNormalCompletion(
    BuildContext context,
    TriageWizardState state,
  ) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = <int, String>{0: 'normal'};
      final verticalStr =
          state.activeVertical == TriageVertical.fisica ? 'physical' : 'emotional';
      final isTransitionToEmotional =
          widget.isDual && state.activeVertical == TriageVertical.fisica;

      final dataSource = ref.read(triageOutcomeDataSourceProvider);
      final connectivity = ref.read(connectivityServiceProvider);
      final isOnline = await connectivity.checkOnline();
      final clientSessionId = const Uuid().v4();

      final langCode = ref.read(localeProvider).languageCode;
      TriageOutcome outcome;
      if (isOnline) {
        try {
          outcome = await dataSource.submitTriage(
            vertical: verticalStr,
            answers: answers,
            narrative: null,
            clientSessionId: clientSessionId,
            language: langCode,
          );
        } catch (_) {
          await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
            vertical: verticalStr,
            answers: answers,
            clientSessionId: clientSessionId,
          );
          outcome = dataSource.generateOfflineFallback(
            verticalStr,
            answers,
            null,
            language: langCode,
          );
        }
      } else {
        await ref.read(triageOutboxRepositoryProvider).enqueueTriageCheckIn(
          vertical: verticalStr,
          answers: answers,
          clientSessionId: clientSessionId,
        );
        outcome = dataSource.generateOfflineFallback(
          verticalStr,
          answers,
          null,
          language: langCode,
        );
      }

      if (isTransitionToEmotional) {
        ref.read(triggerCheckInProvider.notifier).completeStage(
          vertical: TriageVertical.fisica,
          summary: 'Bem / Normal',
          status: TriggerStatus.goodNormal,
          intensity: 0,
        );
        if (mounted) {
          setState(() {
            _physicalOutcome = outcome;
            _isSubmitting = false;
          });
        }
        ref
            .read(triageWizardNotifierProvider.notifier)
            .setVertical(TriageVertical.psicoEmocional);
        return;
      }

      var finalOutcome = outcome;
      final currentTrigger = ref.read(triggerCheckInProvider);
      final existingOutcome = ref.read(triageOutcomeProvider).outcome;

      if (widget.isDual && _physicalOutcome != null) {
        finalOutcome = _physicalOutcome!.copyWith(
          secondaryCategoryLabel: outcome.categoryLabel,
          secondarySomaticMapping: outcome.somaticMapping,
          secondaryIntensityScore: outcome.intensityScore,
        );
      } else if (outcome.vertical == 'physical' &&
          (currentTrigger.isEmotionalCompleted ||
              (existingOutcome != null && existingOutcome.vertical == 'emotional'))) {
        final emoOutcome =
            existingOutcome?.vertical == 'emotional' ? existingOutcome : null;
        final emoLabel = currentTrigger.emotionalSummary ?? emoOutcome?.categoryLabel;
        final emoMapping = currentTrigger.emotionalNarrative ??
            emoOutcome?.somaticMapping ??
            'Registro emocional salvo';
        final emoScore = AxisIntensityResolver.resolveDisplayIntensity(
          axis: CheckInAxis.emotional,
          state: currentTrigger,
          outcome: existingOutcome,
        );
        finalOutcome = outcome.copyWith(
          secondaryCategoryLabel: emoLabel,
          secondarySomaticMapping: emoMapping,
          secondaryIntensityScore: emoScore,
        );
      } else if (outcome.vertical == 'emotional' &&
          (currentTrigger.isPhysicalCompleted ||
              (existingOutcome != null && existingOutcome.vertical == 'physical'))) {
        final physOutcome =
            existingOutcome?.vertical == 'physical' ? existingOutcome : null;
        final physLabel = currentTrigger.physicalSummary ?? physOutcome?.categoryLabel;
        final physMapping = currentTrigger.physicalNarrative ??
            physOutcome?.somaticMapping ??
            'Registro físico salvo';
        final physScore = AxisIntensityResolver.resolveDisplayIntensity(
          axis: CheckInAxis.physical,
          state: currentTrigger,
          outcome: existingOutcome,
        );
        finalOutcome = outcome.copyWith(
          secondaryCategoryLabel: physLabel,
          secondarySomaticMapping: physMapping,
          secondaryIntensityScore: physScore,
        );
      }

      ref.read(triageOutcomeProvider.notifier).setOutcome(finalOutcome);
      ref.read(triggerCheckInProvider.notifier).completeStage(
        vertical: state.activeVertical,
        summary: 'Bem / Normal',
        status: TriggerStatus.goodNormal,
        intensity: 0,
      );

      if (context.mounted) {
        ref.read(triageWizardNotifierProvider.notifier).reset();
        context.go(RoutePaths.home);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleNext(BuildContext context, TriageWizardState state) async {
    if (state.currentStep == 0 &&
        (state.answers[0] == 'normal' || state.answers[0] == 'bem_normal')) {
      await _handleNormalCompletion(context, state);
      return;
    }

    if (state.currentStep == 1) {
      final selectedPersistence = state.answers[1] ?? '';
      if (selectedPersistence == 'comecou_agora' ||
          selectedPersistence == 'comecou_hoje') {
        final verticalStr = state.activeVertical == TriageVertical.fisica
            ? 'physical'
            : 'emotional';
        final category = state.answers[0] ?? '';

        final antiburlaDataSource = ref.read(antiburlaDataSourceProvider);
        final checkResult = await antiburlaDataSource.checkConsistency(
          vertical: verticalStr,
          category: category,
          selectedPersistence: selectedPersistence,
          narrative: (widget.naturalLanguageText != null &&
                  widget.naturalLanguageText!.trim().isNotEmpty &&
                  int.tryParse(widget.naturalLanguageText!.trim()) == null)
              ? widget.naturalLanguageText!.trim()
              : null,
        );

        if (checkResult.triggered && context.mounted) {
          final choice = await AntiburlaVerificationBottomSheet.show(
            context,
            result: checkResult,
          );

          if (choice == AntiburlaUserChoice.recurring) {
            final reconciledValue =
                state.activeVertical == TriageVertical.fisica
                    ? 'ha_alguns_dias'
                    : 'ja_faz_alguns_dias';
            ref
                .read(triageWizardNotifierProvider.notifier)
                .updateAnswer(1, reconciledValue);
          }
        }
      }
    }

    if (context.mounted) {
      ref.read(triageWizardNotifierProvider.notifier).advance();
    }
  }
}

/// Maps step-0 (body-area/mood) option keys to a representative Material
/// icon. Purely a presentation concern resolved at render time — the
/// underlying option keys and their category semantics are untouched.
const Map<String, IconData> _stepZeroOptionIcons = {
  // Physical
  'cabeca_pescoco': Icons.face,
  'cardiovascular_torax': Icons.favorite,
  'respiratorio': Icons.air,
  'gastrointestinal_abdomen': Icons.restaurant,
  'coluna_dor_dorsal': Icons.accessibility,
  'membros_superiores': Icons.back_hand,
  'membros_inferiores': Icons.directions_walk,
  'neurologico': Icons.psychology_alt,
  'geniturinario_pelvico': Icons.wc,
  'dermatologico': Icons.healing,
  'muscular_geral_sistemico': Icons.fitness_center,
  'endocrino_metabolico': Icons.bolt,
  // Emotional
  'ansiosa_agitacao': Icons.bolt,
  'depressiva_desanimo': Icons.cloud,
  'estresse_burnout': Icons.whatshot,
  'somatica': Icons.favorite_border,
  'sono': Icons.bedtime,
  'cognitiva_foco': Icons.lightbulb,
  'autoestima': Icons.star,
  // Shared by both verticals
  'normal': Icons.sentiment_satisfied,
};

/// Circular icon tile for the step-0 body-area/mood grid. Visually replaces
/// [TriageOptionChip] for step 0 only; tapping triggers the same
/// `selectOption` call that the chip used to trigger.
class _IconOptionTile extends StatelessWidget {
  final String optionKey;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconOptionTile({
    required this.optionKey,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _stepZeroOptionIcons[optionKey] ?? Icons.circle_outlined;

    final textColor = isSelected
        ? activeColor
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: isSelected ? 0.25 : 0.1),
                border: isSelected
                    ? Border.all(color: activeColor, width: 2.0)
                    : null,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? activeColor
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

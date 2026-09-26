import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../data/triage_outcome_remote_data_source.dart';
import '../../domain/curated_articles_catalog.dart';
import '../../domain/triage_outcome_models.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../home/domain/axis_intensity_resolver.dart';
import '../../../home/presentation/controllers/trigger_checkin_controller.dart';

final triageOutcomeDataSourceProvider = Provider<TriageOutcomeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return TriageOutcomeRemoteDataSource(apiClient: apiClient, secureStorage: secureStorage);
});

class TriageOutcomeState {
  final bool isLoading;
  final TriageOutcome? outcome;
  final String? errorMessage;

  const TriageOutcomeState({
    this.isLoading = false,
    this.outcome,
    this.errorMessage,
  });

  TriageOutcomeState copyWith({
    bool? isLoading,
    TriageOutcome? outcome,
    String? errorMessage,
  }) {
    return TriageOutcomeState(
      isLoading: isLoading ?? this.isLoading,
      outcome: outcome ?? this.outcome,
      errorMessage: errorMessage,
    );
  }
}

class TriageOutcomeNotifier extends Notifier<TriageOutcomeState> {
  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);

  @override
  TriageOutcomeState build() {
    Future.microtask(() => loadTodayOutcome());
    return const TriageOutcomeState();
  }

  String _getTodayDateString([DateTime? now]) {
    final d = now ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _syncWithTriggerCheckIn(TriageOutcome outcome) {
    try {
      ref.read(triggerCheckInProvider.notifier).markCompletedWithOutcome(outcome);
    } catch (_) {}
  }

  Future<void> loadTodayOutcome() async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      final saved = await _storage.getTodayTriageOutcome(userId);
      if (saved != null) {
        final outcome = TriageOutcome.fromJson(saved);
        final recordedDate = _getTodayDateString(outcome.recordedAt.toLocal());
        final todayStr = _getTodayDateString();
        if (recordedDate == todayStr) {
          state = state.copyWith(outcome: outcome);
          _syncWithTriggerCheckIn(outcome);
          return;
        } else {
          await _storage.clearTodayTriageOutcome(userId);
        }
      }

      // If local storage did not have today's outcome, try remote history
      await _syncTodayOutcomeFromRemote();
    } catch (_) {}
  }

  Future<void> _syncTodayOutcomeFromRemote() async {
    try {
      final historyDataSource = ref.read(triageHistoryDataSourceProvider);
      final history = await historyDataSource.fetchHistory(days: 1);
      if (history.logs.isEmpty) return;

      final todayStr = _getTodayDateString();
      final todayLogs = history.logs.where((log) {
        final localDate = log.recordedAt.toLocal();
        return _getTodayDateString(localDate) == todayStr;
      }).toList();

      if (todayLogs.isEmpty) return;

      todayLogs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final triageLogs = todayLogs
          .where((log) => log.stepAnswers?['type'] != 'daily_checkin')
          .toList();
      final targetLog = triageLogs.isNotEmpty ? triageLogs.first : todayLogs.first;

      final outcome = _buildOutcomeFromHistoryEntry(targetLog, todayLogs);
      if (outcome != null) {
        state = state.copyWith(outcome: outcome);
        await _persistOutcome(outcome);
        _syncWithTriggerCheckIn(outcome);
      }
    } catch (_) {}
  }

  TriageOutcome? _buildOutcomeFromHistoryEntry(
    TriageHistoryEntry log,
    List<TriageHistoryEntry> todayLogs,
  ) {
    final isPhysical = log.anatomicalSystem != null && log.anatomicalSystem != 'geral_emocional';
    final isDual = log.anatomicalSystem != null && log.emotionalDimension != null;
    final isOrganicPrimacy = log.organicPrimacyApplied || isDual;

    // Vertical follows the record's own (primary) axis, not its cross-vertical tag.
    final primaryAxis = AxisIntensityResolver.primaryAxisOf(log) ??
        (isPhysical ? CheckInAxis.physical : CheckInAxis.emotional);
    final secondaryAxis = primaryAxis.other;
    final secondaryCode =
        isDual ? AxisIntensityResolver.categoryCodeFor(log, secondaryAxis) : null;

    final primaryCode = AxisIntensityResolver.categoryCodeFor(log, primaryAxis) ??
        log.anatomicalSystem ??
        log.emotionalDimension ??
        'geral';
    final narrative = log.narrative ?? log.stepAnswers?['naturalLanguageText'] as String? ?? '';

    final articles = CuratedArticlesCatalog.getArticlesForSymptoms(
      queryText: narrative,
      anatomicalSystem: log.anatomicalSystem,
      emotionalDimension: log.emotionalDimension,
      isEmotionalDistressed: log.emotionalDimension != null,
      isPhysicalDistressed: log.anatomicalSystem != null,
    );

    return TriageOutcome(
      id: log.id,
      vertical: primaryAxis.outcomeVertical,
      intensityScore: log.intensity,
      careDisposition: CareDisposition.fromCode(log.disposition),
      primaryCategory: primaryCode,
      categoryLabel: _mapCategoryLabel(primaryCode),
      somaticMapping: _mapSomaticDescription(primaryCode),
      organicPrimacyApplied: isOrganicPrimacy,
      organicPrimacyNotice: isOrganicPrimacy
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.'
          : null,
      recommendedArticles: articles,
      recordedAt: log.recordedAt.toLocal(),
      secondaryCategoryLabel:
          secondaryCode != null ? _mapCategoryLabel(secondaryCode) : null,
      secondarySomaticMapping:
          secondaryCode != null ? _mapSomaticDescription(secondaryCode) : null,
      secondaryIntensityScore: isDual
          ? (AxisIntensityResolver.latestRecordFor(secondaryAxis, todayLogs)
                  ?.intensity ??
              log.intensity)
          : null,
      aiMappedLayTerm: narrative.isNotEmpty ? narrative : null,
    );
  }

  String _mapCategoryLabel(String code) => mapCategoryLabel(code);

  String _mapSomaticDescription(String code) => mapSomaticDescription(code);

  Future<void> setOutcomeFromCheckIn({
    required String id,
    required int intensity,
    required String disposition,
    required String emotionalStatus,
    required String physicalStatus,
    String? naturalLanguageText,
    List<RecommendedArticle>? articles,
    DateTime? recordedAt,
  }) async {
    final isPhysical = physicalStatus != 'goodNormal';
    final isEmotional = emotionalStatus != 'goodNormal';
    final isDual = isPhysical && isEmotional;

    String primaryCode;
    String? secondaryCode;

    final lower = (naturalLanguageText ?? '').toLowerCase();
    if (lower.contains('coceira') || lower.contains('pele') || lower.contains('alergia')) {
      primaryCode = 'dermatologico';
    } else if (lower.contains('braco') || lower.contains('braço') || lower.contains('ombro')) {
      primaryCode = 'membros_superiores';
    } else if (lower.contains('cabeca') || lower.contains('cabeça')) {
      primaryCode = 'cabeca_pescoco';
    } else if (lower.contains('coluna') || lower.contains('lombar')) {
      primaryCode = 'coluna_dor_lombar';
    } else if (isPhysical) {
      primaryCode = 'geral_fisico';
    } else {
      primaryCode = emotionalStatus == 'badSick' ? 'depressiva_desanimo' : 'ansiosa_agitacao';
    }

    if (isDual) {
      secondaryCode = emotionalStatus == 'badSick' ? 'depressiva_desanimo' : 'ansiosa_agitacao';
    }

    final resolvedArticles = (articles != null && articles.isNotEmpty)
        ? articles
        : CuratedArticlesCatalog.getArticlesForSymptoms(
            queryText: naturalLanguageText,
            anatomicalSystem: primaryCode,
            emotionalDimension: secondaryCode,
            isEmotionalDistressed: isEmotional,
            isPhysicalDistressed: isPhysical,
          );

    final outcome = TriageOutcome(
      id: id,
      vertical: isPhysical ? 'physical' : 'emotional',
      intensityScore: intensity,
      careDisposition: CareDisposition.fromCode(disposition),
      primaryCategory: primaryCode,
      categoryLabel: mapCategoryLabel(primaryCode),
      somaticMapping: mapSomaticDescription(primaryCode),
      organicPrimacyApplied: isDual,
      organicPrimacyNotice: isDual
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.'
          : null,
      recommendedArticles: resolvedArticles,
      recordedAt: recordedAt ?? DateTime.now(),
      secondaryCategoryLabel: secondaryCode != null ? mapCategoryLabel(secondaryCode) : null,
      secondarySomaticMapping: secondaryCode != null ? mapSomaticDescription(secondaryCode) : null,
      secondaryIntensityScore: isDual ? intensity : null,
      aiMappedLayTerm: naturalLanguageText,
    );

    state = state.copyWith(isLoading: false, outcome: outcome);
    await _persistOutcome(outcome);
    _syncWithTriggerCheckIn(outcome);
  }

  Future<void> submitOutcome({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
    String? language,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dataSource = ref.read(triageOutcomeDataSourceProvider);
      final lang = language ?? ref.read(localeProvider).languageCode;
      final outcome = await dataSource.submitTriage(
        vertical: vertical,
        answers: answers,
        narrative: narrative,
        token: token,
        language: lang,
      );
      state = state.copyWith(isLoading: false, outcome: outcome);
      await _persistOutcome(outcome);
      _syncWithTriggerCheckIn(outcome);
    } catch (e) {
      String cleanError = 'Não foi possível carregar o resultado da triagem.';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          cleanError = 'Não foi possível conectar ao servidor. Verifique sua conexão.';
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
    }
  }

  Future<void> _persistOutcome(TriageOutcome outcome) async {
    try {
      final userId = await _storage.getUserId() ?? 'anonymous';
      await _storage.saveTodayTriageOutcome(
        userId: userId,
        data: outcome.toJson(),
      );
    } catch (_) {}
  }

  void setOutcome(TriageOutcome outcome) {
    state = state.copyWith(isLoading: false, outcome: outcome);
    _persistOutcome(outcome);
    _syncWithTriggerCheckIn(outcome);
  }

  void reset() {
    state = const TriageOutcomeState();
  }
}

String mapCategoryLabel(String code) {
  switch (code) {
    case 'cabeca_pescoco':
    case 'cabeca':
      return 'Cabeça e Pescoço';
    case 'cardiovascular_torax':
    case 'cardiovascular':
      return 'Cardiovascular e Tórax';
    case 'respiratorio':
      return 'Sistema Respiratório';
    case 'gastrointestinal_abdomen':
    case 'abdomen':
      return 'Gastrointestinal e Abdômen';
    case 'coluna_dor_lombar':
    case 'coluna':
      return 'Coluna e Dor Lombar';
    case 'coluna_dor_dorsal':
    case 'coluna_dorsal':
      return 'Coluna e Dor Dorsal';
    case 'membros_superiores':
      return 'Membros Superiores e Articulações';
    case 'membros_inferiores':
      return 'Membros Inferiores';
    case 'dermatologico':
      return 'Dermatológico / Pele';
    case 'muscular_geral_sistemico':
      return 'Sistema Muscular / Geral Sistêmico';
    case 'geral_fisico':
      return 'Avaliação Física Geral';
    case 'ansiosa_agitacao':
    case 'ansiedade':
      return 'Dimensão Ansiosa / Agitação';
    case 'depressiva_desanimo':
    case 'tristeza':
      return 'Dimensão Depressiva / Desânimo';
    case 'estresse_burnout':
    case 'estresse':
      return 'Estresse e Burnout';
    case 'cognitiva_foco':
      return 'Cognição e Foco';
    case 'sono_vigilia':
    case 'sono':
      return 'Sono e Ritmo Circadiano';
    case 'somatica':
    case 'somatico':
    case 'somatizacao_tensao':
      return 'Dimensão Somática (Psicossomática)';
    case 'autoestima':
      return 'Autoestima e Autoimagem';
    case 'geral_emocional':
      return 'Avaliação Psico-Emocional Geral';
    default:
      return 'Avaliação de Saúde';
  }
}

String mapSomaticDescription(String code) {
  switch (code) {
    case 'dermatologico':
      return 'Prurido cutâneo / Desconforto na pele';
    case 'membros_superiores':
      return 'Desconforto musculoesquelético nos braços e ombros';
    case 'membros_inferiores':
      return 'Desconforto musculoesquelético nos membros inferiores';
    case 'cabeca_pescoco':
    case 'cabeca':
      return 'Cefaleia / Desconforto crânio-cervical';
    case 'cardiovascular_torax':
    case 'cardiovascular':
      return 'Sensação de aperto torácico ou palpitação funcional';
    case 'respiratorio':
      return 'Desconforto respiratório ou cansaço aos esforços';
    case 'gastrointestinal_abdomen':
    case 'abdomen':
      return 'Desconforto abdominal ou queixa digestiva';
    case 'coluna_dor_lombar':
    case 'coluna':
      return 'Desconforto na coluna / Lombalgia tensional';
    case 'coluna_dor_dorsal':
    case 'coluna_dorsal':
      return 'Desconforto musculoesquelético dorsal / Tensão escapular';
    case 'muscular_geral_sistemico':
      return 'Dores musculares difusas ou tensão corporal';
    case 'geral_fisico':
      return 'Desconforto somático ou queixa física reportada';
    case 'depressiva_desanimo':
    case 'tristeza':
      return 'Desânimo / Fadiga emocional transitória';
    case 'ansiosa_agitacao':
    case 'ansiedade':
      return 'Tensão psicomotora / Ansiedade antecipatória';
    case 'estresse_burnout':
    case 'estresse':
      return 'Exaustão emocional / Sobrecarga de estresse';
    case 'cognitiva_foco':
      return 'Dificuldade de concentração ou sobrecarga cognitiva';
    case 'sono_vigilia':
    case 'sono':
      return 'Desregulação do padrão de sono / Fadiga circadiana';
    case 'somatica':
    case 'somatico':
    case 'somatizacao_tensao':
      return 'Manifestação somatizada de sobrecarga emocional (nó na garganta / aperto torácico)';
    case 'autoestima':
      return 'Insegurança emocional / Autocrítica acentuada';
    case 'geral_emocional':
      return 'Alteração no bem-estar psico-emocional';
    default:
      return 'Sintomatologia reportada no check-in diário';
  }
}

final triageOutcomeProvider =
    NotifierProvider<TriageOutcomeNotifier, TriageOutcomeState>(
  TriageOutcomeNotifier.new,
);


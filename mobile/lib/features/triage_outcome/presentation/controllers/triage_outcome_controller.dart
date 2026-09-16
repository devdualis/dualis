import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../dashboard/data/triage_history_remote_data_source.dart';
import '../../../dashboard/domain/models/triage_history_models.dart';
import '../../data/triage_outcome_remote_data_source.dart';
import '../../domain/curated_articles_catalog.dart';
import '../../domain/triage_outcome_models.dart';

final triageOutcomeDataSourceProvider = Provider<TriageOutcomeRemoteDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return TriageOutcomeRemoteDataSource(secureStorage: secureStorage);
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
      final latestLog = todayLogs.first;

      final outcome = _buildOutcomeFromHistoryEntry(latestLog);
      if (outcome != null) {
        state = state.copyWith(outcome: outcome);
        await _persistOutcome(outcome);
      }
    } catch (_) {}
  }

  TriageOutcome? _buildOutcomeFromHistoryEntry(TriageHistoryEntry log) {
    final isPhysical = log.anatomicalSystem != null && log.anatomicalSystem != 'geral_emocional';
    final isDual = log.anatomicalSystem != null && log.emotionalDimension != null;

    final primaryCode = log.anatomicalSystem ?? log.emotionalDimension ?? 'geral';
    final narrative = log.stepAnswers?['naturalLanguageText'] as String? ?? '';

    final articles = CuratedArticlesCatalog.getArticlesForSymptoms(
      queryText: narrative,
      anatomicalSystem: log.anatomicalSystem,
      emotionalDimension: log.emotionalDimension,
      isEmotionalDistressed: log.emotionalDimension != null,
      isPhysicalDistressed: log.anatomicalSystem != null,
    );

    return TriageOutcome(
      id: log.id,
      vertical: isPhysical ? 'physical' : 'emotional',
      intensityScore: log.intensity,
      careDisposition: CareDisposition.fromCode(log.disposition),
      primaryCategory: primaryCode,
      categoryLabel: _mapCategoryLabel(primaryCode),
      somaticMapping: _mapSomaticDescription(primaryCode),
      organicPrimacyApplied: isDual,
      organicPrimacyNotice: isDual
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.'
          : null,
      recommendedArticles: articles,
      recordedAt: log.recordedAt.toLocal(),
      secondaryCategoryLabel: isDual && log.emotionalDimension != null
          ? _mapCategoryLabel(log.emotionalDimension!)
          : null,
      secondarySomaticMapping: isDual && log.emotionalDimension != null
          ? _mapSomaticDescription(log.emotionalDimension!)
          : null,
      secondaryIntensityScore: isDual ? log.intensity : null,
      aiMappedLayTerm: narrative.isNotEmpty ? narrative : null,
    );
  }

  String _mapCategoryLabel(String code) {
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
      case 'membros_superiores':
        return 'Membros Superiores e Articulações';
      case 'membros_inferiores':
        return 'Membros Inferiores';
      case 'dermatologico':
        return 'Dermatológico / Pele';
      case 'muscular_geral_sistemico':
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
        return 'Sono e Vigília';
      case 'somatizacao_tensao':
        return 'Somatização e Tensão Corporal';
      case 'geral_emocional':
        return 'Avaliação Psico-Emocional Geral';
      default:
        return 'Avaliação de Saúde';
    }
  }

  String _mapSomaticDescription(String code) {
    switch (code) {
      case 'dermatologico':
        return 'Prurido cutâneo / Desconforto na pele';
      case 'membros_superiores':
        return 'Desconforto musculoesquelético nos braços e ombros';
      case 'cabeca_pescoco':
      case 'cabeca':
        return 'Cefaleia / Desconforto crânio-cervical';
      case 'cardiovascular_torax':
        return 'Sensação de aperto torácico ou palpitação funcional';
      case 'coluna_dor_lombar':
        return 'Desconforto na coluna / Lombalgia tensional';
      case 'geral_fisico':
        return 'Desconforto somático ou queixa física reportada';
      case 'depressiva_desanimo':
        return 'Desânimo / Fadiga emocional transitória';
      case 'ansiosa_agitacao':
        return 'Tensão psicomotora / Ansiedade antecipatória';
      case 'estresse_burnout':
        return 'Exaustão emocional / Sobrecarga de estresse';
      case 'geral_emocional':
        return 'Alteração no bem-estar psico-emocional';
      default:
        return 'Sintomatologia reportada no check-in diário';
    }
  }

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
      categoryLabel: _mapCategoryLabel(primaryCode),
      somaticMapping: _mapSomaticDescription(primaryCode),
      organicPrimacyApplied: isDual,
      organicPrimacyNotice: isDual
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.'
          : null,
      recommendedArticles: resolvedArticles,
      recordedAt: recordedAt ?? DateTime.now(),
      secondaryCategoryLabel: secondaryCode != null ? _mapCategoryLabel(secondaryCode) : null,
      secondarySomaticMapping: secondaryCode != null ? _mapSomaticDescription(secondaryCode) : null,
      secondaryIntensityScore: isDual ? intensity : null,
      aiMappedLayTerm: naturalLanguageText,
    );

    state = state.copyWith(isLoading: false, outcome: outcome);
    await _persistOutcome(outcome);
  }

  Future<void> submitOutcome({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dataSource = ref.read(triageOutcomeDataSourceProvider);
      final outcome = await dataSource.submitTriage(
        vertical: vertical,
        answers: answers,
        narrative: narrative,
        token: token,
      );
      state = state.copyWith(isLoading: false, outcome: outcome);
      await _persistOutcome(outcome);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
  }

  void reset() {
    state = const TriageOutcomeState();
  }
}

final triageOutcomeProvider =
    NotifierProvider<TriageOutcomeNotifier, TriageOutcomeState>(
  TriageOutcomeNotifier.new,
);


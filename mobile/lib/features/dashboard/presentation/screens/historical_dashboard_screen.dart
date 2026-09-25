import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_message_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/anatomical_body_map.dart';
import '../widgets/critical_recurrence_card.dart';
import '../widgets/dashboard_segmented_tab.dart';
import '../widgets/emotional_trend_chart.dart';
import '../widgets/retrospective_list_view.dart';

class HistoricalDashboardScreen extends ConsumerWidget {
  final bool isEmbedded;
  const HistoricalDashboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);

    final content = dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) {
          final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
          final errorText = l10n != null
              ? ErrorMessageResolver.resolve(err, l10n)
              : (l10n?.errorLoadHistory ?? 'Não foi possível carregar o histórico de triagens.');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Não foi possível carregar o histórico',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.read(dashboardControllerProvider.notifier).refreshHistory(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (state) {
          final tab = state.selectedTab;
          final isEmotional = tab == DashboardTab.emotional;
          final recurrences = state.history.criticalRecurrences.where((r) {
            return isEmotional
                ? r.vertical == 'emotional'
                : r.vertical == 'physical';
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refreshHistory(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardSegmentedTab(
                    selectedTab: tab,
                    onTabChanged: (newTab) {
                      ref
                          .read(dashboardControllerProvider.notifier)
                          .switchTab(newTab);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isEmotional) ...[
                          EmotionalTrendChart(
                            data: state.history.emotionalSummary,
                          ),
                        ] else ...[
                          Card(
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.accessibility_new_rounded,
                                        color: Color(0xFF00796B),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mapa Corporal 2D (Últimos 14 Dias)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AnatomicalBodyMap(
                                    physicalSummary:
                                        state.history.physicalSummary,
                                    onRegionSelected: (key) {
                                      ref
                                          .read(
                                              dashboardControllerProvider.notifier)
                                          .selectRegion(key);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (recurrences.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Alertas de Recorrência Crítica',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...recurrences.map(
                            (r) => CriticalRecurrenceCard(item: r),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEmotional
                                  ? 'Registros Emocionais Recentes'
                                  : 'Registros Físicos Recentes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RetrospectiveListView(
                          entries: state.history.logs,
                          verticalFilter:
                              isEmotional ? 'emotional' : 'physical',
                          onDeleteEntry: (id) => ref
                              .read(dashboardControllerProvider.notifier)
                              .deleteHistoryEntry(id),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Histórico & Tendências',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).refreshHistory(),
          ),
        ],
      ),
      body: content,
    );
  }
}

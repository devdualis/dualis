import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../emergency/domain/red_flag_evaluator.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../../triage/presentation/widgets/off_topic_narrative_confirmation_bottom_sheet.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';
import '../widgets/admob_banner_container.dart';
import '../widgets/dual_axis_trigger_card.dart';
import '../widgets/wellness_confirmation_dialog.dart';
import '../../../sync/presentation/widgets/offline_indicator_banner.dart';
import '../../../sync/presentation/controllers/sync_outbox_worker.dart';
import '../../../settings/presentation/widgets/avatar_selector_sheet.dart';
import '../widgets/dualis_bottom_nav_bar.dart';
import '../widgets/today_triage_result_tab.dart';
import '../../../dashboard/presentation/screens/historical_dashboard_screen.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isResolvingNavigation = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authControllerProvider);
      if (authState.user == null) {
        await ref.read(authControllerProvider.notifier).restoreSession();
      }
      ref.read(triggerCheckInProvider.notifier).checkAndResetIfNewDay();
      ref.read(triggerCheckInProvider.notifier).loadTodayCheckIn();
      ref.read(triageOutcomeProvider.notifier).loadTodayOutcome();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if ((prev == null || !prev.isAuthenticated) && next.isAuthenticated) {
        ref.read(triggerCheckInProvider.notifier).loadTodayCheckIn();
      }
    });

    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Paciente';
    final userEmail = (user?.email != null && user!.email.isNotEmpty) ? user.email : 'Sessão ativa';
    ref.watch(syncOutboxWorkerProvider);

    final triggerState = ref.watch(triggerCheckInProvider);

    Widget appBarTitle;
    List<Widget> appBarActions = [];

    if (_currentTabIndex == 0) {
      appBarTitle = const DualisLogo(
        variant: DualisLogoVariant.emblemOnly,
        emblemSize: 28,
        withEmblemContainer: false,
      );
      appBarActions = [
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    } else if (_currentTabIndex == 1) {
      appBarTitle = Text(
        'Resultado do Dia',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      );
      appBarActions = [
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    } else {
      appBarTitle = Text(
        'Histórico & Tendências',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      );
      appBarActions = [
        _AppBarIconButton(
          key: const Key('home_refresh_history_button'),
          icon: Icons.refresh_rounded,
          color: AppColors.clinicalTealDark,
          tooltip: 'Atualizar',
          onTap: () => ref.read(dashboardControllerProvider.notifier).refreshHistory(),
        ),
        const SizedBox(width: 4),
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: _currentTabIndex != 0,
        titleSpacing: 16,
        title: appBarTitle,
        actions: appBarActions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicatorBanner(),
            Expanded(
              child: _buildCurrentTab(
                context,
                user,
                userName,
                userEmail,
                triggerState,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DualisBottomNavBar(
        currentIndex: _currentTabIndex,
        hasCompletedToday: triggerState.isCompletedToday,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
      ),
    );
  }

  Widget _buildCurrentTab(
    BuildContext context,
    dynamic user,
    String userName,
    String userEmail,
    TriggerCheckInState triggerState,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeTab(context, user, userName, userEmail, triggerState);
      case 1:
        return TodayTriageResultTab(
          onGoToCheckIn: () => setState(() => _currentTabIndex = 0),
        );
      case 2:
        return const HistoricalDashboardScreen(isEmbedded: true);
      default:
        return _buildHomeTab(context, user, userName, userEmail, triggerState);
    }
  }

  Widget _buildHomeTab(
    BuildContext context,
    dynamic user,
    String userName,
    String userEmail,
    TriggerCheckInState triggerState,
  ) {
    return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              GestureDetector(
                key: const Key('home_profile_card'),
                onTap: () => context.push(RoutePaths.settings),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.clinicalTeal, AppColors.softIndigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softIndigo.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            picture: user?.picture,
                            fallbackInitial: userName,
                            radius: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, $userName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prontuário Ativo & Protegido (LGPD Art. 11)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 24),

              const DualAxisTriggerCard(),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final triggerState = ref.watch(triggerCheckInProvider);
                  final isReady = triggerState.isReadyToSubmit;

                  String buttonText;
                  if (!isReady) {
                    buttonText = 'Selecione os Dois Eixos';
                  } else if (triggerState.isCompletedToday && !triggerState.isModifiedAfterCompletion) {
                    buttonText = 'Check-in de Hoje Concluído';
                  } else if (triggerState.isCompletedToday && triggerState.isModifiedAfterCompletion) {
                    buttonText = 'Atualizar Check-in de Hoje';
                  } else {
                    buttonText = 'Confirmar Check-in';
                  }

                  return DualisPrimaryButton(
                    key: const Key('startTriageButton'),
                    text: buttonText,
                    isLoading: _isResolvingNavigation,
                    onPressed: isReady && !_isResolvingNavigation
                        ? () async {
                            // If already completed today and nothing changed, do nothing.
                            if (triggerState.isCompletedToday &&
                                !triggerState.isModifiedAfterCompletion) {
                              return;
                            }

                            final narrative = triggerState.naturalLanguageText.trim();
                            if (narrative.isNotEmpty) {
                              final emergency = RedFlagEvaluator.evaluateText(narrative);
                              if (emergency != null) {
                                if (context.mounted) {
                                  ref
                                      .read(emergencyControllerProvider.notifier)
                                      .triggerEmergency(context, emergency);
                                }
                                return;
                              }

                              // Only let free text steer routing when it's new this
                              // session — editing an already-completed check-in must
                              // not resurrect a stale, previously-submitted description.
                              final useTextDrivenNav = !triggerState.isCompletedToday ||
                                  triggerState.textTouched;
                              if (useTextDrivenNav) {
                                setState(() => _isResolvingNavigation = true);
                                final navArgs = await ref
                                    .read(triggerCheckInProvider.notifier)
                                    .resolveTextDrivenNavigation();
                                if (mounted) {
                                  setState(() => _isResolvingNavigation = false);
                                }
                                if (navArgs != null) {
                                  if (navArgs.isOffTopic) {
                                    if (!context.mounted) return;
                                    final shouldContinue =
                                        await OffTopicNarrativeConfirmationBottomSheet.show(
                                      context,
                                    );
                                    if (shouldContinue != true) return;
                                  }
                                  if (context.mounted) {
                                    context.push(RoutePaths.triage, extra: navArgs);
                                  }
                                  return;
                                }
                                // Classification failed (offline/error) — fall through
                                // to the axis-only routing below so the user isn't stuck.
                              }
                            }

                            if (!context.mounted) return;
                            final outcome = triggerState.routingOutcome;
                            switch (outcome) {
                              case RoutingOutcome.wellnessConfirmation:
                                WellnessConfirmationDialog.show(
                                  context,
                                  onDismiss: () {
                                    ref.read(triggerCheckInProvider.notifier).markCompletedToday();
                                  },
                                );
                                break;
                              case RoutingOutcome.psicoEmocionalOnly:
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageNavigationArgs(
                                    initialVertical: TriageVertical.psicoEmocional,
                                    isDual: false,
                                    naturalLanguageText: triggerState.naturalLanguageText,
                                  ),
                                );
                                break;
                              case RoutingOutcome.fisicaOnly:
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageNavigationArgs(
                                    initialVertical: TriageVertical.fisica,
                                    isDual: false,
                                    naturalLanguageText: triggerState.naturalLanguageText,
                                  ),
                                );
                                break;
                              case RoutingOutcome.dualOrganicPrimacy:
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageNavigationArgs(
                                    initialVertical: TriageVertical.fisica,
                                    isDual: true,
                                    naturalLanguageText: triggerState.naturalLanguageText,
                                  ),
                                );
                                break;
                              case RoutingOutcome.none:
                                break;
                            }
                          }
                        : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              const AdMobBannerContainer(),
              const SizedBox(height: 16),
            ],
          ),
        );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

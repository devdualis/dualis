import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';
import '../widgets/admob_banner_container.dart';
import '../widgets/dual_axis_trigger_card.dart';
import '../widgets/wellness_confirmation_dialog.dart';
import '../../../sync/presentation/widgets/offline_indicator_banner.dart';
import '../../../sync/presentation/controllers/sync_outbox_worker.dart';
import '../../../settings/presentation/widgets/avatar_selector_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      if (authState.user == null) {
        ref.read(authControllerProvider.notifier).restoreSession();
      }
      ref.read(triggerCheckInProvider.notifier).checkAndResetIfNewDay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Paciente';
    final userEmail = (user?.email != null && user!.email.isNotEmpty) ? user.email : 'Sessão ativa';
    ref.watch(syncOutboxWorkerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 16,
        title: const DualisLogo(
          variant: DualisLogoVariant.emblemOnly,
          emblemSize: 28,
          withEmblemContainer: false,
        ),
        actions: [
          _AppBarIconButton(
            key: const Key('home_settings_button'),
            icon: Icons.settings_outlined,
            color: AppColors.clinicalTealDark,
            tooltip: 'Configurações',
            onTap: () => context.push(RoutePaths.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicatorBanner(),
            Expanded(
              child: SingleChildScrollView(
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
                    onPressed: isReady
                        ? () {
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

              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.softIndigo.withValues(alpha: 0.2)),
                ),
                child: InkWell(
                  key: const Key('home_history_card'),
                  onTap: () => context.push(RoutePaths.history),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.softIndigo.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: AppColors.softIndigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Histórico & Mapa Corporal 2D',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tendências de 7 dias e mapa de calor de 14 dias',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ],
  ),
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

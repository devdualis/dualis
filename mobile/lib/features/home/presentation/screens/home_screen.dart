import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../../../shared/widgets/language_picker_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../triage/domain/triage_vertical.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';
import '../widgets/admob_banner_container.dart';
import '../widgets/dual_axis_trigger_card.dart';
import '../widgets/wellness_confirmation_dialog.dart';
import '../../../sync/presentation/widgets/offline_indicator_banner.dart';
import '../../../sync/presentation/controllers/sync_outbox_worker.dart';

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
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sair da Conta',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente encerrar sua sessão? Seus dados clínicos permanecem seguros e criptografados.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sair',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(RoutePaths.onboarding);
      }
    }
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
        title: const DualisLogo(
          variant: DualisLogoVariant.horizontal,
          emblemSize: 32,
          fontSize: 18,
        ),
        actions: [
          IconButton(
            key: const Key('home_privacy_button'),
            icon: const Icon(Icons.shield_outlined, color: AppColors.clinicalTeal),
            tooltip: 'Privacidade & Dados (LGPD)',
            onPressed: () => context.push(RoutePaths.privacyCenter),
          ),
          IconButton(
            key: const Key('home_history_button'),
            icon: const Icon(Icons.analytics_outlined, color: AppColors.softIndigo),
            tooltip: 'Histórico & Tendências',
            onPressed: () => context.push(RoutePaths.history),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguagePickerButton(),
          ),
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
                    // Welcome Header
              Container(
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
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
              const SizedBox(height: 24),

              // Dual-Axis Mandatory Trigger Check-in Card (RF-001 / TRG-01)
              const DualAxisTriggerCard(),
              const SizedBox(height: 16),

              // Action CTA: Confirmar Check-in com Roteamento Clínico
              Consumer(
                builder: (context, ref, child) {
                  final triggerState = ref.watch(triggerCheckInProvider);
                  final isReady = triggerState.isReadyToSubmit;

                  return DualisPrimaryButton(
                    key: const Key('startTriageButton'),
                    text: isReady ? 'Confirmar Check-in' : 'Selecione os Dois Eixos',
                    onPressed: isReady
                        ? () {
                            final outcome = triggerState.routingOutcome;
                            switch (outcome) {
                              case RoutingOutcome.wellnessConfirmation:
                                WellnessConfirmationDialog.show(
                                  context,
                                  onDismiss: () {
                                    ref.read(triggerCheckInProvider.notifier).reset();
                                  },
                                );
                                break;
                              case RoutingOutcome.psicoEmocionalOnly:
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageVertical.psicoEmocional,
                                );
                                break;
                              case RoutingOutcome.fisicaOnly:
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageVertical.fisica,
                                );
                                break;
                              case RoutingOutcome.dualOrganicPrimacy:
                                // Organic Primacy: somatic/physical evaluation first
                                context.push(
                                  RoutePaths.triage,
                                  extra: TriageVertical.fisica,
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

              // Privacy-safe Local Partner AdMob Banner (RF-009 / AD-01)
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
              const SizedBox(height: 16),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.clinicalTeal.withValues(alpha: 0.2)),
                ),
                child: InkWell(
                  key: const Key('home_privacy_card'),
                  onTap: () => context.push(RoutePaths.privacyCenter),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: AppColors.clinicalTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Central de Privacidade & LGPD',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Exportação de dados e exclusão permanente',
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  key: const Key('logoutButton'),
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: AppColors.emergencyCrimson, size: 20),
                  label: Text(
                    'Sair da Conta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emergencyCrimson,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.emergencyCrimson),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

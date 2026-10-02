import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../shared/widgets/dualis_logo.dart';
import '../../../shared/widgets/dualis_primary_button.dart';

class NotFoundScreen extends ConsumerWidget {
  final String? uri;

  const NotFoundScreen({
    super.key,
    this.uri,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DualisLogo(
                    variant: DualisLogoVariant.horizontal,
                    width: 160,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.clinicalTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.clinicalTeal.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: 44,
                        color: AppColors.clinicalTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.outlineLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ERRO 404',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softIndigo,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Página Não Encontrada',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A página ou recurso clínico que você tentou acessar não existe, foi movido ou o link expirou.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  if (uri != null && uri!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        uri!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  DualisPrimaryButton(
                    key: const Key('not_found_home_button'),
                    text: isAuthenticated ? 'Voltar para o Painel' : 'Ir para o Início',
                    icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      if (isAuthenticated) {
                        context.go(RoutePaths.home);
                      } else {
                        context.go(RoutePaths.onboarding);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(isAuthenticated ? RoutePaths.home : RoutePaths.onboarding);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Voltar à tela anterior',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.softIndigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/dualis_logo.dart';
import '../../../shared/widgets/dualis_primary_button.dart';
import '../../../shared/widgets/duotone_icon_tile.dart';

class NotFoundScreen extends ConsumerWidget {
  final String? uri;

  const NotFoundScreen({
    super.key,
    this.uri,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authControllerProvider).isAuthenticated;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
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
                  const DuotoneIconTile(
                    size: 88,
                    radius: 28,
                    child: Icon(
                      Icons.travel_explore_rounded,
                      size: 44,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.dualisNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.notFoundErrorCode,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softIndigo,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.notFoundTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.notFoundBody,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
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
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassEdge),
                      ),
                      child: Text(
                        uri!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  DualisPrimaryButton(
                    key: const Key('not_found_home_button'),
                    text: isAuthenticated ? l10n.notFoundBackToDashboard : l10n.notFoundGoHome,
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
                      l10n.notFoundGoBack,
                      style: GoogleFonts.inter(
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

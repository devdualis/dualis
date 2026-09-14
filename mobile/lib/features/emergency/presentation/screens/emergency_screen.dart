import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_context.dart';
import '../../services/telephony_service.dart';
import '../controllers/emergency_controller.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_badge.dart';
import '../widgets/emergency_exit_confirmation_dialog.dart';
import '../widgets/emergency_instructions_card.dart';
import '../widgets/telephony_fallback_dialog.dart';

/// Screen 8: Emergency Risk Alert Screen (RF-006).
///
/// Full-screen high-contrast clinical emergency interface rendered upon detection
/// of red-flag symptoms. Locked against accidental dismissal via [PopScope].
class EmergencyScreen extends ConsumerWidget {
  final EmergencyContext emergencyContext;

  const EmergencyScreen({
    super.key,
    required this.emergencyContext,
  });

  Future<void> _handlePopAttempt(BuildContext context, WidgetRef ref) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const EmergencyExitConfirmationDialog(),
    );

    if (shouldExit == true && context.mounted) {
      ref.read(emergencyControllerProvider.notifier).recordExitConfirmed(context);
    }
  }

  Future<void> _dialOrFallback({
    required BuildContext context,
    required TelephonyService telephonyService,
    required String number,
    required String serviceName,
  }) async {
    final launched = await telephonyService.callNumber(number);
    if (!launched && context.mounted) {
      showDialog(
        context: context,
        builder: (_) => TelephonyFallbackDialog(
          phoneNumber: number,
          serviceName: serviceName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final telephonyService = ref.watch(telephonyServiceProvider);
    final isEmotional = emergencyContext.isEmotional;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePopAttempt(context, ref);
      },
      child: Scaffold(
        backgroundColor: AppColors.emergencyCrimson,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top alert icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Badge
                Center(
                  child: EmergencyBadge(category: emergencyContext.category),
                ),
                const SizedBox(height: 16),

                // Emergency Title
                Text(
                  loc.emergencyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Emergency Subtitle
                Text(
                  loc.emergencySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Clinical Instructions Card
                EmergencyInstructionsCard(isEmotional: isEmotional),
                const SizedBox(height: 24),

                // Primary Dialer Button (56px)
                EmergencyActionButton(
                  label: isEmotional ? loc.emergencyCallCvv : loc.emergencyCallSamu,
                  icon: Icons.phone,
                  isPrimary: true,
                  onPressed: () => _dialOrFallback(
                    context: context,
                    telephonyService: telephonyService,
                    number: isEmotional ? '188' : '192',
                    serviceName: isEmotional ? 'CVV' : 'SAMU',
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Dialer Button (56px)
                EmergencyActionButton(
                  label: isEmotional ? loc.emergencyCallSamu : loc.emergencyCallBombeiros,
                  icon: Icons.phone_in_talk,
                  isOutlined: true,
                  onPressed: () => _dialOrFallback(
                    context: context,
                    telephonyService: telephonyService,
                    number: isEmotional ? '192' : '193',
                    serviceName: isEmotional ? 'SAMU' : 'Bombeiros',
                  ),
                ),
                const SizedBox(height: 12),

                // Maps Emergency Room Locator Button
                EmergencyActionButton(
                  label: loc.emergencyFindHospital,
                  icon: Icons.local_hospital,
                  isOutlined: true,
                  onPressed: () async {
                    await telephonyService.openNearestEmergencyRoom();
                  },
                ),
                const SizedBox(height: 16),

                // Dispatcher Advice
                Text(
                  loc.emergencyDispatcherHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Exit Screen Text Button
                Center(
                  child: TextButton(
                    onPressed: () => _handlePopAttempt(context, ref),
                    child: Text(
                      loc.emergencyExitButton,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

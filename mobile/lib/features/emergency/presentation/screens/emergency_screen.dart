import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_context.dart';
import '../../services/emergency_audit_service.dart';
import '../../services/telephony_service.dart';
import '../controllers/emergency_controller.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_badge.dart';
import '../widgets/emergency_exit_confirmation_dialog.dart';
import '../widgets/emergency_instructions_card.dart';
import '../widgets/telephony_fallback_dialog.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  final EmergencyContext emergencyContext;

  const EmergencyScreen({
    super.key,
    required this.emergencyContext,
  });

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(emergencyControllerProvider.notifier)
          .setEmergency(widget.emergencyContext);
    });
  }

  Future<void> _handlePopAttempt(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const EmergencyExitConfirmationDialog(),
    );

    if (shouldExit == true && context.mounted) {
      ref.read(emergencyAuditServiceProvider).reportEventFireAndForget(
            widget.emergencyContext,
            actionTaken: 'DISMISSED_CONFIRMED',
          );
      await ref.read(emergencyControllerProvider.notifier).recordExitConfirmed(context);
    }
  }

  Future<void> _dialOrFallback({
    required BuildContext context,
    required TelephonyService telephonyService,
    required String number,
    required String serviceName,
  }) async {
    ref.read(emergencyAuditServiceProvider).reportEventFireAndForget(
          widget.emergencyContext,
          actionTaken: 'DIALED_$number',
        );
    final emergencyWithLevel5 = widget.emergencyContext.copyWith(severityLevel: 5);
    ref
        .read(emergencyControllerProvider.notifier)
        .persistEmergencyTriage(emergencyWithLevel5);

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
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final telephonyService = ref.watch(telephonyServiceProvider);
    final isEmotional = widget.emergencyContext.isEmotional;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePopAttempt(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.emergencyCrimson,
        appBar: AppBar(
          backgroundColor: AppColors.emergencyCrimson,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              key: const Key('emergency_close_button'),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              tooltip: loc.emergencyExitButton,
              onPressed: () => _handlePopAttempt(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Center(
                  child: EmergencyBadge(category: widget.emergencyContext.category),
                ),
                const SizedBox(height: 16),
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
                EmergencyInstructionsCard(isEmotional: isEmotional),
                const SizedBox(height: 24),
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
                EmergencyActionButton(
                  label: loc.emergencyFindHospital,
                  icon: Icons.local_hospital,
                  isOutlined: true,
                  onPressed: () async {
                    ref.read(emergencyAuditServiceProvider).reportEventFireAndForget(
                          widget.emergencyContext,
                          actionTaken: 'OPENED_MAPS',
                        );
                    await telephonyService.openNearestEmergencyRoom();
                  },
                ),
                const SizedBox(height: 16),
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
                Center(
                  child: TextButton(
                    onPressed: () => _handlePopAttempt(context),
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

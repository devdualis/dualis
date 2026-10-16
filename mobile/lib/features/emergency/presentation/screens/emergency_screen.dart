import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/safety/emergency_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/emergency_audit_service.dart';
import '../../services/telephony_service.dart';
import '../help_line_labels.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_warning_signs_card.dart';
import '../widgets/telephony_fallback_dialog.dart';

/// Static help resources screen: identical for every user, works offline and
/// can always be closed. Numbers come from the device region.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  /// Opens the help resources screen from anywhere under the app router.
  static void open(BuildContext context) => context.push(RoutePaths.emergency);

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(emergencyAuditServiceProvider)
        .reportFireAndForget(SafetyEventAction.openedResources);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  Future<void> _call(HelpLine line, String serviceName) async {
    ref
        .read(emergencyAuditServiceProvider)
        .reportFireAndForget(SafetyEventAction.callStarted, channel: line.channel);

    final launched = await ref.read(telephonyServiceProvider).callNumber(line.number);
    if (!launched && mounted) {
      showDialog(
        context: context,
        builder: (_) => TelephonyFallbackDialog(
          phoneNumber: line.number,
          serviceName: serviceName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lines = ref.watch(helpLinesProvider);
    final emergencyNumber = lines.emergency.number;

    return Scaffold(
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
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
            tooltip: loc.safetyClose,
            onPressed: _close,
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
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 40),
                ),
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
              for (final (index, line) in lines.all.indexed) ...[
                if (index > 0) const SizedBox(height: 12),
                Builder(builder: (context) {
                  final name = helpLineName(loc, line);
                  return EmergencyActionButton(
                    key: Key('emergency_call_${line.dialable}'),
                    label: loc.safetyCallLine(name, line.number),
                    icon: index == 0 ? Icons.phone : Icons.phone_in_talk,
                    isPrimary: index == 0,
                    isOutlined: index != 0,
                    onPressed: () => _call(line, name),
                  );
                }),
              ],
              if (lines.isFallback) ...[
                const SizedBox(height: 10),
                Text(
                  loc.safetyLocalNumberHint(emergencyNumber),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              EmergencyActionButton(
                label: loc.emergencyFindHospital,
                icon: Icons.local_hospital,
                isOutlined: true,
                onPressed: () => ref
                    .read(telephonyServiceProvider)
                    .openNearestEmergencyRoom(loc.emergencyMapsQuery),
              ),
              const SizedBox(height: 16),
              Text(
                loc.emergencyDispatcherHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              EmergencyWarningSignsCard(emergencyNumber: emergencyNumber),
              const SizedBox(height: 16),
              Container(
                key: const Key('emergency_crisis_card'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  crisisResourcesText(loc, lines),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  key: const Key('emergency_close_text_button'),
                  onPressed: _close,
                  child: Text(
                    loc.safetyClose,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

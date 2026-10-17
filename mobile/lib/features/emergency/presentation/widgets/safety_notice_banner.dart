import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/safety/emergency_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/red_flag_evaluator.dart';
import '../help_line_labels.dart';
import '../screens/emergency_screen.dart';

/// Shows the generic, non-blocking safety notice as a [MaterialBanner] at the
/// top of the current screen (pushes content down, never covers it).
///
/// The text depends only on [kind] and the device region, never on what the
/// user logged, so every trigger of the same kind shows exactly the same card.
class SafetyNotice {
  const SafetyNotice._();

  static ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>? _active;

  static void show(BuildContext context, SafetyNoticeKind kind) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    hide();
    final controller = messenger.showMaterialBanner(_build(kind));
    _active = controller;
    controller.closed.then((_) {
      if (identical(_active, controller)) _active = null;
    });
  }

  /// Hides the notice if it is still showing. Safe to call any time.
  static void hide() {
    final active = _active;
    _active = null;
    try {
      active?.close();
    } catch (_) {
      // Messenger already gone.
    }
  }

  static MaterialBanner _build(SafetyNoticeKind kind) {
    return MaterialBanner(
      key: const Key('safety_notice_banner'),
      backgroundColor: AppColors.emergencySurfaceRed,
      leading: const Icon(Icons.info_outline_rounded, color: AppColors.emergencyDarkRed),
      content: _SafetyNoticeText(kind: kind),
      actions: const [_CloseAction(), _OpenResourcesAction()],
    );
  }
}

class _SafetyNoticeText extends ConsumerWidget {
  final SafetyNoticeKind kind;
  const _SafetyNoticeText({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lines = ref.watch(helpLinesProvider);
    final text = switch (kind) {
      SafetyNoticeKind.general => loc.safetyNoticeGeneral(lines.emergency.number),
      SafetyNoticeKind.selfHarm => crisisResourcesText(loc, lines),
    };
    return Text(
      text,
      key: const Key('safety_notice_text'),
      style: const TextStyle(
        color: AppColors.emergencyTextDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class _CloseAction extends StatelessWidget {
  const _CloseAction();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('safety_notice_close'),
      onPressed: SafetyNotice.hide,
      child: Text(
        AppLocalizations.of(context).safetyClose,
        style: const TextStyle(color: AppColors.emergencyTextDark),
      ),
    );
  }
}

class _OpenResourcesAction extends StatelessWidget {
  const _OpenResourcesAction();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('safety_notice_open_resources'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emergencyCrimson,
        foregroundColor: Colors.white,
      ),
      onPressed: () => EmergencyScreen.open(context),
      child: Text(AppLocalizations.of(context).safetyNoticeOpenResources),
    );
  }
}

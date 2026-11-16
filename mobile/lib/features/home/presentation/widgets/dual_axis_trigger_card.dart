import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/premium_gradient_icon.dart';
import '../../../journal/presentation/controllers/journal_flow_state.dart';
import '../../../journal/presentation/screens/journal_flow_screen.dart';
import '../../domain/axis_intensity_resolver.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';

class DualAxisTriggerCard extends ConsumerWidget {
  const DualAxisTriggerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(triggerCheckInProvider);
    final notifier = ref.read(triggerCheckInProvider.notifier);
    final premium = ref.watch(premiumProfilesEnabledProvider);

    final isEmotionalCompleted = state.isEmotionalCompleted;
    final isPhysicalCompleted = state.isPhysicalCompleted;

    final emotionalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.emotional,
      state: state,
    );

    final physicalIntensity = AxisIntensityResolver.resolveDisplayIntensity(
      axis: CheckInAxis.physical,
      state: state,
    );

    final viewOnly = activeProfileIsViewOnly(ref);
    // On a shared profile each area follows its journal category: unreadable
    // shows the not-shared text, readable but not writable hides the starts.
    // Help and the emergency path are never gated here.
    final canReadEmotional =
        activeProfileCanRead(ref, ShareCategory.emotionalJournal);
    final canReadPhysical =
        activeProfileCanRead(ref, ShareCategory.physicalJournal);
    final emotionalViewOnly =
        viewOnly || !activeProfileCanWrite(ref, ShareCategory.emotionalJournal);
    final physicalViewOnly =
        viewOnly || !activeProfileCanWrite(ref, ShareCategory.physicalJournal);

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget tileFor({
      required String areaKey,
      required bool canRead,
      required String title,
      required String subtitle,
      required IconData icon,
      required Color accentColor,
      required bool isCompleted,
      required TriggerStatus? status,
      required int? intensity,
      required String buttonKey,
      required String completedCardKey,
      required bool tileViewOnly,
      required JournalArea area,
    }) {
      final tint = Color.lerp(accentColor, Colors.white, 0.65)!;
      final iconWidget = premium
          ? PremiumGradientIcon(icon: Icon(icon, color: tint, size: 22))
          : Icon(icon, color: tint, size: 22);
      if (!canRead) {
        return _AxisTile(
          key: ValueKey('home-area-not-shared-$areaKey'),
          title: title,
          semanticsLabel: title,
          icon: Icon(icon, color: tint, size: 22),
          badge: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Colors.white70,
          ),
          note: AppLocalizations.of(context).profileCategoryNotSharedTitle,
          reduceMotion: reduceMotion,
        );
      }
      if (isCompleted) {
        final tier = intensity != null
            ? ClinicalIntensityTier.fromScore(intensity)
            : (status?.tier ?? ClinicalIntensityTier.none);
        return _AxisTile(
          key: Key(completedCardKey),
          title: title,
          semanticsLabel: '$title, ${tier.localizedLabel(context)}',
          icon: iconWidget,
          badge: const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.dualisSymbolGreen,
          ),
          fill: tier.color.withValues(alpha: 0.2),
          edge: tier.color.withValues(alpha: 0.6),
          reduceMotion: reduceMotion,
        );
      }
      return _AxisTile(
        key: tileViewOnly ? null : Key(buttonKey),
        title: title,
        semanticsLabel: tileViewOnly ? title : 'Iniciar $title',
        semanticsHint: subtitle,
        icon: iconWidget,
        onTap: tileViewOnly
            ? null
            : () {
                context.push(
                  RoutePaths.journal,
                  extra: JournalFlowArgs(initialArea: area),
                );
              },
        reduceMotion: reduceMotion,
      );
    }

    final emotionalTile = tileFor(
      areaKey: 'emotional',
      canRead: canReadEmotional,
      title: 'Psicoemocional',
      subtitle: 'Humor, ansiedade, estresse e clareza mental',
      icon: Icons.psychology_rounded,
      accentColor: AppColors.dualisSymbolGreen,
      isCompleted: isEmotionalCompleted,
      status: state.emotionalStatus,
      intensity: emotionalIntensity,
      buttonKey: 'start_psicoemocional_triage_button',
      completedCardKey: 'psicoemocional_completed_card',
      tileViewOnly: emotionalViewOnly,
      area: JournalArea.emotional,
    );
    final physicalTile = tileFor(
      areaKey: 'physical',
      canRead: canReadPhysical,
      title: 'Físico',
      subtitle: 'Dores corporais, desconforto somático ou fadiga',
      icon: Icons.accessibility_new_rounded,
      accentColor: AppColors.dualisSymbolBlue,
      isCompleted: isPhysicalCompleted,
      status: state.physicalStatus,
      intensity: physicalIntensity,
      buttonKey: 'start_fisica_triage_button',
      completedCardKey: 'fisica_completed_card',
      tileViewOnly: physicalViewOnly,
      area: JournalArea.physical,
    );

    final details = <Widget>[
      if (canReadEmotional && isEmotionalCompleted)
        _CompletedDetails(
          icon: Icons.psychology_rounded,
          summary: state.emotionalSummary,
          // Only text the user typed in that stage's triage; never the
          // AI's mapped lay term.
          narrative: state.emotionalNarrative,
          retakeKey: 'retake_psicoemocional_button',
          showRetake: !emotionalViewOnly,
          onRetake: () {
            notifier.prepareForUpdate();
            context.push(
              RoutePaths.journal,
              extra: const JournalFlowArgs(initialArea: JournalArea.emotional),
            );
          },
        ),
      if (canReadPhysical && isPhysicalCompleted)
        _CompletedDetails(
          icon: Icons.accessibility_new_rounded,
          summary: state.physicalSummary,
          narrative: state.physicalNarrative,
          retakeKey: 'retake_fisica_button',
          showRetake: !physicalViewOnly,
          onRetake: () {
            notifier.prepareForUpdate();
            context.push(
              RoutePaths.journal,
              extra: const JournalFlowArgs(initialArea: JournalArea.physical),
            );
          },
        ),
    ];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.gradientNavy,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.softIndigoDark.withValues(alpha: 0.7),
            blurRadius: 40,
            offset: const Offset(0, 24),
            spreadRadius: -22,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -6,
            width: 170,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  AppAssets.logoSymbol,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Check-in Diário em 2 Etapas'.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.dualisSymbolCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Como você está hoje?',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    height: 1.15,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: emotionalTile),
                      const SizedBox(width: 12),
                      Expanded(child: physicalTile),
                    ],
                  ),
                ),
                if (viewOnly) const ActiveProfileReadOnlyNote(),
                for (final d in details) ...[
                  const SizedBox(height: 14),
                  d,
                ],
                if (state.conditionsSummary != null &&
                    state.conditionsSummary!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ConditionsTodaySummary(summary: state.conditionsSummary!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One axis tile on the navy card: translucent rounded square holding the axis
/// icon, the label below, an optional corner badge (check or lock). The whole
/// tile is the tap target when [onTap] is set, with scale feedback on
/// pointer-down (instant when animations are disabled).
class _AxisTile extends StatefulWidget {
  const _AxisTile({
    super.key,
    required this.title,
    required this.semanticsLabel,
    required this.icon,
    required this.reduceMotion,
    this.semanticsHint,
    this.badge,
    this.note,
    this.onTap,
    this.fill,
    this.edge,
  });

  final String title;
  final String semanticsLabel;
  final String? semanticsHint;
  final Widget icon;
  final Widget? badge;
  final String? note;
  final VoidCallback? onTap;
  final Color? fill;
  final Color? edge;
  final bool reduceMotion;

  @override
  State<_AxisTile> createState() => _AxisTileState();
}

class _AxisTileState extends State<_AxisTile> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.fill ??
            Colors.white.withValues(alpha: _pressed ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.edge ?? Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.icon,
              ),
              const SizedBox(height: 22),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (widget.note != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.note!,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          if (widget.badge != null)
            Positioned(top: 0, right: 0, child: widget.badge!),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      excludeSemantics: widget.semanticsHint != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: tile,
        ),
      ),
    );
  }
}

/// Summary, narrative and "Atualizar" action for a finished axis, as compact
/// translucent text under the tiles.
class _CompletedDetails extends StatelessWidget {
  const _CompletedDetails({
    required this.icon,
    required this.summary,
    required this.narrative,
    required this.retakeKey,
    required this.showRetake,
    required this.onRetake,
  });

  final IconData icon;
  final String? summary;
  final String? narrative;
  final String retakeKey;
  final bool showRetake;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary != null && summary!.isNotEmpty;
    final hasNarrative = narrative != null &&
        narrative!.trim().isNotEmpty &&
        int.tryParse(narrative!.trim()) == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSummary)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        if (hasNarrative) ...[
          const SizedBox(height: 6),
          Text(
            '“${narrative!.trim()}”',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
        if (showRetake)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key(retakeKey),
              onPressed: onRetake,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Atualizar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.dualisSymbolCyan,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }
}

/// Today's "Minhas condições" items in the user's own words. Its own small
/// block: conditions never fill the emotional or physical axis.
class _ConditionsTodaySummary extends StatelessWidget {
  final String summary;

  const _ConditionsTodaySummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('conditions_today_summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.jv2ConditionsTitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

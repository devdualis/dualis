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
  const DualAxisTriggerCard({super.key, this.greeting});

  /// Greeting shown as the first title line ("Olá, Ana! Bom dia", or the
  /// dependent's profile text). Omitted: the title is just the question.
  final String? greeting;

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
    final canReadEmotional = activeProfileCanRead(
      ref,
      ShareCategory.emotionalJournal,
    );
    final canReadPhysical = activeProfileCanRead(
      ref,
      ShareCategory.physicalJournal,
    );
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
      final iconWidget =
          premium
              ? PremiumGradientIcon(
                icon: Icon(icon, color: accentColor, size: 36),
              )
              : Icon(icon, color: accentColor, size: 36);
      if (!canRead) {
        return _AxisTile(
          key: ValueKey('home-area-not-shared-$areaKey'),
          title: title,
          semanticsLabel: title,
          accent: AppColors.textSecondaryLight,
          icon: Icon(icon, color: AppColors.textSecondaryLight, size: 36),
          badge: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.textSecondaryLight,
          ),
          note: AppLocalizations.of(context).profileCategoryNotSharedTitle,
          fill: const Color(0xFFF1F5F9),
          edge: AppColors.dualisNavy.withValues(alpha: 0.10),
          reduceMotion: reduceMotion,
        );
      }
      if (isCompleted) {
        final tier =
            intensity != null
                ? ClinicalIntensityTier.fromScore(intensity)
                : (status?.tier ?? ClinicalIntensityTier.none);
        return _AxisTile(
          key: Key(completedCardKey),
          title: title,
          semanticsLabel: '$title, ${tier.localizedLabel(context)}',
          accent: accentColor,
          icon: iconWidget,
          badge: const Icon(
            Icons.check_circle_rounded,
            size: 22,
            color: AppColors.dualisCareGreen,
          ),
          result: _ResultChip(
            label: tier.localizedLabel(context),
            dot: tier.color,
            edge: tier.borderColor,
          ),
          fill: tier.cardBgColor,
          edge: tier.borderColor,
          reduceMotion: reduceMotion,
        );
      }
      return _AxisTile(
        key: tileViewOnly ? null : Key(buttonKey),
        title: title,
        semanticsLabel: tileViewOnly ? title : 'Iniciar $title',
        semanticsHint: subtitle,
        accent: accentColor,
        icon: iconWidget,
        onTap:
            tileViewOnly
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
      accentColor: AppColors.dualisCareGreen,
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
          accent: AppColors.dualisCareGreen,
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
          accent: AppColors.dualisSymbolBlue,
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

    final titleStyle = GoogleFonts.inter(
      fontSize: 24,
      height: 1.15,
      letterSpacing: -0.4,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.dualisNavy.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dualisNavy.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -18,
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
                opacity: 0.07,
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
                  AppLocalizations.of(context).homeCheckinEyebrow.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.clinicalTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Column(
                  key: const Key('home_checkin_title'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (greeting != null && greeting!.isNotEmpty)
                      Text(greeting!, style: titleStyle),
                    Text('Como você está hoje?', style: titleStyle),
                  ],
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
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: AppColors.dualisNavy.withValues(alpha: 0.08),
                  ),
                ],
                for (final d in details) ...[const SizedBox(height: 12), d],
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

/// One axis tile on the light check-in card: accent-tinted icon square, the
/// label below, an optional corner badge (check), and the self-reported
/// result chip (completed) or a short note (not shared). The whole tile is the tap target
/// when [onTap] is set, with scale feedback on pointer-down (instant when
/// animations are disabled).
class _AxisTile extends StatefulWidget {
  const _AxisTile({
    super.key,
    required this.title,
    required this.semanticsLabel,
    required this.accent,
    required this.icon,
    required this.reduceMotion,
    this.semanticsHint,
    this.badge,
    this.note,
    this.result,
    this.onTap,
    this.fill,
    this.edge,
  });

  final String title;
  final String semanticsLabel;
  final String? semanticsHint;
  final Color accent;
  final Widget icon;
  final Widget? badge;
  final String? note;
  final Widget? result;
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
    final accent = widget.accent;
    final startable = widget.onTap != null;
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            widget.fill ??
            (_pressed
                ? Color.lerp(Colors.white, accent, 0.10)!
                : Color.lerp(Colors.white, accent, 0.05)!),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1.5,
          color: widget.edge ?? accent.withValues(alpha: 0.35),
        ),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: widget.icon,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                if (widget.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.note!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
                if (widget.result != null) ...[
                  const SizedBox(height: 10),
                  widget.result!,
                ],
              ],
            ),
          ),
          if (widget.badge != null)
            Positioned(top: 0, right: 0, child: widget.badge!),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: startable,
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      excludeSemantics: widget.semanticsHint != null || widget.result != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration:
              widget.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: tile,
        ),
      ),
    );
  }
}

/// The user's own self-reported intensity for a finished area: white chip,
/// band-coloured dot and edge, dark text so every band stays legible.
class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.dot,
    required this.edge,
  });

  final String label;
  final Color dot;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary, narrative and "Atualizar" action for a finished axis, on a soft
/// panel under the tiles.
class _CompletedDetails extends StatelessWidget {
  const _CompletedDetails({
    required this.icon,
    required this.accent,
    required this.summary,
    required this.narrative,
    required this.retakeKey,
    required this.showRetake,
    required this.onRetake,
  });

  final IconData icon;
  final Color accent;
  final String? summary;
  final String? narrative;
  final String retakeKey;
  final bool showRetake;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary != null && summary!.isNotEmpty;
    final hasNarrative =
        narrative != null &&
        narrative!.trim().isNotEmpty &&
        int.tryParse(narrative!.trim()) == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSummary)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          if (hasNarrative) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '“${narrative!.trim()}”',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondaryLight,
                ),
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
                  foregroundColor: AppColors.clinicalTealDark,
                  backgroundColor: AppColors.iconTileTint,
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
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
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dualisNavy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.jv2ConditionsTitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

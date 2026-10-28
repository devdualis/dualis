import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';

/// White card with a title, shared by the dashboard sections.
class InsightsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const InsightsCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Passado / Presente / Futuro distribution (strategy §9.1). Counts only.
class TimeDistributionBar extends StatelessWidget {
  static const List<Color> colors = [
    Color(0xFF9FB6D6),
    Color(0xFF5C82B8),
    Color(0xFF2B4F86),
  ];

  final Map<String, int> byTime;

  const TimeDistributionBar({super.key, required this.byTime});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = [
      for (final t in JournalLabels.times) byTime[t] ?? 0,
    ];
    final total = counts.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Text(
        l10n.xv2DashNoEmotional,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    return Column(
      key: const Key('time_distribution_bar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < counts.length; i++)
                  if (counts[i] > 0)
                    Expanded(
                      flex: counts[i],
                      child: ColoredBox(color: colors[i]),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (var i = 0; i < counts.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.xv2DashTimeCount(
                      JournalLabels.timeShort(l10n, JournalLabels.times[i])!,
                      counts[i],
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Front and back silhouettes with the five regions the person can mark
/// (strategy §6), shaded by how many days each one was marked. Single hue.
/// The counts list lives in `HistoryBodyMap`.
class JournalBodyMap extends StatelessWidget {
  final Map<String, int> byRegion;

  /// Called with the region tapped on a silhouette, when set.
  final ValueChanged<String>? onRegionTap;

  const JournalBodyMap({super.key, required this.byRegion, this.onRegionTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxCount = byRegion.values.fold<int>(0, (a, b) => b > a ? b : a);
    return Column(
      key: const Key('journal_body_map'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: _Silhouette(
                  side: _Side.front,
                  byRegion: byRegion,
                  maxCount: maxCount,
                  onRegionTap: onRegionTap,
                  caption: l10n.xv2DashFront,
                ),
              ),
              Expanded(
                child: _Silhouette(
                  side: _Side.back,
                  byRegion: byRegion,
                  maxCount: maxCount,
                  onRegionTap: onRegionTap,
                  caption: l10n.xv2DashBack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Light to deep blue by count; grey when never marked.
Color regionShade(int count, int maxCount) {
  if (count <= 0 || maxCount <= 0) return const Color(0xFFE2E8F0);
  final t = 0.3 + 0.7 * (count / maxCount);
  return Color.lerp(const Color(0xFFBFD3EC), const Color(0xFF1F4A85), t)!;
}

enum _Side { front, back }

class _Silhouette extends StatelessWidget {
  final _Side side;
  final Map<String, int> byRegion;
  final int maxCount;
  final String caption;
  final ValueChanged<String>? onRegionTap;

  const _Silhouette({
    required this.side,
    required this.byRegion,
    required this.maxCount,
    required this.caption,
    this.onRegionTap,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = onRegionTap;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              key: Key('journal_body_map_${side.name}'),
              behavior: HitTestBehavior.opaque,
              onTapUp: onTap == null
                  ? null
                  : (details) {
                      final region = _SilhouettePainter.regionAt(
                        side,
                        details.localPosition,
                        constraints.biggest,
                      );
                      if (region != null) onTap(region);
                    },
              child: CustomPaint(
                size: Size.infinite,
                painter: _SilhouettePainter(
                  side: side,
                  shade: (region) =>
                      regionShade(byRegion[region] ?? 0, maxCount),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final _Side side;
  final Color Function(String region) shade;

  _SilhouettePainter({required this.side, required this.shade});

  /// Region shapes for a silhouette of [size]; `null` region = neutral hips.
  static List<(String?, RRect, bool oval)> shapes(_Side side, Size size) {
    final h = size.height;
    final w = h * 0.5;
    final left = (size.width - w) / 2;
    Rect r(double x, double y, double rw, double rh) =>
        Rect.fromLTWH(left + x * w, y * h, rw * w, rh * h);
    final radius = Radius.circular(w * 0.08);
    RRect rr(Rect rect) => RRect.fromRectAndRadius(rect, radius);
    return [
      ('cabeca', RRect.fromRectAndRadius(r(0.36, 0.0, 0.28, 0.14), Radius.zero), true),
      ('cabeca', rr(r(0.44, 0.13, 0.12, 0.05)), false),
      if (side == _Side.front) ...[
        ('peito', rr(r(0.25, 0.18, 0.5, 0.18)), false),
        ('barriga', rr(r(0.27, 0.36, 0.46, 0.16)), false),
      ] else
        ('costas', rr(r(0.25, 0.18, 0.5, 0.34)), false),
      // Hips stay neutral: no region there.
      (null, rr(r(0.27, 0.52, 0.46, 0.06)), false),
      // Arms, legs and hands.
      ('membros', rr(r(0.08, 0.19, 0.14, 0.36)), false),
      ('membros', rr(r(0.78, 0.19, 0.14, 0.36)), false),
      ('membros', rr(r(0.28, 0.59, 0.19, 0.41)), false),
      ('membros', rr(r(0.53, 0.59, 0.19, 0.41)), false),
    ];
  }

  /// Region under [position], with a small margin so thin limbs are easy
  /// to hit.
  static String? regionAt(_Side side, Offset position, Size size) {
    final margin = size.height * 0.02;
    for (final (region, shape, _) in shapes(side, size)) {
      if (region != null && shape.outerRect.inflate(margin).contains(position)) {
        return region;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const neutral = Color(0xFFE2E8F0);
    for (final (region, shape, oval) in shapes(side, size)) {
      final paint = Paint()..color = region == null ? neutral : shade(region);
      oval ? canvas.drawOval(shape.outerRect, paint) : canvas.drawRRect(shape, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) => true;
}

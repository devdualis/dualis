import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/duotone_icon_tile.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/library_catalog.dart';

IconData _categoryIcon(LibraryCategory c) => switch (c) {
  LibraryCategory.emocoes => Icons.sentiment_satisfied_alt_rounded,
  LibraryCategory.estresse => Icons.spa_rounded,
  LibraryCategory.sono => Icons.bedtime_rounded,
  LibraryCategory.corpo => Icons.accessibility_new_rounded,
  LibraryCategory.alimentacao => Icons.restaurant_rounded,
  LibraryCategory.hidratacao => Icons.water_drop_rounded,
  LibraryCategory.relacoes => Icons.groups_rounded,
  LibraryCategory.ajuda => Icons.health_and_safety_rounded,
};

/// General library (strategy §9.3): wellness topics, the same texts in the
/// same order for everyone, each with its real public source. It takes no
/// input on purpose, so it can never be ordered by what someone recorded.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byTopic = libraryByCategory();
    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDepth,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.dualisNavy,
        title: Text(
          l10n.xv2LibTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dualisNavy,
          ),
        ),
        // Space for the global urgent-help button (UrgentHelpOverlay).
        actions: const [SizedBox(width: 56)],
      ),
      body: ListView(
        key: const Key('library_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softIndigoLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.dualisNavy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.xv2LibIntro,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final entry in byTopic.entries)
            if (entry.value.isNotEmpty) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  DuotoneIconTile(
                    size: 32,
                    radius: 10,
                    child: Icon(
                      _categoryIcon(entry.key),
                      size: 18,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key.label(l10n),
                      key: Key('library_category_${entry.key.name}'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final article in entry.value)
                LibraryArticleTile(article: article),
            ],
        ],
      ),
    );
  }
}

class LibraryArticleTile extends StatelessWidget {
  final LibraryArticle article;

  const LibraryArticleTile({super.key, required this.article});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(article.url);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).xv2LibOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = GoogleFonts.inter(
      fontSize: 12,
      color: AppColors.textSecondaryLight,
    );
    return Padding(
      key: Key('library_article_${article.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _open(context),
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DuotoneIconTile(
                  child: Icon(
                    _categoryIcon(article.category),
                    size: 22,
                    color: AppColors.dualisNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title(l10n),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.1,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.summary(l10n),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.xv2LibSource(article.source), style: muted),
                      const SizedBox(height: 2),
                      Text(
                        l10n.xv2LibReadTime(article.readTimeMinutes),
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.iconTileTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    semanticLabel: l10n.xv2LibOpen,
                    color: AppColors.dualisNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/library_catalog.dart';

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimaryLight,
        title: Text(
          l10n.xv2LibTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Space for the global urgent-help button (UrgentHelpOverlay).
        actions: const [SizedBox(width: 56)],
      ),
      body: ListView(
        key: const Key('library_list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.xv2LibIntro,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondaryLight,
            ),
          ),
          for (final entry in byTopic.entries)
            if (entry.value.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                entry.key.label(l10n),
                key: Key('library_category_${entry.key.name}'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
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
    return Card(
      key: Key('library_article_${article.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title(l10n),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                article.summary(l10n),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.xv2LibSource(article.source),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                  ),
                  Text(
                    l10n.xv2LibReadTime(article.readTimeMinutes),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    semanticLabel: l10n.xv2LibOpen,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

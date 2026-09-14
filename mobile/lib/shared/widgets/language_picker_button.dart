import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/locale_provider.dart';

class LanguagePickerButton extends ConsumerWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    String getLanguageLabel(String languageCode) {
      switch (languageCode) {
        case 'pt':
          return 'PT';
        case 'es':
          return 'ES';
        case 'en':
          return 'EN';
        default:
          return languageCode.toUpperCase();
      }
    }

    return PopupMenuButton<Locale>(
      tooltip: 'Select Language',
      initialValue: currentLocale,
      onSelected: (Locale newLocale) {
        ref.read(localeProvider.notifier).setLocale(newLocale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('pt', 'BR'),
          child: Text('🇧🇷  Português (Brasil)'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('es'),
          child: Text('🇪🇸  Español'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Text('🇺🇸  English'),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.softIndigo.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.softIndigo.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 16,
              color: AppColors.softIndigo,
            ),
            const SizedBox(width: 6),
            Text(
              getLanguageLabel(currentLocale.languageCode),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.softIndigo,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.softIndigo,
            ),
          ],
        ),
      ),
    );
  }
}

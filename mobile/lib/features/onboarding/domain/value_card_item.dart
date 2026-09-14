import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ValueCardItem {
  final String titleKey;
  final String bodyKey;
  final Color accentColor;
  final IconData icon;

  const ValueCardItem({
    required this.titleKey,
    required this.bodyKey,
    required this.accentColor,
    this.icon = Icons.health_and_safety_outlined,
  });

  String getTitle(AppLocalizations l10n) {
    switch (titleKey) {
      case 'valueCard1Title':
        return l10n.valueCard1Title;
      case 'valueCard2Title':
        return l10n.valueCard2Title;
      case 'valueCard3Title':
        return l10n.valueCard3Title;
      default:
        return titleKey;
    }
  }

  String getBody(AppLocalizations l10n) {
    switch (bodyKey) {
      case 'valueCard1Body':
        return l10n.valueCard1Body;
      case 'valueCard2Body':
        return l10n.valueCard2Body;
      case 'valueCard3Body':
        return l10n.valueCard3Body;
      default:
        return bodyKey;
    }
  }
}

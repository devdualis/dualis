import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_trigger_category.dart';

/// High-visibility pill container displaying the intercepted emergency category.
class EmergencyBadge extends StatelessWidget {
  final EmergencyTriggerCategory category;

  const EmergencyBadge({
    super.key,
    required this.category,
  });

  String _getCategoryLabel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (category) {
      case EmergencyTriggerCategory.chestPain:
        return loc.emergencyBadgeChestPain;
      case EmergencyTriggerCategory.respiratoryDistress:
      case EmergencyTriggerCategory.anaphylaxisAirway:
        return loc.emergencyBadgeRespiratory;
      case EmergencyTriggerCategory.neurologicalStroke:
        return loc.emergencyBadgeStroke;
      case EmergencyTriggerCategory.thunderclapHeadache:
        return loc.emergencyBadgeHeadache;
      case EmergencyTriggerCategory.suicidalCrisis:
      case EmergencyTriggerCategory.anxiousPanicCollapse:
      case EmergencyTriggerCategory.severePsychosisDelirium:
        return loc.emergencyBadgeEmotional;
      case EmergencyTriggerCategory.massiveHemorrhage:
      case EmergencyTriggerCategory.generalCriticalIntensity:
        return loc.emergencyBadgeGeneral;
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case EmergencyTriggerCategory.chestPain:
        return Icons.favorite;
      case EmergencyTriggerCategory.respiratoryDistress:
      case EmergencyTriggerCategory.anaphylaxisAirway:
        return Icons.air;
      case EmergencyTriggerCategory.neurologicalStroke:
        return Icons.psychology;
      case EmergencyTriggerCategory.thunderclapHeadache:
        return Icons.flash_on;
      case EmergencyTriggerCategory.suicidalCrisis:
      case EmergencyTriggerCategory.anxiousPanicCollapse:
      case EmergencyTriggerCategory.severePsychosisDelirium:
        return Icons.support_agent;
      case EmergencyTriggerCategory.massiveHemorrhage:
      case EmergencyTriggerCategory.generalCriticalIntensity:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _getCategoryLabel(context),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

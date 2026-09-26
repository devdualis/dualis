import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClinicalIntensityTier - Single Source of Truth', () {
    test('tier score mapping adheres to the 4-tier clinical scale', () {
      expect(ClinicalIntensityTier.fromScore(null), ClinicalIntensityTier.none);
      expect(ClinicalIntensityTier.fromScore(-1), ClinicalIntensityTier.none);
      expect(ClinicalIntensityTier.fromScore(0), ClinicalIntensityTier.none);

      expect(ClinicalIntensityTier.fromScore(1), ClinicalIntensityTier.mild);
      expect(ClinicalIntensityTier.fromScore(2), ClinicalIntensityTier.mild);

      expect(ClinicalIntensityTier.fromScore(3), ClinicalIntensityTier.moderate);

      expect(ClinicalIntensityTier.fromScore(4), ClinicalIntensityTier.intense);
      expect(ClinicalIntensityTier.fromScore(5), ClinicalIntensityTier.intense);
      expect(ClinicalIntensityTier.fromScore(10), ClinicalIntensityTier.intense);
    });

    test('fromIntensity is an alias of fromScore', () {
      expect(ClinicalIntensityTier.fromIntensity(0), ClinicalIntensityTier.none);
      expect(ClinicalIntensityTier.fromIntensity(2), ClinicalIntensityTier.mild);
      expect(ClinicalIntensityTier.fromIntensity(3), ClinicalIntensityTier.moderate);
      expect(ClinicalIntensityTier.fromIntensity(5), ClinicalIntensityTier.intense);
    });

    test('canonical labels and score ranges match specification', () {
      expect(ClinicalIntensityTier.none.label, 'Sem dor');
      expect(ClinicalIntensityTier.none.scoreRangeDescription, '0');

      expect(ClinicalIntensityTier.mild.label, 'Leve (1-2)');
      expect(ClinicalIntensityTier.mild.scoreRangeDescription, '1-2');

      expect(ClinicalIntensityTier.moderate.label, 'Moderada (3)');
      expect(ClinicalIntensityTier.moderate.scoreRangeDescription, '3');

      expect(ClinicalIntensityTier.intense.label, 'Intensa (4-5)');
      expect(ClinicalIntensityTier.intense.scoreRangeDescription, '4-5');
    });

    test('exact palette colors match clinical heat map and WCAG contrast standards', () {
      expect(ClinicalIntensityTier.none.color, const Color(0xFFCFD8DC));
      expect(ClinicalIntensityTier.none.textColor, const Color(0xFF37474F));
      expect(ClinicalIntensityTier.none.cardBgColor, const Color(0xFFF5F7F8));
      expect(ClinicalIntensityTier.none.borderColor, const Color(0xFFCFD8DC));

      expect(ClinicalIntensityTier.mild.color, const Color(0xFFFFD54F));
      expect(ClinicalIntensityTier.mild.textColor, const Color(0xFF3E2723));
      expect(ClinicalIntensityTier.mild.cardBgColor, const Color(0xFFFFFDE7));
      expect(ClinicalIntensityTier.mild.borderColor, const Color(0xFFFFE082));

      expect(ClinicalIntensityTier.moderate.color, const Color(0xFFFF8A65));
      expect(ClinicalIntensityTier.moderate.textColor, const Color(0xFFFFFFFF));
      expect(ClinicalIntensityTier.moderate.cardBgColor, const Color(0xFFFBE9E7));
      expect(ClinicalIntensityTier.moderate.borderColor, const Color(0xFFFFAB91));

      expect(ClinicalIntensityTier.intense.color, const Color(0xFFE53935));
      expect(ClinicalIntensityTier.intense.textColor, const Color(0xFFFFFFFF));
      expect(ClinicalIntensityTier.intense.cardBgColor, const Color(0xFFFFEBEE));
      expect(ClinicalIntensityTier.intense.borderColor, const Color(0xFFEF9A9A));
    });

    test('isCritical flag only activates for intense (scores 4-5)', () {
      expect(ClinicalIntensityTier.none.isCritical, isFalse);
      expect(ClinicalIntensityTier.mild.isCritical, isFalse);
      expect(ClinicalIntensityTier.moderate.isCritical, isFalse);
      expect(ClinicalIntensityTier.intense.isCritical, isTrue);
    });

    test('containsScore correctly validates boundaries', () {
      expect(ClinicalIntensityTier.none.containsScore(0), isTrue);
      expect(ClinicalIntensityTier.none.containsScore(1), isFalse);

      expect(ClinicalIntensityTier.mild.containsScore(1), isTrue);
      expect(ClinicalIntensityTier.mild.containsScore(2), isTrue);
      expect(ClinicalIntensityTier.mild.containsScore(3), isFalse);

      expect(ClinicalIntensityTier.moderate.containsScore(3), isTrue);
      expect(ClinicalIntensityTier.moderate.containsScore(4), isFalse);

      expect(ClinicalIntensityTier.intense.containsScore(4), isTrue);
      expect(ClinicalIntensityTier.intense.containsScore(5), isTrue);
      expect(ClinicalIntensityTier.intense.containsScore(3), isFalse);
    });

    test('TriggerStatusTierExtension bridges trigger status to clinical tier', () {
      expect(TriggerStatus.goodNormal.defaultIntensity, 0);
      expect(TriggerStatus.goodNormal.tier, ClinicalIntensityTier.none);

      expect(TriggerStatus.soSo.defaultIntensity, 3);
      expect(TriggerStatus.soSo.tier, ClinicalIntensityTier.moderate);

      expect(TriggerStatus.badSick.defaultIntensity, 4);
      expect(TriggerStatus.badSick.tier, ClinicalIntensityTier.intense);
    });

    test('TriggerCheckInState resolves tiers via Single Source of Truth', () {
      const stateWithIntensities = TriggerCheckInState(
        emotionalStatus: TriggerStatus.soSo,
        emotionalIntensity: 1, // explicit mild intensity overrides default 3
        physicalStatus: TriggerStatus.badSick,
        physicalIntensity: 5,
      );

      expect(stateWithIntensities.resolvedEmotionalTier, ClinicalIntensityTier.mild);
      expect(stateWithIntensities.resolvedPhysicalTier, ClinicalIntensityTier.intense);

      const stateWithoutIntensities = TriggerCheckInState(
        emotionalStatus: TriggerStatus.goodNormal,
        physicalStatus: TriggerStatus.soSo,
      );

      expect(stateWithoutIntensities.resolvedEmotionalTier, ClinicalIntensityTier.none);
      expect(stateWithoutIntensities.resolvedPhysicalTier, ClinicalIntensityTier.moderate);
    });
  });
}

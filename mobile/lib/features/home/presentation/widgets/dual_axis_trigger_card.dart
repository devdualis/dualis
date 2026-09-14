import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';

/// Interactive dual-axis card for the mandatory trigger question:
/// "Como você está se sentindo hoje?" (RF-001 / TRG-01).
class DualAxisTriggerCard extends ConsumerStatefulWidget {
  const DualAxisTriggerCard({super.key});

  @override
  ConsumerState<DualAxisTriggerCard> createState() => _DualAxisTriggerCardState();
}

class _DualAxisTriggerCardState extends ConsumerState<DualAxisTriggerCard> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triggerCheckInProvider);
    final notifier = ref.read(triggerCheckInProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.clinicalTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in Diário de Triagem',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clinicalTeal,
                        ),
                      ),
                      Text(
                        'Como você está se sentindo hoje?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Axis 1: Psico-Emocional
            _buildAxisSection(
              context: context,
              title: '1. Eixo Psico-Emocional',
              subtitle: 'Humor, ansiedade, estresse e clareza mental',
              icon: Icons.psychology_outlined,
              accentColor: AppColors.softIndigo,
              selectedStatus: state.emotionalStatus,
              onSelect: notifier.setEmotionalStatus,
              isDark: isDark,
              axisKey: 'emotional',
            ),

            const SizedBox(height: 24),

            // Axis 2: Avaliação Física
            _buildAxisSection(
              context: context,
              title: '2. Eixo Avaliação Física',
              subtitle: 'Dores corporais, desconforto somático ou fadiga',
              icon: Icons.accessibility_new_rounded,
              accentColor: AppColors.clinicalTeal,
              selectedStatus: state.physicalStatus,
              onSelect: notifier.setPhysicalStatus,
              isDark: isDark,
              axisKey: 'physical',
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Free-form Lay Term Description Field (TRG-02 / I18N-02)
            Text(
              'Descreva com suas palavras (opcional):',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('naturalLanguageInput'),
              controller: _textController,
              onChanged: notifier.setNaturalLanguageText,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: "Sensação de aperto no peito e dor de cabeça..."',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSuggestionChip('Dor de cabeça', notifier),
                  _buildSuggestionChip('Cansaço excessivo', notifier),
                  _buildSuggestionChip('Aperto no peito', notifier),
                  _buildSuggestionChip('Crise de ansiedade', notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required TriggerStatus? selectedStatus,
    required ValueChanged<TriggerStatus> onSelect,
    required bool isDark,
    required String axisKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                label: 'Bem / Normal',
                icon: Icons.sentiment_satisfied_alt,
                status: TriggerStatus.goodNormal,
                isSelected: selectedStatus == TriggerStatus.goodNormal,
                activeColor: AppColors.clinicalTeal,
                onTap: () => onSelect(TriggerStatus.goodNormal),
                isDark: isDark,
                keyName: '${axisKey}_goodNormal',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusOption(
                label: 'Mais ou menos',
                icon: Icons.sentiment_neutral,
                status: TriggerStatus.soSo,
                isSelected: selectedStatus == TriggerStatus.soSo,
                activeColor: Colors.amber.shade800,
                onTap: () => onSelect(TriggerStatus.soSo),
                isDark: isDark,
                keyName: '${axisKey}_soSo',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusOption(
                label: 'Mal / Ruim',
                icon: Icons.sentiment_very_dissatisfied,
                status: TriggerStatus.badSick,
                isSelected: selectedStatus == TriggerStatus.badSick,
                activeColor: AppColors.emergencyCrimson,
                onTap: () => onSelect(TriggerStatus.badSick),
                isDark: isDark,
                keyName: '${axisKey}_badSick',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption({
    required String label,
    required IconData icon,
    required TriggerStatus status,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
    required String keyName,
  }) {
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, TriggerCheckInNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
        ),
        onPressed: () {
          final current = _textController.text;
          final updated = current.isEmpty ? text : '$current, $text';
          _textController.text = updated;
          _textController.selection = TextSelection.collapsed(offset: updated.length);
          notifier.setNaturalLanguageText(updated);
        },
      ),
    );
  }
}

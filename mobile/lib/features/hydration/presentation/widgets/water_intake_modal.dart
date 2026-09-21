import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../controllers/hydration_controller.dart';

class WaterIntakeModal extends ConsumerStatefulWidget {
  final String source;

  const WaterIntakeModal({
    super.key,
    this.source = 'manual',
  });

  static Future<void> show(BuildContext context, {String source = 'manual'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WaterIntakeModal(source: source),
    );
  }

  @override
  ConsumerState<WaterIntakeModal> createState() => _WaterIntakeModalState();
}

class _WaterIntakeModalState extends ConsumerState<WaterIntakeModal> {
  int _selectedAmount = 250;
  final TextEditingController _customController = TextEditingController();
  bool _isCustom = false;
  bool _isSaving = false;

  final List<int> _quickPresets = const [150, 200, 250, 300, 500];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    int amountToSave = _selectedAmount;
    if (_isCustom) {
      final parsed = int.tryParse(_customController.text.trim());
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, informe uma quantidade válida em ml.'),
            backgroundColor: AppColors.emergencyCrimson,
          ),
        );
        return;
      }
      amountToSave = parsed;
    }

    setState(() => _isSaving = true);
    final success = await ref
        .read(hydrationControllerProvider.notifier)
        .logWater(amountMl: amountToSave, source: widget.source);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💧 +$amountToSave ml registrados com sucesso!'),
            backgroundColor: AppColors.clinicalTealDark,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationControllerProvider);
    final target = state.dailyTargetMl;
    final total = state.todayTotalMl;
    final percent = state.progressPercent;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + viewInsets,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.clinicalTealDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hora de se hidratar 💧',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Quanto de água você consumiu agora?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Daily progress mini banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meta do dia: $target ml',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '$total ml ($percent%)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: state.isGoalReached
                            ? AppColors.clinicalTealDark
                            : AppColors.softIndigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.progressRatio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isGoalReached
                          ? AppColors.clinicalTealDark
                          : AppColors.clinicalTeal,
                    ),
                  ),
                ),
                if (state.isGoalReached) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.clinicalTealDark),
                      const SizedBox(width: 4),
                      Text(
                        'Parabéns! Meta diária atingida!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clinicalTealDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Selecione a porção:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._quickPresets.map((ml) {
                final isSelected = !_isCustom && _selectedAmount == ml;
                return ChoiceChip(
                  key: Key('water_preset_${ml}ml'),
                  selected: isSelected,
                  label: Text('$ml ml'),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                  ),
                  selectedColor: AppColors.clinicalTealDark,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.clinicalTealDark
                        : Colors.grey.shade300,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isCustom = false;
                        _selectedAmount = ml;
                      });
                    }
                  },
                );
              }),
              ChoiceChip(
                key: const Key('water_preset_custom'),
                selected: _isCustom,
                label: const Text('Outro valor'),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: _isCustom ? FontWeight.bold : FontWeight.w500,
                  color: _isCustom ? Colors.white : AppColors.textPrimaryLight,
                ),
                selectedColor: AppColors.clinicalTealDark,
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(
                  color: _isCustom
                      ? AppColors.clinicalTealDark
                      : Colors.grey.shade300,
                ),
                onSelected: (val) {
                  setState(() {
                    _isCustom = val;
                  });
                },
              ),
            ],
          ),

          if (_isCustom) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('water_custom_amount_input'),
              controller: _customController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantidade personalizada',
                hintText: 'Ex: 350',
                suffixText: 'ml',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.clinicalTealDark,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.local_drink_outlined,
                  color: AppColors.clinicalTealDark,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          DualisPrimaryButton(
            key: const Key('confirm_water_intake_button'),
            text: 'Registrar Consumo',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleConfirm,
          ),
        ],
      ),
    );
  }
}

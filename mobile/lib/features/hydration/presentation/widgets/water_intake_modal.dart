import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
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
  bool _saveFailed = false;

  final List<int> _quickPresets = const [150, 200, 250, 300, 500];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hydrationControllerProvider.notifier).loadData();
    });
  }

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
          SnackBar(
            content: Text(AppLocalizations.of(context).waterInvalidAmount),
            backgroundColor: AppColors.emergencyCrimson,
          ),
        );
        return;
      }
      amountToSave = parsed;
    }

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    final success = await ref
        .read(hydrationControllerProvider.notifier)
        .logWater(amountMl: amountToSave, source: widget.source);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _saveFailed = !success;
      });
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).waterLoggedSuccess(amountToSave)),
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
                      AppLocalizations.of(context).waterTimeTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).waterHowMuchNow,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('water_intake_modal_close_button'),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: AppLocalizations.of(context).waterClose,
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
                      AppLocalizations.of(context).waterDailyGoal(target),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      state.isLoading
                          ? AppLocalizations.of(context).waterLoading
                          : '$total ml ($percent%)',
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
                  child: state.isLoading
                      ? LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.clinicalTeal,
                          ),
                        )
                      : LinearProgressIndicator(
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
                        AppLocalizations.of(context).waterGoalReached,
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
            AppLocalizations.of(context).waterSelectPortion,
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
                  materialTapTargetSize: MaterialTapTargetSize.padded,
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
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(AppLocalizations.of(context).waterOtherValue),
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
                labelText: AppLocalizations.of(context).waterCustomAmount,
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

          // A snackbar would sit behind this sheet, so the failure shows here.
          if (_saveFailed) ...[
            Text(
              AppLocalizations.of(context).commonSaveFailed,
              key: const Key('water_intake_save_failed'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.emergencyCrimson,
              ),
            ),
            const SizedBox(height: 12),
          ],

          DualisPrimaryButton(
            key: const Key('confirm_water_intake_button'),
            text: AppLocalizations.of(context).waterLogButton,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleConfirm,
          ),
        ],
      ),
    );
  }
}

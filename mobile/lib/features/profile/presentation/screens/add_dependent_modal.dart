import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../../../shared/widgets/dualis_text_field.dart';
import '../../../../core/utils/date_input_formatter.dart';
import '../../../auth/domain/form_validators.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/widgets/biological_sex_selector.dart';
import '../../domain/models/profile.dart';
import '../controllers/active_profile_controller.dart';

const _relationshipParent = 'parent';
const _relationshipLegalGuardian = 'legal_guardian';
const _relationshipCurator = 'curator';

Future<Profile?> showAddDependentModal(BuildContext context) {
  return showModalBottomSheet<Profile?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => const AddDependentModal(),
  );
}

class AddDependentModal extends ConsumerStatefulWidget {
  const AddDependentModal({super.key});

  @override
  ConsumerState<AddDependentModal> createState() => _AddDependentModalState();
}

class _AddDependentModalState extends ConsumerState<AddDependentModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();

  Gender _selectedGender = Gender.masculino;
  String? _relationshipType;
  DateTime? _selectedDate;
  bool _lgpdConsent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  DateTime? _parseDobText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        final candidate = DateTime.tryParse(
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        );
        if (candidate != null &&
            candidate.day == day &&
            candidate.month == month) {
          return candidate;
        }
      }
    }
    return DateTime.tryParse(trimmed);
  }

  DateTime? _resolveDateOfBirth() {
    if (_selectedDate != null) return _selectedDate;
    return _parseDobText(_dobController.text);
  }

  bool get _isFormReady {
    final nameOk = FormValidators.validateName(_nameController.text) == null;
    final dobOk = _validateDependentDateOfBirth(_resolveDateOfBirth()) == null;
    final relationshipOk = _relationshipType != null;
    return nameOk && dobOk && relationshipOk && _lgpdConsent && !_isSubmitting;
  }

  String? _validateDependentDateOfBirth(DateTime? date) {
    final l10n = AppLocalizations.of(context);
    if (date == null) {
      return l10n.addDependentDobInvalid;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(date.year, date.month, date.day);
    if (picked.isAfter(today)) {
      return l10n.addDependentDobFuture;
    }
    int age = today.year - picked.year;
    if (today.month < picked.month ||
        (today.month == picked.month && today.day < picked.day)) {
      age--;
    }
    if (age > 120) {
      return l10n.addDependentDobInvalid;
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final initial = _selectedDate ?? DateTime(now.year - 10, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: l10n.addDependentDobPickerHelp,
      cancelText: l10n.familySharingCancel,
      confirmText: l10n.familySharingDone,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String _relationshipLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case _relationshipParent:
        return l10n.addDependentRelationshipParent;
      case _relationshipCurator:
        return l10n.addDependentRelationshipCurator;
      case _relationshipLegalGuardian:
        return l10n.addDependentRelationshipLegalGuardian;
      default:
        return value;
    }
  }

  Future<void> _submit() async {
    if (!_isFormReady) return;
    final l10n = AppLocalizations.of(context);
    final dob = _resolveDateOfBirth();
    if (dob == null) return;

    setState(() => _isSubmitting = true);
    try {
      final profile = await ref.read(activeProfileControllerProvider.notifier).createDependent(
            name: _nameController.text.trim(),
            dateOfBirth: dob,
            gender: _selectedGender.value,
            relationshipType: _relationshipType!,
            lgpdConsent: true,
          );
      if (!mounted) return;
      Navigator.of(context).pop(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addDependentSuccess),
          backgroundColor: AppColors.clinicalTealDark,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final message = ref.read(activeProfileControllerProvider).errorMessage ??
          l10n.addDependentGenericError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.emergencyCrimson,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.addDependentTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DualisTextField(
                        controller: _nameController,
                        labelText: l10n.addDependentNameLabel,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _onFieldChanged(),
                        validator: FormValidators.validateName,
                      ),
                      const SizedBox(height: 16),
                      DualisTextField(
                        key: const ValueKey('add-dependent-dob'),
                        controller: _dobController,
                        labelText: l10n.addDependentDobLabel,
                        hintText: l10n.addDependentDobHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                        onChanged: (_) {
                          _selectedDate = null;
                          _onFieldChanged();
                        },
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _isSubmitting ? null : _pickDateOfBirth,
                        ),
                        validator: (_) =>
                            _validateDependentDateOfBirth(_resolveDateOfBirth()),
                      ),
                      const SizedBox(height: 16),
                      BiologicalSexSelector(
                        selectedGender: _selectedGender,
                        onGenderChanged: (g) {
                          setState(() => _selectedGender = g);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.addDependentRelationshipLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        key: const ValueKey('add-dependent-relationship'),
                        children: [
                          for (final value in [
                            _relationshipParent,
                            _relationshipCurator,
                            _relationshipLegalGuardian,
                          ])
                            _RelationshipOptionTile(
                              label: _relationshipLabel(l10n, value),
                              selected: _relationshipType == value,
                              onTap: _isSubmitting
                                  ? null
                                  : () => setState(() => _relationshipType = value),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _LgpdGuardianConsentBlock(
                        value: _lgpdConsent,
                        consentText: l10n.addDependentLgpdArt14Consent,
                        onChanged: _isSubmitting
                            ? null
                            : (v) {
                                setState(() => _lgpdConsent = v ?? false);
                              },
                      ),
                      const SizedBox(height: 24),
                      DualisPrimaryButton(
                        key: const ValueKey('add-dependent-submit'),
                        text: l10n.addDependentSubmit,
                        isLoading: _isSubmitting,
                        onPressed: _isFormReady ? _submit : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _RelationshipOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _RelationshipOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.softIndigo : AppColors.outlineLight,
              width: selected ? 2 : 1.5,
            ),
            color: selected ? AppColors.softIndigoLight : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.softIndigo : AppColors.textSecondaryLight,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LgpdGuardianConsentBlock extends StatelessWidget {
  final bool value;
  final String consentText;
  final ValueChanged<bool?>? onChanged;

  const _LgpdGuardianConsentBlock({
    required this.value,
    required this.consentText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softIndigoLight,
        border: Border.all(color: AppColors.softIndigo, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            key: const ValueKey('lgpd-art14-consent'),
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.softIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                consentText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

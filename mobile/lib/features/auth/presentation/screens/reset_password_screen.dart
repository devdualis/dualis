import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/error_message_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../../../shared/widgets/dualis_text_field.dart';
import '../../domain/form_validators.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref.read(authControllerProvider.notifier).resetPassword(
          email: widget.email,
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetPasswordSuccessMessage),
          backgroundColor: AppColors.clinicalTeal,
          duration: const Duration(seconds: 4),
        ),
      );
      context.go(RoutePaths.login);
    } else {
      final rawError = ref.read(authControllerProvider).errorMessage;
      if (rawError != null) {
        final errorText = ErrorMessageResolver.resolve(rawError, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: AppColors.emergencyCrimson,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 16),
                    child: DualisLogo(
                      key: Key('resetPasswordBrandLogo'),
                      variant: DualisLogoVariant.vertical,
                      width: 160,
                      withProtectionArea: true,
                      isHighVisibility: true,
                    ),
                  ),
                ),
                Text(
                  l10n.resetPasswordTitle,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.resetPasswordSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                DualisTextField(
                  key: const Key('resetPasswordCodeField'),
                  labelText: l10n.resetPasswordCodeLabel,
                  hintText: l10n.resetPasswordCodeHint,
                  controller: _codeController,
                  validator: (v) =>
                      (v == null || v.trim().length != 6) ? l10n.resetPasswordCodeRequired : null,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),
                DualisTextField(
                  key: const Key('resetPasswordNewPasswordField'),
                  labelText: l10n.newPassword,
                  hintText: l10n.newPasswordHint,
                  helperText: l10n.passwordComplexityHint,
                  controller: _newPasswordController,
                  validator: FormValidators.validatePassword,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
                const SizedBox(height: 16),
                DualisTextField(
                  key: const Key('resetPasswordConfirmPasswordField'),
                  labelText: l10n.confirmNewPassword,
                  hintText: l10n.confirmPasswordHint,
                  controller: _confirmPasswordController,
                  validator: (v) => v != _newPasswordController.text ? l10n.passwordsDoNotMatch : null,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 28),
                DualisPrimaryButton(
                  key: const Key('resetPasswordSubmitButton'),
                  text: l10n.resetPasswordSubmitCta,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

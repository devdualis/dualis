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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).forgotPassword(email: email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.forgotPasswordSuccessMessage),
          backgroundColor: AppColors.clinicalTeal,
          duration: const Duration(seconds: 4),
        ),
      );
      context.go(RoutePaths.resetPassword, extra: email);
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
                      key: Key('forgotPasswordBrandLogo'),
                      variant: DualisLogoVariant.vertical,
                      width: 160,
                      withProtectionArea: true,
                      isHighVisibility: true,
                    ),
                  ),
                ),
                Text(
                  l10n.forgotPasswordTitle,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forgotPasswordSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                DualisTextField(
                  key: const Key('forgotPasswordEmailField'),
                  labelText: l10n.email,
                  hintText: l10n.authEmailHint,
                  controller: _emailController,
                  validator: FormValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 28),
                DualisPrimaryButton(
                  key: const Key('forgotPasswordSubmitButton'),
                  text: l10n.forgotPasswordSendCta,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleSubmit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    key: const Key('backToLoginButton'),
                    onPressed: () => context.go(RoutePaths.login),
                    child: Text(
                      l10n.forgotPasswordBackToLogin,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.softIndigo,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

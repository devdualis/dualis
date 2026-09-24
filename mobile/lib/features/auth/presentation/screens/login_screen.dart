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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go(RoutePaths.home);
    } else if (mounted) {
      final rawError = ref.read(authControllerProvider).errorMessage;
      if (rawError != null) {
        final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
        final errorText = l10n != null
            ? ErrorMessageResolver.resolve(rawError, l10n)
            : ((rawError.toLowerCase().contains('unauthorized') ||
                    rawError.toLowerCase().contains('401'))
                ? 'Credenciais inválidas. Verifique seu e-mail e senha.'
                : rawError);
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.onboarding),
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
                      key: Key('loginBrandLogo'),
                      variant: DualisLogoVariant.vertical,
                      width: 160,
                      withProtectionArea: true,
                      isHighVisibility: true,
                    ),
                  ),
                ),
                Text(
                  'Entrar no DualisCheckUp',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse seu prontuário e histórico de triagens preventivas com segurança.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                DualisTextField(
                  key: const Key('loginEmailField'),
                  labelText: 'E-mail',
                  hintText: 'seu.email@exemplo.com',
                  controller: _emailController,
                  validator: FormValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),
                DualisTextField(
                  key: const Key('loginPasswordField'),
                  labelText: 'Senha',
                  controller: _passwordController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Senha é obrigatória.' : null,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 28),
                DualisPrimaryButton(
                  key: const Key('loginSubmitButton'),
                  text: 'Entrar',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    key: const Key('goToRegisterButton'),
                    onPressed: () => context.go(RoutePaths.register),
                    child: Text.rich(
                      TextSpan(
                        text: 'Ainda não possui conta? ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        children: [
                          TextSpan(
                            text: 'Criar Conta',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.softIndigo,
                            ),
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
      ),
    );
  }
}

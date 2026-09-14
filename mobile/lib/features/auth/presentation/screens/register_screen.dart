import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../../../shared/widgets/dualis_text_field.dart';
import '../../domain/form_validators.dart';
import '../../domain/user_profile.dart';
import '../controllers/auth_controller.dart';
import '../widgets/biological_sex_selector.dart';
import '../widgets/lgpd_consent_checkbox.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Gender _selectedGender = Gender.masculino;
  bool _lgpdConsent = false;
  bool _obscurePassword = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateFormState);
    _dobController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);
    _passwordController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {});
  }

  bool get _isFormValid {
    final isNameValid = FormValidators.validateName(_nameController.text) == null;
    final isEmailValid = FormValidators.validateEmail(_emailController.text) == null;
    final isPasswordValid = FormValidators.validatePassword(_passwordController.text) == null;
    final isDobValid = FormValidators.validateDateOfBirth(_dobController.text) == null;

    return isNameValid && isEmailValid && isPasswordValid && isDobValid && _lgpdConsent;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      _selectedDate = picked;
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  String _formatIsoDate(DateTime? date, String text) {
    if (date != null) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    final parts = text.trim().split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return text;
  }

  Future<void> _handleRegister() async {
    if (!_isFormValid) return;

    final isoDate = _formatIsoDate(_selectedDate, _dobController.text);

    final success = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          gender: _selectedGender.value,
          dateOfBirth: isoDate,
          lgpdConsent: _lgpdConsent,
        );

    if (success && mounted) {
      context.go(RoutePaths.home);
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.emergencyCrimson,
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar sua conta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Informe seus dados clínicos e cadastrais para personalizar sua triagem preventiva.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Nome Completo
                DualisTextField(
                  key: const Key('fullNameField'),
                  labelText: 'Nome Completo',
                  hintText: 'Ex: Carlos Silva',
                  controller: _nameController,
                  validator: FormValidators.validateName,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),

                // 2. Data de Nascimento
                DualisTextField(
                  key: const Key('birthDateField'),
                  labelText: 'Data de Nascimento',
                  hintText: 'DD/MM/AAAA',
                  controller: _dobController,
                  validator: FormValidators.validateDateOfBirth,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondaryLight),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined, color: AppColors.softIndigo),
                    onPressed: _pickDateOfBirth,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Sexo Biológico
                BiologicalSexSelector(
                  key: const Key('biologicalSexSelector'),
                  selectedGender: _selectedGender,
                  onGenderChanged: (gender) {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 4. E-mail
                DualisTextField(
                  key: const Key('emailField'),
                  labelText: 'E-mail',
                  hintText: 'seu.email@exemplo.com',
                  controller: _emailController,
                  validator: FormValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),

                // 5. Senha
                DualisTextField(
                  key: const Key('passwordField'),
                  labelText: 'Senha',
                  hintText: 'Mínimo 8 caracteres',
                  controller: _passwordController,
                  validator: FormValidators.validatePassword,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Consentimento LGPD Art. 11 Checkbox
                LgpdConsentCheckbox(
                  value: _lgpdConsent,
                  onChanged: (val) {
                    setState(() {
                      _lgpdConsent = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 7. Primary CTA: Finalizar Cadastro (Strictly gated)
                DualisPrimaryButton(
                  key: const Key('submitRegisterButton'),
                  text: 'Finalizar Cadastro',
                  isLoading: authState.isLoading,
                  onPressed: _isFormValid && !authState.isLoading ? _handleRegister : null,
                ),
                const SizedBox(height: 16),

                // 8. Link to Login
                Center(
                  child: TextButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: Text.rich(
                      TextSpan(
                        text: 'Já possui uma conta? ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        children: [
                          TextSpan(
                            text: 'Entrar',
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

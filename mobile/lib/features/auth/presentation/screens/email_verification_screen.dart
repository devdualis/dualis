import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../controllers/auth_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  static const int _codeLength = 6;
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _digitControllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;
  bool _canResend = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (int i = 0; i < _codeLength; i++) {
      _digitControllers[i].addListener(_onCodeChanged);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = _resendCooldownSeconds;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  void _onCodeChanged() {
    setState(() {});
  }

  String get _currentCode {
    return _digitControllers.map((c) => c.text).join();
  }

  bool get _isCodeComplete => _currentCode.length == _codeLength;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '$username***@$domain';
    }
    final first = username[0];
    final last = username[username.length - 1];
    return '$first***$last@$domain';
  }

  Future<void> _handleVerify() async {
    if (!_isCodeComplete) return;

    final code = _currentCode;
    final success = await ref.read(authControllerProvider.notifier).verifyEmail(
          email: widget.email,
          code: code,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail verificado com sucesso! Bem-vindo ao DualisCheckUp.'),
          backgroundColor: AppColors.clinicalTeal,
          duration: Duration(seconds: 3),
        ),
      );
      context.go(RoutePaths.home);
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.emergencyCrimson,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationCode(email: widget.email);

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Novo código enviado para seu e-mail.'),
          backgroundColor: AppColors.clinicalTeal,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      final error = ref.read(authControllerProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.emergencyCrimson,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildDigitInput(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _digitControllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        child: TextFormField(
          key: Key('otp_digit_$index'),
          controller: _digitControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _digitControllers[index].text.isNotEmpty
                    ? AppColors.clinicalTeal
                    : AppColors.outlineLight,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.clinicalTeal,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < _codeLength - 1) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
                _handleVerify();
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final masked = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 24),
                child: DualisLogo(
                  key: Key('verificationBrandLogo'),
                  variant: DualisLogoVariant.horizontal,
                  emblemSize: 40,
                  fontSize: 22,
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.clinicalTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 38,
                  color: AppColors.clinicalTeal,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verifique seu e-mail',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos um código de segurança de 6 dígitos para o e-mail:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Text(
                  masked,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.clinicalTeal,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_codeLength, (i) => _buildDigitInput(i)),
              ),
              const SizedBox(height: 36),
              DualisPrimaryButton(
                text: 'Confirmar e Ativar Conta',
                isLoading: authState.isLoading,
                onPressed: _isCodeComplete ? _handleVerify : null,
              ),
              const SizedBox(height: 28),
              if (!_canResend) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'Reenviar código em ${_secondsRemaining.toString().padLeft(2, '0')}s',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending ? 'Enviando novo código...' : 'Não recebeu o código? Reenviar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.clinicalTeal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
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

  /// Route email, or the remembered pending one when the app reopened here.
  late final String _email = widget.email.isNotEmpty
      ? widget.email
      : ref.read(authControllerProvider).pendingVerificationEmail ?? '';

  @override
  void initState() {
    super.initState();
    // Count down only for a code sent moments ago in this session; after a
    // restart or a login the user may ask for a new code right away.
    final remaining = ref
        .read(authControllerProvider.notifier)
        .resendCooldownRemaining(const Duration(seconds: _resendCooldownSeconds));
    if (remaining > Duration.zero) {
      _startResendTimer(seconds: remaining.inSeconds.clamp(1, _resendCooldownSeconds));
    } else {
      _secondsRemaining = 0;
      _canResend = true;
    }
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

  void _startResendTimer({int seconds = _resendCooldownSeconds}) {
    setState(() {
      _secondsRemaining = seconds;
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
          email: _email,
          code: code,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).emailVerificationSuccess),
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
        .resendVerificationCode(email: _email);

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).newCodeSentSuccess),
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
      width: 48,
      height: 56,
      child: Semantics(
        label: AppLocalizations.of(context).emailVerifyDigitLabel(index + 1),
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
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dualisNavy,
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
                      ? AppColors.dualisNavy
                      : AppColors.outlineLight,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.dualisSymbolCyan,
                  width: 2.5,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final masked = _maskEmail(_email);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDepth,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.jv2Back,
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
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: DualisLogo(
                  key: Key('verificationBrandLogo'),
                  variant: DualisLogoVariant.horizontal,
                  width: 170,
                  withProtectionArea: true,
                ),
              ),
              const DuotoneIconTile(
                size: 72,
                radius: 22,
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 38,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.emailVerifyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dualisNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.emailVerifySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassEdge),
                ),
                child: Text(
                  masked,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dualisNavy,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_codeLength, (i) => _buildDigitInput(i)),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              DualisPrimaryButton(
                text: l10n.emailVerifyConfirmButton,
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
                      l10n.emailVerifyResendCountdown(
                        _secondsRemaining.toString().padLeft(2, '0'),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending
                        ? l10n.emailVerifyResending
                        : l10n.emailVerifyResendPrompt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dualisSymbolBlue,
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

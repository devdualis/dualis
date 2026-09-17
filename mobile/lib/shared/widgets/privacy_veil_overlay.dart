import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'dualis_logo.dart';
import '../../core/security/app_lifecycle_observer.dart';
import '../../core/security/biometric_service.dart';

class PrivacyVeilOverlay extends StatefulWidget {
  final Widget child;
  final BiometricService? biometricService;
  final bool initialLocked;
  final bool isBypassed;
  final VoidCallback? onUnlocked;

  const PrivacyVeilOverlay({
    super.key,
    required this.child,
    this.biometricService,
    this.initialLocked = false,
    this.isBypassed = false,
    this.onUnlocked,
  });

  @override
  State<PrivacyVeilOverlay> createState() => PrivacyVeilOverlayState();
}

class PrivacyVeilOverlayState extends State<PrivacyVeilOverlay> {
  late final BiometricService _biometricService;
  late final AppLifecycleObserver _lifecycleObserver;
  bool _isLocked = false;
  bool _showManualFallback = false;

  bool get isLocked => _isLocked;
  AppLifecycleObserver get lifecycleObserver => _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _biometricService = widget.biometricService ?? BiometricService();
    _isLocked = widget.initialLocked;

    _lifecycleObserver = AppLifecycleObserver(
      onLockStateChanged: (locked) {
        if (mounted) {
          setState(() {
            _isLocked = locked;
          });
        }
      },
    );

    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> unlock() async {
    try {
      final success = await _biometricService.authenticate(
        localizedReason: 'Autentique-se para acessar seus dados de saúde confidenciais.',
      );

      if (success && mounted) {
        _lifecycleObserver.unlock();
        setState(() {
          _isLocked = false;
          _showManualFallback = false;
        });
        widget.onUnlocked?.call();
      } else if (mounted) {
        setState(() {
          _showManualFallback = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _showManualFallback = true;
        });
      }
    }
  }

  void forceLock() {
    _lifecycleObserver.lock();
    setState(() {
      _isLocked = true;
    });
  }

  void forceUnlock() {
    _lifecycleObserver.unlock();
    setState(() {
      _isLocked = false;
      _showManualFallback = false;
    });
    widget.onUnlocked?.call();
  }

  @override
  Widget build(BuildContext context) {
    final showVeil = _isLocked && !widget.isBypassed;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (showVeil)
          Positioned.fill(
            child: BackdropFilter(
              key: const Key('privacyVeilBackdrop'),
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: AppColors.backgroundDark.withAlpha(220),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DualisEmblem(
                        key: Key('privacyVeilEmblem'),
                        size: 64,
                        withContainer: true,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Dados de Saúde Protegidos',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Autentique-se com biometria ou senha para acessar seu prontuário.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondaryDark,
                          height: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          key: const Key('privacyVeilUnlockButton'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.softIndigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: unlock,
                          icon: const Icon(Icons.fingerprint, size: 22),
                          label: Text(
                            'Desbloquear',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_showManualFallback) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          key: const Key('privacyVeilFallbackButton'),
                          onPressed: forceUnlock,
                          child: Text(
                            'Desbloquear manualmente',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.clinicalTeal,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/feature_flags.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/route_paths.dart';
import '../../core/security/biometric_lock_controller.dart';
import '../../core/utils/error_message_resolver.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import 'dualis_logo.dart';
import 'urgent_help_button.dart';

/// Premium app lock. Wraps the whole app (MaterialApp `builder`) and hides
/// it behind a lock screen while [BiometricLockController] says so.
///
/// The help resources screen holds no personal data, so the lock is not
/// drawn while it is on top: help stays one tap away, and going back from it
/// shows the lock again. Free builds return [child] untouched.
class PrivacyVeilOverlay extends ConsumerStatefulWidget {
  final GoRouter router;
  final Widget child;

  const PrivacyVeilOverlay({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  ConsumerState<PrivacyVeilOverlay> createState() => _PrivacyVeilOverlayState();
}

class _PrivacyVeilOverlayState extends ConsumerState<PrivacyVeilOverlay>
    with WidgetsBindingObserver {
  late final bool _premium;
  bool _syncScheduled = false;

  /// Last build's answer to "is the lock drawn?", read by the back handler.
  bool _covered = false;

  /// The app is inactive, hidden or paused (app switcher, shade, other app).
  bool _appAway = false;

  ChildBackButtonDispatcher? _backDispatcher;

  @override
  void initState() {
    super.initState();
    _premium = ref.read(premiumProfilesEnabledProvider);
    if (!_premium) return;
    WidgetsBinding.instance.addObserver(this);
    _attachRouter(widget.router);
  }

  @override
  void didUpdateWidget(PrivacyVeilOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_premium && oldWidget.router != widget.router) {
      _detachRouter(oldWidget.router);
      _attachRouter(widget.router);
    }
  }

  @override
  void dispose() {
    if (_premium) {
      WidgetsBinding.instance.removeObserver(this);
      _detachRouter(widget.router);
    }
    super.dispose();
  }

  void _attachRouter(GoRouter router) {
    router.routerDelegate.addListener(_onRouteChanged);
    // Asked before the app's router on Android back. While the lock is drawn
    // it swallows back, so hidden screens are never popped. On the help
    // screen the lock is not drawn, so back pops help and shows the lock.
    final dispatcher =
        router.backButtonDispatcher.createChildBackButtonDispatcher()
          ..addCallback(_onBack);
    _backDispatcher = dispatcher;
    _takeBackPriority(router, dispatcher);
  }

  /// The app's router sits below this widget and registers its own back
  /// handler on its first build (not at all while the update-required
  /// screen replaces it); priority can only be taken after that.
  void _takeBackPriority(
    GoRouter router,
    ChildBackButtonDispatcher dispatcher,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _backDispatcher != dispatcher) return;
      if (router.backButtonDispatcher.hasCallbacks) {
        dispatcher.takePriority();
      } else {
        _takeBackPriority(router, dispatcher);
      }
    });
  }

  void _detachRouter(GoRouter router) {
    router.routerDelegate.removeListener(_onRouteChanged);
    final dispatcher = _backDispatcher;
    if (dispatcher != null) {
      dispatcher.removeCallback(_onBack);
      router.backButtonDispatcher.forget(dispatcher);
      _backDispatcher = null;
    }
  }

  Future<bool> _onBack() => SynchronousFuture<bool>(_covered);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(biometricLockControllerProvider.notifier);
    if (state == AppLifecycleState.paused) lock.onPaused();
    if (state == AppLifecycleState.resumed) lock.onResumed();
    if (state == AppLifecycleState.detached) return;
    final away = state != AppLifecycleState.resumed;
    if (away != _appAway && mounted) setState(() => _appAway = away);
  }

  void _onRouteChanged() {
    // Same as UrgentHelpOverlay: the router may notify mid-build, so
    // rebuild after the current frame.
    if (_syncScheduled) return;
    _syncScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _syncScheduled = false;
        if (mounted) setState(() {});
      })
      ..ensureVisualUpdate();
  }

  bool _isOnHelpScreen() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    return router.state.matchedLocation == RoutePaths.emergency;
  }

  @override
  Widget build(BuildContext context) {
    if (!_premium) return widget.child;

    final lock = ref.watch(biometricLockControllerProvider);
    // Covered while the saved setting loads too: session restore is async,
    // so "not signed in yet" proves nothing on the first frames.
    final covered = (lock.locked || lock.checking) && !_isOnHelpScreen();
    _covered = covered;
    // App-switcher snapshots are taken while the app is inactive (frames
    // still run then): paint a plain cover so they never show entries.
    final snapshotCover = _appAway && lock.enabled && !covered;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Offstage keeps the app's state but paints nothing and takes no
        // taps or screen-reader focus while locked.
        Offstage(offstage: covered || snapshotCover, child: widget.child),
        if (snapshotCover)
          const ColoredBox(
            key: Key('privacyVeilSnapshotCover'),
            color: AppColors.backgroundLight,
            child: Center(
              child: DualisEmblem(
                size: 64,
                withContainer: true,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (covered)
          // The lock lives above the app's navigator, so it brings its own
          // (text fields need an Overlay).
          HeroControllerScope.none(
            child: Navigator(
              key: const Key('privacyVeilBackdrop'),
              onGenerateRoute:
                  (_) => PageRouteBuilder<void>(
                    pageBuilder:
                        (_, __, ___) => _LockScreen(router: widget.router),
                  ),
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  final GoRouter router;

  const _LockScreen({required this.router});

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  bool _passwordMode = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoPrompt());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _maybeAutoPrompt() {
    if (!mounted || !ref.read(biometricLockControllerProvider).locked) return;
    if (ref.read(biometricLockControllerProvider.notifier).takeAutoPrompt()) {
      _tryBiometrics();
    }
  }

  Future<void> _tryBiometrics() async {
    if (_busy) return;
    final reason = AppLocalizations.of(context).privacyVeilBiometricReason;
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref
        .read(biometricLockControllerProvider.notifier)
        .unlockWithBiometrics(reason);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _submitPassword() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = l10n.bioLockPasswordEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(biometricLockControllerProvider.notifier)
        .unlockWithPassword(password);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case PasswordUnlockResult.success:
          _passwordController.clear();
        case PasswordUnlockResult.noAccount:
          _error = l10n.bioLockNoAccount;
        case PasswordUnlockResult.failed:
          final raw = ref.read(authControllerProvider).errorMessage;
          final message =
              raw != null
                  ? ErrorMessageResolver.resolve(raw, l10n)
                  : l10n.errorUnexpected;
          // The password needs the server; offline, point to the device
          // passcode instead of showing a connection error.
          final offline =
              message == l10n.errorNetworkConnection ||
              message == l10n.errorConnectionTimeout;
          _error = offline ? l10n.bioLockOffline : message;
      }
    });
    if (result != PasswordUnlockResult.success) {
      // Ready for a second try: focus kept, old text selected.
      _passwordController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _passwordController.text.length,
      );
      _passwordFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lock = ref.watch(biometricLockControllerProvider);
    ref.listen<bool>(biometricLockControllerProvider.select((s) => s.locked), (
      previous,
      next,
    ) {
      if (next) _maybeAutoPrompt();
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                child: Column(
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
                      l10n.bioLockTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.bioLockBody,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!lock.locked)
                      const CircularProgressIndicator()
                    else if (_passwordMode)
                      ..._buildPasswordForm(l10n)
                    else
                      ..._buildBiometricActions(l10n),
                  ],
                ),
              ),
            ),
            // Help resources: one tap, even while locked.
            Positioned(
              top: 8,
              right: 12,
              child: UrgentHelpButton(
                onPressed: () => widget.router.push(RoutePaths.emergency),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBiometricActions(AppLocalizations l10n) {
    return [
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
          onPressed: _busy ? null : _tryBiometrics,
          icon: const Icon(Icons.fingerprint, size: 22),
          label: Text(
            l10n.privacyVeilUnlock,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        key: const Key('bioLockPasswordButton'),
        onPressed:
            _busy
                ? null
                : () => setState(() {
                  _passwordMode = true;
                  _error = null;
                }),
        child: Text(
          l10n.bioLockPasswordButton,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.clinicalTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextButton(
        key: const Key('bioLockSignOutButton'),
        onPressed: _busy ? null : _confirmSignOut,
        child: Text(
          l10n.logoutButton,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.logoutButton),
            content: Text(l10n.settingsLogoutConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.bioLockPasswordBack),
              ),
              TextButton(
                key: const Key('bioLockSignOutConfirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.settingsLogoutConfirmAction),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(biometricLockControllerProvider.notifier).signOut();
    if (mounted) setState(() => _busy = false);
  }

  List<Widget> _buildPasswordForm(AppLocalizations l10n) {
    final email = ref.watch(
      authControllerProvider.select((s) => s.user?.email),
    );
    return [
      if (email != null && email.isNotEmpty) ...[
        Text(
          email,
          key: const Key('bioLockPasswordEmail'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        key: const Key('bioLockPasswordField'),
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscure,
        // Read-only (not disabled) while checking, so the keyboard and the
        // focus stay for a second try.
        readOnly: _busy,
        autofocus: true,
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submitPassword(),
        decoration: InputDecoration(
          labelText: l10n.bioLockPasswordLabel,
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(
          _error!,
          key: const Key('bioLockPasswordError'),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.emergencyCrimson,
          ),
        ),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          key: const Key('bioLockPasswordSubmit'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.softIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _busy ? null : _submitPassword,
          child:
              _busy
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    l10n.bioLockPasswordSubmit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: const Key('bioLockPasswordBack'),
        onPressed:
            _busy
                ? null
                : () => setState(() {
                  _passwordMode = false;
                  _error = null;
                  _passwordController.clear();
                }),
        child: Text(
          l10n.bioLockPasswordBack,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.clinicalTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }
}

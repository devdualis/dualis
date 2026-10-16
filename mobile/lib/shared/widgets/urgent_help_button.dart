import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/route_paths.dart';
import '../../l10n/app_localizations.dart';

/// Slim "Ajuda urgente" bar that opens the help resources screen.
/// Does not depend on any user data.
class UrgentHelpButton extends StatelessWidget {
  final VoidCallback onPressed;

  const UrgentHelpButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).urgentHelpButton;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.emergencySurfaceRed,
        child: InkWell(
          key: const Key('urgent_help_button'),
          onTap: onPressed,
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.emergencyCrimson),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.emergencyCrimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

/// Wraps the whole app (MaterialApp `builder`) and adds [UrgentHelpButton]
/// below every screen, so it never covers content. Hidden on the help screen
/// itself and while the keyboard is open.
class UrgentHelpOverlay extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const UrgentHelpOverlay({super.key, required this.router, required this.child});

  @override
  State<UrgentHelpOverlay> createState() => _UrgentHelpOverlayState();
}

class _UrgentHelpOverlayState extends State<UrgentHelpOverlay> {
  bool _onHelpScreen = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(UrgentHelpOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
      _onHelpScreen = _isOnHelpScreen();
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  bool _isOnHelpScreen() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    return router.state.matchedLocation == RoutePaths.emergency;
  }

  void _onRouteChanged() {
    // The router lives below this widget and may notify while it is building.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _sync());
    } else {
      _sync();
    }
  }

  void _sync() {
    if (!mounted) return;
    final value = _isOnHelpScreen();
    if (value != _onHelpScreen) setState(() => _onHelpScreen = value);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final visible = media.viewInsets.bottom == 0 && !_onHelpScreen;

    return Column(
      children: [
        Expanded(
          // Same widget structure either way so screen state is kept.
          child: MediaQuery(
            data: visible ? media.removePadding(removeBottom: true) : media,
            child: widget.child,
          ),
        ),
        if (visible)
          ColoredBox(
            color: AppColors.emergencySurfaceRed,
            child: SafeArea(
              top: false,
              child: UrgentHelpButton(
                onPressed: () => widget.router.push(RoutePaths.emergency),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/route_paths.dart';
import '../../l10n/app_localizations.dart';

/// Small round "Ajuda urgente" button that opens the help resources screen.
/// Sits top-right, near the settings icon, so it is never in the path of
/// routine taps (bottom nav / check-in actions). Does not depend on any user data.
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
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          key: const Key('urgent_help_button'),
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.phone_in_talk_rounded, size: 20, color: AppColors.emergencyCrimson),
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

  bool _homeNavCoversHelp() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    return router.state.matchedLocation == RoutePaths.home;
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = !_isOnHelpScreen() && !_homeNavCoversHelp();

    return Stack(
      children: [
        widget.child,
        if (visible)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: UrgentHelpButton(
                  onPressed: () => widget.router.push(RoutePaths.emergency),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

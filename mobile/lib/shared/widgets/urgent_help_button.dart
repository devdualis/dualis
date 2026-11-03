import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/route_paths.dart';
import '../../features/voice/presentation/voice_widgets.dart';
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

/// Tracks popup routes (bottom sheets, dialogs, menus) open on a router's
/// navigator. On /home the bottom bar's emergency entry stands in for the
/// floating help button, but a modal sheet covers that bar; while a popup is
/// open [UrgentHelpOverlay] shows the floating button again so help stays one
/// tap away (claim sheet, profile sheet, family-sharing dialogs).
class PopupRouteTracker extends NavigatorObserver with ChangeNotifier {
  static final Expando<PopupRouteTracker> _byRouter = Expando();

  /// The tracker registered for [router] with [attachTo], if any.
  static PopupRouteTracker? of(GoRouter router) => _byRouter[router];

  final Set<Route<dynamic>> _popups = {};

  void attachTo(GoRouter router) => _byRouter[router] = this;

  bool get hasOpenPopup {
    _popups.removeWhere((r) => !r.isActive);
    return _popups.isNotEmpty;
  }

  void _add(Route<dynamic>? route) {
    if (route is PopupRoute && _popups.add(route)) notifyListeners();
  }

  void _drop(Route<dynamic>? route) {
    if (route != null && _popups.remove(route)) notifyListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _drop(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _drop(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _drop(oldRoute);
    _add(newRoute);
  }
}

/// Wraps the whole app (MaterialApp `builder`) and adds [UrgentHelpButton]
/// below every screen, so it never covers content. Hidden on the help screen
/// itself and while the keyboard is open. On Premium builds the check-in
/// screen also gets the voice mic next to it, and every screen the voice
/// status banner along the top.
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
    _listen(widget.router);
  }

  @override
  void didUpdateWidget(UrgentHelpOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      _unlisten(oldWidget.router);
      _listen(widget.router);
    }
  }

  @override
  void dispose() {
    _unlisten(widget.router);
    super.dispose();
  }

  void _listen(GoRouter router) {
    router.routerDelegate.addListener(_onRouteChanged);
    PopupRouteTracker.of(router)?.addListener(_onRouteChanged);
  }

  void _unlisten(GoRouter router) {
    router.routerDelegate.removeListener(_onRouteChanged);
    PopupRouteTracker.of(router)?.removeListener(_onRouteChanged);
  }

  bool _isOnHelpScreen() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    return router.state.matchedLocation == RoutePaths.emergency;
  }

  /// On /home the bottom bar's emergency entry is the one-tap help, unless a
  /// popup (sheet or dialog) covers it.
  bool _homeNavCoversHelp() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    if (router.state.matchedLocation != RoutePaths.home) return false;
    return !(PopupRouteTracker.of(router)?.hasOpenPopup ?? false);
  }

  bool _onCheckIn() {
    final router = widget.router;
    if (router.routerDelegate.currentConfiguration.isEmpty) return false;
    return router.state.matchedLocation == RoutePaths.journal;
  }

  bool _syncScheduled = false;

  void _onRouteChanged() {
    // The router lives below this widget and may notify while the tree is
    // building, even outside a frame (runApp's first build runs with the
    // scheduler idle), so always rebuild after the current frame.
    if (_syncScheduled) return;
    _syncScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _syncScheduled = false;
        if (mounted) setState(() {});
      })
      ..ensureVisualUpdate();
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
        // Premium hands-free check-in: the mic sits left of the help button,
        // inside the app bar band (that screen has no app bar actions), so
        // it never covers content. Home has its own mic in the app bar.
        if (visible && _onCheckIn())
          const Positioned(
            top: 0,
            right: 64,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: IfProviderScope(child: VoiceMicButton(size: 40)),
              ),
            ),
          ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(64, 10, 64, 0),
              child: Center(child: IfProviderScope(child: VoiceStatusBanner())),
            ),
          ),
        ),
      ],
    );
  }
}

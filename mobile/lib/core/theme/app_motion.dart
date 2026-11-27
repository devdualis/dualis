import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Motion tokens shared by the whole app.
///
/// Keep motion short and calm: people may open the app when they feel bad.
/// Help resources never wait on an animation.
abstract final class AppMotion {
  /// Taps, toggles, small state changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// Page transitions, content swaps.
  static const Duration medium = Duration(milliseconds: 250);

  /// Confirmations and the longest allowed motion.
  static const Duration slow = Duration(milliseconds: 400);

  /// Elements entering or settling.
  static const Curve standard = Curves.easeOutCubic;

  /// Larger moves that start and end at rest.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// A short overshoot for confirmations only.
  static const Curve confirm = Curves.easeOutBack;

  /// Whether the system asks to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or [Duration.zero] when the system asks to reduce motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Fade plus a short upward slide. Used on Android, Linux and Windows; iOS
/// and macOS keep the Cupertino transition and its swipe-back gesture.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.medium;

  @override
  Duration get reverseTransitionDuration => AppMotion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// The app's page transitions per platform.
const appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: AppPageTransitionsBuilder(),
    TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
    TargetPlatform.linux: AppPageTransitionsBuilder(),
    TargetPlatform.windows: AppPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

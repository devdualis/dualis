import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Shrinks [child] a little while a finger is on it and settles back with a
/// short overshoot on release. It only listens to pointers, so the tap still
/// reaches the [InkWell] or button inside. Does nothing when [enabled] is
/// false or the system asks to reduce motion.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  /// Scale while pressed: 0.94 for icons, about 0.97 for cards and rows.
  final double pressedScale;

  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: _pressed ? const Duration(milliseconds: 100) : AppMotion.fast,
        curve: _pressed ? AppMotion.standard : AppMotion.confirm,
        child: widget.child,
      ),
    );
  }
}

/// Plays a short "pop" (1.0, 1.12, 1.0) on [child] each time [selected]
/// turns true. Nothing moves when the system asks to reduce motion.
class SelectPop extends StatefulWidget {
  final bool selected;
  final Widget child;

  const SelectPop({super.key, required this.selected, required this.child});

  @override
  State<SelectPop> createState() => _SelectPopState();
}

class _SelectPopState extends State<SelectPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: AppMotion.standard)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.confirm)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(SelectPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Swaps icons with a quick scale and quarter turn instead of a hard cut.
/// Give each state's child its own [Key] (for example `ValueKey(selected)`).
class IconStateSwitcher extends StatelessWidget {
  final Widget child;

  const IconStateSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      // The overshoot goes on scale only: opacity must stay within 0..1.
      transitionBuilder: (child, animation) {
        final pop = CurvedAnimation(
          parent: animation,
          curve: AppMotion.confirm,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: pop,
          child: RotationTransition(
            turns: Tween(begin: -0.125, end: 0.0).animate(pop),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// Scales [child] in once when it first appears, for marks such as a "saved"
/// check. Static when the system asks to reduce motion.
class PopIn extends StatelessWidget {
  final Widget child;

  const PopIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.confirm,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}

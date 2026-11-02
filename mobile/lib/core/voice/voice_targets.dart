import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/feature_flags.dart';
import 'voice_matcher.dart';

/// Something on screen the person can pick by voice: an option, a button.
class VoiceTargetEntry {
  VoiceTargetEntry._(this._registry, this.order);

  final VoiceTargetRegistry _registry;
  final int order;
  List<String> labels = const [];
  VoidCallback? onSelect;
  ModalRoute<dynamic>? route;
  Object? step;

  /// Only targets of the route on top (not the screens under it or behind
  /// a dialog), of the step on screen (not the one sliding out) and that
  /// can be tapped right now.
  bool get isActive =>
      onSelect != null &&
      (route?.isCurrent ?? true) &&
      (step == null || step == _registry.activeStep);

  void remove() => _registry._targets.remove(this);
}

/// A free-text field on screen; speech that is not a command goes there.
class VoiceTextSinkEntry {
  VoiceTextSinkEntry._(this._registry, this.order);

  final VoiceTargetRegistry _registry;
  final int order;
  ValueChanged<String>? onText;
  ModalRoute<dynamic>? route;
  Object? step;

  bool get isActive =>
      onText != null &&
      (route?.isCurrent ?? true) &&
      (step == null || step == _registry.activeStep);

  void remove() => _registry._sinks.remove(this);
}

/// A match of what was said against the targets on screen.
class VoiceTargetMatch {
  const VoiceTargetMatch(this.entry, this.score, this.label);
  final VoiceTargetEntry entry;
  final double score;
  final String label;
}

/// Everything that can be picked by voice on the screen right now.
class VoiceTargetRegistry {
  final List<VoiceTargetEntry> _targets = [];
  final List<VoiceTextSinkEntry> _sinks = [];
  int _order = 0;

  /// Token of the [VoiceStep] on screen. Targets of another step (one
  /// still animating out) do not answer.
  Object? activeStep;

  VoiceTargetEntry addTarget() {
    final entry = VoiceTargetEntry._(this, _order++);
    _targets.add(entry);
    return entry;
  }

  VoiceTextSinkEntry addSink() {
    final entry = VoiceTextSinkEntry._(this, _order++);
    _sinks.add(entry);
    return entry;
  }

  List<VoiceTargetEntry> get activeTargets =>
      [for (final t in _targets) if (t.isActive) t];

  /// The newest active text field, if any.
  VoiceTextSinkEntry? get activeSink {
    VoiceTextSinkEntry? best;
    for (final s in _sinks) {
      if (s.isActive && (best == null || s.order > best.order)) best = s;
    }
    return best;
  }

  /// Best target for [spoken]; on a tie the newest one wins (the screen
  /// that just slid in, not the one sliding out).
  VoiceTargetMatch? bestMatch(String spoken) {
    VoiceTargetMatch? best;
    for (final t in activeTargets) {
      for (final label in t.labels) {
        final s = VoiceMatcher.score(spoken, label);
        if (s < VoiceMatcher.threshold) continue;
        if (best == null ||
            s > best.score ||
            (s == best.score && t.order > best.entry.order)) {
          best = VoiceTargetMatch(t, s, label);
        }
      }
    }
    return best;
  }
}

final voiceTargetRegistryProvider = Provider<VoiceTargetRegistry>(
  (ref) => VoiceTargetRegistry(),
);

/// Marks the targets of one step. The newest step built is the active
/// one, so targets of a step that is animating out stop answering at once.
class VoiceStep extends StatelessWidget {
  const VoiceStep({super.key, required this.token, required this.child});

  final Object token;
  final Widget child;

  static Object? tokenOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_VoiceStepScope>()?.token;

  @override
  Widget build(BuildContext context) {
    return _VoiceStepScope(token: token, child: child);
  }
}

class _VoiceStepScope extends InheritedWidget {
  const _VoiceStepScope({required this.token, required super.child});

  final Object token;

  @override
  bool updateShouldNotify(_VoiceStepScope oldWidget) => token != oldWidget.token;
}

/// Makes [child] pickable by voice under [labels] (Premium builds only).
/// [onSelect] null means disabled, exactly like a disabled button.
class VoiceTarget extends StatefulWidget {
  const VoiceTarget({
    super.key,
    required this.labels,
    required this.onSelect,
    required this.child,
  });

  final List<String> labels;
  final VoidCallback? onSelect;
  final Widget child;

  @override
  State<VoiceTarget> createState() => _VoiceTargetState();
}

class _VoiceTargetState extends State<VoiceTarget> {
  VoiceTargetEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final container = ProviderScope.containerOf(context, listen: false);
    if (_entry == null && container.read(premiumProfilesEnabledProvider)) {
      _entry = container.read(voiceTargetRegistryProvider).addTarget();
    }
    _entry
      ?..route = ModalRoute.of(context)
      ..step = VoiceStep.tokenOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(VoiceTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final entry = _entry;
    if (entry == null) return;
    entry
      ..labels = widget.labels
      ..onSelect = widget.onSelect;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Marks a free-text field: in voice mode, speech that matches no option
/// or command is handed to [onText] (Premium builds only).
class VoiceTextSink extends StatefulWidget {
  const VoiceTextSink({super.key, required this.onText, required this.child});

  final ValueChanged<String>? onText;
  final Widget child;

  @override
  State<VoiceTextSink> createState() => _VoiceTextSinkState();
}

class _VoiceTextSinkState extends State<VoiceTextSink> {
  VoiceTextSinkEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final container = ProviderScope.containerOf(context, listen: false);
    if (_entry == null && container.read(premiumProfilesEnabledProvider)) {
      _entry = container.read(voiceTargetRegistryProvider).addSink();
    }
    _entry
      ?..route = ModalRoute.of(context)
      ..step = VoiceStep.tokenOf(context);
    _entry?.onText = widget.onText;
  }

  @override
  void didUpdateWidget(VoiceTextSink oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.onText = widget.onText;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

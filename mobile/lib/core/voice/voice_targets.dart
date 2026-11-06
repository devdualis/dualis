import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/feature_flags.dart';
import 'voice_matcher.dart';

/// What a voice target is on screen. Only [option] and [choice] targets are
/// read aloud as answers; the others are actions or hidden duplicates.
enum VoiceTargetRole {
  /// An answer of a multi-select step.
  option,

  /// An answer of a single-choice step (a tap answers and moves on).
  choice,

  /// "Continuar" / "Próximo".
  advance,

  /// "Salvar" / "Só registrar".
  save,

  /// "Voltar".
  back,

  /// "Pular".
  skip,

  /// Anything else: tabs, switches, "+ mais", hidden duplicates.
  other,
}

/// Something on screen the person can pick by voice: an option, a button.
class VoiceTargetEntry {
  VoiceTargetEntry._(this._registry, this.order);

  final VoiceTargetRegistry _registry;
  final int order;
  List<String> labels = const [];
  VoidCallback? onSelect;
  ModalRoute<dynamic>? route;
  Object? step;
  VoiceTargetRole role = VoiceTargetRole.option;

  /// Pressing it saves the entry (a "Bem" card that saves at once). A
  /// multi-answer phrase never presses it; said alone it still works.
  bool saves = false;

  /// Role as seen by a multi-answer phrase: a target that saves counts
  /// as "Salvar", whatever it looks like on screen.
  VoiceTargetRole get carryRole => saves ? VoiceTargetRole.save : role;

  /// Read aloud instead of `labels.first` when set.
  String? spokenLabel;

  /// Its label is something the person wrote (a condition name, an
  /// "Escrever o meu" label): it can be said, but it is never read aloud.
  bool personal = false;

  /// Labels that count in a phrase carried over from an earlier step,
  /// and only when one is all its segment says (filler words aside). The
  /// intensity levels keep their numbers here, so "muito cedo" or "dois
  /// dias" never set a level. Null: [labels], said exactly.
  List<String>? carryLabels;

  /// Only targets of the route on top (not the screens under it or behind
  /// a dialog), of the step on screen (not the one sliding out) and that
  /// can be tapped right now.
  bool get isActive => onSelect != null && isOnStep;

  /// On the route on top and the step on screen, enabled or not.
  bool get isOnStep =>
      (route?.isCurrent ?? true) && (step == null || step == _registry.activeStep);

  void remove() {
    _registry._targets.remove(this);
    _registry._revision++;
  }
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

/// The question of the step on screen, read aloud in the hands-free
/// check-in.
class VoicePromptEntry {
  VoicePromptEntry._(this._registry, this.order);

  final VoiceTargetRegistry _registry;
  final int order;
  String text = '';
  ModalRoute<dynamic>? route;
  Object? step;

  bool get isActive =>
      text.trim().isNotEmpty &&
      (route?.isCurrent ?? true) &&
      (step == null || step == _registry.activeStep);

  void remove() => _registry._prompts.remove(this);
}

/// A match of what was said against the targets on screen.
class VoiceTargetMatch {
  const VoiceTargetMatch(this.entry, this.score, this.label);
  final VoiceTargetEntry entry;
  final double score;
  final String label;
}

/// A target matched by a span of words inside a longer phrase. The words
/// before and after the span are left for other answers.
class VoiceSpanMatch {
  const VoiceSpanMatch(this.entry, this.score, this.label, this.before, this.after);
  final VoiceTargetEntry entry;
  final double score;
  final String label;
  final String before;
  final String after;
}

/// Everything that can be picked by voice on the screen right now.
class VoiceTargetRegistry {
  final List<VoiceTargetEntry> _targets = [];
  final List<VoiceTextSinkEntry> _sinks = [];
  final List<VoicePromptEntry> _prompts = [];
  int _order = 0;
  int _revision = 0;

  /// Longest span of words tried against one label.
  static const int maxSpanWords = 10;

  /// Changes whenever a target is added or removed, changes its labels,
  /// action, role or step, or another step comes on screen. A phrase
  /// carried to the next step waits for it to change.
  int get revision => _revision;

  Object? _activeStep;

  /// Token of the [VoiceStep] on screen. Targets of another step (one
  /// still animating out) do not answer.
  Object? get activeStep => _activeStep;
  set activeStep(Object? token) {
    if (token == _activeStep) return;
    _activeStep = token;
    _revision++;
  }

  VoiceTargetEntry addTarget() {
    final entry = VoiceTargetEntry._(this, _order++);
    _targets.add(entry);
    _revision++;
    return entry;
  }

  VoiceTextSinkEntry addSink() {
    final entry = VoiceTextSinkEntry._(this, _order++);
    _sinks.add(entry);
    return entry;
  }

  VoicePromptEntry addPrompt() {
    final entry = VoicePromptEntry._(this, _order++);
    _prompts.add(entry);
    return entry;
  }

  /// The newest active prompt: the question of the step on screen.
  VoicePromptEntry? get activePrompt {
    VoicePromptEntry? best;
    for (final p in _prompts) {
      if (p.isActive && (best == null || p.order > best.order)) best = p;
    }
    return best;
  }

  /// Answers on screen, in build (reading) order.
  List<VoiceTargetEntry> get readableEntries {
    final entries = [
      for (final t in activeTargets)
        if ((t.role == VoiceTargetRole.option || t.role == VoiceTargetRole.choice) &&
            !t.personal &&
            _readLabel(t).isNotEmpty)
          t,
    ]..sort((a, b) => a.order.compareTo(b.order));
    return entries;
  }

  /// Labels of [readableEntries], as they are read aloud.
  List<String> get readableOptions => [for (final t in readableEntries) _readLabel(t)];

  static String _readLabel(VoiceTargetEntry t) =>
      (t.spokenLabel ?? (t.labels.isEmpty ? '' : t.labels.first)).trim();

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
  /// that just slid in, not the one sliding out). [roles] limits the
  /// targets that may answer.
  VoiceTargetMatch? bestMatch(String spoken, {Set<VoiceTargetRole>? roles}) {
    VoiceTargetMatch? best;
    for (final t in activeTargets) {
      if (roles != null && !roles.contains(t.carryRole)) continue;
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

  /// Best target of [roles] named by a run of consecutive words of
  /// [segment] ("comecou hoje" inside "comecou hoje intensidade tres").
  /// Highest score wins; on a tie the longer run, then the earlier one,
  /// then the newest target. A run never ends on a filler word unless it
  /// is the label as written. With [disabledAdvance], an advance button
  /// that is still disabled also counts (it is enabled by the answer just
  /// given, after the next frame).
  ///
  /// With [carried] (words left from an earlier step) only an exact label
  /// counts, never part of one ("hoje" is not "Começou hoje", "muito" is
  /// not "Muito forte"), and a target with [VoiceTargetEntry.carryLabels]
  /// answers only to those, as a whole segment.
  VoiceSpanMatch? bestSpanMatch(
    String segment,
    Set<VoiceTargetRole> roles, {
    bool disabledAdvance = false,
    bool carried = false,
  }) {
    final words = VoiceMatcher.words(segment);
    if (words.isEmpty) return null;
    final targets = [
      for (final t in _targets)
        if (roles.contains(t.carryRole) &&
            (t.isActive ||
                (disabledAdvance && t.carryRole == VoiceTargetRole.advance && t.isOnStep)))
          t,
    ];
    if (targets.isEmpty) return null;
    VoiceTargetEntry? bestEntry;
    var bestScore = 0.0;
    var bestLabel = '';
    var bestStart = 0;
    var bestEnd = 0;
    for (var start = 0; start < words.length; start++) {
      for (var end = start + 1;
          end <= words.length && end - start <= maxSpanWords;
          end++) {
        final window = words.sublist(start, end).join(' ');
        final endsOnFiller = VoiceMatcher.isFiller(words[end - 1]);
        final alone = words.sublist(0, start).every(VoiceMatcher.isFiller) &&
            words.sublist(end).every(VoiceMatcher.isFiller);
        for (final t in targets) {
          final strict = carried ? t.carryLabels : null;
          if (strict != null && !alone) continue;
          for (final label in strict ?? t.labels) {
            if (endsOnFiller && VoiceMatcher.normalize(label) != window) continue;
            final s = VoiceMatcher.score(window, label);
            if (s < VoiceMatcher.threshold || (carried && s < 1)) continue;
            final length = end - start;
            final bestLength = bestEnd - bestStart;
            final better = bestEntry == null ||
                s > bestScore ||
                (s == bestScore &&
                    (length > bestLength ||
                        (length == bestLength &&
                            (start < bestStart ||
                                (start == bestStart && t.order > bestEntry.order)))));
            if (better) {
              bestEntry = t;
              bestScore = s;
              bestLabel = label;
              bestStart = start;
              bestEnd = end;
            }
          }
        }
      }
    }
    if (bestEntry == null) return null;
    return VoiceSpanMatch(
      bestEntry,
      bestScore,
      bestLabel,
      words.sublist(0, bestStart).join(' '),
      words.sublist(bestEnd).join(' '),
    );
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
    this.role = VoiceTargetRole.option,
    this.saves = false,
    this.spokenLabel,
    this.carryLabels,
    this.personal = false,
    required this.child,
  });

  final List<String> labels;
  final VoidCallback? onSelect;
  final VoiceTargetRole role;

  /// Its action saves the entry: never pressed by a multi-answer phrase.
  final bool saves;

  /// Read aloud instead of the first label (hands-free check-in).
  final String? spokenLabel;

  /// The only labels that count in a carried multi-answer phrase.
  final List<String>? carryLabels;

  /// The label is the person's own text: never read aloud.
  final bool personal;
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
    final entry = _entry;
    if (entry != null) {
      final route = ModalRoute.of(context);
      final step = VoiceStep.tokenOf(context);
      if (route != entry.route || step != entry.step) {
        entry
          ..route = route
          ..step = step;
        entry._registry._revision++;
      }
    }
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
    final changed = !listEquals(entry.labels, widget.labels) ||
        entry.onSelect != widget.onSelect ||
        entry.role != widget.role ||
        entry.saves != widget.saves ||
        !listEquals(entry.carryLabels, widget.carryLabels);
    entry
      ..labels = widget.labels
      ..onSelect = widget.onSelect
      ..role = widget.role
      ..saves = widget.saves
      ..carryLabels = widget.carryLabels
      ..spokenLabel = widget.spokenLabel
      ..personal = widget.personal;
    if (changed) entry._registry._revision++;
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

/// The question of a step, read aloud in the hands-free check-in before
/// listening (Premium builds only). Only the step's own question goes
/// here, never text the person wrote.
class VoicePrompt extends StatefulWidget {
  const VoicePrompt({super.key, required this.text, required this.child});

  final String text;
  final Widget child;

  @override
  State<VoicePrompt> createState() => _VoicePromptState();
}

class _VoicePromptState extends State<VoicePrompt> {
  VoicePromptEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final container = ProviderScope.containerOf(context, listen: false);
    if (_entry == null && container.read(premiumProfilesEnabledProvider)) {
      _entry = container.read(voiceTargetRegistryProvider).addPrompt();
    }
    _entry
      ?..route = ModalRoute.of(context)
      ..step = VoiceStep.tokenOf(context)
      ..text = widget.text;
  }

  @override
  void didUpdateWidget(VoicePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.text = widget.text;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

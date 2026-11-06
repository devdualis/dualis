import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/security/biometric_lock_controller.dart';
import '../../../core/voice/voice_input_service.dart';
import '../../../core/voice/voice_matcher.dart';
import '../../../core/voice/voice_output_service.dart';
import '../../../core/voice/voice_targets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_provider.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../hydration/presentation/controllers/hydration_controller.dart';
import '../../journal/presentation/controllers/journal_flow_state.dart';
import '../../journal/presentation/screens/journal_flow_screen.dart';

enum VoiceFeedbackKind {
  heard,
  noted,
  notUnderstood,
  notHeard,
  permissionDenied,
  unavailable,
  waterLogged,
  waterFailed,
}

@immutable
class VoiceFeedback {
  const VoiceFeedback(this.kind, this.id, [this.text = '']);
  final VoiceFeedbackKind kind;
  final String text;

  /// Changes on every message, so the same text shown twice still animates.
  final int id;
}

@immutable
class VoiceState {
  const VoiceState({
    this.listening = false,
    this.partial = '',
    this.handsFree = false,
    this.dictating = false,
    this.speaking = false,
    this.feedback,
  });

  final bool listening;
  final String partial;

  /// Daily check-in answered by voice: keeps listening after each answer.
  final bool handsFree;

  /// Speech goes to one text field (mic next to the field).
  final bool dictating;

  /// Hands-free check-in: the step's question is being read aloud. The mic
  /// is closed meanwhile.
  final bool speaking;
  final VoiceFeedback? feedback;

  VoiceState copyWith({
    bool? listening,
    String? partial,
    bool? handsFree,
    bool? dictating,
    bool? speaking,
    VoiceFeedback? feedback,
  }) =>
      VoiceState(
        listening: listening ?? this.listening,
        partial: partial ?? this.partial,
        handsFree: handsFree ?? this.handsFree,
        dictating: dictating ?? this.dictating,
        speaking: speaking ?? this.speaking,
        feedback: feedback ?? this.feedback,
      );
}

/// Premium voice commands: picks what is on screen, opens screens, logs a
/// glass of water and dictates text. It never interprets what was said:
/// a phrase either names something the person could tap, or nothing
/// happens. "Ajuda" always opens the help resources, from any screen.
class VoiceController extends Notifier<VoiceState> {
  int _session = 0;
  int _feedbackId = 0;
  int _misses = 0;
  bool _handled = false;
  ValueChanged<String>? _dictationSink;

  /// What was last read aloud in this hands-free run (step, entries), so a
  /// step is read once and not again after a phrase not understood.
  String? _lastReadKey;

  /// Set once text to speech was used, so stopping never wakes the engine
  /// for people who only dictate.
  bool _outputUsed = false;

  /// Gap between the end of the speech and opening the mic, so the mic
  /// never hears the tail of the app's own voice.
  static const Duration speechGap = Duration(milliseconds: 300);

  /// Silences or phrases not understood in a row before hands-free mode
  /// stops by itself (so a TV or a chat in the room never keeps it going).
  static const int maxMisses = 3;

  /// Glass logged by "registrar água".
  static const int glassMl = 250;

  /// Most steps one phrase may go through (multi-answer replays).
  static const int maxCarryPasses = 12;

  /// Roles a multi-answer phrase may pick: answers and "Continuar". Never
  /// "Salvar", "Pular", "Voltar" or anything else, and never a target
  /// whose action saves the entry (see [VoiceTargetEntry.carryRole]).
  static const Set<VoiceTargetRole> carryRoles = {
    VoiceTargetRole.option,
    VoiceTargetRole.choice,
    VoiceTargetRole.advance,
  };

  /// Words of a multi-answer phrase not used yet, tried on the next step
  /// once it is on screen. Bound to [_carryToken] and [_carrySession].
  List<String> _carry = const [];
  int _carryToken = 0;
  int _carrySession = 0;
  int _carryPasses = 0;
  int _carryRevision = 0;
  Object? _carryStep;
  bool _carryAdvance = false;
  final List<String> _carryLabels = [];
  Completer<void>? _carryDone;

  @override
  VoiceState build() {
    // In the background nothing is read and the mic closes.
    final lifecycle = AppLifecycleListener(onPause: stop);
    ref.onDispose(() {
      _session++;
      _clearCarry();
      lifecycle.dispose();
      _watchedRouter?.routerDelegate.removeListener(_onRouteChanged);
      // The output provider stops its own speech when it is disposed.
    });
    // The app lock hides the screens but keeps them mounted: voice must not
    // reach them. Same after signing out.
    ref.listen<bool>(biometricLockControllerProvider.select((s) => s.locked), (_, locked) {
      if (locked) stop();
    });
    ref.listen<bool>(authControllerProvider.select((s) => s.isAuthenticated), (_, signedIn) {
      if (!signedIn) stop();
    });
    return const VoiceState();
  }

  bool get _locked => ref.read(biometricLockControllerProvider).locked;

  VoiceInputService get _service => ref.read(voiceInputServiceProvider);
  VoiceOutputService get _output => ref.read(voiceOutputServiceProvider);
  GoRouter get _router => ref.read(appRouterProvider);
  AppLocalizations get _l10n => lookupAppLocalizations(ref.read(localeProvider));

  bool get _enabled => ref.read(premiumProfilesEnabledProvider);

  String get _location {
    try {
      if (_router.routerDelegate.currentConfiguration.isEmpty) return '';
      return _router.state.matchedLocation;
    } catch (_) {
      return '';
    }
  }

  bool get _onJournal => _location == RoutePaths.journal;

  void _say(VoiceFeedbackKind kind, [String text = '']) {
    state = state.copyWith(feedback: VoiceFeedback(kind, ++_feedbackId, text));
  }

  /// Mic button: start, or stop when listening, reading the question or
  /// between two answers of the hands-free check-in.
  Future<void> toggle() =>
      state.listening || state.speaking || state.handsFree ? stop() : startCommands();

  Future<void> startCommands() async {
    if (!_enabled || _locked) return;
    // Route stops (help, leaving the check-in) also cover the reading.
    _watchRoutes();
    _dictationSink = null;
    _misses = 0;
    _lastReadKey = null;
    state = state.copyWith(handsFree: _onJournal, dictating: false);
    await _listen();
  }

  /// Mic next to a text field: what is said is written into it.
  Future<void> startDictation(ValueChanged<String> onText) async {
    if (!_enabled || _locked) return;
    if (state.listening) await _stopSession();
    _dictationSink = onText;
    _misses = 0;
    state = state.copyWith(handsFree: false, dictating: true);
    await _listen();
  }

  /// The help screen opened (red button or "ajuda"): close the mic and
  /// stop reading at once. Leaving the check-in ends hands-free mode too.
  void _onRouteChanged() {
    final active = state.listening || state.handsFree || state.speaking;
    if (_location == RoutePaths.emergency && active) {
      stop();
    } else if ((state.handsFree || state.speaking) && !_onJournal) {
      stop();
    }
  }

  GoRouter? _watchedRouter;

  void _watchRoutes() {
    final router = _router;
    if (identical(router, _watchedRouter)) return;
    _watchedRouter?.routerDelegate.removeListener(_onRouteChanged);
    _watchedRouter = router;
    router.routerDelegate.addListener(_onRouteChanged);
  }

  Future<void> stop() async {
    // Silence first: help, the lock or sign-out are never talked over
    // while the mic closes.
    final output = _outputUsed ? _stopOutput() : null;
    _clearCarry();
    await _stopSession();
    _dictationSink = null;
    _lastReadKey = null;
    state = state.copyWith(handsFree: false, dictating: false, speaking: false);
    if (output != null) await output;
  }

  Future<void> _stopOutput() async {
    try {
      await _output.stop();
    } catch (_) {}
  }

  Future<void> _stopSession() async {
    _session++;
    state = state.copyWith(listening: false, partial: '', speaking: false);
    try {
      await _service.cancel();
    } catch (_) {}
  }

  Future<void> _listen() async {
    if (_location == RoutePaths.emergency) return;
    _watchRoutes();
    if (state.handsFree && !state.dictating && _onJournal) {
      final session = _session;
      await _readStep();
      if (session != _session) return; // Stopped while reading.
    }
    final error = await _service.prepare();
    if (error != null) {
      state = state.copyWith(listening: false, handsFree: false, dictating: false);
      _say(error == VoiceStartError.permissionDenied
          ? VoiceFeedbackKind.permissionDenied
          : VoiceFeedbackKind.unavailable);
      return;
    }
    final session = ++_session;
    _handled = false;
    var lastPartial = '';
    state = state.copyWith(listening: true, partial: '');
    await _service.listen(
      languageCode: ref.read(localeProvider).languageCode,
      dictation: state.dictating,
      onResult: (text, isFinal) {
        if (session != _session) return;
        lastPartial = text;
        if (!isFinal) {
          state = state.copyWith(partial: text);
          return;
        }
        _endSession(session, text);
      },
      onDone: () {
        if (session != _session) return;
        _endSession(session, lastPartial);
      },
    );
  }

  /// Hands-free check-in: reads the question of the step on screen and up
  /// to [maxReadOptions] of its options, once per step, before listening.
  Future<void> _readStep() async {
    final session = _session;
    final readAloud = await ref.read(voiceReadAloudProvider.notifier).isEnabled();
    if (!readAloud || session != _session || !_onJournal) return;
    final registry = ref.read(voiceTargetRegistryProvider);
    final prompt = registry.activePrompt;
    if (prompt == null) return;
    final entries = registry.readableEntries;
    final key = '${prompt.order}:${[for (final e in entries) e.order].join(',')}';
    if (key == _lastReadKey) return;
    _lastReadKey = key;
    final text = composeReadOut(_l10n, prompt.text, registry.readableOptions);
    _outputUsed = true;
    state = state.copyWith(speaking: true);
    try {
      await _output.prepare(ref.read(localeProvider).languageCode);
      if (session != _session || _location == RoutePaths.emergency) return;
      await _output.speak(text);
    } finally {
      if (session == _session) state = state.copyWith(speaking: false);
    }
    if (session != _session) return;
    await Future<void>.delayed(speechGap);
  }

  void _endSession(int session, String text) {
    if (_handled || session != _session) return;
    _handled = true;
    state = state.copyWith(listening: false, partial: '');
    unawaited(_afterPhrase(text));
  }

  Future<void> _afterPhrase(String text) async {
    final session = _session;
    final keepGoing = await handlePhrase(text);
    // A multi-answer phrase goes on through the next steps first, so the
    // step it stops on is read once.
    final carried = _carryDone;
    if (carried != null) await carried.future;
    if (session != _session) return; // Mic tapped again meanwhile.
    if (keepGoing && state.handsFree && _onJournal && _misses < maxMisses) {
      // Hands-free check-in: listen again while the flow is on screen.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (session != _session) return;
      if (state.handsFree && _onJournal) {
        await _listen();
        return;
      }
    }
    await stop();
  }

  /// Acts on one finished phrase. Returns false when listening must stop
  /// (help opened, "parar", or dictation done). Public for tests.
  Future<bool> handlePhrase(String raw) async {
    // A new phrase replaces whatever an earlier one left to say.
    _clearCarry();
    final text = raw.trim();
    // On the help screen voice does nothing: no "voltar" may close it.
    if (_location == RoutePaths.emergency) return false;
    if (text.isEmpty) {
      // Silence, or the recognizer gave no words: say so, never act.
      _misses++;
      _say(VoiceFeedbackKind.notHeard);
      return true;
    }
    final previousMisses = _misses;
    _misses = 0;
    final l10n = _l10n;
    final helpWords = VoiceMatcher.aliases(l10n.voiceAliasHelp);

    final sink = _dictationSink;
    if (sink != null) {
      // Saying only "ajuda" opens help; anything else is written as said.
      if (VoiceMatcher.bestScore(text, helpWords) == 1) {
        _openHelp();
      } else {
        sink(text);
        _say(VoiceFeedbackKind.noted, text);
      }
      return false;
    }

    if (VoiceMatcher.containsPhrase(text, helpWords)) {
      _openHelp();
      return false;
    }
    // Locked: only help, nothing on the hidden screens.
    if (_locked) return false;
    if (VoiceMatcher.bestScore(text, VoiceMatcher.aliases(l10n.voiceAliasStop)) >=
        VoiceMatcher.strong) {
      return false;
    }

    final registry = ref.read(voiceTargetRegistryProvider);
    final best = registry.bestMatch(text);
    // Said exactly as written: that option, even if its label has an "e".
    if (best != null && best.score == 1) {
      _select(best);
      return true;
    }
    // "Cansado e ansioso, começou hoje, intensidade três": one phrase that
    // answers this step and the next ones (daily check-in only).
    if (_onJournal) {
      final segments = [
        for (final s in VoiceMatcher.phraseSegments(text))
          if (!VoiceMatcher.isFillerOnly(s)) s,
      ];
      if (segments.length > 1) return _multiAnswer(text, segments, previousMisses);
      // Recognizers rarely return commas: one run of words that names an
      // answer here and still has words for the next steps.
      if (segments.length == 1 && _carriesMore(registry, segments.single)) {
        return _multiAnswer(text, segments, previousMisses);
      }
    }
    // "Cansado e ansioso": several options in one answer.
    final parts = VoiceMatcher.segments(text);
    if (parts.length > 1) {
      final matches = [for (final p in parts) registry.bestMatch(p)];
      final entries = {for (final m in matches) m?.entry};
      if (!entries.contains(null) && entries.length > 1) {
        for (final entry in entries) {
          entry!.onSelect?.call();
        }
        _say(VoiceFeedbackKind.heard, [for (final m in matches) m!.label].join(', '));
        return true;
      }
    }
    if (best != null) {
      _select(best);
      return true;
    }

    if (await _globalCommand(text, l10n)) return !_leftJournalHandsFree();

    final textSink = registry.activeSink;
    if (textSink != null) {
      textSink.onText?.call(text);
      _say(VoiceFeedbackKind.noted, text);
      return true;
    }
    _misses = previousMisses + 1;
    _say(VoiceFeedbackKind.notUnderstood, text);
    return true;
  }

  bool _leftJournalHandsFree() => state.handsFree && !_onJournal;

  /// Content words a single phrase must keep after this step's answer to
  /// go on to the next steps ("cansado começou hoje"), so a short extra
  /// word ("cansada demais") keeps the plain one-answer behavior.
  static const int minCarryWords = 2;

  bool _carriesMore(VoiceTargetRegistry registry, String segment) {
    final match = registry.bestSpanMatch(segment, carryRoles);
    if (match == null) return false;
    final rest = VoiceMatcher.words('${match.before} ${match.after}');
    return rest.where((w) => !VoiceMatcher.isFiller(w)).length >= minCarryWords;
  }

  /// Several answers in one phrase. The step on screen takes what it can;
  /// the rest waits for the next step. Nothing is pressed but answers and
  /// "Continuar", and "Continuar" only after this step took an answer.
  bool _multiAnswer(String text, List<String> segments, int previousMisses) {
    final registry = ref.read(voiceTargetRegistryProvider);
    final pass = _consumeStep(registry, segments);
    if (pass.labels.isEmpty) {
      // Nothing on this step was named: the whole phrase as before, but
      // never "Salvar", "Pular" or "Voltar" (dictation into the note).
      final match = registry.bestMatch(text, roles: carryRoles);
      if (match != null) {
        _select(match);
        return true;
      }
      final textSink = registry.activeSink;
      if (textSink != null) {
        textSink.onText?.call(text);
        _say(VoiceFeedbackKind.noted, text);
        return true;
      }
      _misses = previousMisses + 1;
      _say(VoiceFeedbackKind.notUnderstood, text);
      return true;
    }
    _carryToken++;
    _carrySession = _session;
    _carryPasses = 1;
    _carryDone = Completer<void>();
    _afterPass(registry, pass);
    return true;
  }

  /// Walks [segments] in order on the step on screen. Stops after an
  /// answer that moves the flow on (a single choice, "Continuar").
  /// [carried]: words left from an earlier step, which only pick what they
  /// name exactly (an intensity only by its number).
  _CarryPass _consumeStep(
    VoiceTargetRegistry registry,
    List<String> segments, {
    bool carried = false,
  }) {
    final queue = [...segments];
    final leftover = <String>[];
    final labels = <String>[];
    final picked = <VoiceTargetEntry>{};
    var movedOn = false;
    var advance = false;
    while (queue.isNotEmpty) {
      final segment = queue.removeAt(0);
      if (movedOn) {
        leftover.add(segment);
        continue;
      }
      final match = registry.bestSpanMatch(
        segment,
        carryRoles,
        disabledAdvance: true,
        carried: carried,
      );
      if (match == null) {
        leftover.add(segment);
        continue;
      }
      final entry = match.entry;
      if (entry.carryRole == VoiceTargetRole.advance) {
        movedOn = true;
        // "Continuar" said after an answer is still disabled until the
        // next frame: pressed then.
        if (entry.onSelect == null) {
          advance = true;
        } else {
          entry.onSelect!.call();
          labels.add(match.label);
        }
      } else if (entry.selected) {
        // Already marked (a tap, an earlier phrase): kept as it is, never
        // pressed again, since that would take it off.
        if (picked.add(entry)) labels.add(match.label);
      } else {
        // The same option named twice is picked once, never toggled off.
        if (picked.add(entry)) {
          entry.onSelect?.call();
          labels.add(match.label);
        }
        if (entry.role == VoiceTargetRole.choice) movedOn = true;
      }
      queue.insertAll(0, [
        if (match.before.isNotEmpty && !VoiceMatcher.isFillerOnly(match.before)) match.before,
        if (match.after.isNotEmpty && !VoiceMatcher.isFillerOnly(match.after)) match.after,
      ]);
    }
    final implicit = !movedOn && leftover.isNotEmpty && labels.isNotEmpty;
    return _CarryPass(
      labels: labels,
      leftover: leftover,
      advance: advance || implicit,
      implicitAdvance: implicit,
    );
  }

  /// After a pass that took answers: say what was heard, then wait for the
  /// next frame to go on with what is left.
  void _afterPass(VoiceTargetRegistry registry, _CarryPass pass) {
    _carryLabels.addAll(pass.labels);
    if (_carryLabels.isNotEmpty) {
      _say(VoiceFeedbackKind.heard, _carryLabels.join(', '));
    }
    _carry = pass.leftover;
    if (_carry.isEmpty) {
      _finishCarry();
      return;
    }
    // Words that name "Salvar", "Pular", "Voltar" or another button of this
    // step were meant for this step: never pressed, and the flow does not
    // move on without the person.
    if (pass.implicitAdvance && _namesOtherButton(registry, _carry)) {
      _notUnderstoodCarry();
      return;
    }
    _carryAdvance = pass.advance;
    _carryStep = registry.activeStep;
    _carryRevision = registry.revision;
    _scheduleReplay();
  }

  bool _namesOtherButton(VoiceTargetRegistry registry, List<String> segments) {
    const others = {
      VoiceTargetRole.save,
      VoiceTargetRole.skip,
      VoiceTargetRole.back,
      VoiceTargetRole.other,
    };
    return segments.any((s) => registry.bestSpanMatch(s, others) != null);
  }

  void _scheduleReplay() {
    final token = _carryToken;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _replay(token))
      ..ensureVisualUpdate();
  }

  /// Next frame of a multi-answer phrase. An answer that throws ends the
  /// phrase as not understood, so hands-free never waits on it forever.
  void _replay(int token) {
    try {
      _replayStep(token);
    } catch (error) {
      debugPrint('Voice: multi-answer replay failed: $error');
      if (token == _carryToken && _carryDone != null) _notUnderstoodCarry();
    }
  }

  /// Presses "Continuar" if the last pass asked for it, or tries what is
  /// left on the step now on screen.
  void _replayStep(int token) {
    if (token != _carryToken || _carryDone == null) return;
    if (_carrySession != _session ||
        !_onJournal ||
        _locked ||
        _location == RoutePaths.emergency) {
      _clearCarry();
      return;
    }
    final registry = ref.read(voiceTargetRegistryProvider);
    if (_carryAdvance) {
      _carryAdvance = false;
      if (registry.activeStep == _carryStep) {
        VoiceTargetEntry? advance;
        for (final t in registry.activeTargets) {
          if (t.carryRole == VoiceTargetRole.advance) advance = t;
        }
        if (advance == null) {
          _notUnderstoodCarry();
          return;
        }
        advance.onSelect!.call();
        _carryRevision = registry.revision;
        _scheduleReplay();
        return;
      }
    }
    if (registry.revision == _carryRevision || _carryPasses >= maxCarryPasses) {
      _notUnderstoodCarry();
      return;
    }
    _carryPasses++;
    final pass = _consumeStep(registry, _carry, carried: true);
    if (pass.labels.isEmpty && !pass.advance) {
      _notUnderstoodCarry();
      return;
    }
    _afterPass(registry, pass);
  }

  /// What is left of the phrase matched nothing: say so with those words.
  /// What was already picked stays.
  void _notUnderstoodCarry() {
    _say(VoiceFeedbackKind.notUnderstood, _carry.join(', '));
    _finishCarry();
  }

  void _finishCarry() {
    _carry = const [];
    _carryAdvance = false;
    _carryStep = null;
    _carryLabels.clear();
    final done = _carryDone;
    _carryDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  /// Drops a pending multi-answer phrase (new phrase, stop, help, lock,
  /// sign-out, leaving the check-in).
  void _clearCarry() {
    _carryToken++;
    _finishCarry();
  }

  void _select(VoiceTargetMatch match) {
    match.entry.onSelect?.call();
    _say(VoiceFeedbackKind.heard, match.label);
  }

  void _openHelp() {
    _clearCarry();
    if (_location != RoutePaths.emergency) _push(RoutePaths.emergency);
  }

  /// Opens a screen without waiting for it to close.
  void _push(String location, {Object? extra}) =>
      unawaited(_router.push(location, extra: extra));

  /// App-wide commands. Inside the check-in only "voltar" applies, so a
  /// word like "água" in an answer never leaves the flow half done.
  Future<bool> _globalCommand(String text, AppLocalizations l10n) async {
    double score(String aliases) =>
        VoiceMatcher.bestScore(text, VoiceMatcher.aliases(aliases));

    if (_onJournal) return false;

    final commands = <(double, Future<void> Function())>[
      (score(l10n.voiceAliasLogWater), _logWater),
      (score(l10n.voiceAliasJournalEmotional),
          () async => _push(RoutePaths.journal,
              extra: const JournalFlowArgs(initialArea: JournalArea.emotional))),
      (score(l10n.voiceAliasJournalPhysical),
          () async => _push(RoutePaths.journal,
              extra: const JournalFlowArgs(initialArea: JournalArea.physical))),
      (score(l10n.voiceAliasHistory), () async => _push(RoutePaths.history)),
      (score(l10n.voiceAliasHydration), () async => _push(RoutePaths.hydration)),
      (score(l10n.voiceAliasHabits), () async => _push(RoutePaths.habits)),
      (score(l10n.voiceAliasSettings), () async => _push(RoutePaths.settings)),
      (score(l10n.voiceAliasLibrary), () async => _push(RoutePaths.library)),
      (score(l10n.voiceAliasHome), () async => _router.go(RoutePaths.home)),
      (score(l10n.voiceAliasBack), () async {
        if (_router.canPop()) _router.pop();
      }),
    ];
    var bestScore = 0.0;
    Future<void> Function()? bestAction;
    for (final (s, action) in commands) {
      if (s > bestScore) {
        bestScore = s;
        bestAction = action;
      }
    }
    if (bestAction == null || bestScore < VoiceMatcher.threshold) return false;
    await bestAction();
    if (bestAction != _logWater) _say(VoiceFeedbackKind.heard, text);
    return true;
  }

  Future<void> _logWater() async {
    final hydration = ref.read(hydrationControllerProvider.notifier);
    if (!ref.read(hydrationControllerProvider).settings.trackingEnabled) {
      _push(RoutePaths.hydration);
      return;
    }
    final ok = await hydration.logWater(amountMl: glassMl, source: 'voice');
    _say(ok ? VoiceFeedbackKind.waterLogged : VoiceFeedbackKind.waterFailed);
  }
}

final voiceControllerProvider =
    NotifierProvider<VoiceController, VoiceState>(VoiceController.new);

/// What one step took from a multi-answer phrase.
class _CarryPass {
  const _CarryPass({
    required this.labels,
    required this.leftover,
    required this.advance,
    required this.implicitAdvance,
  });

  /// Labels of the answers picked, for the "heard" feedback.
  final List<String> labels;

  /// Segments not used, in phrase order.
  final List<String> leftover;

  /// "Continuar" is pressed on the next frame (said while still disabled,
  /// or words are left after this step took its answers).
  final bool advance;

  /// [advance] comes from words left over, not from "Continuar" said.
  final bool implicitAdvance;
}

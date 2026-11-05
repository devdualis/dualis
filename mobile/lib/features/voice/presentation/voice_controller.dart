import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/security/biometric_lock_controller.dart';
import '../../../core/voice/voice_input_service.dart';
import '../../../core/voice/voice_matcher.dart';
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
    this.feedback,
  });

  final bool listening;
  final String partial;

  /// Daily check-in answered by voice: keeps listening after each answer.
  final bool handsFree;

  /// Speech goes to one text field (mic next to the field).
  final bool dictating;
  final VoiceFeedback? feedback;

  VoiceState copyWith({
    bool? listening,
    String? partial,
    bool? handsFree,
    bool? dictating,
    VoiceFeedback? feedback,
  }) =>
      VoiceState(
        listening: listening ?? this.listening,
        partial: partial ?? this.partial,
        handsFree: handsFree ?? this.handsFree,
        dictating: dictating ?? this.dictating,
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

  /// Silences or phrases not understood in a row before hands-free mode
  /// stops by itself (so a TV or a chat in the room never keeps it going).
  static const int maxMisses = 3;

  /// Glass logged by "registrar água".
  static const int glassMl = 250;

  @override
  VoiceState build() {
    ref.onDispose(() {
      _session++;
      _watchedRouter?.routerDelegate.removeListener(_onRouteChanged);
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

  /// Mic button: start, or stop when already listening.
  Future<void> toggle() => state.listening ? stop() : startCommands();

  Future<void> startCommands() async {
    if (!_enabled || _locked) return;
    _dictationSink = null;
    _misses = 0;
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

  /// The help screen opened (red button or "ajuda"): close the mic at once.
  void _onRouteChanged() {
    if (_location == RoutePaths.emergency && (state.listening || state.handsFree)) {
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
    await _stopSession();
    _dictationSink = null;
    state = state.copyWith(handsFree: false, dictating: false);
  }

  Future<void> _stopSession() async {
    _session++;
    state = state.copyWith(listening: false, partial: '');
    try {
      await _service.cancel();
    } catch (_) {}
  }

  Future<void> _listen() async {
    if (_location == RoutePaths.emergency) return;
    _watchRoutes();
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

  void _endSession(int session, String text) {
    if (_handled || session != _session) return;
    _handled = true;
    state = state.copyWith(listening: false, partial: '');
    unawaited(_afterPhrase(text));
  }

  Future<void> _afterPhrase(String text) async {
    final session = _session;
    final keepGoing = await handlePhrase(text);
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

  void _select(VoiceTargetMatch match) {
    match.entry.onSelect?.call();
    _say(VoiceFeedbackKind.heard, match.label);
  }

  void _openHelp() {
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

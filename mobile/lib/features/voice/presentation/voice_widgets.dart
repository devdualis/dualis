import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'voice_controller.dart';

/// Voice works only on Premium builds and for a signed-in person.
bool voiceAvailable(WidgetRef ref) =>
    ref.watch(premiumProfilesEnabledProvider) &&
    ref.watch(authControllerProvider.select((s) => s.isAuthenticated));

/// Renders [child] only under a ProviderScope. The help overlay uses it so
/// the help button never depends on the voice feature being set up.
class IfProviderScope extends StatelessWidget {
  const IfProviderScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
      return child;
    } on StateError {
      return const SizedBox.shrink();
    }
  }
}

/// Round mic button for voice commands. Renders nothing on Free builds.
class VoiceMicButton extends ConsumerWidget {
  const VoiceMicButton({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!voiceAvailable(ref)) return const SizedBox.shrink();
    final voice = ref.watch(voiceControllerProvider);
    final active = voice.listening && !voice.dictating;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      toggled: active,
      label: active ? l10n.voiceStopTooltip : l10n.voiceButtonTooltip,
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.dualisSymbolBlue : AppColors.surfaceLight,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.dualisSymbolBlue.withValues(alpha: 0.35)),
        ),
        elevation: 3,
        child: InkWell(
          key: const Key('voice_mic_button'),
          customBorder: const CircleBorder(),
          onTap: () => ref.read(voiceControllerProvider.notifier).toggle(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              active ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: size * 0.48,
              color: active ? Colors.white : AppColors.dualisSymbolBlue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mic inside a text field: dictates into [controller].
class VoiceDictationButton extends ConsumerWidget {
  const VoiceDictationButton({
    super.key,
    required this.controller,
    this.onChanged,
    this.fieldKey = 'field',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// Suffix for the widget key, so tests can find each field's mic.
  final String fieldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!voiceAvailable(ref)) return const SizedBox.shrink();
    final voice = ref.watch(voiceControllerProvider);
    final l10n = AppLocalizations.of(context);
    final active = voice.listening && voice.dictating;
    return IconButton(
      key: Key('voice_dictate_$fieldKey'),
      tooltip: active ? l10n.voiceStopTooltip : l10n.voiceDictate,
      icon: Icon(
        active ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: AppColors.dualisSymbolBlue,
      ),
      onPressed: () {
        final notifier = ref.read(voiceControllerProvider.notifier);
        if (active) {
          notifier.stop();
          return;
        }
        notifier.startDictation((text) {
          appendDictation(controller, text);
          onChanged?.call(controller.text);
        });
      },
    );
  }
}

/// Adds dictated [text] after what is already in the field, respecting
/// the field's own length limit through its formatters on the next edit.
void appendDictation(TextEditingController controller, String text) {
  final current = controller.text.trimRight();
  final next = current.isEmpty ? text : '$current $text';
  controller.value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
}

/// "Ouvindo…" with what is being heard, then a short note of what was
/// understood. Drawn above every screen, below the status bar.
class VoiceStatusBanner extends ConsumerStatefulWidget {
  const VoiceStatusBanner({super.key});

  @override
  ConsumerState<VoiceStatusBanner> createState() => _VoiceStatusBannerState();
}

class _VoiceStatusBannerState extends ConsumerState<VoiceStatusBanner> {
  Timer? _hide;
  VoiceFeedback? _shown;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  String _feedbackText(AppLocalizations l10n, VoiceFeedback f) => switch (f.kind) {
        VoiceFeedbackKind.heard => l10n.voiceHeard(f.text),
        VoiceFeedbackKind.noted => l10n.voiceNoted,
        VoiceFeedbackKind.notUnderstood => l10n.voiceNotUnderstood(f.text),
        VoiceFeedbackKind.notHeard => l10n.voiceNotHeard,
        VoiceFeedbackKind.permissionDenied => l10n.voicePermissionDenied,
        VoiceFeedbackKind.unavailable => l10n.voiceUnavailable,
        VoiceFeedbackKind.waterLogged => l10n.voiceWaterLogged,
        VoiceFeedbackKind.waterFailed => l10n.voiceWaterFailed,
      };

  @override
  Widget build(BuildContext context) {
    if (!voiceAvailable(ref)) return const SizedBox.shrink();
    final voice = ref.watch(voiceControllerProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen(voiceControllerProvider.select((s) => s.feedback), (_, next) {
      if (next == null) return;
      _hide?.cancel();
      setState(() => _shown = next);
      _hide = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _shown = null);
      });
    });

    String? text;
    var listening = false;
    if (voice.listening) {
      listening = true;
      final lead = voice.handsFree ? l10n.voiceListeningHandsFree : l10n.voiceListening;
      text = voice.partial.isEmpty ? lead : '${l10n.voiceListening} ${voice.partial}';
    } else if (_shown != null) {
      text = _feedbackText(l10n, _shown!);
    }

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: text == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                child: Container(
                  key: const Key('voice_status_banner'),
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.dualisNavy.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        listening ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
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

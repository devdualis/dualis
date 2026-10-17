import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time feature flags.
///
/// Premium (v2) features stay off in the 1.0 store build. Enable them with
/// `--dart-define=PREMIUM_FEATURES=true` (e2e and internal builds).
class FeatureFlags {
  static const bool premiumProfiles =
      bool.fromEnvironment('PREMIUM_FEATURES', defaultValue: false);
}

/// Overridable in tests: `premiumProfilesEnabledProvider.overrideWithValue(true)`.
final premiumProfilesEnabledProvider =
    Provider<bool>((ref) => FeatureFlags.premiumProfiles);

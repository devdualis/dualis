import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config_service.dart';
import 'app_update_required_screen.dart';

/// Wrap the app root to block outdated builds when the backend requires an update.
class AppVersionGate extends ConsumerWidget {
  final Widget child;

  const AppVersionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appVersionGateProvider);

    return gate.when(
      loading: () => child,
      error: (_, __) => child,
      data: (state) {
        if (state.status == AppVersionGateStatus.updateRequired) {
          return AppUpdateRequiredScreen(
            minSupportedVersion: state.minSupportedVersion,
          );
        }
        return child;
      },
    );
  }
}

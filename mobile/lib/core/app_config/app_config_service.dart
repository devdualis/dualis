import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'app_config_api_paths.dart';
import 'app_config_models.dart';
import 'app_semver.dart';

enum AppVersionGateStatus {
  checking,
  allowed,
  updateRequired,
}

class AppVersionGateState {
  final AppVersionGateStatus status;
  final String? minSupportedVersion;

  const AppVersionGateState({
    required this.status,
    this.minSupportedVersion,
  });

  static const checking = AppVersionGateState(status: AppVersionGateStatus.checking);
  static const allowed = AppVersionGateState(status: AppVersionGateStatus.allowed);
}

final appVersionGateProvider =
    AsyncNotifierProvider<AppVersionGateNotifier, AppVersionGateState>(
  AppVersionGateNotifier.new,
);

class AppVersionGateNotifier extends AsyncNotifier<AppVersionGateState> {
  @override
  Future<AppVersionGateState> build() async {
    return _evaluate();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _evaluate());
  }

  Future<AppVersionGateState> _evaluate() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(
        AppConfigApiPaths.config,
        options: Options(extra: const {'skipAuthRefresh': true}),
      );
      if (response.data is! Map<String, dynamic>) {
        return AppVersionGateState.allowed;
      }
      final config = RemoteAppConfig.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (isAppVersionBelowMinimum(kInstalledAppSemver, config.minSupportedVersion)) {
        return AppVersionGateState(
          status: AppVersionGateStatus.updateRequired,
          minSupportedVersion: config.minSupportedVersion,
        );
      }
      return AppVersionGateState.allowed;
    } catch (_) {
      return AppVersionGateState.allowed;
    }
  }
}

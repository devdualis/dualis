import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnlineStream;
});

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool _isOnlineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnlineFromResults(results);
    } catch (_) {
      return false;
    }
  }

  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.map(_isOnlineFromResults);
  }
}

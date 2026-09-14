import 'package:flutter/widgets.dart';

typedef OnLockStateChanged = void Function(bool isLocked);

class AppLifecycleObserver with WidgetsBindingObserver {
  final OnLockStateChanged onLockStateChanged;
  bool _isLocked = false;
  DateTime? _lastPausedTime;

  AppLifecycleObserver({required this.onLockStateChanged});

  bool get isLocked => _isLocked;
  DateTime? get lastPausedTime => _lastPausedTime;

  void lock() {
    if (!_isLocked) {
      _isLocked = true;
      onLockStateChanged(true);
    }
  }

  void unlock() {
    if (_isLocked) {
      _isLocked = false;
      onLockStateChanged(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _lastPausedTime = DateTime.now();
        lock();
        break;
      case AppLifecycleState.resumed:
        // App resumed; remains locked until unlocked via biometric or passcode
        break;
      case AppLifecycleState.detached:
        break;
    }
  }
}

import 'dart:async';

import '../api/device_api.dart';
import '../models/device_state.dart';
import 'signal_monitor.dart';

class StatePoller {
  final DeviceApi api;
  final void Function(DeviceState) onUpdate;
  final void Function()? onOffline;
  Timer? _timer;
  bool _running = false;
  int _failures = 0;
  Duration _interval = const Duration(milliseconds: 200);

  StatePoller({
    required this.api,
    required this.onUpdate,
    this.onOffline,
  });

  void start({Duration interval = const Duration(milliseconds: 200)}) {
    _interval = interval;
    stop();
    _timer = Timer.periodic(_interval, (_) => _tick());
    // Trigger an immediate poll so the UI updates without waiting a full interval.
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      final st = await api.fetchState();
      if (st != null) {
        _failures = 0;
        onUpdate(st);
        SignalMonitor.I.pushRx(st.y);
      } else {
        _handleFailure();
      }
    } catch (_) {
      _handleFailure();
    } finally {
      _running = false;
    }
  }

  void _handleFailure() {
    _failures++;
    if (_failures == 1 || _failures % 10 == 0) {
      onOffline?.call();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _failures = 0;
  }
}

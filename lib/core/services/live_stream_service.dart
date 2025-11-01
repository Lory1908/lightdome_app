import 'dart:async';

import '../api/device_api.dart';
import 'signal_monitor.dart';

class LiveStreamService {
  final DeviceApi api;
  Timer? _timer;
  double? _pendingY; // 0..1
  bool _sending = false;

  LiveStreamService(this.api);

  void setY(double y01) {
    _pendingY = y01.clamp(0.0, 1.0);
    // Push immediately for scope feedback, even before HTTP returns.
    try {
      SignalMonitor.I.pushTx(_pendingY!);
    } catch (_) {}
    _ensurePump();
  }

  void _ensurePump() {
    _timer ??= Timer(const Duration(milliseconds: 16), _pump);
  }

  Future<void> _pump() async {
    _timer = null;
    if (_pendingY == null) return;
    if (_sending) {
      _ensurePump();
      return;
    }
    final y = _pendingY!;
    _pendingY = null;
    _sending = true;
    try {
      await api.setY(y);
    } catch (_) {
      // Ignore failures here; the poller will mark the device offline if needed.
    } finally {
      _sending = false;
    }
    try {
      SignalMonitor.I.pushTx(y);
    } catch (_) {}
    if (_pendingY != null) {
      _ensurePump();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

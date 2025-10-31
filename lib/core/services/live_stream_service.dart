import 'dart:async';

import '../api/device_api.dart';

class LiveStreamService {
  final DeviceApi api;
  Timer? _timer;
  double? _pendingY; // 0..1
  bool _sending = false;

  LiveStreamService(this.api);

  void setY(double y01) {
    _pendingY = y01.clamp(0.0, 1.0);
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_pendingY == null || _sending) return;
    final y = _pendingY!;
    _pendingY = null;
    _sending = true;
    try {
      await api.setY(y);
    } finally {
      _sending = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}


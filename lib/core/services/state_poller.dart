import 'dart:async';

import '../api/device_api.dart';
import '../models/device_state.dart';

class StatePoller {
  final DeviceApi api;
  final void Function(DeviceState) onUpdate;
  Timer? _timer;

  StatePoller({required this.api, required this.onUpdate});

  void start({Duration interval = const Duration(milliseconds: 200)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final st = await api.fetchState();
      if (st != null) onUpdate(st);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}


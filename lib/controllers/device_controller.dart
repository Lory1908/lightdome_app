import 'package:flutter/foundation.dart';

import '../core/api/device_api.dart';
import '../core/models/device_state.dart';
import '../core/services/live_stream_service.dart';
import '../core/services/state_poller.dart';

class DeviceController extends ChangeNotifier {
  static final DeviceController I = DeviceController._();
  DeviceController._();

  String _ip = '';
  DeviceApi? _api;
  LiveStreamService? _live;
  StatePoller? _poller;

  DeviceState state = DeviceState.initial();

  String get ip => _ip;
  bool get isConnected => _api != null;

  void setIp(String ip) {
    _ip = ip.trim();
    if (_ip.isEmpty) {
      disconnect();
      return;
    }
    final base = _ip.startsWith('http') ? _ip : 'http://$_ip';
    _api = DeviceApi(base);
    _live = LiveStreamService(_api!);
    _poller?.stop();
    _poller = StatePoller(api: _api!, onUpdate: (s) {
      state = s;
      notifyListeners();
    })
      ..start();
    notifyListeners();
  }

  void disconnect() {
    _poller?.stop();
    _poller = null;
    _live?.dispose();
    _live = null;
    _api = null;
    state = DeviceState.initial();
    notifyListeners();
  }

  Future<void> refreshOnce() async {
    final api = _api;
    if (api == null) return;
    final st = await api.fetchState();
    if (st != null) {
      state = st;
      notifyListeners();
    }
  }

  void sendY(double y01) {
    _live?.setY(y01);
  }

  Future<void> off() async {
    await _api?.off();
    await refreshOnce();
  }

  Future<void> setParams({double? brightnessPct, double? gamma, bool? loop}) async {
    await _api?.setParams(brightnessPct: brightnessPct, gamma: gamma, loop: loop);
    await refreshOnce();
  }

  Future<List<String>> listPrograms() async {
    final api = _api;
    if (api == null) return [];
    return api.listPrograms();
  }

  Future<void> startProgram(String name) async {
    await _api?.startProgram(name);
  }

  Future<void> stopProgram() async {
    await _api?.stopProgram();
  }

  Future<void> deleteProgram(String name) async {
    await _api?.deleteProgram(name);
  }
}


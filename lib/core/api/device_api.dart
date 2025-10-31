import 'dart:convert';

import '../models/device_state.dart';
import 'http_client.dart';

class DeviceApi {
  final String base; // e.g. http://192.168.1.50
  const DeviceApi(this.base);

  String _u(String path) => base.endsWith('/') ? '${base.substring(0, base.length - 1)}$path' : '$base$path';

  Future<DeviceState?> fetchState() async {
    try {
      final j = await getJson(_u('/api/state'));
      return DeviceState.fromApiJson(j);
    } catch (_) {
      try {
        final j = await getJson(_u('/status'));
        return DeviceState.fromStatusJson(j);
      } catch (e) {
        return null;
      }
    }
  }

  Future<void> setY(double y01) async {
    // Prefer legacy GET /set for immediate response and compatibility
    final y1023 = (y01.clamp(0.0, 1.0) * 1023).round();
    await getText(_u('/set?y=$y1023'));
  }

  Future<void> off() async {
    await getText(_u('/set?y=0'));
  }

  Future<void> setParams({double? brightnessPct, double? gamma, bool? loop}) async {
    final q = <String, String>{};
    if (brightnessPct != null) q['brightness'] = brightnessPct.clamp(0, 100).toStringAsFixed(0);
    if (gamma != null) q['gamma'] = gamma.clamp(1.0, 3.0).toStringAsFixed(1);
    if (loop != null) q['loop'] = loop ? '1' : '0';
    if (q.isEmpty) return;
    final qs = q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    await getText(_u('/params?$qs'));
  }

  // Programs (basic)
  Future<List<String>> listPrograms() async {
    try {
      final txt = await getText(_u('/prog/list'));
      final lines = const LineSplitter().convert(txt);
      return lines
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != '(vuoto)')
          .map((e) => e.replaceAll('.ldy', '').split(' ').first)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> startProgram(String name) async {
    await postJson(_u('/prog/start?name=${Uri.encodeComponent(name)}'), {});
  }

  Future<void> stopProgram() async {
    await postJson(_u('/prog/stop'), {});
  }

  Future<void> deleteProgram(String name) async {
    await deleteText(_u('/prog/delete?name=${Uri.encodeComponent(name)}'));
  }
}


import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/device_state.dart';

class RealtimeService {
  final WebSocketChannel _channel;
  final StreamSubscription _sub;
  final VoidCallback? _onDisconnected;

  RealtimeService._(this._channel, this._sub, this._onDisconnected);

  static Future<RealtimeService?> connect({
    required String baseUrl,
    required void Function(DeviceState) onState,
    void Function(double tx)? onTx,
    VoidCallback? onDisconnected,
  }) async {
    final attempts = _buildCandidateUris(baseUrl);
    for (final uri in attempts) {
      try {
        final channel = WebSocketChannel.connect(uri);
        final svc = _attach(
          channel: channel,
          onState: onState,
          onTx: onTx,
          onDisconnected: onDisconnected,
        );
        return svc;
      } catch (_) {
        // Try next candidate.
      }
    }
    return null;
  }

  static List<Uri> _buildCandidateUris(String base) {
    final normalized = base.trim().isEmpty
        ? ''
        : (base.endsWith('/') ? base.substring(0, base.length - 1) : base);
    Uri uri;
    try {
      uri = Uri.parse(normalized);
    } catch (_) {
      return const [];
    }
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final List<String> baseSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    Uri buildUri(String tail) {
      final tailSegments = tail.split('/').where((s) => s.isNotEmpty);
      return uri.replace(
        scheme: scheme,
        pathSegments: [...baseSegments, ...tailSegments],
        query: '',
        fragment: '',
      );
    }

    return [buildUri('api/ws'), buildUri('api/stream'), buildUri('ws')];
  }

  static RealtimeService _attach({
    required WebSocketChannel channel,
    required void Function(DeviceState) onState,
    required void Function(double tx)? onTx,
    VoidCallback? onDisconnected,
  }) {
    final sub = channel.stream.listen(
      (event) {
        final map = _parseEvent(event);
        if (map == null) return;
        final handled = _handleMessage(map, onState: onState, onTx: onTx);
        if (!handled && map.containsKey('state') && map['state'] is Map<String, dynamic>) {
          final payload = map['state'] as Map<String, dynamic>;
          _handleMessage(payload, onState: onState, onTx: onTx);
        }
      },
      onError: (_) => onDisconnected?.call(),
      onDone: onDisconnected,
      cancelOnError: false,
    );
    return RealtimeService._(channel, sub, onDisconnected);
  }

  static Map<String, dynamic>? _parseEvent(dynamic event) {
    try {
      if (event is String) {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) return decoded;
      } else if (event is List<int>) {
        final decoded = jsonDecode(utf8.decode(event));
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static bool _handleMessage(
    Map<String, dynamic> map, {
    required void Function(DeviceState) onState,
    void Function(double tx)? onTx,
  }) {
    final type = map['type']?.toString();
    if (type == 'telemetry' && map['payload'] is Map<String, dynamic>) {
      return _handleMessage(
        map['payload'] as Map<String, dynamic>,
        onState: onState,
        onTx: onTx,
      );
    }

    if (map.containsKey('on') || map.containsKey('mode') || map.containsKey('level')) {
      try {
        final state = DeviceState.fromApiJson(map);
        onState(state);
        return true;
      } catch (_) {
        return false;
      }
    }

    if (map.containsKey('tx')) {
      final raw = map['tx'];
      double? tx;
      if (raw is num) {
        tx = raw.toDouble();
      } else if (raw is Map && raw['y'] is num) {
        tx = (raw['y'] as num).toDouble();
      }
      if (tx != null) {
        final norm = tx > 1.01 ? (tx / 1023.0) : tx;
        onTx?.call(norm.clamp(0.0, 1.0));
        return true;
      }
    }

    if (map.containsKey('y')) {
      final raw = map['y'];
      if (raw is num) {
        final norm = raw > 1.01 ? (raw / 1023.0) : raw.toDouble();
        onTx?.call(norm.clamp(0.0, 1.0));
        return true;
      }
    }

    return false;
  }


  Future<void> dispose() async {
    await _sub.cancel();
    await _channel.sink.close();
    _onDisconnected?.call();
  }
}

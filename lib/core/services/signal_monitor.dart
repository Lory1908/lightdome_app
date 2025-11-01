import 'dart:collection';

import 'package:flutter/foundation.dart';

class SignalMonitor extends ChangeNotifier {
  static final SignalMonitor I = SignalMonitor._();
  SignalMonitor._() {
    // Pre-fill buffers so the painter always receives a fixed-length series.
    for (var i = 0; i < capacity; i++) {
      _tx.addLast(0.0);
      _rx.addLast(0.0);
    }
  }

  static const int capacity = 300; // ~5s at 60 Hz
  final ListQueue<double> _tx = ListQueue<double>(capacity);
  final ListQueue<double> _rx = ListQueue<double>(capacity);

  void pushTx(double y01) {
    _push(_tx, y01);
  }

  void pushRx(double y01) {
    _push(_rx, y01);
  }

  void _push(ListQueue<double> buffer, double value) {
    final v = value.clamp(0.0, 1.0);
    if (buffer.length == capacity) {
      buffer.removeFirst();
    }
    buffer.addLast(v);
    notifyListeners();
  }

  List<double> get tx => List<double>.from(_tx);
  List<double> get rx => List<double>.from(_rx);
  double get lastTx => _tx.isEmpty ? 0.0 : _tx.last;
  double get lastRx => _rx.isEmpty ? 0.0 : _rx.last;

  void reset() {
    _tx.clear();
    _rx.clear();
    for (var i = 0; i < capacity; i++) {
      _tx.addLast(0.0);
      _rx.addLast(0.0);
    }
    notifyListeners();
  }
}

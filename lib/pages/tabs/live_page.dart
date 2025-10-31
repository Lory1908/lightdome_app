import 'dart:async';
import 'package:flutter/material.dart';

import '../../controllers/device_controller.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  double _localY = 0; // 0..1 (solo UI)
  bool _dragging = false;
  double _localBrightness = 100; // %
  double _localGamma = 2.0; // 1..3
  bool _localLoop = false;
  Timer? _brTimer;
  Timer? _gmTimer;

  @override
  void initState() {
    super.initState();
    final st = DeviceController.I.state;
    _localY = st.y;
    _localBrightness = st.brightness * 100;
    _localGamma = st.gamma;
    _localLoop = st.loop;
  }

  @override
  void dispose() {
    _brTimer?.cancel();
    _gmTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final st = ctrl.state;
        final double yVal = ((_dragging ? _localY : st.y).clamp(0.0, 1.0)).toDouble();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('Intensita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${(yVal * 100).round()}%'),
              ],
            ),
            Slider(
              value: yVal,
              onChanged: (v) {
                setState(() { _localY = v; _dragging = true; });
                ctrl.sendY(v);
              },
              onChangeStart: (_) => setState(() => _dragging = true),
              onChangeEnd: (_) => setState(() => _dragging = false),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: () => ctrl.off(), child: const Text('OFF')),
                for (final p in [25, 50, 75, 100])
                  OutlinedButton(
                    onPressed: () { ctrl.sendY(p / 100); },
                    child: Text('$p%'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Brightness %', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_localBrightness.round()}%'),
              ],
            ),
            Slider(
              value: _localBrightness,
              min: 0,
              max: 100,
              onChanged: (v) {
                setState(() => _localBrightness = v);
                _brTimer?.cancel();
                _brTimer = Timer(const Duration(milliseconds: 80), () {
                  ctrl.setParams(brightnessPct: _localBrightness);
                });
              },
              onChangeEnd: (v) => ctrl.setParams(brightnessPct: v),
            ),
            Row(
              children: [
                const Text('Gamma', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(_localGamma.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: _localGamma,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              onChanged: (v) {
                setState(() => _localGamma = v);
                _gmTimer?.cancel();
                _gmTimer = Timer(const Duration(milliseconds: 120), () {
                  ctrl.setParams(gamma: _localGamma);
                });
              },
              onChangeEnd: (v) => ctrl.setParams(gamma: v),
            ),
            SwitchListTile(
              title: const Text('Loop'),
              value: _localLoop,
              onChanged: (v) {
                setState(() => _localLoop = v);
                ctrl.setParams(loop: v);
              },
            ),
          ],
        );
      },
    );
  }
}

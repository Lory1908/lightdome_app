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
  bool _brightnessEditing = false;
  bool _gammaEditing = false;
  bool _loopPending = false;
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
        final double remoteBrightness = (st.brightness * 100).clamp(0, 100);
        final double displayBrightness = _brightnessEditing ? _localBrightness : remoteBrightness;
        final double remoteGamma = st.gamma.clamp(1.0, 3.0);
        final double displayGamma = _gammaEditing ? _localGamma : remoteGamma;
        if (_loopPending && st.loop == _localLoop) {
          _loopPending = false;
        }
        if (!_loopPending) {
          _localLoop = st.loop;
        }
        final bool loopValue = _loopPending ? _localLoop : st.loop;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune),
                        const SizedBox(width: 8),
                        const Text('Intensità', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          FilledButton.tonal(
                            onPressed: () { ctrl.sendY(p / 100); },
                            child: Text('$p%'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.brightness_6_outlined),
                        const SizedBox(width: 8),
                        const Text('Brightness', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${displayBrightness.round()}%'),
                      ],
                    ),
                    Slider(
                      value: displayBrightness,
                      min: 0,
                      max: 100,
                      onChangeStart: (_) => setState(() => _brightnessEditing = true),
                      onChanged: (v) {
                        setState(() => _localBrightness = v);
                        _brTimer?.cancel();
                        _brTimer = Timer(const Duration(milliseconds: 80), () {
                          ctrl.setParams(brightnessPct: v);
                        });
                      },
                      onChangeEnd: (v) {
                        _brTimer?.cancel();
                        ctrl.setParams(brightnessPct: v);
                        setState(() => _brightnessEditing = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline),
                        const SizedBox(width: 8),
                        const Text('Gamma', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(displayGamma.toStringAsFixed(1)),
                      ],
                    ),
                    Slider(
                      value: displayGamma,
                      min: 1.0,
                      max: 3.0,
                      divisions: 20,
                      onChangeStart: (_) => setState(() => _gammaEditing = true),
                      onChanged: (v) {
                        setState(() => _localGamma = v);
                        _gmTimer?.cancel();
                        _gmTimer = Timer(const Duration(milliseconds: 120), () {
                          ctrl.setParams(gamma: v);
                        });
                      },
                      onChangeEnd: (v) {
                        _gmTimer?.cancel();
                        ctrl.setParams(gamma: v);
                        setState(() => _gammaEditing = false);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Loop'),
                      value: loopValue,
                      onChanged: (v) {
                        setState(() {
                          _localLoop = v;
                          _loopPending = true;
                        });
                        ctrl.setParams(loop: v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

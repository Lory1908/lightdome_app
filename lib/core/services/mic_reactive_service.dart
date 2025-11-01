import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

typedef MicLevelCallback = void Function(double y01);

class MicReactiveService {
  final _rec = AudioRecorder();
  StreamSubscription<Amplitude>? _sub;

  Future<bool> _ensure() async => await _rec.hasPermission();

  double _env = 0; // smoothed envelope 0..1

  Future<void> start(MicLevelCallback onLevel, {double threshold = 0.05, double attack = 0.6, double release = 0.3}) async {
    if (!await _ensure()) return;
    if (await _rec.isRecording()) {
      await _rec.stop();
    }
    // Some platforms require a non-null path; on Web we pass a dummy filename.
    late final String path;
    try {
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/mic_${DateTime.now().millisecondsSinceEpoch}.wav';
      } else {
        path = 'mic_${DateTime.now().millisecondsSinceEpoch}.wav';
      }
    } catch (_) {
      // Fallback to a simple filename if directories are unavailable
      path = 'mic_${DateTime.now().millisecondsSinceEpoch}.wav';
    }
    const cfg = RecordConfig(
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );
    await _rec.start(cfg, path: path);
    _sub?.cancel();
    _sub = _rec.onAmplitudeChanged(const Duration(milliseconds: 30)).listen((amp) {
      // amp.current in dBFS [-inf..0]
      final db = amp.current.isFinite ? amp.current : -160.0;
      // Convert to linear amplitude 0..1 (0 = silence)
      var lin = math.pow(10.0, db / 20.0).toDouble();
      if (!lin.isFinite || lin.isNaN) lin = 0.0;
      lin = lin.clamp(0.0, 1.0);
      // Noise gate
      if (lin < threshold) lin = 0.0;
      // Attack/Release smoothing (EMA) on linear amplitude
      final alphaUp = attack.clamp(0.0, 1.0);
      final alphaDown = release.clamp(0.0, 1.0);
      final target = lin;
      if (target >= _env) {
        _env = _env + (target - _env) * alphaUp;
      } else {
        _env = _env + (target - _env) * alphaDown;
      }
      // perceptual curve for LED response
      final perceptual = math.pow(_env, 0.6).toDouble();
      onLevel(perceptual.clamp(0.0, 1.0));
    });
  }

  Future<void> stop() async {
    await _rec.stop();
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
  }
}

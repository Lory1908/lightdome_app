import 'dart:io';
import 'dart:math' as math;

import 'package:just_waveform/just_waveform.dart';

class EnvelopeBuilder {
  static Future<List<int>> fromAudioFile({required String path, int sampleRateHz = 100}) async {
    final input = File(path);
    if (!await input.exists()) {
      throw Exception('File non trovato');
    }
    // Compute waveform stream and take final result
    final stream = JustWaveform.extract(
      audioInFile: input,
      waveOutFile: File('$path.waveform'),
    );
    final progress = await stream.last; // WaveformProgress
    final wave = progress.waveform; // Waveform?
    if (wave == null) {
      throw Exception('Impossibile generare waveform');
    }
    // Convert waveform to frames y 0..1023 sampled at sampleRateHz
    final duration = wave.duration.inMilliseconds / 1000.0; // seconds
    final frames = math.max(1, (duration * sampleRateHz).round());
    final List<int> ys = List.filled(frames, 0);
    for (int i = 0; i < frames; i++) {
      final t = i / sampleRateHz;
      final pos = (t / duration).clamp(0.0, 1.0);
      final amp = _amplitudeAt(wave, pos);
      final y01 = amp.clamp(0.0, 1.0);
      ys[i] = (y01 * 1023).round();
    }
    return ys;
  }

  static double _amplitudeAt(Waveform wave, double pos01) {
    // Access fields dynamically to stay compatible across just_waveform versions
    final dyn = wave as dynamic;
    final List samples = (dyn.samples ?? dyn.data?.samples) as List;
    final int idx = (pos01 * (samples.length - 1)).clamp(0, samples.length - 1).round();
    final s = samples[idx];
    // Many versions expose WaveformSample with min/max (int16)
    final int minV = (s.min as int);
    final int maxV = (s.max as int);
    final a = (maxV.abs() + minV.abs()) / 2.0; // approximate
    final n = (a / 32768.0).clamp(0.0, 1.0);
    return math.pow(n, 0.6).toDouble();
  }
}

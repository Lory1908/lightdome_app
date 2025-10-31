class DeviceState {
  final bool connected;
  final bool on;
  final String mode; // live | program | ram | idle | unknown
  final double y; // 0..1 (mapped from 0..1023 or 0..255)
  final double brightness; // master brightness 0..1 (if available)
  final double gamma; // 1.0..3.0 (if available)
  final String? programName;
  final int sr; // sample rate (if available)
  final bool loop;
  final String? fwVersion;
  final int? uptime;

  const DeviceState({
    required this.connected,
    required this.on,
    required this.mode,
    required this.y,
    required this.brightness,
    required this.gamma,
    required this.programName,
    required this.sr,
    required this.loop,
    required this.fwVersion,
    required this.uptime,
  });

  factory DeviceState.initial() => const DeviceState(
        connected: false,
        on: false,
        mode: 'idle',
        y: 0,
        brightness: 1.0,
        gamma: 2.0,
        programName: null,
        sr: 0,
        loop: false,
        fwVersion: null,
        uptime: null,
      );

  DeviceState copyWith({
    bool? connected,
    bool? on,
    String? mode,
    double? y,
    double? brightness,
    double? gamma,
    String? programName,
    int? sr,
    bool? loop,
    String? fwVersion,
    int? uptime,
  }) {
    return DeviceState(
      connected: connected ?? this.connected,
      on: on ?? this.on,
      mode: mode ?? this.mode,
      y: y ?? this.y,
      brightness: brightness ?? this.brightness,
      gamma: gamma ?? this.gamma,
      programName: programName ?? this.programName,
      sr: sr ?? this.sr,
      loop: loop ?? this.loop,
      fwVersion: fwVersion ?? this.fwVersion,
      uptime: uptime ?? this.uptime,
    );
  }

  static double _clamp01(num v) => v < 0 ? 0 : (v > 1 ? 1 : v.toDouble());

  // Parse from preferred /api/state
  factory DeviceState.fromApiJson(Map<String, dynamic> j) {
    final hasY = j.containsKey('y');
    final hasLevel = j.containsKey('level');
    final hasBrightness255 = j.containsKey('brightness');
    double y = 0;
    if (hasY) {
      y = (j['y'] as num).toDouble();
      if (y > 1.0) {
        // Some firmwares may return 0..1023
        y = (y / 1023.0);
      }
    } else if (hasLevel) {
      y = (j['level'] as num).toDouble() / 1023.0;
    } else if (hasBrightness255) {
      y = (j['brightness'] as num).toDouble() / 255.0;
    }

    final String mode = (j['mode']?.toString().toLowerCase() ?? 'unknown');

    return DeviceState(
      connected: true,
      on: (j['on'] == true) || y > 0,
      mode: mode,
      y: _clamp01(y),
      brightness: j.containsKey('brightnessPct')
          ? _clamp01((j['brightnessPct'] as num).toDouble() / 100)
          : (j.containsKey('brightnessMaster')
              ? _clamp01((j['brightnessMaster'] as num).toDouble())
              : 1.0),
      gamma: j.containsKey('gamma') ? (j['gamma'] as num).toDouble() : 2.0,
      programName:
          (j['programName']?.toString().isEmpty ?? true) ? null : j['programName'].toString(),
      sr: j.containsKey('sr')
          ? (j['sr'] as num).toInt()
          : (j['sampleRateHz'] is num ? (j['sampleRateHz'] as num).toInt() : 0),
      loop: j['loop'] == true,
      fwVersion: j['fwVersion']?.toString(),
      uptime: j['uptime'] is num ? (j['uptime'] as num).toInt() : null,
    );
  }

  // Parse from legacy /status
  factory DeviceState.fromStatusJson(Map<String, dynamic> j) {
    final playingProgram = (j['mode'] is Map && j['mode']['programPlaying'] == true);
    final playingRam = (j['mode'] is Map && j['mode']['ramPlaying'] == true);
    final mode = playingProgram
        ? 'program'
        : (playingRam
            ? 'program'
            : ((j['on'] == true) ? 'live' : 'idle'));

    return DeviceState(
      connected: true,
      on: j['on'] == true,
      mode: mode,
      y: _clamp01(((j['levelY'] as num?) ?? 0) / 1023.0),
      brightness: (j['masterBrightness'] is num)
          ? _clamp01((j['masterBrightness'] as num).toDouble())
          : 1.0,
      gamma: (j['gamma'] is num) ? (j['gamma'] as num).toDouble() : 2.0,
      programName: j['mode'] is Map ? (j['mode']['programName']?.toString()) : null,
      sr: j['mode'] is Map ? ((j['mode']['sampleRateHz'] as num?)?.toInt() ?? 0) : 0,
      loop: j['loop'] == true,
      fwVersion: null,
      uptime: null,
    );
  }
}


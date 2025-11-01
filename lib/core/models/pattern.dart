import 'dart:convert';

enum PatternType {
  none,
  sine,
  pulse,
  micReactive,
  songWaveSpotify,
  songWaveOpen,
}

class PatternConfig {
  final PatternType type;
  final double amplitude; // 0..1
  final double offset; // 0..1 baseline
  final double freqHz; // used for sine/pulse
  final double? duty; // 0..1 for pulse
  final bool? gammaComp; // apply inverse gamma
  final double? micThreshold; // 0..1 gate
  final double? micAttack; // 0..1
  final double? micRelease; // 0..1

  const PatternConfig({
    required this.type,
    this.amplitude = 1.0,
    this.offset = 0.0,
    this.freqHz = 1.0,
    this.duty,
    this.gammaComp,
    this.micThreshold,
    this.micAttack,
    this.micRelease,
  });

  const PatternConfig.none() : this(type: PatternType.none);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amplitude': amplitude,
        'offset': offset,
        'freqHz': freqHz,
        if (duty != null) 'duty': duty,
        if (gammaComp != null) 'gammaComp': gammaComp,
        if (micThreshold != null) 'micThreshold': micThreshold,
        if (micAttack != null) 'micAttack': micAttack,
        if (micRelease != null) 'micRelease': micRelease,
      };

  factory PatternConfig.fromJson(Map<String, dynamic> j) {
    PatternType t;
    final s = (j['type']?.toString() ?? 'none');
    t = PatternType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PatternType.none,
    );
    return PatternConfig(
      type: t,
      amplitude: (j['amplitude'] as num?)?.toDouble() ?? 1.0,
      offset: (j['offset'] as num?)?.toDouble() ?? 0.0,
      freqHz: (j['freqHz'] as num?)?.toDouble() ?? 1.0,
      duty: (j['duty'] as num?)?.toDouble(),
      gammaComp: j['gammaComp'] as bool?,
      micThreshold: (j['micThreshold'] as num?)?.toDouble(),
      micAttack: (j['micAttack'] as num?)?.toDouble(),
      micRelease: (j['micRelease'] as num?)?.toDouble(),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static PatternConfig fromJsonString(String s) => PatternConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  PatternConfig copyWith({PatternType? type, double? amplitude, double? offset, double? freqHz, double? duty, bool? gammaComp, double? micThreshold, double? micAttack, double? micRelease}) => PatternConfig(
        type: type ?? this.type,
        amplitude: amplitude ?? this.amplitude,
        offset: offset ?? this.offset,
        freqHz: freqHz ?? this.freqHz,
        duty: duty ?? this.duty,
        gammaComp: gammaComp ?? this.gammaComp,
        micThreshold: micThreshold ?? this.micThreshold,
        micAttack: micAttack ?? this.micAttack,
        micRelease: micRelease ?? this.micRelease,
      );
}

class DeviceEntry {
  final String baseUrl;
  final String label;
  final DateTime lastSeen;
  final bool discovered;

  const DeviceEntry({
    required this.baseUrl,
    required this.label,
    required this.lastSeen,
    this.discovered = false,
  });

  DeviceEntry copyWith({
    String? baseUrl,
    String? label,
    DateTime? lastSeen,
    bool? discovered,
  }) =>
      DeviceEntry(
        baseUrl: baseUrl ?? this.baseUrl,
        label: label ?? this.label,
        lastSeen: lastSeen ?? this.lastSeen,
        discovered: discovered ?? this.discovered,
      );

  factory DeviceEntry.fromJson(Map<String, dynamic> j) => DeviceEntry(
        baseUrl: j['baseUrl']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        lastSeen: DateTime.tryParse(j['lastSeen']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        discovered: j['discovered'] == true,
      );

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'label': label,
        'lastSeen': lastSeen.toIso8601String(),
        'discovered': discovered,
      };
}

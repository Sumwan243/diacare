/// Represents a single blood sugar reading.
class BloodSugarEntry {
  String id;
  int level; // mg/dL
  String context; // e.g., Fasting, Post-meal
  DateTime timestamp;

  BloodSugarEntry({
    required this.id,
    required this.level,
    required this.context,
    required this.timestamp,
  });

  /// Converts the object to a map for Hive storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'level': level,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Creates an object from a map.
  factory BloodSugarEntry.fromMap(Map<String, dynamic> map) => BloodSugarEntry(
        id: map['id'] ?? '',
        level: map['level'] ?? 0,
        context: map['context'] ?? '',
        timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}

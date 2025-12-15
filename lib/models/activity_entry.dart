/// Represents a single physical activity session.
class ActivityEntry {
  String id;
  String type; // e.g., Walking, Running
  int durationMinutes;
  int caloriesBurned;
  DateTime timestamp;

  ActivityEntry({
    required this.id,
    required this.type,
    required this.durationMinutes,
    this.caloriesBurned = 0,
    required this.timestamp,
  });

  /// Converts the object to a map for Hive storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Creates an object from a map.
  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
        id: map['id'] ?? '',
        type: map['type'] ?? 'Other',
        durationMinutes: map['durationMinutes'] ?? 0,
        caloriesBurned: map['caloriesBurned'] ?? 0,
        timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}

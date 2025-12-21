/// Represents a single blood pressure reading (systolic/diastolic).
class BloodPressureEntry {
  String id;
  int systolic; // mmHg
  int diastolic; // mmHg
  String context; // e.g., Resting, After exercise
  DateTime timestamp;

  BloodPressureEntry({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.context,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BloodPressureEntry.fromMap(Map<String, dynamic> map) => BloodPressureEntry(
        id: map['id'] ?? '',
        systolic: map['systolic'] ?? 0,
        diastolic: map['diastolic'] ?? 0,
        context: map['context'] ?? '',
        timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}

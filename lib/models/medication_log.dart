/// Represents a record of a single medication dose being taken.
class MedicationLog {
  String id;
  String medicationId;
  DateTime time; // The exact time the dose was logged
  bool taken;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.time,
    required this.taken,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicationId': medicationId,
        'time': time.toIso8601String(),
        'taken': taken,
      };

  factory MedicationLog.fromMap(Map<String, dynamic> map) => MedicationLog(
        id: map['id'] ?? '',
        medicationId: map['medicationId'] ?? '',
        time: DateTime.parse(map['time'] ?? DateTime.now().toIso8601String()),
        taken: map['taken'] ?? false,
      );
}

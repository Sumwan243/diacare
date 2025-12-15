import 'package:flutter/material.dart';

// Represents a single medication, which can have multiple reminder times.
class MedicationReminder {
  String id;
  String name;
  int pillsPerDose;
  List<TimeOfDay> times; // A medication can have multiple reminder times
  bool isEnabled;

  MedicationReminder({
    required this.id,
    required this.name,
    required this.pillsPerDose,
    required this.times,
    this.isEnabled = true,
  });

  // Methods to convert to and from a map for local storage (Hive)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pillsPerDose': pillsPerDose,
        'isEnabled': isEnabled,
        // Store times as a list of strings for persistence
        'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
      };

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    return MedicationReminder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      pillsPerDose: map['pillsPerDose'] ?? 1,
      isEnabled: map['isEnabled'] ?? true,
      times: (map['times'] as List<dynamic>? ?? []).map((timeStr) {
        final parts = (timeStr as String).split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList(),
    );
  }

  MedicationReminder copyWith({
    String? name,
    int? pillsPerDose,
    List<TimeOfDay>? times,
    bool? isEnabled,
  }) {
    return MedicationReminder(
      id: id,
      name: name ?? this.name,
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      times: times ?? this.times,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

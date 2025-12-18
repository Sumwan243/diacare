import 'package:flutter/material.dart';

class MedicationReminder {
  final String id;
  final String name;
  final int pillsPerDose;
  final List<TimeOfDay> times;
  final bool isEnabled;

  const MedicationReminder({
    required this.id,
    required this.name,
    required this.pillsPerDose,
    required this.times,
    required this.isEnabled,
  });

  MedicationReminder copyWith({
    String? id,
    String? name,
    int? pillsPerDose,
    List<TimeOfDay>? times,
    bool? isEnabled,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      times: times ?? this.times,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pillsPerDose': pillsPerDose,
        'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
        'isEnabled': isEnabled,
      };

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['times'] as List)
        .map((t) => t.toString().split(':'))
        .where((p) => p.length == 2)
        .toList();

    return MedicationReminder(
      id: map['id'] as String,
      name: map['name'] as String,
      pillsPerDose: (map['pillsPerDose'] as num?)?.toInt() ?? 1,
      times: timeParts
          .map((p) => TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])))
          .toList(),
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }
}

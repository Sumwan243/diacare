import 'package:diacare/models/medication_log.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class MedicationLogProvider extends ChangeNotifier {
  final Box _box = Hive.box('medication_logs_box');

  String _logKey(String medicationId, DateTime date, TimeOfDay time) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return '${medicationId}_${dateString}_${time.hour}:${time.minute}';
  }

  Future<void> logDose(String medicationId, TimeOfDay time, bool taken) async {
    final logTime = DateTime.now();
    final id = const Uuid().v4();
    final log = MedicationLog(id: id, medicationId: medicationId, time: logTime, taken: taken);
    final key = _logKey(medicationId, logTime, time);

    if (taken) {
      await _box.put(key, log.toMap());
    } else {
      await _box.delete(key);
    }
    notifyListeners();
  }

  bool isDoseTaken(String medicationId, TimeOfDay time) {
    final key = _logKey(medicationId, DateTime.now(), time);
    return _box.containsKey(key);
  }

  int dosesTakenToday(String medicationId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int count = 0;
    for (final key in _box.keys) {
      if (key.toString().startsWith(medicationId) && key.toString().contains(today)) {
        final log = MedicationLog.fromMap(Map<String, dynamic>.from(_box.get(key) as Map));
        if (log.taken) {
          count++;
        }
      }
    }
    return count;
  }
}

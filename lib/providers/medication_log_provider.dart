import 'package:diacare/models/medication_log.dart';
import 'package:flutter/material.dart' show ChangeNotifier, TimeOfDay, DateUtils;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class MedicationLogProvider extends ChangeNotifier {
  final Box _box = Hive.box('medication_logs_box');
  final Box _intakeBox = Hive.box('med_intake_log_box'); // Box used by notifications

  String _logKey(String medicationId, DateTime date, TimeOfDay time) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return '${medicationId}_${dateString}_${time.hour}:${time.minute}';
  }

  /// Key format used by notification handler: reminderId::ISO8601DateTime
  String _notificationKey(String reminderId, DateTime scheduled) {
    return '$reminderId::${scheduled.toIso8601String()}';
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

  bool isDoseTaken(String medicationId, TimeOfDay time, [DateTime? date]) {
    final checkDate = date ?? DateTime.now();
    
    // Check the medication_logs_box (used by UI)
    final key = _logKey(medicationId, checkDate, time);
    if (_box.containsKey(key)) {
      return true;
    }
    
    // Also check med_intake_log_box (used by notifications)
    // Look for entries where the scheduled time matches the date and time
    final dateOnly = DateUtils.dateOnly(checkDate);
    for (final notificationKey in _intakeBox.keys) {
      final entry = _intakeBox.get(notificationKey);
      if (entry != null && entry is Map) {
        final entryReminderId = entry['reminderId'] as String?;
        final scheduledIso = entry['scheduled'] as String?;
        
        if (entryReminderId == medicationId && scheduledIso != null) {
          final scheduled = DateTime.tryParse(scheduledIso);
          if (scheduled != null) {
            final scheduledDateOnly = DateUtils.dateOnly(scheduled);
            final scheduledTime = TimeOfDay.fromDateTime(scheduled);
            
            // Check if date and time match
            if (scheduledDateOnly == dateOnly && 
                scheduledTime.hour == time.hour && 
                scheduledTime.minute == time.minute) {
              return true;
            }
          }
        }
      }
    }
    
    return false;
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

  /// Refreshes the provider to check for updates from notification handler
  /// Call this when the app resumes or when the reminders screen is shown
  void refresh() {
    notifyListeners();
  }
}

import 'package:diacare/models/medication_reminder.dart';
import 'package:diacare/utils/notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart'; // Missing import added

// Generates a unique integer ID for a notification.
int _notificationId(String medicationId, TimeOfDay time) {
  return '${medicationId}_${time.hour}:${time.minute}'.hashCode;
}

class MedicationProvider extends ChangeNotifier {
  final Box _box = Hive.box('medications');

  // This getter is now robust and will not crash on bad data.
  List<MedicationReminder> get reminders {
    final List<MedicationReminder> validReminders = [];
    for (final key in _box.keys) {
      try {
        final value = _box.get(key);
        if (value != null && value is Map) {
          validReminders.add(MedicationReminder.fromMap(Map<String, dynamic>.from(value)));
        }
      } catch (e) {
        // If an entry is malformed, print an error and safely skip it.
        debugPrint('Could not parse reminder with key $key. It may be from an old version. Error: $e');
      }
    }
    return validReminders;
  }

  Future<void> addMedication({
    required String name,
    required int pills,
    required List<TimeOfDay> times,
    required bool isEnabled,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final medication = MedicationReminder(id: id, name: name, pillsPerDose: pills, times: times, isEnabled: isEnabled);

    if (isEnabled) {
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        for (final time in times) {
          await NotificationService().scheduleDaily(medication, time, _notificationId(id, time));
        }
      }
    }

    await _box.put(id, medication.toMap());
    notifyListeners();
  }

  Future<void> updateMedication(MedicationReminder updatedMedication) async {
    final oldReminderMap = _box.get(updatedMedication.id) as Map?;
    if (oldReminderMap == null) return;
    final oldReminder = MedicationReminder.fromMap(Map<String, dynamic>.from(oldReminderMap));

    for (final time in oldReminder.times) {
      await NotificationService().cancelById(_notificationId(oldReminder.id, time));
    }

    if (updatedMedication.isEnabled) {
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        for (final time in updatedMedication.times) {
          await NotificationService().scheduleDaily(updatedMedication, time, _notificationId(updatedMedication.id, time));
        }
      }
    }

    await _box.put(updatedMedication.id, updatedMedication.toMap());
    notifyListeners();
  }

  Future<void> toggleMedicationStatus(String medicationId) async {
    final reminder = reminders.firstWhere((r) => r.id == medicationId);
    final updatedReminder = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await updateMedication(updatedReminder);
  }

  Future<void> deleteReminder(String medicationId) async {
    final reminder = reminders.firstWhere((r) => r.id == medicationId);
    for (final time in reminder.times) {
      await NotificationService().cancelById(_notificationId(reminder.id, time));
    }
    await _box.delete(medicationId);
    notifyListeners();
  }
}

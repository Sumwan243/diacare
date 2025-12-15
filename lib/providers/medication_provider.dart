import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission handler
import '../models/medication_reminder.dart';
import '../utils/notifications.dart';

// Generates a unique integer ID for a notification.
int _notificationId(String medicationId, TimeOfDay time) {
  return '${medicationId}_${time.hour}:${time.minute}'.hashCode;
}

class MedicationProvider extends ChangeNotifier {
  final Box _box = Hive.box('medications');

  List<MedicationReminder> get reminders {
    return _box.values
        .map((e) => MedicationReminder.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
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
      // Request permission before scheduling
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        for (final time in times) {
          await NotificationService().scheduleDaily(medication, time, _notificationId(id, time));
        }
      } else {
        debugPrint('Exact alarm permission not granted. Cannot schedule notifications.');
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
      } else {
        debugPrint('Exact alarm permission not granted. Cannot schedule notifications.');
      }
    }

    await _box.put(updatedMedication.id, updatedMedication.toMap());
    notifyListeners();
  }

  Future<void> toggleMedicationStatus(String medicationId) async {
    final reminderMap = _box.get(medicationId) as Map?;
    if (reminderMap == null) return;
    final reminder = MedicationReminder.fromMap(Map<String, dynamic>.from(reminderMap));
    final updatedReminder = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await updateMedication(updatedReminder);
  }

  Future<void> deleteReminder(String medicationId) async {
    final reminderMap = _box.get(medicationId) as Map?;
    if (reminderMap == null) return;
    final reminder = MedicationReminder.fromMap(Map<String, dynamic>.from(reminderMap));

    for (final time in reminder.times) {
      await NotificationService().cancelById(_notificationId(reminder.id, time));
    }
    await _box.delete(medicationId);
    notifyListeners();
  }
}

import 'package:diacare/models/medication_reminder.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/notification_service.dart';
import '../utils/notification_ids.dart';

class MedicationProvider extends ChangeNotifier {
  final Box _box = Hive.box('medications');
  final NotificationService _notifs = NotificationService();

  static const int _daysAhead = 7;

  List<MedicationReminder> get reminders {
    final List<MedicationReminder> validReminders = [];
    for (final key in _box.keys) {
      try {
        final value = _box.get(key);
        if (value != null && value is Map) {
          validReminders.add(
            MedicationReminder.fromMap(Map<String, dynamic>.from(value)),
          );
        }
      } catch (e) {
        debugPrint(
          'Could not parse reminder with key $key. Old version? Error: $e',
        );
      }
    }
    // BUGFIX: Always sort the list for a consistent UI.
    return validReminders..sort((a, b) => a.name.compareTo(b.name));
  }

  List<TimeOfDay> _dedupAndSortTimes(List<TimeOfDay> times) {
    final unique = <String, TimeOfDay>{};

    for (final t in times) {
      final k = '${t.hour}:${t.minute}';
      unique[k] = t;
    }

    final list = unique.values.toList()
      ..sort((a, b) {
        final am = a.hour * 60 + a.minute;
        final bm = b.hour * 60 + b.minute;
        return am.compareTo(bm);
      });

    return list;
  }

  Future<void> _scheduleIfEnabled(MedicationReminder r) async {
    if (!r.isEnabled) return;

    try {
      for (final t in r.times) {
        final baseId = baseIdForReminderTime(r.id, t);
        await _notifs.scheduleDailySeries(
          reminder: r,
          time: t,
          baseId: baseId,
          daysAhead: _daysAhead,
          escalationDelay: const Duration(minutes: 10),
        );
      }
      debugPrint('Successfully scheduled reminders for ${r.name}');
    } catch (e) {
      debugPrint('Error scheduling reminders for ${r.name}: $e');
      // Don't throw - let the medication be saved even if notifications fail
    }
  }

  Future<void> _cancelAllForReminder(MedicationReminder r) async {
    try {
      for (final t in r.times) {
        final baseId = baseIdForReminderTime(r.id, t);
        await _notifs.cancelDailySeries(baseId: baseId, daysAhead: _daysAhead);
      }
    } catch (e) {
      debugPrint('Error canceling reminders for ${r.name}: $e');
      // Continue even if cancellation fails
    }
  }

  Future<void> addMedication({
    required String name,
    required int pills,
    required List<TimeOfDay> times,
    required bool isEnabled,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final medication = MedicationReminder(
      id: id,
      name: name,
      pillsPerDose: pills,
      times: _dedupAndSortTimes(times),
      isEnabled: isEnabled,
    );

    await _box.put(id, medication.toMap());
    await _scheduleIfEnabled(medication);

    notifyListeners();
  }

  Future<void> updateMedication(MedicationReminder updatedMedication) async {
    // Load the old reminder so we can cancel old schedules (especially if times changed)
    final oldRaw = _box.get(updatedMedication.id);
    MedicationReminder? oldReminder;
    if (oldRaw is Map) {
      try {
        oldReminder = MedicationReminder.fromMap(Map<String, dynamic>.from(oldRaw));
      } catch (_) {
        oldReminder = null;
      }
    }

    final normalized = updatedMedication.copyWith(
      times: _dedupAndSortTimes(updatedMedication.times),
    );

    // Cancel old schedules first
    if (oldReminder != null) {
      await _cancelAllForReminder(oldReminder);
    }

    // Save new
    await _box.put(normalized.id, normalized.toMap());

    // Schedule new if enabled
    await _scheduleIfEnabled(normalized);

    notifyListeners();
  }

  Future<void> toggleMedicationStatus(String medicationId) async {
    // BUGFIX: Safely find the reminder to prevent crashes.
    final reminder = reminders.firstWhere((r) => r.id == medicationId, orElse: () => throw Exception('Reminder not found'));

    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);

    if (reminder.isEnabled) {
      // turning OFF
      await _cancelAllForReminder(reminder);
    }

    await _box.put(updated.id, updated.toMap());

    if (updated.isEnabled) {
      // turning ON
      await _scheduleIfEnabled(updated);
    }

    notifyListeners();
  }

  Future<void> deleteReminder(String medicationId) async {
    // BUGFIX: Safely find the reminder to prevent crashes.
    final reminder = reminders.firstWhere((r) => r.id == medicationId, orElse: () => throw Exception('Reminder not found'));

    await _cancelAllForReminder(reminder);
    await _box.delete(medicationId);

    notifyListeners();
  }

  /// Reschedules all enabled medication reminders.
  /// This should be called on app start and when app resumes to ensure
  /// notifications are always scheduled for the next 7 days.
  Future<void> rescheduleAllReminders() async {
    try {
      for (final reminder in reminders) {
        if (reminder.isEnabled) {
          await _scheduleIfEnabled(reminder);
        }
      }
      debugPrint('Rescheduled all enabled medication reminders');
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }
}

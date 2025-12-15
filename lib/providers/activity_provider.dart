import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_entry.dart';

class ActivityProvider extends ChangeNotifier {
  final Box _box = Hive.box('activity_box');

  List<ActivityEntry> get entries {
    return _box.values
        .map((e) => ActivityEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addActivity(String type, int duration, int calories) async {
    final id = const Uuid().v4();
    final entry = ActivityEntry(
      id: id,
      type: type,
      durationMinutes: duration,
      caloriesBurned: calories,
      timestamp: DateTime.now(),
    );
    await _box.put(id, entry.toMap());
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Map<String, int> getTodaySummary() {
    final today = DateTime.now();
    int totalDuration = 0;
    int totalCalories = 0;

    for (final entry in entries) {
      if (entry.timestamp.year == today.year &&
          entry.timestamp.month == today.month &&
          entry.timestamp.day == today.day) {
        totalDuration += entry.durationMinutes;
        totalCalories += entry.caloriesBurned;
      }
    }
    return {'duration': totalDuration, 'calories': totalCalories};
  }

  /// Returns a set of weekday abbreviations (e.g., 'mon', 'tue') for days
  /// that have at least one activity logged in the current week.
  Set<String> getDaysWithActivityThisWeek() {
    final now = DateTime.now();
    // Handle week starting on Sunday vs. Monday based on locale if needed, assuming Monday start for now.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final Set<String> activeDays = {};
    final dayAbbreviations = {1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat', 7: 'sun'};

    for (final entry in entries) {
      if (entry.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        final dayAbbr = dayAbbreviations[entry.timestamp.weekday];
        if (dayAbbr != null) {
          activeDays.add(dayAbbr);
        }
      }
    }
    return activeDays;
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/blood_sugar_entry.dart';

class BloodSugarProvider extends ChangeNotifier {
  final Box _box = Hive.box('blood_sugar_box');

  List<BloodSugarEntry> get entries {
    return _box.values
        .map((e) => BloodSugarEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort descending
  }

  Future<void> addEntry(int level, String context, DateTime timestamp) async {
    final id = const Uuid().v4();
    final entry = BloodSugarEntry(id: id, level: level, context: context, timestamp: timestamp);
    await _box.put(id, entry.toMap());
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  BloodSugarEntry? getLatestEntry() {
    if (entries.isEmpty) return null;
    return entries.first;
  }

  // Example of a more complex data query
  Map<String, double> getWeeklyTrend() {
    final Map<String, List<int>> weeklyData = {};
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    for (final entry in entries) {
      if (entry.timestamp.isAfter(weekAgo)) {
        final day = entry.timestamp.weekday.toString(); // Group by weekday
        weeklyData.putIfAbsent(day, () => []).add(entry.level);
      }
    }

    return weeklyData.map((day, levels) {
      final avg = levels.reduce((a, b) => a + b) / levels.length;
      return MapEntry(day, avg);
    });
  }
}

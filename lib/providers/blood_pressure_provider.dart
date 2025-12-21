import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/blood_pressure_entry.dart';
import 'package:intl/intl.dart';

class BloodPressureProvider extends ChangeNotifier {
  final Box _box = Hive.box('blood_pressure_box');

  List<BloodPressureEntry> get entries {
    return _box.values
        .map((e) => BloodPressureEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addEntry(int systolic, int diastolic, String context, DateTime timestamp) async {
    final id = const Uuid().v4();
    final entry = BloodPressureEntry(
      id: id,
      systolic: systolic,
      diastolic: diastolic,
      context: context,
      timestamp: timestamp,
    );
    await _box.put(id, entry.toMap());
    notifyListeners();
  }

  Future<void> upsertEntry(BloodPressureEntry entry) async {
    await _box.put(entry.id, entry.toMap());
    notifyListeners();
  }

  Future<void> updateEntry({
    required String id,
    required int systolic,
    required int diastolic,
    required String context,
    required DateTime timestamp,
  }) async {
    final updated = BloodPressureEntry(
      id: id,
      systolic: systolic,
      diastolic: diastolic,
      context: context,
      timestamp: timestamp,
    );
    await upsertEntry(updated);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  BloodPressureEntry? getLatestEntry() {
    if (entries.isEmpty) return null;
    return entries.first;
  }

  Map<String, Map<String, double>> getWeeklyTrend() {
    final Map<String, Map<String, double>> trend = {};
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final dayEntries = _box.values
          .map((e) => BloodPressureEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((e) => DateFormat('yyyy-MM-dd').format(e.timestamp) == key)
          .toList();
      if (dayEntries.isEmpty) continue;
      final avgSys = dayEntries.map((e) => e.systolic).reduce((a, b) => a + b) / dayEntries.length;
      final avgDia = dayEntries.map((e) => e.diastolic).reduce((a, b) => a + b) / dayEntries.length;
      trend[key] = {'systolic': avgSys.toDouble(), 'diastolic': avgDia.toDouble()};
    }

    return trend;
  }
}

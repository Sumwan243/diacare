import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/hydration_entry.dart';

class HydrationProvider extends ChangeNotifier {
  final Box _box = Hive.box('hydration_box');
  int _dailyGoal = 2500; // Default 2.5L per day

  int get dailyGoal => _dailyGoal;

  set dailyGoal(int goal) {
    _dailyGoal = goal;
    _box.put('daily_goal', goal);
    notifyListeners();
  }

  List<HydrationEntry> get entries {
    return _box.values
        .where((e) => e is Map)
        .map((e) => HydrationEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<HydrationEntry> get todayIntakes {
    final today = DateTime.now();
    return entries.where((entry) {
      return entry.timestamp.year == today.year &&
          entry.timestamp.month == today.month &&
          entry.timestamp.day == today.day;
    }).toList();
  }

  int get currentIntake {
    return todayIntakes.fold(0, (sum, entry) => sum + entry.amount);
  }

  double get dailyProgress {
    return (currentIntake / dailyGoal).clamp(0.0, 1.0);
  }

  int get todayIntakeCount {
    return todayIntakes.length;
  }

  Future<void> addIntake(int amount) async {
    final id = const Uuid().v4();
    final entry = HydrationEntry(
      id: id,
      amount: amount,
      timestamp: DateTime.now(),
    );
    await _box.put(id, entry.toMap());
    notifyListeners();
  }

  Future<void> deleteIntake(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Initialize provider and load saved daily goal
  Future<void> initialize() async {
    final savedGoal = _box.get('daily_goal');
    if (savedGoal != null) {
      _dailyGoal = savedGoal as int;
    }
    notifyListeners();
  }

  /// Get recommended daily water intake based on user profile
  int getRecommendedIntake({
    double? weightKg,
    int? ageYears,
    String? activityLevel,
  }) {
    // Base recommendation: 35ml per kg of body weight
    int baseIntake = 2500; // Default 2.5L
    
    if (weightKg != null) {
      baseIntake = (weightKg * 35).round();
    }
    
    // Adjust for activity level
    if (activityLevel != null) {
      switch (activityLevel.toLowerCase()) {
        case 'high':
          baseIntake = (baseIntake * 1.3).round();
          break;
        case 'moderate':
          baseIntake = (baseIntake * 1.15).round();
          break;
        case 'low':
        default:
          // Keep base intake
          break;
      }
    }
    
    // Adjust for age (older adults need slightly more)
    if (ageYears != null && ageYears > 65) {
      baseIntake = (baseIntake * 1.1).round();
    }
    
    return baseIntake;
  }

  /// Get hydration status message
  String getHydrationStatus() {
    final progress = dailyProgress;
    
    if (progress >= 1.0) {
      return 'Excellent! You\'ve reached your daily goal! 🎉';
    } else if (progress >= 0.8) {
      return 'Great job! You\'re almost there! 💪';
    } else if (progress >= 0.6) {
      return 'Good progress! Keep it up! 👍';
    } else if (progress >= 0.4) {
      return 'You\'re on track, but drink more water! 💧';
    } else if (progress >= 0.2) {
      return 'Time to hydrate! Your body needs water! ⚡';
    } else {
      return 'Start hydrating! Your health depends on it! 🚨';
    }
  }

  /// Get weekly hydration summary
  Map<String, int> getWeeklySummary() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyData = <String, int>{};
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayEntries = entries.where((entry) {
        return entry.timestamp.year == day.year &&
            entry.timestamp.month == day.month &&
            entry.timestamp.day == day.day;
      });
      
      final totalIntake = dayEntries.fold(0, (sum, entry) => sum + entry.amount);
      weeklyData[dayNames[i]] = totalIntake;
    }
    
    return weeklyData;
  }
}
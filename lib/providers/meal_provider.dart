import 'dart:collection';

import 'package:diacare/models/meal.dart';
import 'package:diacare/models/nutrition_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils, TimeOfDay;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// Ensure this class matches what your UI expects
class NutritionInfo {
  final double caloriesKcal;
  final double carbsG;
  final double proteinG;
  final double fatG;

  const NutritionInfo({
    this.caloriesKcal = 0,
    this.carbsG = 0,
    this.proteinG = 0,
    this.fatG = 0,
  });
}

class MealProvider extends ChangeNotifier {
  final Box _box = Hive.box('meals_box');

  List<Meal> get meals {
    final List<Meal> validMeals = [];
    for (final value in _box.values) {
      try {
        if (value != null && value is Map) {
          validMeals.add(
            Meal.fromMap(Map<String, dynamic>.from(value)),
          );
        }
      } catch (e) {
        debugPrint('Error parsing meal: $e');
        // Skip corrupted entries
      }
    }
    validMeals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return validMeals;
  }

  Map<DateTime, List<Meal>> get mealsByDay {
    final Map<DateTime, List<Meal>> grouped = {};
    for (final m in meals) {
      final day = DateUtils.dateOnly(m.timestamp);
      grouped.putIfAbsent(day, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final result = LinkedHashMap<DateTime, List<Meal>>();
    for (final k in sortedKeys) {
      final list = grouped[k]!..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      result[k] = list;
    }
    return result;
  }

  NutritionInfo getNutritionForDay(DateTime date) {
    final day = DateUtils.dateOnly(date);
    NutritionSummary total = NutritionSummary.zero;
    for (final m in meals) {
      if (DateUtils.dateOnly(m.timestamp) == day) {
        total = total + m.totalNutrients;
      }
    }
    return NutritionInfo(
      caloriesKcal: total.caloriesKcal,
      carbsG: total.carbsG,
      proteinG: total.proteinG,
      fatG: total.fatG,
    );
  }

  // Users manually enter calories and carbs - no AI estimation
  Future<void> addMeal({
    required String name,
    required double grams,
    required MealType mealType,
    DateTime? timestamp,
    double calories = 0,
    double carbs = 0,
    double protein = 0,
    double fat = 0,
    NutritionSummary? nutrition,
  }) async {
    final id = const Uuid().v4();

    // Use user-provided values directly
    final totalNutrients = nutrition ?? NutritionSummary(
      caloriesKcal: calories,
      carbsG: carbs,
      proteinG: protein,
      fatG: fat,
      fiberG: 0,
    );

    final meal = Meal(
      id: id,
      name: name.trim(),
      grams: grams,
      mealType: mealType,
      timestamp: timestamp ?? DateTime.now(),
      totalNutrients: totalNutrients,
    );

    await _box.put(id, meal.toMap());
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> updateMeal(Meal updated) async {
    await _box.put(updated.id, updated.toMap());
    notifyListeners();
  }
}

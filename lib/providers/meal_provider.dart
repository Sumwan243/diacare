import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/meal.dart';
import '../models/nutrition_summary.dart';
import '../services/openai_meal_estimator.dart';

class MealProvider extends ChangeNotifier {
  final Box _box = Hive.box('meals_box');
  final OpenAiMealEstimator _ai = OpenAiMealEstimator();

  List<Meal> get meals {
    return _box.values
        .map((e) => Meal.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Map of day -> list of meals on that day (newest days first).
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

  NutritionSummary getNutritionForDay(DateTime date) {
    final day = DateUtils.dateOnly(date);
    NutritionSummary total = NutritionSummary.zero;
    for (final m in meals) {
      if (DateUtils.dateOnly(m.timestamp) == day) {
        total = total + m.totalNutrients;
      }
    }
    return total;
  }

  Future<void> addMeal({
    required String name,
    required double grams,
    required MealType mealType,
    DateTime? timestamp,
  }) async {
    final id = const Uuid().v4();
    final meal = Meal(
      id: id,
      name: name.trim(),
      grams: grams,
      mealType: mealType,
      timestamp: timestamp ?? DateTime.now(),
      estimatedPer100g: null,
      estimateError: null,
    );

    await _box.put(id, meal.toMap());
    notifyListeners();

    // Fire-and-forget estimate (updates the card when it arrives).
    Future(() => _estimateAndUpdate(id));
  }

  Future<void> deleteMeal(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> updateMeal(Meal updated) async {
    await _box.put(updated.id, updated.toMap());
    notifyListeners();
  }

  Future<void> _estimateAndUpdate(String mealId) async {
    final raw = _box.get(mealId);
    if (raw == null) return;

    final meal = Meal.fromMap(Map<String, dynamic>.from(raw as Map));

    // Don't re-estimate if already estimated.
    if (meal.estimatedPer100g != null) return;

    try {
      final per100g = await _ai.estimatePer100g(
        foodName: meal.name,
        veganBias: true,
        cuisine: 'Ethiopian',
      );

      final updated = meal.copyWith(
        estimatedPer100g: per100g,
        estimateError: null,
      );

      await _box.put(mealId, updated.toMap());
      notifyListeners();
    } catch (e) {
      final updated = meal.copyWith(estimateError: e.toString());
      await _box.put(mealId, updated.toMap());
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/custom_food.dart';
import '../models/dish_template.dart';
import '../models/food_nutrients.dart';
import '../models/meal_log_item.dart';
import '../services/usda_nutrition_service.dart';

class MealProvider extends ChangeNotifier {
  final Box _mealBox = Hive.box('meal_logs_box');
  final Box _customFoodsBox = Hive.box('custom_foods_box');
  final Box _usdaCacheBox = Hive.box('usda_food_cache_box');
  final Box _dishCacheBox = Hive.box('dish_nutrition_cache_box');
  final Box _dishResolutionBox = Hive.box('dish_ingredient_resolution_box');

  // Provide USDA key via: flutter run --dart-define=USDA_API_KEY=YOUR_KEY
  static const String _usdaKey = String.fromEnvironment('USDA_API_KEY');
  late final UsdaNutritionService _usda = UsdaNutritionService(apiKey: _usdaKey);

  List<DishTemplate> get ethiopianTemplates => defaultEthiopianVeganTemplates;

  List<CustomFood> get customFoods {
    return _customFoodsBox.values
        .map((e) => CustomFood.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<MealLogItem> get allLogs {
    return _mealBox.values
        .map((e) => MealLogItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<MealLogItem> logsForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return allLogs.where((e) {
      final t = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return t == d;
    }).toList();
  }

  Map<MealType, List<MealLogItem>> logsByMealType(DateTime date) {
    final items = logsForDate(date);
    final map = <MealType, List<MealLogItem>>{
      MealType.breakfast: [],
      MealType.lunch: [],
      MealType.dinner: [],
      MealType.snack: [],
    };
    for (final i in items) {
      map[i.mealType]!.add(i);
    }
    // Keep time order
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return map;
  }

  FoodNutrients totalsForDate(DateTime date) {
    final items = logsForDate(date);
    FoodNutrients total = FoodNutrients.zero;
    for (final i in items) {
      total = total + i.totals;
    }
    return total;
  }

  Future<void> addCustomFood({
    required String name,
    required FoodNutrients per100g,
  }) async {
    final id = const Uuid().v4();
    final food = CustomFood(id: id, name: name, per100g: per100g);
    await _customFoodsBox.put(id, food.toMap());
    notifyListeners();
  }

  Future<void> deleteCustomFood(String id) async {
    await _customFoodsBox.delete(id);
    notifyListeners();
  }

  Future<void> logCustomFood({
    required CustomFood food,
    required MealType mealType,
    required DateTime timestamp,
    required double gramsEaten,
  }) async {
    final id = const Uuid().v4();
    final item = MealLogItem(
      id: id,
      timestamp: timestamp,
      mealType: mealType,
      source: MealItemSource.customFood,
      name: food.name,
      refId: food.id,
      gramsEaten: gramsEaten,
      per100g: food.per100g,
    );
    await _mealBox.put(id, item.toMap());
    notifyListeners();
  }

  Future<List<UsdaSearchResult>> searchUsda(String query) async {
    return _usda.searchFoods(query);
  }

  Future<UsdaFoodDetails> _getUsdaFoodCached(int fdcId) async {
    final key = fdcId.toString();
    final cached = _usdaCacheBox.get(key);
    if (cached != null) {
      final m = Map<String, dynamic>.from(cached as Map);
      return UsdaFoodDetails(
        fdcId: fdcId,
        description: m['description'] as String,
        per100g: FoodNutrients.fromMap(Map<String, dynamic>.from(m['per100g'] as Map)),
      );
    }

    final details = await _usda.getFoodDetails(fdcId);
    await _usdaCacheBox.put(key, {
      'description': details.description,
      'per100g': details.per100g.toMap(),
    });
    return details;
  }

  Future<void> logUsdaFood({
    required int fdcId,
    required String name,
    required MealType mealType,
    required DateTime timestamp,
    required double gramsEaten,
  }) async {
    final details = await _getUsdaFoodCached(fdcId);

    final id = const Uuid().v4();
    final item = MealLogItem(
      id: id,
      timestamp: timestamp,
      mealType: mealType,
      source: MealItemSource.usdaFood,
      name: name,
      refId: fdcId.toString(),
      gramsEaten: gramsEaten,
      per100g: details.per100g,
    );

    await _mealBox.put(id, item.toMap());
    notifyListeners();
  }

  Future<void> logDishTemplate({
    required DishTemplate template,
    required MealType mealType,
    required DateTime timestamp,
    required double gramsEaten,
  }) async {
    final per100g = await getDishPer100g(template);

    final id = const Uuid().v4();
    final item = MealLogItem(
      id: id,
      timestamp: timestamp,
      mealType: mealType,
      source: MealItemSource.dishTemplate,
      name: template.name,
      refId: template.id,
      gramsEaten: gramsEaten,
      per100g: per100g,
    );

    await _mealBox.put(id, item.toMap());
    notifyListeners();
  }

  Future<FoodNutrients> getDishPer100g(DishTemplate template) async {
    final signature = _templateSignature(template);
    final cacheKey = '${template.id}::$signature';

    final cached = _dishCacheBox.get(cacheKey);
    if (cached != null) {
      return FoodNutrients.fromMap(Map<String, dynamic>.from(cached as Map));
    }

    // Compute totals for the whole batch
    FoodNutrients batchTotal = FoodNutrients.zero;

    for (final ing in template.ingredients) {
      if (ing.query == '__water__') continue;

      final fdcId = await _resolveIngredientQueryToFdcId(ing.query);
      final details = await _getUsdaFoodCached(fdcId);

      batchTotal = batchTotal + details.per100g.scale(ing.grams / 100.0);
    }

    // Convert batch total -> per 100g cooked yield
    final per100g = batchTotal.scale(100.0 / template.yieldGrams);

    await _dishCacheBox.put(cacheKey, per100g.toMap());
    return per100g;
  }

  String _templateSignature(DishTemplate t) {
    final parts = t.ingredients
        .map((i) => '${i.query}:${i.grams.toStringAsFixed(1)}')
        .join('|');
    return 'yield:${t.yieldGrams.toStringAsFixed(1)}|$parts';
  }

  Future<int> _resolveIngredientQueryToFdcId(String query) async {
    final cached = _dishResolutionBox.get(query);
    if (cached != null) return (cached as num).toInt();

    final results = await _usda.searchFoods(query);
    if (results.isEmpty) {
      throw Exception('No USDA match found for ingredient: "$query"');
    }

    final fdcId = results.first.fdcId;
    await _dishResolutionBox.put(query, fdcId);
    return fdcId;
  }

  Future<void> deleteLog(String id) async {
    await _mealBox.delete(id);
    notifyListeners();
  }

  Future<void> updateLog(MealLogItem updated) async {
    await _mealBox.put(updated.id, updated.toMap());
    notifyListeners();
  }
}
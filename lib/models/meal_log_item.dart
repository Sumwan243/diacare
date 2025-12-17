import 'food_nutrients.dart';

enum MealType { breakfast, lunch, dinner, snack }

enum MealItemSource { dishTemplate, usdaFood, customFood }

class MealLogItem {
  final String id;
  final DateTime timestamp;
  final MealType mealType;

  final MealItemSource source;
  final String name;

  /// Template id OR USDA fdcId as string OR customFood id
  final String refId;

  final double gramsEaten;

  /// Snapshot per-100g used at log time (stable even if API changes later)
  final FoodNutrients per100g;

  const MealLogItem({
    required this.id,
    required this.timestamp,
    required this.mealType,
    required this.source,
    required this.name,
    required this.refId,
    required this.gramsEaten,
    required this.per100g,
  });

  FoodNutrients get totals => per100g.scale(gramsEaten / 100.0);

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'mealType': mealType.name,
    'source': source.name,
    'name': name,
    'refId': refId,
    'gramsEaten': gramsEaten,
    'per100g': per100g.toMap(),
  };

  factory MealLogItem.fromMap(Map<String, dynamic> map) => MealLogItem(
    id: map['id'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    mealType: MealType.values
        .firstWhere((e) => e.name == (map['mealType'] as String)),
    source: MealItemSource.values
        .firstWhere((e) => e.name == (map['source'] as String)),
    name: map['name'] as String,
    refId: map['refId'] as String,
    gramsEaten: (map['gramsEaten'] as num).toDouble(),
    per100g: FoodNutrients.fromMap(
      Map<String, dynamic>.from(map['per100g'] as Map),
    ),
  );

  MealLogItem copyWith({
    DateTime? timestamp,
    MealType? mealType,
    double? gramsEaten,
  }) {
    return MealLogItem(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      source: source,
      name: name,
      refId: refId,
      gramsEaten: gramsEaten ?? this.gramsEaten,
      per100g: per100g,
    );
  }
}
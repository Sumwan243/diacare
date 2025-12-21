import 'package:diacare/models/nutrition_summary.dart';

enum MealType { breakfast, lunch, dinner, snack }

class Meal {
  final String id;
  final String name;
  final double grams;
  final MealType mealType;
  final DateTime timestamp;

  // This now directly stores the final, total nutritional info.
  final NutritionSummary totalNutrients;

  const Meal({
    required this.id,
    required this.name,
    required this.grams,
    required this.mealType,
    required this.timestamp,
    required this.totalNutrients,
  });

  Meal copyWith({
    String? id,
    String? name,
    double? grams,
    MealType? mealType,
    DateTime? timestamp,
    NutritionSummary? totalNutrients,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      totalNutrients: totalNutrients ?? this.totalNutrients,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'grams': grams,
        'mealType': mealType.name,
        'timestamp': timestamp.toIso8601String(),
        'totalNutrients': totalNutrients.toMap(),
      };

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      name: map['name'] as String,
      grams: (map['grams'] as num).toDouble(),
      mealType: MealType.values.firstWhere((e) => e.name == map['mealType'], orElse: () => MealType.snack),
      timestamp: DateTime.parse(map['timestamp'] as String),
      totalNutrients: NutritionSummary.fromMap(
        Map<String, dynamic>.from(map['totalNutrients'] ?? {})
      ),
    );
  }
}

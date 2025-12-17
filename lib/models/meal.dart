import 'nutrition_summary.dart';

enum MealType { breakfast, lunch, dinner, snack }

class Meal {
  final String id;
  final String name;
  final double grams;
  final MealType mealType;
  final DateTime timestamp;

  /// AI estimate per 100g. Null until the estimate arrives.
  final NutritionSummary? estimatedPer100g;

  /// If AI failed, store the error so UI can show subtle fallback.
  final String? estimateError;

  const Meal({
    required this.id,
    required this.name,
    required this.grams,
    required this.mealType,
    required this.timestamp,
    required this.estimatedPer100g,
    required this.estimateError,
  });

  bool get isEstimating => estimatedPer100g == null && estimateError == null;
  bool get hasEstimate => estimatedPer100g != null;

  NutritionSummary get totalNutrients {
    final per100 = estimatedPer100g;
    if (per100 == null) return NutritionSummary.zero;
    return per100.scale(grams / 100.0);
  }

  Meal copyWith({
    String? name,
    double? grams,
    MealType? mealType,
    DateTime? timestamp,
    NutritionSummary? estimatedPer100g,
    String? estimateError,
  }) {
    return Meal(
      id: id,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      estimatedPer100g: estimatedPer100g ?? this.estimatedPer100g,
      estimateError: estimateError ?? this.estimateError,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'grams': grams,
        'mealType': mealType.name,
        'timestamp': timestamp.toIso8601String(),
        'estimatedPer100g': estimatedPer100g?.toMap(),
        'estimateError': estimateError,
      };

  factory Meal.fromMap(Map<String, dynamic> map) => Meal(
        id: map['id'] as String,
        name: map['name'] as String,
        grams: (map['grams'] as num).toDouble(),
        mealType: MealType.values.firstWhere((e) => e.name == map['mealType']),
        timestamp: DateTime.parse(map['timestamp'] as String),
        estimatedPer100g: map['estimatedPer100g'] == null
            ? null
            : NutritionSummary.fromMap(
                Map<String, dynamic>.from(map['estimatedPer100g'] as Map),
              ),
        estimateError: map['estimateError'] as String?,
      );
}

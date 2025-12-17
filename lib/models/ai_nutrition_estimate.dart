import 'food_nutrients.dart';

class AiNutritionEstimate {
  final FoodNutrients per100g;
  final List<String> assumptions;
  final String confidence; // "low" | "medium" | "high"

  const AiNutritionEstimate({
    required this.per100g,
    required this.assumptions,
    required this.confidence,
  });

  Map<String, dynamic> toMap() => {
        'per100g': per100g.toMap(),
        'assumptions': assumptions,
        'confidence': confidence,
      };

  factory AiNutritionEstimate.fromMap(Map<String, dynamic> map) {
    return AiNutritionEstimate(
      per100g: FoodNutrients.fromMap(Map<String, dynamic>.from(map['per100g'] as Map)),
      assumptions: (map['assumptions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      confidence: (map['confidence'] as String?) ?? 'low',
    );
  }
}

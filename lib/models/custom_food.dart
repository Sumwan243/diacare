import 'food_nutrients.dart';

class CustomFood {
  final String id;
  final String name;
  final FoodNutrients per100g;

  // Optional convenience if you later want "servings"
  final double? defaultServingGrams;

  const CustomFood({
    required this.id,
    required this.name,
    required this.per100g,
    this.defaultServingGrams,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'per100g': per100g.toMap(),
    'defaultServingGrams': defaultServingGrams,
  };

  factory CustomFood.fromMap(Map<String, dynamic> map) => CustomFood(
    id: map['id'] as String,
    name: map['name'] as String,
    per100g: FoodNutrients.fromMap(
      Map<String, dynamic>.from(map['per100g'] as Map),
    ),
    defaultServingGrams: (map['defaultServingGrams'] as num?)?.toDouble(),
  );
}
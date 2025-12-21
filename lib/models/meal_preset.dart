import 'package:diacare/models/nutrition_summary.dart';

class MealPreset {
  final String id;
  final String name;
  final double defaultGrams;
  final NutritionSummary nutrition;
  final String notes;
  final String source;

  const MealPreset({
    required this.id,
    required this.name,
    required this.defaultGrams,
    required this.nutrition,
    this.notes = '',
    this.source = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'defaultGrams': defaultGrams,
        'nutrition': nutrition.toMap(),
        'notes': notes,
        'source': source,
      };

  factory MealPreset.fromMap(Map<String, dynamic> m) => MealPreset(
        id: m['id'] as String,
        name: m['name'] as String,
        defaultGrams: (m['defaultGrams'] as num).toDouble(),
        nutrition: NutritionSummary.fromMap(Map<String, dynamic>.from(m['nutrition'] ?? {})),
        notes: m['notes'] as String? ?? '',
        source: m['source'] as String? ?? '',
      );
}

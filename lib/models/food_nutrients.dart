/// A generic model to hold macronutrient data.
class FoodNutrients {
  final double caloriesKcal;
  final double carbsG;
  final double fiberG;
  final double proteinG;
  final double fatG;

  const FoodNutrients({
    this.caloriesKcal = 0,
    this.carbsG = 0,
    this.fiberG = 0,
    this.proteinG = 0,
    this.fatG = 0,
  });

  /// Returns a new FoodNutrients object with all values scaled by a factor.
  FoodNutrients scale(double factor) {
    return FoodNutrients(
      caloriesKcal: caloriesKcal * factor,
      carbsG: carbsG * factor,
      fiberG: fiberG * factor,
      proteinG: proteinG * factor,
      fatG: fatG * factor,
    );
  }

  Map<String, dynamic> toMap() => {
        'kcal': caloriesKcal,
        'carbs_g': carbsG,
        'fiber_g': fiberG,
        'protein_g': proteinG,
        'fat_g': fatG,
      };

  factory FoodNutrients.fromMap(Map<String, dynamic> map) {
    return FoodNutrients(
      caloriesKcal: (map['kcal'] as num?)?.toDouble() ?? 0,
      carbsG: (map['carbs_g'] as num?)?.toDouble() ?? 0,
      fiberG: (map['fiber_g'] as num?)?.toDouble() ?? 0,
      proteinG: (map['protein_g'] as num?)?.toDouble() ?? 0,
      fatG: (map['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FoodNutrients {
  final double caloriesKcal;
  final double carbsG;
  final double fiberG;
  final double proteinG;
  final double fatG;

  const FoodNutrients({
    required this.caloriesKcal,
    required this.carbsG,
    required this.fiberG,
    required this.proteinG,
    required this.fatG,
  });

  static const zero = FoodNutrients(
    caloriesKcal: 0,
    carbsG: 0,
    fiberG: 0,
    proteinG: 0,
    fatG: 0,
  );

  FoodNutrients operator +(FoodNutrients other) => FoodNutrients(
    caloriesKcal: caloriesKcal + other.caloriesKcal,
    carbsG: carbsG + other.carbsG,
    fiberG: fiberG + other.fiberG,
    proteinG: proteinG + other.proteinG,
    fatG: fatG + other.fatG,
  );

  FoodNutrients scale(double factor) => FoodNutrients(
    caloriesKcal: caloriesKcal * factor,
    carbsG: carbsG * factor,
    fiberG: fiberG * factor,
    proteinG: proteinG * factor,
    fatG: fatG * factor,
  );

  double get netCarbsG => (carbsG - fiberG).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    'caloriesKcal': caloriesKcal,
    'carbsG': carbsG,
    'fiberG': fiberG,
    'proteinG': proteinG,
    'fatG': fatG,
  };

  factory FoodNutrients.fromMap(Map<String, dynamic> map) => FoodNutrients(
    caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble() ?? 0,
    carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0,
    fiberG: (map['fiberG'] as num?)?.toDouble() ?? 0,
    proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0,
    fatG: (map['fatG'] as num?)?.toDouble() ?? 0,
  );
}
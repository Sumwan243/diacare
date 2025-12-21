class NutritionSummary {
  final double caloriesKcal;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final double fiberG;
  final Map<String, double> micros;

  const NutritionSummary({
    required this.caloriesKcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.fiberG = 0.0, // FIX: Made this parameter optional with a default value
    this.micros = const {},
  });

  static const zero = NutritionSummary(
    caloriesKcal: 0,
    carbsG: 0,
    proteinG: 0,
    fatG: 0,
    fiberG: 0,
    micros: {},
  );

  NutritionSummary operator +(NutritionSummary other) {
    return NutritionSummary(
      caloriesKcal: caloriesKcal + other.caloriesKcal,
      carbsG: carbsG + other.carbsG,
      proteinG: proteinG + other.proteinG,
      fatG: fatG + other.fatG,
      fiberG: fiberG + other.fiberG,
      micros: _mergeMicros(micros, other.micros),
    );
  }

  static Map<String, double> _mergeMicros(Map<String, double> a, Map<String, double> b) {
    final out = <String, double>{};
    for (final e in a.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value;
    }
    for (final e in b.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value;
    }
    return out;
  }

  Map<String, dynamic> toMap() {
    return {
      'caloriesKcal': caloriesKcal,
      'carbsG': carbsG,
      'proteinG': proteinG,
      'fatG': fatG,
      'fiberG': fiberG,
      'micros': micros,
    };
  }

  factory NutritionSummary.fromMap(Map<String, dynamic> map) {
    return NutritionSummary(
      caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble() ?? 0.0,
      carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0.0,
      proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0.0,
      fatG: (map['fatG'] as num?)?.toDouble() ?? 0.0,
      fiberG: (map['fiberG'] as num?)?.toDouble() ?? 0.0,
      micros: Map<String, double>.from((map['micros'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {}),
    );
  }

  NutritionSummary scale(double ratio) {
    return NutritionSummary(
      caloriesKcal: caloriesKcal * ratio,
      carbsG: carbsG * ratio,
      proteinG: proteinG * ratio,
      fatG: fatG * ratio,
      fiberG: fiberG * ratio,
      micros: micros.map((k, v) => MapEntry(k, v * ratio)),
    );
  }
}

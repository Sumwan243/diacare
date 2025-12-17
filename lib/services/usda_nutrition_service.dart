import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/food_nutrients.dart';

class UsdaSearchResult {
  final int fdcId;
  final String description;
  final String? dataType;

  const UsdaSearchResult({
    required this.fdcId,
    required this.description,
    this.dataType,
  });
}

class UsdaFoodDetails {
  final int fdcId;
  final String description;
  final FoodNutrients per100g;

  const UsdaFoodDetails({
    required this.fdcId,
    required this.description,
    required this.per100g,
  });
}

/// USDA FoodData Central API docs:
/// https://fdc.nal.usda.gov/api-guide.html
class UsdaNutritionService {
  final String apiKey;
  final http.Client _client;

  UsdaNutritionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void _requireKey() {
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'USDA_API_KEY is not set. Provide it via --dart-define=USDA_API_KEY=YOUR_KEY',
      );
    }
  }

  Future<List<UsdaSearchResult>> searchFoods(String query) async {
    _requireKey();

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': apiKey,
    });

    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'pageSize': 20,
        // Prefer foundational-ish entries for ingredients
        'dataType': ['Foundation', 'SR Legacy'],
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('USDA search failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final foods = (json['foods'] as List?) ?? const [];

    return foods.map((f) {
      final m = Map<String, dynamic>.from(f as Map);
      return UsdaSearchResult(
        fdcId: (m['fdcId'] as num).toInt(),
        description: (m['description'] as String?) ?? 'Unknown',
        dataType: m['dataType'] as String?,
      );
    }).toList();
  }

  Future<UsdaFoodDetails> getFoodDetails(int fdcId) async {
    _requireKey();

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/food/$fdcId', {
      'api_key': apiKey,
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('USDA details failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final description = (json['description'] as String?) ?? 'Unknown';

    final per100g = _extractPer100gNutrients(json);

    return UsdaFoodDetails(
      fdcId: fdcId,
      description: description,
      per100g: per100g,
    );
  }

  FoodNutrients _extractPer100gNutrients(Map<String, dynamic> json) {
    // FDC returns nutrients in "foodNutrients" with nutrient info + amount.
    // Many Foundation/SR entries are per 100g by default.
    final list = (json['foodNutrients'] as List?) ?? const [];

    double energyKcal = 0;
    double carbs = 0;
    double fiber = 0;
    double protein = 0;
    double fat = 0;

    for (final n in list) {
      final m = Map<String, dynamic>.from(n as Map);

      final amount = (m['amount'] as num?)?.toDouble();
      if (amount == null) continue;

      final nutrient = (m['nutrient'] as Map?) != null
          ? Map<String, dynamic>.from(m['nutrient'] as Map)
          : null;

      final number = nutrient?['number']?.toString(); // e.g., "1008"
      final name = (nutrient?['name'] as String?)?.toLowerCase() ?? '';

      // Common nutrient numbers in USDA FDC:
      // 1008 = Energy (kcal), 1005 = Carbohydrate, 1079 = Fiber,
      // 1003 = Protein, 1004 = Total lipid (fat)
      if (number == '1008' || name.contains('energy')) energyKcal = amount;
      if (number == '1005' || name.contains('carbohydrate')) carbs = amount;
      if (number == '1079' || name.contains('fiber')) fiber = amount;
      if (number == '1003' || name.contains('protein')) protein = amount;
      if (number == '1004' || name.contains('total lipid') || name == 'fat') {
        fat = amount;
      }
    }

    return FoodNutrients(
      caloriesKcal: energyKcal,
      carbsG: carbs,
      fiberG: fiber,
      proteinG: protein,
      fatG: fat,
    );
  }
}
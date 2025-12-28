import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_summary.dart';

class OpenAiMealEstimator {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini'; // demo-friendly
  static const int _cacheVersion = 1;

  final http.Client _client;
  final Box _cache; // ai_nutrition_cache_box

  OpenAiMealEstimator({
    http.Client? client,
    Box? cacheBox,
  })  : _client = client ?? http.Client(),
        _cache = cacheBox ?? Hive.box('ai_nutrition_cache_box');

  void _requireKey() {
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is not set. Use --dart-define=OPENAI_API_KEY=YOUR_KEY',
      );
    }
  }

  Future<NutritionSummary> estimatePer100g({
    required String foodName,
    bool veganBias = true,
    String cuisine = 'Ethiopian',
  }) async {
    _requireKey();

    final normalized = foodName.trim().toLowerCase();
    final cacheKey = sha256
        .convert(utf8.encode('v=$_cacheVersion|$normalized|$veganBias|$cuisine'))
        .toString();

    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return NutritionSummary.fromMap(Map<String, dynamic>.from(cached as Map));
    }

    final prompt = '''
Estimate nutrition per 100 grams for the prepared dish/food.
Food: "$foodName"
Cuisine context: $cuisine
Diet bias: ${veganBias ? 'assume vegan unless clearly not' : 'no bias'}

Return ONLY valid JSON with this exact shape:
{
  "kcal": number,
  "carbs_g": number,
  "fiber_g": number,
  "protein_g": number,
  "fat_g": number
}

Rules:
- numbers must be >= 0
- be realistic for cooked foods (stews are often lower kcal per 100g than dry foods)
''';

    final resp = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.2,
        // If this errors on your chosen model, remove it and parse JSON defensively.
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': 'You output JSON only. No extra text.',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI error: ${resp.statusCode} ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final choice = (body['choices'] as List).first as Map<String, dynamic>;
    final content = (choice['message'] as Map)['content']?.toString() ?? '';

    final decoded = jsonDecode(content) as Map<String, dynamic>;

    final n = NutritionSummary(
      caloriesKcal: ((decoded['kcal'] as num?)?.toDouble() ?? 0).clamp(0, 900),
      carbsG: ((decoded['carbs_g'] as num?)?.toDouble() ?? 0).clamp(0, 100),
      fiberG: ((decoded['fiber_g'] as num?)?.toDouble() ?? 0).clamp(0, 50),
      proteinG: ((decoded['protein_g'] as num?)?.toDouble() ?? 0).clamp(0, 80),
      fatG: ((decoded['fat_g'] as num?)?.toDouble() ?? 0).clamp(0, 100),
    );

    await _cache.put(cacheKey, n.toMap());
    return n;
  }
}
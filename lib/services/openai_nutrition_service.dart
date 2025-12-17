import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/ai_nutrition_estimate.dart';
import '../models/food_nutrients.dart';

class OpenAiNutritionService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const int _cacheVersion = 1;

  final http.Client _client;
  final Box _cacheBox;

  OpenAiNutritionService({
    http.Client? client,
    Box? cacheBox,
  })  : _client = client ?? http.Client(),
        _cacheBox = cacheBox ?? Hive.box('ai_nutrition_cache_box');

  void _requireKey() {
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is not set. Run with --dart-define=OPENAI_API_KEY=YOUR_KEY',
      );
    }
  }

  Future<AiNutritionEstimate> estimatePer100gForDish({
    required String dishName,
    bool vegan = true,
    String cuisine = 'Ethiopian',
    String cookingStyle = 'home-cooked, typical oil',
    String notes = '',
  }) async {
    _requireKey();

    final prompt = '''
Estimate nutrition per 100 grams for the prepared dish.
Dish: "$dishName"
Cuisine: $cuisine
Diet: ${vegan ? 'vegan' : 'not necessarily vegan'}
Cooking style: $cookingStyle
Notes: $notes

Return ONLY valid JSON with this exact shape:
{
  "per_100g": {"kcal": number, "carbs_g": number, "fiber_g": number, "protein_g": number, "fat_g": number},
  "assumptions": [string, ...],
  "confidence": "low" | "medium" | "high"
}

Rules:
- Numbers must be >= 0.
- Keep estimates realistic for a wet stew-like dish when applicable.
- If uncertain, set confidence="low" and explain assumptions.
''';

    final cacheKey = _hash('v=$_cacheVersion|dish=$dishName|$vegan|$cuisine|$cookingStyle|$notes');
    final cached = _cacheBox.get(cacheKey);
    if (cached != null) {
      return AiNutritionEstimate.fromMap(Map<String, dynamic>.from(cached as Map));
    }

    final content = await _callOpenAiJson(prompt);

    final decoded = _safeJsonDecode(content);
    final per100gMap = Map<String, dynamic>.from(decoded['per_100g'] as Map);

    final estimate = AiNutritionEstimate(
      per100g: _validatePer100g(
        FoodNutrients(
          caloriesKcal: (per100gMap['kcal'] as num?)?.toDouble() ?? 0,
          carbsG: (per100gMap['carbs_g'] as num?)?.toDouble() ?? 0,
          fiberG: (per100gMap['fiber_g'] as num?)?.toDouble() ?? 0,
          proteinG: (per100gMap['protein_g'] as num?)?.toDouble() ?? 0,
          fatG: (per100gMap['fat_g'] as num?)?.toDouble() ?? 0,
        ),
      ),
      assumptions: (decoded['assumptions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      confidence: (decoded['confidence'] as String?) ?? 'low',
    );

    await _cacheBox.put(cacheKey, estimate.toMap());
    return estimate;
  }

  Future<String> _callOpenAiJson(String userPrompt) async {
    // Uses Chat Completions API. Docs:
    // https://platform.openai.com/docs/api-reference/chat/create
    final resp = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // change if needed
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition estimation engine. Output JSON only. No extra text.'
          },
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI error: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw Exception('OpenAI returned no choices.');

    final message = Map<String, dynamic>.from(choices.first as Map)['message'] as Map;
    final content = message['content']?.toString() ?? '';
    if (content.trim().isEmpty) throw Exception('OpenAI returned empty content.');
    return content;
  }

  Map<String, dynamic> _safeJsonDecode(String text) {
    // response_format=json_object should give clean JSON, but be defensive.
    final trimmed = text.trim();
    try {
      return Map<String, dynamic>.from(jsonDecode(trimmed) as Map);
    } catch (_) {
      final extracted = _extractFirstJsonObject(trimmed);
      return Map<String, dynamic>.from(jsonDecode(extracted) as Map);
    }
  }

  String _extractFirstJsonObject(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception('Could not find JSON object in AI response.');
    }
    return s.substring(start, end + 1);
  }

  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  FoodNutrients _validatePer100g(FoodNutrients n) {
    // Clamp out insane values to keep UI safe.
    double clamp(double v, double lo, double hi) => v.isNaN ? lo : v.clamp(lo, hi);

    return FoodNutrients(
      caloriesKcal: clamp(n.caloriesKcal, 0, 900), // per 100g
      carbsG: clamp(n.carbsG, 0, 100),
      fiberG: clamp(n.fiberG, 0, 50),
      proteinG: clamp(n.proteinG, 0, 80),
      fatG: clamp(n.fatG, 0, 100),
    );
  }
}

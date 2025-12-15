import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';

  Future<String> generateRecommendation({
    required String diabeticType,     // e.g. "Type 2"
    required String focusArea,        // "meals", "medication", "glucose"
    required String historySummary,   // short text we build from your data
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final systemPrompt = """
You are a diabetic health assistant. The user has $diabeticType diabetes.
You will receive a short summary of their recent data and a focus area.
Provide one concise, practical recommendation (max 80 words) for that area.
Do NOT change medications/insulin doses. Avoid emergency-level decisions.
If the history suggests dangerous patterns (very high/low sugar), recommend they speak to a doctor.
""";

    final userPrompt = """
Focus area: $focusArea
Patient history summary:
$historySummary

Give one clear recommendation only, no bullet points, no greeting, no closing.
""";

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userPrompt},
      ],
      "temperature": 0.7,
      "max_tokens": 200,
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        return text.trim();
      } else {
        return 'Unable to generate recommendation right now (${response.statusCode}).';
      }
    } catch (e) {
      return 'Could not reach the AI service. Check your internet connection.';
    }
  }
}
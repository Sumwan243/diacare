import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = "Loading insights...";

  Future<void> fetchRecommendation({
    required List<Map<String, dynamic>> glucose,
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer YOUR_OPENAI_API_KEY",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": "You are an assistant giving diabetic health insights."
            },
            {
              "role": "user",
              "content": """
Glucose readings: $glucose
Meals: $meals

Give a short 1–2 sentence health insight.
"""
            }
          ]
        }),
      );

      final data = jsonDecode(res.body);
      recommendation = data["choices"][0]["message"]["content"];
      notifyListeners();
    } catch (e) {
      recommendation = "Unable to load insights.";
      notifyListeners();
    }
  }
}

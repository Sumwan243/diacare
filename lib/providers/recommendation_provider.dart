import 'package:diacare/services/ai_service.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = "Tap to get personalized health recommendations";
  bool isLoading = false;
  final AIService _aiService = AIService();

  Future<void> fetchRecommendation({
    required List<Map<String, dynamic>> glucose,
    required List<Map<String, dynamic>> meals,
  }) async {
    if (isLoading) return;
    
    isLoading = true;
    recommendation = "Analyzing your data...";
    notifyListeners();

    try {
      // Prepare data summary for AI
      final glucoseSummary = glucose.isEmpty 
          ? "No glucose readings recorded"
          : "Latest: ${glucose.first['level']} mg/dL (${glucose.first['context']})";
      
      final mealsSummary = meals.isEmpty
          ? "No meals logged today"
          : "${meals.length} meal(s) logged today";

      final prompt = '''
You are a helpful diabetic health assistant. Based on the user's health data, provide a brief, personalized recommendation (1-2 sentences).

Glucose readings: $glucoseSummary
Meals: $mealsSummary

Provide a friendly, encouraging health tip or recommendation. Be specific and actionable. If data is limited, suggest logging more information.

Response format: Just the recommendation text, no quotes or formatting.
''';

      // Use Gemini API for recommendations
      final aiRecommendation = await _aiService.getRecommendation(prompt);
      
      if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
        recommendation = aiRecommendation;
      } else {
        // Fallback to simple recommendation if AI fails
        recommendation = _generateRecommendation(glucose, meals);
      }
    } catch (e) {
      debugPrint('Error fetching recommendation: $e');
      recommendation = _generateRecommendation(glucose, meals);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _generateRecommendation(List<Map<String, dynamic>> glucose, List<Map<String, dynamic>> meals) {
    if (glucose.isEmpty && meals.isEmpty) {
      return "Start logging your glucose readings and meals to get personalized recommendations!";
    }
    
    if (glucose.isNotEmpty) {
      final latest = glucose.first;
      final level = latest['level'] as int? ?? 0;
      
      if (level > 180) {
        return "Your glucose is elevated. Consider light exercise or reviewing your recent meals.";
      } else if (level < 70) {
        return "Your glucose is low. Have a quick snack and monitor closely.";
      } else if (level >= 70 && level <= 100) {
        return "Great glucose levels! Keep up your healthy habits.";
      } else {
        return "Your glucose is in a good range. Continue monitoring and maintaining your routine.";
      }
    }
    
    if (meals.isNotEmpty) {
      return "You've logged ${meals.length} meal(s) today. Remember to check your glucose 2 hours after meals.";
    }
    
    return "Keep tracking your health data for better insights!";
  }
}

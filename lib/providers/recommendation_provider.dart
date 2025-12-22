import 'package:diacare/services/ai_service.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = "Tap to get personalized health recommendations";
  bool isLoading = false;
  final AIService _aiService = AIService();
  DateTime? lastUpdated;
  final Duration _cacheDuration = const Duration(minutes: 15);

    Future<void> fetchRecommendation({
    List<Map<String, dynamic>>? glucose,
    List<Map<String, dynamic>>? meals,
    List<Map<String, dynamic>>? medications,
    Map<String, dynamic>? bloodPressure,
    Map<String, dynamic>? activity,
    List<Map<String, dynamic>>? intakeLogs,
    bool force = false,
    }) async {
    if (isLoading) return;

    // Rate-limit using cacheDuration unless forced
    if (!force && lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated!);
      if (diff < _cacheDuration) return;
    }
    
    isLoading = true;
    recommendation = "Analyzing your data...";
    notifyListeners();

    try {
      // Prepare data summary for AI
      final glucoseSummary = (glucose == null || glucose.isEmpty)
        ? "No glucose readings recorded"
        : "Latest: ${glucose.first['level']} mg/dL (${glucose.first['context']})";

      final mealsSummary = (meals == null || meals.isEmpty)
        ? "No meals logged"
        : "${meals.length} meal(s) logged (latest: ${meals.first['name'] ?? 'meal'})";

      final medsSummary = (medications == null || medications.isEmpty)
        ? "No medications tracked"
        : "${medications.length} medication(s) tracked: ${medications.map((m) => m['name']).take(3).join(', ')}";

      final bpSummary = (bloodPressure == null)
        ? "No blood pressure readings"
        : "Latest BP: ${bloodPressure['systolic']}/${bloodPressure['diastolic']} mmHg";

      final activitySummary = (activity == null || activity.isEmpty)
        ? "No recent activity logged"
        : "Today: ${activity['duration'] ?? 0} mins activity";

      final intakeSummary = (intakeLogs == null || intakeLogs.isEmpty)
        ? "No recent medication intake logs"
        : "${intakeLogs.length} intake confirmations in recent logs";

      final prompt = '''
    You are a helpful diabetic health assistant. Based on the user's health data, provide a brief, personalized recommendation (1-2 sentences).

    Glucose readings: $glucoseSummary
    Meals: $mealsSummary
    Medications: $medsSummary
    Blood pressure: $bpSummary
    Activity: $activitySummary
    Medication intake logs: $intakeSummary

    Provide a friendly, encouraging health tip or recommendation. Be specific and actionable (one or two simple steps). If data is limited, suggest what to log next.

    Privacy: Do not request personal identifiers. Use only the provided summaries.

    Response format: Just the recommendation text, no quotes or formatting.
    ''';

      // Use Gemini API for recommendations
      final aiRecommendation = await _aiService.getRecommendation(prompt);
      
      if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
        recommendation = aiRecommendation;
      } else {
        // Fallback to simple recommendation if AI fails
        recommendation = _generateRecommendation(glucose ?? [], meals ?? []);
      }
      lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching recommendation: $e');
      recommendation = _generateRecommendation(glucose ?? [], meals ?? []);
      lastUpdated = lastUpdated ?? DateTime.now();
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
  String? get lastUpdatedDisplay => lastUpdated == null ? null : lastUpdated!.toLocal().toString().split('.').first;
}

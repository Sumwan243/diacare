import 'package:diacare/services/ai_service.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = ""; // Start with empty recommendation
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
      Map<String, dynamic>? userProfile,
      Map<String, dynamic>? glucoseStats,
      Map<String, dynamic>? mealStats,
      bool force = false,
    }) async {
    debugPrint('AI Analysis - fetchRecommendation called with force: $force');
    debugPrint('AI Analysis - Current recommendation: "${recommendation.isEmpty ? "EMPTY" : recommendation.substring(0, recommendation.length > 50 ? 50 : recommendation.length)}..."');
    debugPrint('AI Analysis - isLoading: $isLoading');
    
    if (isLoading) {
      debugPrint('AI Analysis - Already loading, returning early');
      return;
    }

      // Rate-limit: return cached if recent and not forced
      if (!force && lastUpdated != null) {
        final diff = DateTime.now().difference(lastUpdated!);
        if (diff < _cacheDuration) {
          debugPrint('AI Analysis - Using cached recommendation (${diff.inMinutes} minutes old)');
          return;
        }
      }
    
    isLoading = true;
    recommendation = "Analyzing your health data...";
    notifyListeners();

    try {
      // Extract user profile information
      final diabetesType = userProfile?['diabeticType'] ?? 'Type 2';
      final age = userProfile?['age'] ?? 0;
      final hypoThreshold = userProfile?['hypoThreshold'] ?? 70;
      final hyperThreshold = userProfile?['hyperThreshold'] ?? 300;
      final name = userProfile?['name'] ?? 'there';

      debugPrint('AI Analysis - Diabetes Type: $diabetesType, Age: $age');
      debugPrint('AI Analysis - Glucose entries: ${glucose?.length ?? 0}');
      debugPrint('AI Analysis - Meals: ${meals?.length ?? 0}');
      debugPrint('AI Analysis - Medications: ${medications?.length ?? 0}');

      // Prepare comprehensive data summary for AI with weekly analysis
      final glucoseSummary = (glucose == null || glucose.isEmpty)
        ? "No glucose readings recorded"
        : glucoseStats != null 
          ? "Weekly: ${glucoseStats['weeklyCount']} readings, avg ${glucoseStats['averageLevel']?.toInt()} mg/dL. ${glucoseStats['inRangeReadings']} in range, ${glucoseStats['highReadings']} high, ${glucoseStats['lowReadings']} low. Latest: ${glucose.first['level']} mg/dL (${glucose.first['context']})"
          : "Latest: ${glucose.first['level']} mg/dL (${glucose.first['context']}). Recent readings: ${glucose.take(3).map((g) => '${g['level']} mg/dL').join(', ')}";

      final mealsSummary = (meals == null || meals.isEmpty)
        ? "No meals logged this week"
        : mealStats != null
          ? "Weekly: ${mealStats['weeklyCount']} meals (${mealStats['avgDailyMeals']?.toStringAsFixed(1)} per day). Total: ${mealStats['totalCalories']?.toInt()} cal, ${mealStats['totalCarbs']?.toInt()}g carbs. Avg per meal: ${mealStats['avgCaloriesPerMeal']?.toInt()} cal, ${mealStats['avgCarbsPerMeal']?.toInt()}g carbs"
          : "${meals.length} meal(s) logged recently. Latest: ${meals.first['name'] ?? 'meal'} (${meals.first['calories']?.toInt() ?? 0} cal, ${meals.first['carbs']?.toInt() ?? 0}g carbs)";

      final medsSummary = (medications == null || medications.isEmpty)
        ? "No medications tracked"
        : "${medications.length} medication(s) tracked: ${medications.map((m) => m['name']).take(3).join(', ')}";

      final bpSummary = (bloodPressure == null)
        ? "No blood pressure readings this week"
        : bloodPressure['weeklyCount'] != null && bloodPressure['weeklyCount'] > 1
          ? "Weekly: ${bloodPressure['weeklyCount']} readings, avg ${bloodPressure['avgSystolic']?.toInt()}/${bloodPressure['avgDiastolic']?.toInt()} mmHg. Latest: ${bloodPressure['systolic']}/${bloodPressure['diastolic']} mmHg"
          : "Latest BP: ${bloodPressure['systolic']}/${bloodPressure['diastolic']} mmHg";

      final activitySummary = (activity == null || activity.isEmpty)
        ? "No recent activity logged"
        : "Today: ${activity['steps'] ?? 0} steps, ${activity['duration'] ?? 0} mins activity";

      final intakeSummary = (intakeLogs == null || intakeLogs.isEmpty)
        ? "No recent medication intake confirmations"
        : "${intakeLogs.length} medication intake confirmations in recent logs";

      // Get diabetes-specific context
      final diabetesContext = _getDiabetesSpecificContext(diabetesType);

      final prompt = '''
You are a specialized diabetes health assistant providing personalized recommendations for a $diabetesType diabetes patient.

PATIENT PROFILE:
- Diabetes Type: $diabetesType
- Age: $age years
- Hypoglycemia threshold: $hypoThreshold mg/dL
- Hyperglycemia threshold: $hyperThreshold mg/dL

WEEKLY HEALTH DATA ANALYSIS:
- Glucose readings: $glucoseSummary
- Meals & Nutrition: $mealsSummary
- Medications: $medsSummary
- Blood pressure: $bpSummary
- Physical activity: $activitySummary
- Medication adherence: $intakeSummary

DIABETES-SPECIFIC CONTEXT:
$diabetesContext

INSTRUCTIONS:
1. Provide a comprehensive WEEKLY health assessment covering patterns and trends
2. Give 2-3 specific, actionable recommendations based on the weekly data patterns
3. Use encouraging, supportive tone with emojis for visual appeal
4. Focus on weekly trends, averages, and patterns rather than just latest readings
5. Consider interactions between different health metrics over the week
6. If glucose patterns show concerning trends, prioritize that but still mention other areas
7. Keep response to 3-4 sentences maximum for readability
8. Highlight both positive patterns and areas for improvement

Response format: Weekly assessment with trend-based recommendations. Address the user as "$name" when appropriate. Use emojis to make it visually appealing and easy to scan.

Example format: "📊 This week you averaged X mg/dL glucose with Y readings in range. 🍽️ Your Z meals show W pattern. 🚶 Consider A for better B. 💊 Keep up C."
    ''';

      // Use Gemini API for recommendations with user's API key
      final userApiKey = userProfile?['geminiApiKey'] as String?;
      debugPrint('AI Analysis - Using API key: ${userApiKey?.isNotEmpty == true ? "Yes" : "No"}');
      
      final aiRecommendation = await _aiService.getRecommendation(prompt, userApiKey: userApiKey);
      
      debugPrint('AI Analysis - Response received: ${aiRecommendation?.isNotEmpty == true ? "Yes" : "No"}');
      
      if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
        recommendation = aiRecommendation;
        debugPrint('AI Analysis - Recommendation: ${aiRecommendation.substring(0, aiRecommendation.length > 100 ? 100 : aiRecommendation.length)}...');
      } else {
        // Enhanced fallback with diabetes-specific recommendations
        recommendation = _generateDiabetesSpecificRecommendation(
          glucose ?? [], 
          meals ?? [], 
          diabetesType, 
          hypoThreshold, 
          hyperThreshold,
          bloodPressure: bloodPressure,
          activity: activity,
          medications: medications,
          intakeLogs: intakeLogs,
          glucoseStats: glucoseStats,
          mealStats: mealStats,
        );
        debugPrint('AI Analysis - Using fallback recommendation');
      }
      lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching recommendation: $e');
      recommendation = _generateDiabetesSpecificRecommendation(
        glucose ?? [], 
        meals ?? [], 
        userProfile?['diabeticType'] ?? 'Type 2',
        userProfile?['hypoThreshold'] ?? 70,
        userProfile?['hyperThreshold'] ?? 300,
        bloodPressure: bloodPressure,
        activity: activity,
        medications: medications,
        intakeLogs: intakeLogs,
        glucoseStats: glucoseStats,
        mealStats: mealStats,
      );
      lastUpdated = lastUpdated ?? DateTime.now();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? get lastUpdatedDisplay => lastUpdated == null ? null : lastUpdated!.toLocal().toString().split('.').first;

  String _getDiabetesSpecificContext(String diabetesType) {
    switch (diabetesType) {
      case 'Type 1':
        return '''
Type 1 diabetes requires insulin management and careful carb counting. Key focus areas:
- Insulin timing and dosing relative to meals
- Carbohydrate counting accuracy
- Exercise impact on blood sugar
- Prevention of diabetic ketoacidosis (DKA)
- Frequent glucose monitoring (4+ times daily)
        ''';
      case 'Type 2':
        return '''
Type 2 diabetes management focuses on lifestyle and medication adherence. Key focus areas:
- Medication adherence (metformin, etc.)
- Weight management and portion control
- Regular physical activity (150+ mins/week)
- Carbohydrate moderation
- Blood pressure and cholesterol monitoring
        ''';
      case 'Prediabetes':
        return '''
Prediabetes prevention focuses on lifestyle changes to prevent progression. Key focus areas:
- Weight loss (5-10% of body weight)
- Regular physical activity (150+ mins/week)
- Reduced refined carbohydrates and sugars
- Portion control and meal timing
- Regular glucose monitoring
        ''';
      case 'Gestational':
        return '''
Gestational diabetes requires careful monitoring for mother and baby. Key focus areas:
- Frequent glucose monitoring (4+ times daily)
- Careful carbohydrate distribution across meals
- Safe physical activity during pregnancy
- Weight gain monitoring
- Coordination with obstetric care
        ''';
      default:
        return 'General diabetes management focusing on glucose control, medication adherence, and lifestyle factors.';
    }
  }

  String _generateDiabetesSpecificRecommendation(
    List<Map<String, dynamic>> glucose, 
    List<Map<String, dynamic>> meals,
    String diabetesType,
    double hypoThreshold,
    double hyperThreshold,
    {Map<String, dynamic>? bloodPressure,
    Map<String, dynamic>? activity,
    List<Map<String, dynamic>>? medications,
    List<Map<String, dynamic>>? intakeLogs,
    Map<String, dynamic>? glucoseStats,
    Map<String, dynamic>? mealStats}
  ) {
    List<String> insights = [];
    
    // Analyze glucose data with weekly patterns
    if (glucoseStats != null && glucoseStats['weeklyCount'] > 0) {
      final weeklyCount = glucoseStats['weeklyCount'] as int;
      final avgLevel = (glucoseStats['averageLevel'] as double).toInt();
      final inRange = glucoseStats['inRangeReadings'] as int;
      final highReadings = glucoseStats['highReadings'] as int;
      final lowReadings = glucoseStats['lowReadings'] as int;
      
      if (lowReadings > weeklyCount * 0.2) { // More than 20% low
        insights.add("⚠️ ${lowReadings}/${weeklyCount} readings were low this week (avg ${avgLevel} mg/dL). Review meal timing and medication dosing.");
      } else if (highReadings > weeklyCount * 0.2) { // More than 20% high
        insights.add("⚠️ ${highReadings}/${weeklyCount} readings were high this week (avg ${avgLevel} mg/dL). Consider reviewing carb intake and activity.");
      } else if (inRange > weeklyCount * 0.7) { // More than 70% in range
        insights.add("✅ Excellent glucose control this week! ${inRange}/${weeklyCount} readings in range (avg ${avgLevel} mg/dL).");
      } else {
        insights.add("📊 Mixed glucose patterns this week: ${inRange}/${weeklyCount} in range, avg ${avgLevel} mg/dL. Let's optimize your routine.");
      }
    } else if (glucose.isNotEmpty) {
      final latest = glucose.first;
      final level = latest['level'] as int? ?? 0;
      
      if (level < hypoThreshold) {
        insights.add("⚠️ Your glucose is low ($level mg/dL). Have 15g fast carbs and recheck in 15 minutes.");
      } else if (level > hyperThreshold) {
        insights.add("⚠️ Your glucose is elevated ($level mg/dL). Consider light exercise and review recent meals.");
      } else {
        insights.add("✅ Good glucose reading ($level mg/dL).");
      }
    } else {
      insights.add("📊 Start logging glucose readings for weekly pattern analysis.");
    }
    
    // Analyze meal data with weekly patterns
    if (mealStats != null && mealStats['weeklyCount'] > 0) {
      final weeklyCount = mealStats['weeklyCount'] as int;
      final avgDaily = (mealStats['avgDailyMeals'] as double);
      final avgCarbs = (mealStats['avgCarbsPerMeal'] as double).toInt();
      final totalCarbs = (mealStats['totalCarbs'] as double).toInt();
      
      if (avgDaily < 2.5) {
        insights.add("🍽️ Only ${avgDaily.toStringAsFixed(1)} meals/day this week. Try for 3 regular meals for better glucose stability.");
      } else if (avgCarbs > 60) {
        insights.add("🍽️ High carb meals this week (avg ${avgCarbs}g per meal, ${totalCarbs}g total). Consider smaller portions.");
      } else {
        insights.add("🍽️ Good meal logging: ${weeklyCount} meals this week, avg ${avgCarbs}g carbs per meal.");
      }
    } else if (meals.isNotEmpty) {
      final totalMeals = meals.length;
      final totalCarbs = meals.fold<double>(0, (sum, meal) => sum + (meal['carbs'] as double? ?? 0));
      insights.add("🍽️ You've logged $totalMeals recent meal(s) with ${totalCarbs.toInt()}g total carbs.");
    } else {
      insights.add("🍽️ Log your meals to track weekly nutrition patterns and carb intake.");
    }
    
    // Analyze blood pressure with weekly data
    if (bloodPressure != null) {
      if (bloodPressure['weeklyCount'] != null && bloodPressure['weeklyCount'] > 1) {
        final weeklyCount = bloodPressure['weeklyCount'] as int;
        final avgSys = (bloodPressure['avgSystolic'] as double).toInt();
        final avgDia = (bloodPressure['avgDiastolic'] as double).toInt();
        
        if (avgSys > 140 || avgDia > 90) {
          insights.add("❤️ Weekly BP average is elevated ($avgSys/$avgDia from $weeklyCount readings). Consider reducing sodium and increasing activity.");
        } else {
          insights.add("❤️ Good weekly BP control: avg $avgSys/$avgDia from $weeklyCount readings.");
        }
      } else {
        final systolic = bloodPressure['systolic'] as int? ?? 0;
        final diastolic = bloodPressure['diastolic'] as int? ?? 0;
        if (systolic > 140 || diastolic > 90) {
          insights.add("❤️ Blood pressure is elevated ($systolic/$diastolic). Consider reducing sodium and increasing activity.");
        } else {
          insights.add("❤️ Blood pressure looks good ($systolic/$diastolic).");
        }
      }
    } else {
      insights.add("❤️ Track blood pressure weekly - it's crucial for diabetes management.");
    }
    
    // Analyze activity
    if (activity != null && activity.isNotEmpty) {
      final steps = activity['steps'] as int? ?? 0;
      if (steps < 5000) {
        insights.add("🚶 Try to increase daily steps - aim for 7,000+ steps for better glucose control.");
      } else {
        insights.add("🚶 Great activity level with $steps steps today!");
      }
    } else {
      insights.add("🚶 Add physical activity tracking - even 10 minutes of walking helps glucose control.");
    }
    
    // Analyze medications
    if (medications != null && medications.isNotEmpty) {
      insights.add("💊 You have ${medications.length} medication(s) tracked. Consistent timing is key for $diabetesType management.");
    } else {
      insights.add("💊 Consider tracking medications if prescribed - adherence is crucial for diabetes control.");
    }
    
    // Add diabetes-specific advice
    switch (diabetesType) {
      case 'Type 1':
        insights.add("🎯 Focus on carb counting and insulin timing for optimal weekly patterns.");
        break;
      case 'Type 2':
        insights.add("🎯 Maintain regular exercise and medication schedule for consistent weekly results.");
        break;
      case 'Prediabetes':
        insights.add("🎯 Small weekly lifestyle improvements can prevent Type 2 diabetes progression.");
        break;
      case 'Gestational':
        insights.add("🎯 Monitor weekly patterns closely for both your health and baby's development.");
        break;
    }
    
    // Combine insights into a comprehensive recommendation
    if (insights.length <= 3) {
      return insights.join(' ');
    } else {
      // For longer insights, format as a list
      return insights.take(4).join(' ');
    }
  }
}

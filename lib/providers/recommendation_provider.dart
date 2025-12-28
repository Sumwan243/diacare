import 'package:diacare/services/ai_service.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = "Tap to get personalized health recommendations";
  bool isLoading = false;
  final AIService _aiService = AIService();
  DateTime? lastUpdated;
  final Duration _cacheDuration = const Duration(minutes: 15);

  // Chat history for follow-up questions
  List<ChatMessage> chatHistory = [];
  bool _isFirstFetch = true;

  Future<void> fetchRecommendation({
    List<Map<String, dynamic>>? glucose,
    List<Map<String, dynamic>>? meals,
    List<Map<String, dynamic>>? medications,
    Map<String, dynamic>? bloodPressure,
    Map<String, dynamic>? activity,
    List<Map<String, dynamic>>? intakeLogs,
    String? userName,
    String? followUpQuestion,
    bool force = false,
  }) async {
    if (isLoading) return;

    // If this is a follow-up question, add it to chat history
    if (followUpQuestion != null) {
      chatHistory.add(ChatMessage(
        role: 'user',
        content: followUpQuestion,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }

    // Rate-limit using cacheDuration unless forced or it's a follow-up
    if (!force && !_isFirstFetch && followUpQuestion == null && lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated!);
      if (diff < _cacheDuration) return;
    }

    isLoading = true;
    recommendation = followUpQuestion != null
        ? "Thinking..."
        : "Analyzing your health data...";
    notifyListeners();

    try {
      // Prepare personalized data summary for AI
      final name = userName ?? 'User';

      // Analyze glucose readings for alerts
      String glucoseAnalysis = '';
      if (glucose == null || glucose.isEmpty) {
        glucoseAnalysis = "$name hasn't logged any glucose readings yet.";
      } else {
        final latestGlucose = glucose.first;
        final level = latestGlucose['level'] as int? ?? 0;
        final context = latestGlucose['context'] ?? 'Unknown';

        if (level >= 180) {
          glucoseAnalysis = "ALERT: $name's latest glucose reading is HIGH at $level mg/dL ($context). This is above the normal range and needs attention.";
        } else if (level > 140) {
          glucoseAnalysis = "$name's latest glucose reading is elevated at $level mg/dL ($context).";
        } else if (level < 70) {
          glucoseAnalysis = "ALERT: $name's latest glucose reading is LOW at $level mg/dL ($context). This requires immediate attention.";
        } else if (level >= 70 && level <= 100) {
          glucoseAnalysis = "Great news: $name's glucose levels are excellent at $level mg/dL ($context).";
        } else {
          glucoseAnalysis = "Latest glucose reading: $level mg/dL ($context).";
        }

        // Check for trends
        if (glucose.length >= 2) {
          final previousLevel = glucose[1]['level'] as int? ?? 0;
          final difference = level - previousLevel;
          if (difference > 50) {
            glucoseAnalysis += " There's been a significant increase of ${difference} mg/dL from the previous reading.";
          } else if (difference < -50) {
            glucoseAnalysis += " There's been a significant decrease of ${difference.abs()} mg/dL from the previous reading.";
          }
        }
      }

      // Analyze blood pressure for alerts
      String bpAnalysis = '';
      if (bloodPressure == null) {
        bpAnalysis = "No blood pressure data available.";
      } else {
        final systolic = bloodPressure['systolic'] as int? ?? 0;
        final diastolic = bloodPressure['diastolic'] as int? ?? 0;

        if (systolic >= 180 || diastolic >= 120) {
          bpAnalysis = "CRITICAL ALERT: $name's blood pressure is dangerously HIGH at $systolic/$diastolic mmHg. This is a hypertensive crisis level and requires immediate medical attention!";
        } else if (systolic >= 140 || diastolic >= 90) {
          bpAnalysis = "WARNING: $name's blood pressure is elevated at $systolic/$diastolic mmHg (Hypertension Stage 2).";
        } else if (systolic >= 130 || diastolic >= 80) {
          bpAnalysis = "CAUTION: $name's blood pressure is slightly high at $systolic/$diastolic mmHg (Hypertension Stage 1).";
        } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
          bpAnalysis = "$name's blood pressure is elevated at $systolic/$diastolic mmHg (Elevated range).";
        } else if (systolic < 120 && diastolic < 80) {
          bpAnalysis = "Great news: $name's blood pressure is excellent at $systolic/$diastolic mmHg.";
        } else {
          bpAnalysis = "Blood pressure reading: $systolic/$diastolic mmHg.";
        }
      }

      // Analyze meals
      String mealsAnalysis = '';
      if (meals == null || meals.isEmpty) {
        mealsAnalysis = "$name hasn't logged any meals today.";
      } else {
        final totalCarbs = meals.fold<double>(0, (sum, m) => sum + (m['carbs'] as num? ?? 0));
        mealsAnalysis = "$name has logged ${meals.length} meal(s) today with approximately ${totalCarbs.toStringAsFixed(0)}g of carbohydrates.";

        // Check for high carb intake
        if (totalCarbs > 200) {
          mealsAnalysis += " This is a relatively high carbohydrate intake for someone managing diabetes.";
        }
      }

      // Analyze medications
      String medsAnalysis = '';
      if (medications == null || medications.isEmpty) {
        medsAnalysis = "No medications are being tracked.";
      } else {
        medsAnalysis = "$name is taking ${medications.length} medication(s): ${medications.map((m) => m['name']).join(', ')}.";
      }

      // Analyze activity
      String activityAnalysis = '';
      if (activity == null || (activity['duration'] as num? ?? 0) == 0) {
        activityAnalysis = "No physical activity logged today.";
      } else {
        final duration = activity['duration'] as int? ?? 0;
        if (duration >= 30) {
          activityAnalysis = "Great job! $name has been active for $duration minutes today.";
        } else {
          activityAnalysis = "$name has logged $duration minutes of physical activity today.";
        }
      }

      // Analyze medication intake
      String intakeAnalysis = '';
      if (intakeLogs == null || intakeLogs.isEmpty) {
        intakeAnalysis = "No medication intake confirmations recorded recently.";
      } else {
        intakeAnalysis = "${intakeLogs.length} medication dose(s) have been confirmed taken recently.";
      }

      // Build the prompt with enhanced context and question analysis
      String prompt;
      if (followUpQuestion != null && chatHistory.length > 1) {
        // Analyze the type of question being asked
        final questionType = _analyzeQuestionType(followUpQuestion);
        
        // Follow-up question - include conversation context
        final recentHistory = chatHistory.length > 5 
            ? chatHistory.sublist(chatHistory.length - 5)
            : chatHistory;
        final historyText = recentHistory.map((m) {
          final role = m.role == 'user' ? 'User' : 'Assistant';
          return '$role: ${m.content}';
        }).join('\n');

        prompt = '''
You are an expert diabetes health assistant named DiaCare AI. The user's name is $name.

CURRENT HEALTH CONTEXT:
- Glucose: $glucoseAnalysis
- Blood Pressure: $bpAnalysis
- Meals: $mealsAnalysis
- Medications: $medsAnalysis
- Activity: $activityAnalysis
- Medication Intake: $intakeAnalysis

CONVERSATION HISTORY:
$historyText

USER'S QUESTION TYPE: $questionType
USER'S CURRENT QUESTION: "$followUpQuestion"

RESPONSE INSTRUCTIONS:
1. DIRECTLY answer the specific question asked - don't give generic advice
2. Use $name's actual health data to provide personalized, specific responses
3. If asking about trends, analyze patterns in their data
4. If asking "why" questions, explain the medical reasoning
5. If asking "what should I do", provide specific actionable steps
6. If asking about symptoms, relate to their current readings
7. If asking about food/meals, reference their logged nutrition data
8. Be conversational and supportive, not clinical
9. Always reference their specific data points when relevant
10. If you don't have enough data to answer specifically, say so and suggest what data would help

CRITICAL: Answer the EXACT question asked. Don't deflect to general advice.
''';
      } else {
        // Enhanced initial recommendation with better context analysis
        prompt = '''
You are DiaCare AI, an expert diabetes health assistant. The user's name is $name.

COMPREHENSIVE HEALTH ANALYSIS FOR $name:

GLUCOSE PATTERNS:
$glucoseAnalysis

BLOOD PRESSURE STATUS:
$bpAnalysis

NUTRITION TRACKING:
$mealsAnalysis

MEDICATION MANAGEMENT:
$medsAnalysis

PHYSICAL ACTIVITY:
$activityAnalysis

MEDICATION ADHERENCE:
$intakeAnalysis

PERSONALIZED RECOMMENDATION REQUIREMENTS:
1. Address $name by name and make it personal
2. PRIORITIZE urgent alerts (glucose >180 or <70, BP >140/90) with specific actions
3. Analyze PATTERNS in their data, not just latest readings
4. Provide 2-3 SPECIFIC, actionable recommendations based on their actual data
5. If data shows good control, acknowledge it and suggest optimization
6. If missing data, specifically mention what would help their management
7. Be encouraging but realistic about areas needing attention
8. Reference specific numbers from their data when giving advice
9. Suggest timing for next actions (e.g., "check glucose in 2 hours")
10. End with one motivational insight about their progress

RESPONSE STYLE: Conversational, supportive, data-driven, and actionable. Avoid generic diabetes advice.
''';
      }

      // Use Gemini API for recommendations
      final aiRecommendation = await _aiService.getRecommendation(prompt);

      if (aiRecommendation != null && aiRecommendation.isNotEmpty) {
        recommendation = aiRecommendation;

        // Add AI response to chat history if it's a follow-up
        if (followUpQuestion != null) {
          chatHistory.add(ChatMessage(
            role: 'assistant',
            content: aiRecommendation,
            timestamp: DateTime.now(),
          ));
        } else {
          // Reset chat history for new initial query
          chatHistory = [
            ChatMessage(
              role: 'assistant',
              content: aiRecommendation,
              timestamp: DateTime.now(),
            ),
          ];
          _isFirstFetch = false;
        }
      } else {
        // Enhanced fallback to specific recommendation if AI fails
        final specificRecommendation = _generateSpecificRecommendation(
          glucose ?? [], 
          bloodPressure, 
          meals ?? [], 
          medications ?? [],
          activity ?? {},
          userName ?? 'User',
          followUpQuestion,
        );
        recommendation = specificRecommendation;
        
        if (followUpQuestion != null) {
          chatHistory.add(ChatMessage(
            role: 'assistant',
            content: recommendation,
            timestamp: DateTime.now(),
          ));
        }
      }
      lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching recommendation: $e');
      final specificRecommendation = _generateSpecificRecommendation(
        glucose ?? [], 
        bloodPressure, 
        meals ?? [], 
        medications ?? [],
        activity ?? {},
        userName ?? 'User',
        followUpQuestion,
      );
      recommendation = specificRecommendation;
      lastUpdated = lastUpdated ?? DateTime.now();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Generate more specific recommendations when AI is unavailable
  String _generateSpecificRecommendation(
    List<Map<String, dynamic>> glucose,
    Map<String, dynamic>? bloodPressure,
    List<Map<String, dynamic>> meals,
    List<Map<String, dynamic>> medications,
    Map<String, dynamic> activity,
    String userName,
    String? followUpQuestion,
  ) {
    // Handle follow-up questions with specific logic
    if (followUpQuestion != null) {
      final q = followUpQuestion.toLowerCase();
      
      if (q.contains('why') && glucose.isNotEmpty) {
        final level = glucose.first['level'] as int? ?? 0;
        if (level > 140) {
          return "Your glucose of ${level} mg/dL might be elevated due to recent meals, stress, illness, or medication timing. Check what you ate in the last 2-3 hours and consider light activity.";
        } else if (level < 80) {
          return "Your glucose of ${level} mg/dL might be lower due to delayed meals, increased activity, or medication effects. Have a small snack if you feel symptoms.";
        }
      }
      
      if (q.contains('what should') || q.contains('what can')) {
        if (glucose.isNotEmpty) {
          final level = glucose.first['level'] as int? ?? 0;
          if (level > 180) {
            return "With glucose at ${level} mg/dL, try: 1) Drink water, 2) Take a 10-15 minute walk, 3) Check for missed medication, 4) Avoid more carbs until it comes down.";
          } else if (level < 70) {
            return "With glucose at ${level} mg/dL, immediately: 1) Have 15g fast carbs (juice, glucose tablets), 2) Wait 15 minutes, 3) Recheck glucose, 4) Have a snack if still low.";
          }
        }
      }
      
      if (q.contains('eat') || q.contains('food')) {
        if (glucose.isNotEmpty) {
          final level = glucose.first['level'] as int? ?? 0;
          if (level > 140) {
            return "With your current glucose at ${level} mg/dL, focus on protein and vegetables. Avoid high-carb foods until your levels normalize. Consider lean meat, eggs, or salad. Also, drink water to help flush glucose.";
          } else {
            return "Your glucose looks good for eating. Choose balanced meals with protein, healthy fats, and complex carbs. Monitor how different foods affect your levels.";
          }
        }
      }
      
      if (q.contains('water') || q.contains('hydrat')) {
        if (glucose.isNotEmpty) {
          final level = glucose.first['level'] as int? ?? 0;
          if (level > 180) {
            return "With high glucose at ${level} mg/dL, drinking water can help. Aim for 250-500ml over the next hour, but don't exceed 4L total daily. Water helps flush excess glucose.";
          } else {
            return "Stay hydrated! Aim for 2-3L daily, but don't exceed 4L. Spread intake throughout the day and limit single drinks to 1L max for safety.";
          }
        }
        return "Proper hydration is crucial for diabetes management. Aim for 2-3L daily, spread throughout the day. Never exceed 4L daily or 1L per hour for safety.";
      }
      
      return "I'd need more specific health data to give you a detailed answer to that question. Try logging more glucose readings, meals, or other health metrics for better insights.";
    }
    
    // Initial recommendation logic with more specificity
    List<String> recommendations = [];
    
    // Glucose analysis
    if (glucose.isNotEmpty) {
      final level = glucose.first['level'] as int? ?? 0;
      if (level >= 180) {
        recommendations.add("🚨 $userName, your glucose is HIGH at ${level} mg/dL. Take action: drink water, walk for 10-15 minutes, and avoid carbs until it drops.");
      } else if (level < 70) {
        recommendations.add("⚠️ $userName, your glucose is LOW at ${level} mg/dL. Have 15g of fast carbs immediately, wait 15 minutes, then recheck.");
      } else if (level >= 70 && level <= 100) {
        recommendations.add("✅ Excellent glucose control at ${level} mg/dL, $userName! Keep up whatever you're doing.");
      } else if (level > 100 && level < 140) {
        recommendations.add("📊 Your glucose is ${level} mg/dL - slightly elevated but manageable. Consider the timing of your last meal.");
      }
      
      // Trend analysis if multiple readings
      if (glucose.length >= 2) {
        final current = glucose[0]['level'] as int? ?? 0;
        final previous = glucose[1]['level'] as int? ?? 0;
        final change = current - previous;
        if (change > 50) {
          recommendations.add("📈 Your glucose rose by ${change} mg/dL since last reading. Review recent food intake or stress levels.");
        } else if (change < -50) {
          recommendations.add("📉 Your glucose dropped by ${change.abs()} mg/dL. Good trend - monitor to ensure it doesn't go too low.");
        }
      }
    } else {
      recommendations.add("📝 Start logging glucose readings to get personalized insights, $userName!");
    }
    
    // Blood pressure analysis
    if (bloodPressure != null) {
      final systolic = bloodPressure['systolic'] as int? ?? 0;
      final diastolic = bloodPressure['diastolic'] as int? ?? 0;
      if (systolic >= 140 || diastolic >= 90) {
        recommendations.add("🩺 Your BP is ${systolic}/${diastolic} - elevated. Reduce sodium, manage stress, and stay hydrated.");
      } else if (systolic < 120 && diastolic < 80) {
        recommendations.add("💚 Great blood pressure at ${systolic}/${diastolic} mmHg!");
      }
    }
    
    // Meal analysis
    if (meals.isNotEmpty) {
      final totalCarbs = meals.fold<double>(0, (sum, m) => sum + (m['carbs'] as num? ?? 0));
      if (totalCarbs > 150) {
        recommendations.add("🍽️ High carb intake today (${totalCarbs.toInt()}g). Consider balancing with protein and fiber.");
      } else if (meals.length < 2) {
        recommendations.add("🍎 Log more meals for better nutrition tracking and glucose correlation analysis.");
      }
    }
    
    // Activity encouragement
    final duration = activity['duration'] as int? ?? 0;
    if (duration == 0) {
      recommendations.add("🚶‍♂️ Add some physical activity today - even 10-15 minutes can help with glucose control.");
    } else if (duration >= 30) {
      recommendations.add("🏃‍♂️ Great job on ${duration} minutes of activity! This helps with glucose management.");
    }
    
    if (recommendations.isEmpty) {
      return "Hi $userName! Log some health data (glucose, meals, BP) to get specific, personalized recommendations.";
    }
    
    return recommendations.take(3).join(' ');
  }

  /// Analyze the type of question being asked to provide more targeted responses
  String _analyzeQuestionType(String question) {
    final q = question.toLowerCase();
    
    if (q.contains('why') || q.contains('reason') || q.contains('cause')) {
      return 'EXPLANATION_REQUEST - User wants to understand the reasoning behind something';
    } else if (q.contains('what should') || q.contains('what can') || q.contains('how do') || q.contains('how can')) {
      return 'ACTION_REQUEST - User wants specific actionable advice';
    } else if (q.contains('trend') || q.contains('pattern') || q.contains('over time') || q.contains('lately') || q.contains('recently')) {
      return 'TREND_ANALYSIS - User wants analysis of patterns in their data';
    } else if (q.contains('normal') || q.contains('good') || q.contains('bad') || q.contains('high') || q.contains('low')) {
      return 'ASSESSMENT_REQUEST - User wants evaluation of their current status';
    } else if (q.contains('eat') || q.contains('food') || q.contains('meal') || q.contains('diet') || q.contains('carb')) {
      return 'NUTRITION_QUESTION - User asking about food and nutrition';
    } else if (q.contains('exercise') || q.contains('activity') || q.contains('walk') || q.contains('workout')) {
      return 'ACTIVITY_QUESTION - User asking about physical activity';
    } else if (q.contains('medication') || q.contains('insulin') || q.contains('dose') || q.contains('medicine')) {
      return 'MEDICATION_QUESTION - User asking about medications';
    } else if (q.contains('symptom') || q.contains('feel') || q.contains('tired') || q.contains('dizzy') || q.contains('thirsty')) {
      return 'SYMPTOM_INQUIRY - User describing or asking about symptoms';
    } else if (q.contains('when') || q.contains('time') || q.contains('schedule')) {
      return 'TIMING_QUESTION - User asking about timing or scheduling';
    } else {
      return 'GENERAL_INQUIRY - General question requiring contextual response';
    }
  }

  String? get lastUpdatedDisplay => lastUpdated == null ? null : lastUpdated!.toLocal().toString().split('.').first;

  /// Clear chat history
  void clearChatHistory() {
    chatHistory = [];
    _isFirstFetch = true;
    notifyListeners();
  }
}

/// Model for chat messages
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
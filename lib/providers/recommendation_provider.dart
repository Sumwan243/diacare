import 'package:diacare/services/ai_service.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String recommendation = "Tap to get personalized health recommendations";
  bool isLoading = false;
  final AIService _aiService = AIService();
  DateTime? lastUpdated;
  final Duration _cacheDuration = const Duration(minutes: 15);
<<<<<<< HEAD

  // Chat history for follow-up questions
  List<ChatMessage> chatHistory = [];
  bool _isFirstFetch = true;

  Future<void> fetchRecommendation({
=======

    Future<void> fetchRecommendation({
>>>>>>> 70c42b35cb2d075a6d2559ec59d609ac987976ad
    List<Map<String, dynamic>>? glucose,
    List<Map<String, dynamic>>? meals,
    List<Map<String, dynamic>>? medications,
    Map<String, dynamic>? bloodPressure,
    Map<String, dynamic>? activity,
    List<Map<String, dynamic>>? intakeLogs,
<<<<<<< HEAD
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

=======
    bool force = false,
    }) async {
    if (isLoading) return;

    // Rate-limit using cacheDuration unless forced
    if (!force && lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated!);
      if (diff < _cacheDuration) return;
    }
    
>>>>>>> 70c42b35cb2d075a6d2559ec59d609ac987976ad
    isLoading = true;
    recommendation = followUpQuestion != null
        ? "Thinking..."
        : "Analyzing your health data...";
    notifyListeners();

    try {
<<<<<<< HEAD
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
You are DiaCare AI, a friendly and personalized diabetes health assistant. The user's name is $name.

CONVERSATION CONTEXT:
$historyText

USER'S CURRENT QUESTION: "$followUpQuestion"
QUESTION TYPE: $questionType

$name's CURRENT HEALTH DATA:
- Glucose: $glucoseAnalysis
- Blood Pressure: $bpAnalysis
- Meals: $mealsAnalysis
- Medications: $medsAnalysis
- Activity: $activityAnalysis
- Medication Intake: $intakeAnalysis

RESPONSE GUIDELINES:
1. ALWAYS respond to the user - never say you don't have data unless they specifically ask about missing health metrics
2. For greetings (hi, hello, how are you): Respond warmly and offer to help with their diabetes management
3. For general questions: Answer helpfully and relate to diabetes management when relevant
4. For health questions: Use their actual data to provide specific, personalized advice
5. For "what should I do" questions: Give 2-3 specific actionable steps
6. For "why" questions: Explain the medical reasoning in simple terms
7. Be conversational, supportive, and use $name's name naturally
8. If they ask about trends, analyze patterns in their data over time
9. Always be encouraging and positive while being medically accurate
10. For non-health topics: Still respond helpfully but gently guide back to health topics

CRITICAL: Never refuse to answer or say you lack data for basic conversation. Always engage meaningfully.
''';
      } else {
        // Enhanced initial recommendation with better personalization
        prompt = '''
You are DiaCare AI, $name's personal diabetes health assistant and companion.

COMPREHENSIVE HEALTH ANALYSIS FOR $name:

GLUCOSE PATTERNS & ALERTS:
$glucoseAnalysis

BLOOD PRESSURE STATUS:
$bpAnalysis

NUTRITION & MEAL TRACKING:
$mealsAnalysis

MEDICATION MANAGEMENT:
$medsAnalysis

PHYSICAL ACTIVITY:
$activityAnalysis

MEDICATION ADHERENCE:
$intakeAnalysis

PERSONALIZED RECOMMENDATION REQUIREMENTS:
1. Address $name personally and warmly - make this feel like a conversation with a knowledgeable friend
2. PRIORITIZE any urgent health alerts (glucose >180 or <70, BP >140/90) with immediate action steps
3. Analyze PATTERNS and TRENDS in their data, not just latest readings
4. Provide 2-3 SPECIFIC, actionable recommendations based on their actual data
5. If data shows good control, celebrate it and suggest optimizations
6. If missing key data, specifically mention what would help their management
7. Be encouraging but realistic about areas needing attention
8. Reference specific numbers from their data when giving advice
9. Suggest timing for next actions (e.g., "check glucose in 2 hours after this meal")
10. End with a motivational insight about their progress or a gentle reminder about their health goals
11. Include proactive suggestions based on patterns (e.g., if no activity logged, suggest movement)
12. If they haven't logged data recently, gently encourage logging with specific suggestions

TONE: Conversational, supportive, knowledgeable, and personally invested in $name's wellbeing.
''';
      }
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
=======
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
>>>>>>> 70c42b35cb2d075a6d2559ec59d609ac987976ad

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
<<<<<<< HEAD
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
=======
        // Fallback to simple recommendation if AI fails
        recommendation = _generateRecommendation(glucose ?? [], meals ?? []);
>>>>>>> 70c42b35cb2d075a6d2559ec59d609ac987976ad
      }
      lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching recommendation: $e');
<<<<<<< HEAD
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
=======
      recommendation = _generateRecommendation(glucose ?? [], meals ?? []);
>>>>>>> 70c42b35cb2d075a6d2559ec59d609ac987976ad
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
      
      // Handle greetings and general conversation
      if (q.contains('hi') || q.contains('hello') || q.contains('hey')) {
        return "Hi $userName! 👋 I'm here to help with your diabetes management. How are you feeling today? Would you like me to check your recent health data or answer any questions?";
      }
      
      if (q.contains('how are you') || q.contains('what\'s up')) {
        return "I'm doing great, thanks for asking $userName! 😊 I'm here and ready to help you manage your diabetes. How are YOU feeling today? Any concerns about your glucose, meals, or medications?";
      }
      
      if (q.contains('thank') || q.contains('thanks')) {
        return "You're very welcome, $userName! 😊 I'm always happy to help you stay healthy. Is there anything else about your diabetes management I can assist you with?";
      }
      
      // Handle specific health questions
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
        return "Here are some general tips for $userName: 1) Check your glucose regularly, 2) Log your meals to track carb impact, 3) Stay active with daily walks, 4) Take medications as prescribed. What specific area would you like help with?";
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
        return "For diabetes-friendly eating, $userName: Focus on lean proteins, non-starchy vegetables, and complex carbs. Limit simple sugars and processed foods. Would you like specific meal suggestions?";
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
      
      if (q.contains('exercise') || q.contains('activity') || q.contains('walk')) {
        return "Great question, $userName! For diabetes: 1) Aim for 150 minutes/week of moderate activity, 2) Start with 10-15 minute walks after meals, 3) Check glucose before/after exercise, 4) Stay hydrated. Even light activity helps lower glucose!";
      }
      
      // Generic helpful response for unrecognized questions
      return "I'm here to help with your diabetes management, $userName! I can assist with glucose readings, meal planning, medication reminders, activity suggestions, and more. What specific aspect of your health would you like to discuss?";
    }
    
    // Initial recommendation logic with more personalization
    List<String> recommendations = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if user has logged data today
    final hasGlucoseToday = glucose.any((g) {
      final timestamp = DateTime.parse(g['timestamp'] as String);
      final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
      return logDate == today;
    });
    
    final hasMealsToday = meals.any((m) {
      final timestamp = DateTime.parse(m['timestamp'] as String);
      final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
      return logDate == today;
    });
    
    // Personalized greeting
    final timeOfDay = now.hour < 12 ? 'morning' : now.hour < 17 ? 'afternoon' : 'evening';
    recommendations.add("Good $timeOfDay, $userName! 🌟");
    
    // Glucose analysis with encouragement
    if (glucose.isNotEmpty) {
      final level = glucose.first['level'] as int? ?? 0;
      if (level >= 180) {
        recommendations.add("🚨 Your glucose is HIGH at ${level} mg/dL. Take action: drink water, walk for 10-15 minutes, and avoid carbs until it drops.");
      } else if (level < 70) {
        recommendations.add("⚠️ Your glucose is LOW at ${level} mg/dL. Have 15g of fast carbs immediately, wait 15 minutes, then recheck.");
      } else if (level >= 70 && level <= 100) {
        recommendations.add("✅ Excellent glucose control at ${level} mg/dL! You're doing great with your diabetes management.");
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
      recommendations.add("📝 I'd love to help you more! Start by logging some glucose readings so I can give you personalized insights.");
    }
    
    // Proactive suggestions based on missing data
    if (!hasGlucoseToday && glucose.isNotEmpty) {
      recommendations.add("💡 You haven't checked your glucose today yet. Consider checking before your next meal!");
    }
    
    if (!hasMealsToday && meals.isNotEmpty) {
      recommendations.add("🍽️ Don't forget to log your meals today - it helps me give you better nutrition advice!");
    }
    
    // Activity encouragement
    final duration = activity['duration'] as int? ?? 0;
    if (duration == 0) {
      recommendations.add("🚶‍♂️ How about a 10-15 minute walk today? Even light activity can help with glucose control!");
    } else if (duration >= 30) {
      recommendations.add("🏃‍♂️ Amazing job on ${duration} minutes of activity! This really helps with your diabetes management.");
    }
    
    // Blood pressure check
    if (bloodPressure != null) {
      final systolic = bloodPressure['systolic'] as int? ?? 0;
      final diastolic = bloodPressure['diastolic'] as int? ?? 0;
      if (systolic >= 140 || diastolic >= 90) {
        recommendations.add("🩺 Your BP is ${systolic}/${diastolic} - elevated. Try reducing sodium, managing stress, and staying hydrated.");
      } else if (systolic < 120 && diastolic < 80) {
        recommendations.add("💚 Great blood pressure at ${systolic}/${diastolic} mmHg!");
      }
    }
    
    if (recommendations.length == 1) {
      recommendations.add("I'm here to help you manage your diabetes better! Feel free to ask me anything about glucose, meals, medications, or activity. 😊");
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
  String? get lastUpdatedDisplay => lastUpdated == null ? null : lastUpdated!.toLocal().toString().split('.').first;
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
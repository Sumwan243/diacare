import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _fallbackApiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<Map<String, double>?> estimateNutrition(String foodName, double grams, {String? userApiKey}) async {
    String? responseText;
    
    try {
      // Use user's API key if provided, otherwise fall back to environment variable
      final apiKey = userApiKey?.trim().isNotEmpty == true ? userApiKey! : _fallbackApiKey;
      
      // Check if API key is available
      if (apiKey.trim().isEmpty) {
        debugPrint('AI Error: No API key available. User needs to set their Gemini API key in profile settings.');
        throw AIException('No API key configured. Please set your Gemini API key in profile settings.');
      }

      // Validate input
      if (foodName.trim().isEmpty) {
        debugPrint('AI Error: Food name is empty');
        return null;
      }
      if (grams <= 0) {
        debugPrint('AI Error: Invalid grams value: $grams');
        return null;
      }

      final prompt = '''
Analyze 100g of "$foodName" to determine its standard nutritional density. 
Then, calculate the total nutrition for exactly $grams grams.
Return ONLY a JSON object with these keys (values as numbers, no units):
{
  "calories": 0.0,
  "carbs": 0.0,
  "protein": 0.0,
  "fat": 0.0
}
''';

      // Try different models in order of preference (stable models first)
      final modelNames = ['gemini-pro', 'gemini-1.5-pro'];
      Exception? lastException;
      
      for (final modelName in modelNames) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json', // Ensures strict JSON output
              temperature: 0.2, // Lower temperature for more consistent results
            ),
          );

          final response = await model.generateContent([Content.text(prompt)]).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('AI request timed out after 30 seconds');
            },
          );
          
          responseText = response.text;
          break; // Success, exit loop
        } catch (e) {
          debugPrint('AI Error: Failed with model $modelName - $e');
          lastException = e is Exception ? e : Exception(e.toString());
          // Continue to next model
          continue;
        }
      }
      
      if (responseText == null) {
        // All models failed
        if (lastException != null) {
          final errorString = lastException.toString().toLowerCase();
          if (errorString.contains('beta') && errorString.contains('supported')) {
            throw AIException('Model configuration error. The selected model is not supported. Please try again.');
          }
          throw lastException;
        }
        throw Exception('All model attempts failed');
      }
      
      if (responseText.trim().isEmpty) {
        debugPrint('AI Error: Empty response from API');
        return null;
      }

      // Try to parse JSON - handle cases where response might have markdown code blocks
      String jsonText = responseText.trim();
      
      // Remove markdown code blocks if present
      if (jsonText.startsWith('```')) {
        final lines = jsonText.split('\n');
        jsonText = lines
            .where((line) => !line.trim().startsWith('```'))
            .join('\n')
            .trim();
      }

      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      
      // Validate and extract values with fallbacks
      return {
        'calories': ((data['calories'] as num?)?.toDouble() ?? 0.0).clamp(0, 10000),
        'carbs': ((data['carbs'] as num?)?.toDouble() ?? 0.0).clamp(0, 1000),
        'protein': ((data['protein'] as num?)?.toDouble() ?? 0.0).clamp(0, 500),
        'fat': ((data['fat'] as num?)?.toDouble() ?? 0.0).clamp(0, 500),
      };
    } on TimeoutException catch (e) {
      debugPrint('AI Error: Request timeout - $e');
      throw AIException('Request timed out. Please check your internet connection and try again.');
    } on SocketException catch (e) {
      debugPrint('AI Error: Network error - $e');
      throw AIException('No internet connection. Please check your network and try again.');
    } on HttpException catch (e) {
      debugPrint('AI Error: HTTP error - $e');
      throw AIException('Network error. Please check your internet connection and try again.');
    } on FormatException catch (e) {
      debugPrint('AI Error: JSON parsing failed - $e');
      if (responseText != null) {
        debugPrint('Response text: $responseText');
      }
      throw AIException('Invalid response from AI service. Please try again.');
    } catch (e) {
      debugPrint('AI Error: Unexpected error - $e');
      // Check for specific Gemini API errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('beta') && errorString.contains('supported')) {
        throw AIException('Model configuration error. Please try again or contact support.');
      }
      if (errorString.contains('network') || 
          errorString.contains('connection') || 
          errorString.contains('socket') ||
          errorString.contains('failed host lookup')) {
        throw AIException('No internet connection. Please check your network and try again.');
      }
      if (errorString.contains('api key') || errorString.contains('authentication')) {
        throw AIException('Invalid API key. Please check your GEMINI_API_KEY configuration.');
      }
      throw AIException('AI service error: ${e.toString()}');
    }
  }

  /// Get personalized health recommendations based on user data
  Future<String?> getRecommendation(String prompt, {String? userApiKey}) async {
    String? responseText;
    
    try {
      // Use user's API key if provided, otherwise fall back to environment variable
      final apiKey = userApiKey?.trim().isNotEmpty == true ? userApiKey! : _fallbackApiKey;
      
      // Check if API key is available
      if (apiKey.trim().isEmpty) {
        debugPrint('AI Error: No API key available. User needs to set their Gemini API key in profile settings.');
        return null;
      }

      // Try different models in order of preference (stable models first)
      final modelNames = ['gemini-pro', 'gemini-1.5-pro'];
      Exception? lastException;
      
      for (final modelName in modelNames) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7, // Slightly higher for more natural recommendations
            ),
          );

          final response = await model.generateContent([Content.text(prompt)]).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('AI request timed out after 30 seconds');
            },
          );
          
          responseText = response.text;
          break; // Success, exit loop
        } catch (e) {
          debugPrint('AI Error: Failed with model $modelName - $e');
          lastException = e is Exception ? e : Exception(e.toString());
          continue;
        }
      }
      
      if (responseText == null) {
        debugPrint('AI Error: All model attempts failed');
        return null;
      }
      
      return responseText.trim();
    } on TimeoutException catch (e) {
      debugPrint('AI Error: Request timeout - $e');
      return null;
    } on SocketException catch (e) {
      debugPrint('AI Error: Network error - $e');
      return null;
    } on HttpException catch (e) {
      debugPrint('AI Error: HTTP error - $e');
      return null;
    } catch (e) {
      debugPrint('AI Error: Unexpected error - $e');
      return null;
    }
  }
}

// TimeoutException class for timeout handling
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

// AIException class for user-friendly error messages
class AIException implements Exception {
  final String message;
  AIException(this.message);
  
  @override
  String toString() => message;
}
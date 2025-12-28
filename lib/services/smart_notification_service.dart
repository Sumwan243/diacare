import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'notification_service.dart';

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final NotificationService _notificationService = NotificationService();
  final Box _settingsBox = Hive.box('settings_box');
  
  // Notification IDs
  static const int exerciseReminderId = 1001;
  static const int glucoseReminderId = 1002;
  static const int mealReminderId = 1003;
  static const int hydrationReminderId = 1004;
  static const int medicationReminderId = 1005;

  /// Initialize smart notifications
  Future<void> initialize() async {
    await _notificationService.init();
    _scheduleSmartReminders();
  }

  /// Schedule smart reminders based on user patterns
  void _scheduleSmartReminders() {
    // Schedule periodic checks every 2 hours during waking hours
    for (int hour = 8; hour <= 20; hour += 2) {
      _scheduleSmartCheck(hour);
    }
  }

  /// Schedule a smart check at a specific hour
  void _scheduleSmartCheck(int hour) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour);
    
    // If the time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Schedule the check
    Future.delayed(scheduledTime.difference(now), () {
      _performSmartCheck();
    });
  }

  /// Perform intelligent health check and send appropriate notifications
  Future<void> _performSmartCheck() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if notifications are enabled
      if (!_areSmartNotificationsEnabled()) return;

      // Check activity levels
      await _checkActivityLevels(today, now);
      
      // Check glucose logging
      await _checkGlucoseLogging(today, now);
      
      // Check meal logging
      await _checkMealLogging(today, now);
      
      // Check hydration
      await _checkHydrationLevels(today, now);
      
      // Check medication adherence
      await _checkMedicationAdherence(today, now);
      
    } catch (e) {
      debugPrint('Smart notification check error: $e');
    }
  }

  /// Check if user needs activity reminder
  Future<void> _checkActivityLevels(DateTime today, DateTime now) async {
    try {
      // Don't send notifications too late in the evening
      if (now.hour > 19) return;
      
      // Check if we already sent an activity reminder today
      final lastActivityNotification = _settingsBox.get('last_activity_notification');
      if (lastActivityNotification != null) {
        final lastDate = DateTime.parse(lastActivityNotification);
        if (DateTime(lastDate.year, lastDate.month, lastDate.day) == today) {
          return; // Already sent today
        }
      }

      // Check user's activity for today
      final activityBox = Hive.box('activity_box');
      bool hasActivityToday = false;
      int totalSteps = 0;
      
      for (final entry in activityBox.values) {
        if (entry is Map) {
          final timestamp = DateTime.parse(entry['timestamp'] ?? '');
          final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
          if (entryDate == today) {
            hasActivityToday = true;
            totalSteps += (entry['steps'] as int? ?? 0);
          }
        }
      }

      // Send notification if no activity or low steps
      if (!hasActivityToday || totalSteps < 2000) {
        String message;
        if (totalSteps == 0) {
          message = "Time to move! 🚶‍♂️ Even a 10-minute walk can help with your glucose control.";
        } else {
          message = "You're at $totalSteps steps today. How about a quick walk to boost your activity? 🏃‍♂️";
        }

        await _notificationService.showInstantNotification(
          id: exerciseReminderId,
          title: 'Activity Reminder',
          body: message,
        );
        
        _settingsBox.put('last_activity_notification', now.toIso8601String());
      }
    } catch (e) {
      debugPrint('Activity check error: $e');
    }
  }

  /// Check if user needs glucose logging reminder
  Future<void> _checkGlucoseLogging(DateTime today, DateTime now) async {
    try {
      // Check if we already sent a glucose reminder today
      final lastGlucoseNotification = _settingsBox.get('last_glucose_notification');
      if (lastGlucoseNotification != null) {
        final lastDate = DateTime.parse(lastGlucoseNotification);
        if (DateTime(lastDate.year, lastDate.month, lastDate.day) == today) {
          return; // Already sent today
        }
      }

      // Check glucose readings for today
      final glucoseBox = Hive.box('blood_sugar_box');
      int todayReadings = 0;
      DateTime? lastReading;
      
      for (final entry in glucoseBox.values) {
        if (entry is Map) {
          final timestamp = DateTime.parse(entry['timestamp'] ?? '');
          final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
          if (entryDate == today) {
            todayReadings++;
            if (lastReading == null || timestamp.isAfter(lastReading)) {
              lastReading = timestamp;
            }
          }
        }
      }

      // Send reminder based on patterns
      bool shouldRemind = false;
      String message = '';

      if (todayReadings == 0 && now.hour >= 10) {
        shouldRemind = true;
        message = "Don't forget to check your glucose today! 📊 Regular monitoring helps manage your diabetes better.";
      } else if (todayReadings < 2 && now.hour >= 16) {
        shouldRemind = true;
        message = "Consider checking your glucose again today. Multiple readings help track patterns! 📈";
      } else if (lastReading != null && now.difference(lastReading).inHours >= 6 && now.hour <= 18) {
        shouldRemind = true;
        message = "It's been a while since your last glucose check. Time for another reading? 🩸";
      }

      if (shouldRemind) {
        await _notificationService.showInstantNotification(
          id: glucoseReminderId,
          title: 'Glucose Check Reminder',
          body: message,
        );
        
        _settingsBox.put('last_glucose_notification', now.toIso8601String());
      }
    } catch (e) {
      debugPrint('Glucose check error: $e');
    }
  }

  /// Check if user needs meal logging reminder
  Future<void> _checkMealLogging(DateTime today, DateTime now) async {
    try {
      // Only remind during meal times
      if (!(now.hour >= 7 && now.hour <= 9) && // Breakfast
          !(now.hour >= 12 && now.hour <= 14) && // Lunch
          !(now.hour >= 18 && now.hour <= 20)) { // Dinner
        return;
      }

      // Check if we already sent a meal reminder in the last 4 hours
      final lastMealNotification = _settingsBox.get('last_meal_notification');
      if (lastMealNotification != null) {
        final lastTime = DateTime.parse(lastMealNotification);
        if (now.difference(lastTime).inHours < 4) {
          return; // Too recent
        }
      }

      // Check meals for today
      final mealsBox = Hive.box('meals_box');
      int todayMeals = 0;
      
      for (final entry in mealsBox.values) {
        if (entry is Map) {
          final timestamp = DateTime.parse(entry['timestamp'] ?? '');
          final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
          if (entryDate == today) {
            todayMeals++;
          }
        }
      }

      // Send reminder based on meal time and logged meals
      String? message;
      
      if (now.hour >= 7 && now.hour <= 9 && todayMeals == 0) {
        message = "Good morning! 🌅 Don't forget to log your breakfast to track how it affects your glucose.";
      } else if (now.hour >= 12 && now.hour <= 14 && todayMeals <= 1) {
        message = "Lunch time! 🍽️ Remember to log your meal to see how different foods impact your levels.";
      } else if (now.hour >= 18 && now.hour <= 20 && todayMeals <= 2) {
        message = "Dinner time! 🍽️ Logging your evening meal helps track daily nutrition patterns.";
      }

      if (message != null) {
        await _notificationService.showInstantNotification(
          id: mealReminderId,
          title: 'Meal Logging Reminder',
          body: message,
        );
        
        _settingsBox.put('last_meal_notification', now.toIso8601String());
      }
    } catch (e) {
      debugPrint('Meal check error: $e');
    }
  }

  /// Check hydration levels
  Future<void> _checkHydrationLevels(DateTime today, DateTime now) async {
    try {
      // Don't remind too late
      if (now.hour > 20) return;

      // Check if we already sent a hydration reminder in the last 3 hours
      final lastHydrationNotification = _settingsBox.get('last_hydration_notification');
      if (lastHydrationNotification != null) {
        final lastTime = DateTime.parse(lastHydrationNotification);
        if (now.difference(lastTime).inHours < 3) {
          return;
        }
      }

      // Check hydration for today
      final hydrationBox = Hive.box('hydration_box');
      int todayIntake = 0;
      
      for (final entry in hydrationBox.values) {
        if (entry is Map) {
          final timestamp = DateTime.parse(entry['timestamp'] ?? '');
          final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
          if (entryDate == today) {
            todayIntake += (entry['amount'] as int? ?? 0);
          }
        }
      }

      // Send reminder if hydration is low
      if (todayIntake < 1500 && now.hour >= 14) {
        await _notificationService.showInstantNotification(
          id: hydrationReminderId,
          title: 'Hydration Reminder',
          body: "You've had ${todayIntake}ml of water today. Stay hydrated! 💧 Proper hydration helps with glucose control.",
        );
        
        _settingsBox.put('last_hydration_notification', now.toIso8601String());
      }
    } catch (e) {
      debugPrint('Hydration check error: $e');
    }
  }

  /// Check medication adherence
  Future<void> _checkMedicationAdherence(DateTime today, DateTime now) async {
    try {
      // Check if we already sent a medication reminder today
      final lastMedNotification = _settingsBox.get('last_medication_notification');
      if (lastMedNotification != null) {
        final lastDate = DateTime.parse(lastMedNotification);
        if (DateTime(lastDate.year, lastDate.month, lastDate.day) == today) {
          return;
        }
      }

      // Check medication intake logs
      final intakeBox = Hive.box('med_intake_log_box');
      bool hasTakenMedsToday = false;
      
      for (final entry in intakeBox.values) {
        if (entry is Map) {
          final timestamp = DateTime.parse(entry['timestamp'] ?? '');
          final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
          if (entryDate == today) {
            hasTakenMedsToday = true;
            break;
          }
        }
      }

      // Send reminder if no medications logged and it's afternoon
      if (!hasTakenMedsToday && now.hour >= 14) {
        await _notificationService.showInstantNotification(
          id: medicationReminderId,
          title: 'Medication Reminder',
          body: "Don't forget to log your medications today! 💊 Consistent tracking helps manage your diabetes effectively.",
        );
        
        _settingsBox.put('last_medication_notification', now.toIso8601String());
      }
    } catch (e) {
      debugPrint('Medication check error: $e');
    }
  }

  /// Check if smart notifications are enabled
  bool _areSmartNotificationsEnabled() {
    return _settingsBox.get('smart_notifications_enabled', defaultValue: true) as bool;
  }

  /// Enable or disable smart notifications
  Future<void> setSmartNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('smart_notifications_enabled', enabled);
    if (enabled) {
      _scheduleSmartReminders();
    }
  }

  /// Send a personalized encouragement notification
  Future<void> sendEncouragementNotification(String userName) async {
    final encouragements = [
      "Great job managing your diabetes today, $userName! 🌟",
      "You're doing amazing with your health tracking, $userName! Keep it up! 💪",
      "Your consistency with diabetes management is inspiring, $userName! 🎉",
      "Every glucose check and meal log makes a difference, $userName! 📊",
      "Your dedication to your health is admirable, $userName! 🏆",
    ];
    
    final message = encouragements[DateTime.now().millisecond % encouragements.length];
    
    await _notificationService.showInstantNotification(
      id: 9999,
      title: 'You\'re Doing Great!',
      body: message,
    );
  }

  /// Send high glucose alert
  Future<void> sendHighGlucoseAlert(int level) async {
    await _notificationService.showHighGlucoseAlert(
      glucoseLevel: level.toDouble(),
      context: "Alert",
    );
  }

  /// Send low glucose alert
  Future<void> sendLowGlucoseAlert(int level) async {
    await _notificationService.showLowGlucoseAlert(
      glucoseLevel: level.toDouble(),
      context: "Alert",
    );
  }
}
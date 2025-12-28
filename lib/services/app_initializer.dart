import 'package:diacare/services/notification_service.dart';
import 'package:diacare/services/smart_notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// A service class to handle the asynchronous initialization of the app.
class AppInitializer {
  /// Initializes all the necessary services and databases for the app.
  Future<void> init() async {
    // Initialize Hive in the app's documents directory.
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);

    // Run database and service initializations in parallel for faster startup.
    await Future.wait([
      _initDatabases(),
      _initServices(),
    ]);
  }

  /// Opens all required Hive boxes in parallel.
  Future<void> _initDatabases() {
    return Future.wait([
      // Core boxes
      Hive.openBox('userProfile'),
      Hive.openBox('medications'),
      Hive.openBox('medication_logs_box'),
      Hive.openBox('med_intake_log_box'), // For the new notification system

      // Feature boxes
      Hive.openBox('blood_sugar_box'),
      Hive.openBox('blood_pressure_box'),
      Hive.openBox('activity_box'),
      Hive.openBox('meals_box'),
      Hive.openBox('hydration_box'), // For water intake tracking

      // Cache boxes
      Hive.openBox('ai_nutrition_cache_box'),
      
      // Settings box for smart notifications
      Hive.openBox('settings_box'),
    ]);
  }

  /// Initializes other app services.
  Future<void> _initServices() async {
    await NotificationService().init();
    await SmartNotificationService().initialize();
  }
}

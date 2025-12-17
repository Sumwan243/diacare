import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/glucose_provider.dart';
import 'package:diacare/providers/meal_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/utils/migration_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'screens/home_screen.dart';
import 'utils/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Open all necessary boxes on startup
  await Hive.openBox('userProfile');
  await Hive.openBox('medications');
  await Hive.openBox('meals');
  await Hive.openBox('blood_sugar_box');
  await Hive.openBox('activity_box');
  await Hive.openBox('glucose');
  await Hive.openBox('meal_logs_box');
  await Hive.openBox('custom_foods_box');
  await Hive.openBox('usda_food_cache_box');
  await Hive.openBox('dish_nutrition_cache_box');
  await Hive.openBox('dish_ingredient_resolution_box');

  await MigrationUtil.cleanupOldReminders();

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => GlucoseProvider()),
        ChangeNotifierProvider(create: (_) => BloodSugarProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
      ],
      child: Consumer<GlucoseProvider>(
        builder: (context, glucoseProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'DiaCare',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

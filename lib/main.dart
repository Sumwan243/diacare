import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/blood_pressure_provider.dart';
import 'package:diacare/providers/meal_provider.dart';
import 'package:diacare/providers/medication_log_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/providers/recommendation_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/providers/hydration_provider.dart';
import 'package:diacare/services/app_initializer.dart';
import 'package:diacare/services/permission_service.dart';
import 'package:diacare/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer().init();

  // Get MedicationProvider instance to reschedule reminders on app start
  final medicationProvider = MedicationProvider();
  await medicationProvider.rescheduleAllReminders();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider.value(value: medicationProvider),
        ChangeNotifierProvider(create: (_) => BloodSugarProvider()),
        ChangeNotifierProvider(create: (_) => BloodPressureProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => MedicationLogProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  MedicationProvider? _medicationProvider;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize medication provider reference early to avoid null in lifecycle callbacks
    _medicationProvider ??= Provider.of<MedicationProvider>(context, listen: false);
    
    // Request permissions on first build
    if (!_permissionsRequested) {
      _permissionsRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PermissionService.requestAllPermissions(context);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reschedule medication reminders when app resumes to ensure
      // notifications are always scheduled for the next 7 days
      _medicationProvider?.rescheduleAllReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store medication provider reference for lifecycle callbacks
    _medicationProvider ??= Provider.of<MedicationProvider>(context, listen: false);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DiaCare',
      // Use medical themes - prioritize medical consistency over dynamic colors
      theme: AppTheme.lightTheme(null), // Pass null to use medical theme
      darkTheme: AppTheme.darkTheme(null), // Pass null to use medical theme
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}

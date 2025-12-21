import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/blood_pressure_provider.dart';
import 'package:diacare/providers/meal_provider.dart';
import 'package:diacare/providers/medication_log_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/providers/recommendation_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/services/app_initializer.dart';
import 'package:diacare/theme/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';

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
  ColorScheme? _lightScheme;
  ColorScheme? _darkScheme;
  MedicationProvider? _medicationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial fetch of the dynamic color palette.
    _updateColorSchemes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize medication provider reference early to avoid null in lifecycle callbacks
    _medicationProvider ??= Provider.of<MedicationProvider>(context, listen: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Manually fetches the system color palette and updates the state.
  // This gives us control to prevent the "flash" of the fallback theme.
  Future<void> _updateColorSchemes() async {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (mounted) {
      setState(() {
        if (corePalette != null) {
          _lightScheme = corePalette.toColorScheme();
          _darkScheme = corePalette.toColorScheme(brightness: Brightness.dark);
        } else {
          _lightScheme = null;
          _darkScheme = null;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the app resumes, re-fetch the colors in case the wallpaper changed.
      _updateColorSchemes();
      
      // Reschedule medication reminders when app resumes to ensure
      // notifications are always scheduled for the next 7 days
      _medicationProvider?.rescheduleAllReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store medication provider reference for lifecycle callbacks
    _medicationProvider ??= Provider.of<MedicationProvider>(context, listen: false);
    
    // No longer using DynamicColorBuilder. We now control the state.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DiaCare',
      // The theme now uses the schemes from our state, preventing the flash.
      theme: AppTheme.lightTheme(_lightScheme),
      darkTheme: AppTheme.darkTheme(_darkScheme),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

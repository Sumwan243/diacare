import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  String _status = '?';
  int _currentSteps = 0; // Steps calculated for TODAY
  int _stepsSinceBoot = 0; // Raw steps from sensor
  int _dailyStepGoal = 10000;
  bool _permissionGranted = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    setState(() {
      _isInitializing = true;
      _permissionGranted = false;
    });

    // 1. Check Permission (Activity Recognition)
    // On Android 10+ (Pixel etc), this is required.
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isPermanentlyDenied) {
      // User selected "Don't ask again" or denied it in settings.
      // We MUST send them to settings to enable it on Pixel phones.
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _permissionGranted = false;
          _status = 'Perm. Denied';
        });
        _showOpenSettingsDialog();
      }
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _permissionGranted = false;
        });
      }
      return;
    }

    // 2. Initialize Pedometer
    try {
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
          _onPedestrianStatusChanged,
          onError: _onPedestrianStatusError);
      _stepCountSubscription = Pedometer.stepCountStream.listen(_onStepCount,
          onError: _onStepCountError);
      // If we got here, we assume permission is okay and wait for first stream event
    } catch (e) {
      print('Pedometer Error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _permissionGranted = false;
        });
      }
    }
  }

  void _onStepCount(StepCount event) async {
    // The sensor gives 'steps since boot'.
    // We need to calculate 'Daily Steps' by comparing with a saved value.
    final prefs = await SharedPreferences.getInstance();
    final int storedStepsAtMidnight = prefs.getInt('steps_at_midnight') ?? 0;
    int todaySteps = 0;
    int bootSteps = event.steps;

    // If the current boot steps are less than what we stored, the phone rebooted.
    // Or it's a new day, and we need to reset.
    // Note: This logic assumes you check for 'new day' elsewhere or reset 'steps_at_midnight' at midnight.
    // Simple logic: Steps Today = (Current Boot Steps) - (Boot Steps at App Start)
    // To make this accurate across reboots, you should save 'steps_at_midnight' whenever the day changes.
    // For this example, we calculate steps relative to the last saved value:
    if (storedStepsAtMidnight == 0 || bootSteps < storedStepsAtMidnight) {
      // First run today OR phone rebooted.
      // We treat current steps as the baseline for "Now" but for a real app,
      // you need a separate logic to reset the counter at exactly 00:00.
      // Let's save the current boot steps as the baseline for now to prevent jumping
      if (storedStepsAtMidnight == 0) {
        await prefs.setInt('steps_at_midnight', bootSteps);
      }
    }

    // Calculate Difference
    final int savedBaseline = prefs.getInt('steps_at_midnight') ?? bootSteps;
    todaySteps = bootSteps - savedBaseline;

    if (mounted) {
      setState(() {
        _stepsSinceBoot = bootSteps;
        // Ensure steps don't go negative if logic fails
        _currentSteps = todaySteps > 0 ? todaySteps : 0;
        _isInitializing = false;
        _permissionGranted = true;
      });
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (mounted) {
      setState(() {
        _status = event.status;
      });
    }
  }

  void _onStepCountError(error) {
    print('Step Count Error: $error');
    // On Pixels, if permission is missing, it might throw here or stream nothing.
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _permissionGranted = false;
      });
      _showOpenSettingsDialog();
    }
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian Status Error: $error');
    setState(() {
      _status = 'Error';
    });
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Step tracking requires "Physical Activity" permission. On some devices (like Pixel), you must enable this manually in system settings if it was previously denied.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Helper to reset steps at midnight (call this from a timer or app lifecycle in a real app)
  Future<void> _resetStepsIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString('last_reset_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate != today) {
      await prefs.setInt('steps_at_midnight', _stepsSinceBoot);
      await prefs.setString('last_reset_date', today);
      setState(() {
        _currentSteps = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activityProv = context.watch<ActivityProvider>();
    final todaySummary = activityProv.getTodaySummary();

    // Ensure UI updates when state changes
    final stepProgress = (_currentSteps / _dailyStepGoal).clamp(0.0, 1.0);
    final estimatedDistance = (_currentSteps * 0.0008).toStringAsFixed(1);
    final estimatedCalories = (_currentSteps * 0.04).toInt();

    // Check for day reset on build (simplified for example)
    // In production, use a Timer or didChangeAppLifecycleState
    _resetStepsIfNewDay();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Physical Activity',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Step Counter Card with Heart Design
            _buildStepCounterCard(
              context,
              _currentSteps,
              stepProgress,
              estimatedDistance,
              estimatedCalories,
            ),
            const SizedBox(height: 16),
            // Today's Activity Summary
            _buildTodaySummaryCard(context, todaySummary),
            const SizedBox(height: 16),
            // Quick Activity Buttons
            _buildQuickActivityButtons(context),
            const SizedBox(height: 16),
            // Recent Activities
            _buildRecentActivitiesCard(context, activityProv),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCounterCard(
    BuildContext context,
    int currentSteps,
    double stepProgress,
    String estimatedDistance,
    int estimatedCalories,
  ) {
    final theme = Theme.of(context);

    if (_isInitializing) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_permissionGranted) {
      return _buildPermissionCard(context);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Daily Steps',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: MedicalTheme.activityPurple,
              ),
            ),
            const SizedBox(height: 20),
            // SAMSUNG STYLE HEART DESIGN
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Background Heart (Grey)
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: HeartPainter(
                      color: theme.colorScheme.surfaceContainerHighest,
                      progress: 1.0, // Always full background
                    ),
                  ),
                  // 2. Foreground Heart (Red/Filled based on progress)
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: HeartPainter(
                      color: MedicalTheme.activityPurple,
                      progress: stepProgress,
                    ),
                  ),
                  // 3. Text in Center
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSteps.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '/ $_dailyStepGoal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                    child: _buildStatItem(context, Icons.straighten,
                        '${estimatedDistance}km', 'Distance')),
                Flexible(
                    child: _buildStatItem(context, Icons.local_fire_department,
                        '${estimatedCalories}', 'Calories')),
                Flexible(
                    child: _buildStatItem(
                        context, Icons.directions_walk, _status, 'Status')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: MedicalTheme.activityPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Track Your Progress',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow physical activity tracking to view your daily steps and heart health progress.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _initPlatformState(),
              icon: const Icon(Icons.refresh),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedicalTheme.activityPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open System Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: MedicalTheme.activityPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodaySummaryCard(
      BuildContext context, Map<String, int> todaySummary) {
    final theme = Theme.of(context);
    final duration = todaySummary['duration'] ?? 0;
    final calories = todaySummary['calories'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activity Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(context, Icons.timer, '${duration}min',
                    'Exercise Time'),
                _buildSummaryItem(context, Icons.local_fire_department,
                    '${calories}kcal', 'Burned'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: MedicalTheme.activityPurple, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActivityButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Log Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActivityButton(
                    context, 'Walking', Icons.directions_walk, 30, 120),
                _buildActivityButton(
                    context, 'Running', Icons.directions_run, 30, 300),
                _buildActivityButton(
                    context, 'Cycling', Icons.directions_bike, 30, 240),
                _buildActivityButton(
                    context, 'Swimming', Icons.pool, 30, 350),
                _buildActivityButton(
                    context, 'Yoga', Icons.self_improvement, 30, 100),
                _buildActivityButton(
                    context, 'Gym', Icons.fitness_center, 60, 400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityButton(BuildContext context, String activity,
      IconData icon, int duration, int calories) {
    return ElevatedButton.icon(
      onPressed: () => _logQuickActivity(activity, duration, calories),
      icon: Icon(icon, size: 18),
      label: Text(activity),
      style: ElevatedButton.styleFrom(
        backgroundColor: MedicalTheme.activityPurple.withValues(alpha: 0.1),
        foregroundColor: MedicalTheme.activityPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _logQuickActivity(String activity, int duration, int calories) {
    context.read<ActivityProvider>().addActivity(activity, duration, calories);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$activity logged: ${duration}min, ${calories}kcal'),
        backgroundColor: MedicalTheme.activityPurple,
      ),
    );
  }

  Widget _buildRecentActivitiesCard(
      BuildContext context, ActivityProvider activityProv) {
    final theme = Theme.of(context);
    final recentActivities = activityProv.entries.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No activities logged yet. Start by using the quick log buttons above!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...recentActivities.map((activity) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          MedicalTheme.activityPurple.withValues(alpha: 0.1),
                      child: Icon(
                        _getActivityIcon(activity.type),
                        color: MedicalTheme.activityPurple,
                        size: 20,
                      ),
                    ),
                    title: Text(activity.type),
                    subtitle: Text(
                        '${activity.durationMinutes}min • ${activity.caloriesBurned}kcal'),
                    trailing: Text(
                      TimeOfDay.fromDateTime(activity.timestamp)
                          .format(context),
                      style: theme.textTheme.bodySmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Custom Painter to draw a Heart Shape that fills up based on progress
class HeartPainter extends CustomPainter {
  final Color color;
  final double progress;

  HeartPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Heart shape math using cubic bezier curves relative to size
    double width = size.width;
    double height = size.height;

    // Move to top center dip
    path.moveTo(width * 0.5, height * 0.35);

    // Right curve
    path.cubicTo(
        width * 0.5, height * 0.25, // control point 1
        width * 0.8, height * 0.1, // control point 2
        width, height * 0.35 // end point (right edge top)
        );

    // Right bottom lobe
    path.cubicTo(
        width, height * 0.55, // control point 1
        width * 0.5, height, // control point 2
        width * 0.5, height // end point (bottom tip)
        );

    // Left bottom lobe
    path.cubicTo(
        width * 0.5, height, // control point 1
        0, height * 0.55, // control point 2
        0, height * 0.35 // end point (left edge top)
        );

    // Left curve
    path.cubicTo(
        0, height * 0.1, // control point 1
        width * 0.5, height * 0.25, // control point 2
        width * 0.5, height * 0.35 // end point (top center)
        );

    path.close();

    // Clip logic to simulate filling up
    // We draw the full heart, but we clip the canvas so only the bottom portion shows
    // based on progress.
    canvas.save();

    // Calculate the clip rect height based on progress (0.0 to 1.0)
    // We start clipping from the bottom (height * (1 - progress))
    double clipTop = height * (1.0 - progress);
    // If progress is very small, clip everything (0)
    // If progress is 1.0, clipTop is 0 (show everything)
    final clipRect = Rect.fromLTRB(0, clipTop, width, height);
    canvas.clipRect(clipRect);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint when progress changes
  }
}
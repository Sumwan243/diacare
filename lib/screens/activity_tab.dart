import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import '../providers/activity_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  int _dailyStepGoal = 10000;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  void _initPlatformState() async {
    // Check device compatibility first
    final isSupported = await PermissionService.isStepCountingSupported();
    if (!isSupported) {
      setState(() {
        _steps = 'Not Supported';
        _status = 'N/A';
        _permissionGranted = false;
      });
      return;
    }

    // Check if permission is granted
    final hasPermission = await PermissionService.isActivityPermissionGranted();
    
    if (!hasPermission) {
      setState(() {
        _steps = 'Permission Required';
        _status = 'N/A';
        _permissionGranted = false;
      });
      return;
    }

    try {
      // Initialize pedometer streams
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _stepCountStream = Pedometer.stepCountStream;
      
      // Set up listeners with timeout
      _pedestrianStatusStream
          .timeout(const Duration(seconds: 5))
          .listen(_onPedestrianStatusChanged, onError: _onPedestrianStatusError);
      
      _stepCountStream
          .timeout(const Duration(seconds: 5))
          .listen(_onStepCount, onError: _onStepCountError);
      
      setState(() {
        _permissionGranted = true;
      });
      
      // Test if we get data within 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      
      if (_steps == '?' && mounted) {
        // No data received, might be a device-specific issue
        setState(() {
          _steps = 'Initializing...';
        });
      }
      
    } catch (e) {
      print('Pedometer initialization error: $e'); // Debug log
      
      setState(() {
        _steps = 'Error';
        _status = 'N/A';
        _permissionGranted = false;
      });
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Step counting unavailable: ${_getErrorMessage(e.toString())}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _initPlatformState(),
            ),
          ),
        );
      }
    }

    if (!mounted) return;
  }

  String _getErrorMessage(String error) {
    if (error.contains('ACTIVITY_RECOGNITION')) {
      return 'Permission needed';
    } else if (error.contains('not available')) {
      return 'Not supported on this device';
    } else if (error.contains('timeout')) {
      return 'Sensor timeout - try again';
    } else {
      return 'Device compatibility issue';
    }
  }

  void _onStepCount(StepCount event) {
    if (mounted) {
      setState(() {
        _steps = event.steps.toString();
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
    if (mounted) {
      setState(() {
        _steps = 'N/A';
        _permissionGranted = false;
      });
      // Show user-friendly message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step counting not available on this device'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _onPedestrianStatusError(error) {
    if (mounted) {
      setState(() {
        _status = 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activityProv = context.watch<ActivityProvider>();
    final todaySummary = activityProv.getTodaySummary();
    
    final currentSteps = int.tryParse(_steps) ?? 0;
    final stepProgress = (currentSteps / _dailyStepGoal).clamp(0.0, 1.0);
    final estimatedDistance = (currentSteps * 0.0008).toStringAsFixed(1); // Rough estimate: 1 step ≈ 0.8m
    final estimatedCalories = (currentSteps * 0.04).toInt(); // Rough estimate: 1 step ≈ 0.04 calories

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Physical Activity', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Step Counter Card
            _buildStepCounterCard(
              context,
              currentSteps,
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
    
    if (!_permissionGranted) {
      return _buildPermissionCard(context);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
            
            // Circular Progress Indicator
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: stepProgress,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(MedicalTheme.activityPurple),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSteps.toString(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MedicalTheme.activityPurple,
                        ),
                      ),
                      Text(
                        'steps',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Goal: $_dailyStepGoal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(child: _buildStatItem(context, Icons.straighten, '${estimatedDistance}km', 'Distance')),
                Flexible(child: _buildStatItem(context, Icons.local_fire_department, '${estimatedCalories}', 'Calories')),
                Flexible(child: _buildStatItem(context, Icons.directions_walk, _status, 'Status')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    final theme = Theme.of(context);
    
    String title = 'Step Counter';
    String message = 'DiaCare needs permission to access your physical activity data to track your daily steps.';
    List<Widget> actions = [
      TextButton(
        onPressed: () => _initPlatformState(),
        child: const Text('Try Again'),
      ),
      ElevatedButton(
        onPressed: () async {
          final granted = await PermissionService.requestActivityPermission();
          if (granted) {
            _initPlatformState();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MedicalTheme.activityPurple,
          foregroundColor: Colors.white,
        ),
        child: const Text('Grant Permission'),
      ),
    ];

    // Customize message based on current state
    if (_steps == 'Not Supported') {
      title = 'Step Counting Unavailable';
      message = 'This device doesn\'t support automatic step counting. You can still manually log your activities using the buttons below.';
      actions = [
        ElevatedButton(
          onPressed: () => setState(() {}), // Just refresh the UI
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicalTheme.activityPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        ),
      ];
    } else if (_steps == 'Error') {
      title = 'Step Counter Error';
      message = 'There was an issue accessing the step counter. This might be due to device-specific limitations. You can still manually log activities.';
    } else if (_steps == 'Initializing...') {
      title = 'Initializing Step Counter';
      message = 'Setting up step counting... This may take a moment on some devices.';
      actions = [
        ElevatedButton(
          onPressed: () => _initPlatformState(),
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicalTheme.activityPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ];
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.directions_run,
              size: 64,
              color: MedicalTheme.activityPurple,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (actions.length == 1)
              actions.first
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTodaySummaryCard(BuildContext context, Map<String, int> todaySummary) {
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
                _buildSummaryItem(context, Icons.timer, '${duration}min', 'Exercise Time'),
                _buildSummaryItem(context, Icons.local_fire_department, '${calories}kcal', 'Burned'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, IconData icon, String value, String label) {
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
                _buildActivityButton(context, 'Walking', Icons.directions_walk, 30, 120),
                _buildActivityButton(context, 'Running', Icons.directions_run, 30, 300),
                _buildActivityButton(context, 'Cycling', Icons.directions_bike, 30, 240),
                _buildActivityButton(context, 'Swimming', Icons.pool, 30, 350),
                _buildActivityButton(context, 'Yoga', Icons.self_improvement, 30, 100),
                _buildActivityButton(context, 'Gym', Icons.fitness_center, 60, 400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityButton(BuildContext context, String activity, IconData icon, int duration, int calories) {
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

  Widget _buildRecentActivitiesCard(BuildContext context, ActivityProvider activityProv) {
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
                  backgroundColor: MedicalTheme.activityPurple.withValues(alpha: 0.1),
                  child: Icon(
                    _getActivityIcon(activity.type),
                    color: MedicalTheme.activityPurple,
                    size: 20,
                  ),
                ),
                title: Text(activity.type),
                subtitle: Text('${activity.durationMinutes}min • ${activity.caloriesBurned}kcal'),
                trailing: Text(
                  TimeOfDay.fromDateTime(activity.timestamp).format(context),
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
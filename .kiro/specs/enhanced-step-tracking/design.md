# Design Document

## Overview

The Enhanced Step Tracking system transforms the current basic pedometer functionality into a sophisticated daily step tracking experience. The design centers around a Samsung-style heart-shaped progress indicator that provides visual feedback on daily step goals, combined with intelligent daily step calculation logic that properly handles device reboots and day transitions. The system integrates seamlessly with the existing DiaCare activity tracking infrastructure while adding enhanced permission management and data persistence capabilities.

## Architecture

The enhanced step tracking follows a layered architecture:

**Presentation Layer:**
- `ActivityTab` widget with heart-shaped progress visualization
- `HeartPainter` custom painter for Samsung-style progress indicator
- Permission request dialogs and error state UI

**Business Logic Layer:**
- Daily step calculation engine with midnight reset logic
- Permission management with system settings integration
- Real-time step event processing and state management

**Data Layer:**
- SharedPreferences for step tracking persistence
- Pedometer stream integration for real-time step data
- Integration with existing ActivityProvider for manual activity logs

**External Dependencies:**
- `pedometer` package for step counting sensor access
- `permission_handler` for activity recognition permissions
- `shared_preferences` for persistent step tracking data

## Components and Interfaces

### HeartPainter Class

```dart
class HeartPainter extends CustomPainter {
  final Color color;
  final double progress; // 0.0 to 1.0
  
  HeartPainter({required this.color, required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Heart shape implementation using cubic bezier curves
    // Progress-based clipping from bottom to top
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

**Heart Shape Mathematics:**
- Uses cubic bezier curves to create smooth heart shape
- Proportional to container size (220x220px)
- Two upper lobes connected to bottom point
- Progress clipping implemented via canvas.clipRect()

### Enhanced ActivityTab State Management

```dart
class _ActivityTabState extends State<ActivityTab> {
  // Stream subscriptions
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  
  // Step tracking state
  int _currentSteps = 0;      // Daily steps (calculated)
  int _stepsSinceBoot = 0;    // Raw sensor steps
  int _dailyStepGoal = 10000; // Configurable goal
  
  // Permission and initialization state
  bool _permissionGranted = false;
  bool _isInitializing = true;
  String _status = '?';
  
  // Core methods
  Future<void> _initPlatformState();
  void _onStepCount(StepCount event);
  Future<void> _resetStepsIfNewDay();
  void _showOpenSettingsDialog();
}
```

### Daily Step Calculation Logic

```dart
// Step calculation algorithm
void _onStepCount(StepCount event) async {
  final prefs = await SharedPreferences.getInstance();
  final int storedStepsAtMidnight = prefs.getInt('steps_at_midnight') ?? 0;
  final int bootSteps = event.steps;
  
  // Handle first run or device reboot
  if (storedStepsAtMidnight == 0 || bootSteps < storedStepsAtMidnight) {
    await prefs.setInt('steps_at_midnight', bootSteps);
  }
  
  // Calculate daily steps
  final int savedBaseline = prefs.getInt('steps_at_midnight') ?? bootSteps;
  final int todaySteps = bootSteps - savedBaseline;
  
  setState(() {
    _stepsSinceBoot = bootSteps;
    _currentSteps = todaySteps > 0 ? todaySteps : 0;
    _isInitializing = false;
    _permissionGranted = true;
  });
}
```

### Permission Management System

```dart
Future<void> _initPlatformState() async {
  // 1. Check Activity Recognition permission
  var status = await Permission.activityRecognition.status;
  
  if (status.isDenied) {
    status = await Permission.activityRecognition.request();
  }
  
  if (status.isPermanentlyDenied) {
    _showOpenSettingsDialog();
    return;
  }
  
  if (!status.isGranted) {
    setState(() {
      _permissionGranted = false;
      _isInitializing = false;
    });
    return;
  }
  
  // 2. Initialize pedometer streams
  try {
    _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream
        .listen(_onPedestrianStatusChanged, onError: _onPedestrianStatusError);
    _stepCountSubscription = Pedometer.stepCountStream
        .listen(_onStepCount, onError: _onStepCountError);
  } catch (e) {
    // Handle initialization errors
  }
}
```

## Data Models

### Step Tracking Data Structure

```dart
// SharedPreferences keys and data structure
class StepTrackingData {
  static const String stepsAtMidnightKey = 'steps_at_midnight';
  static const String lastResetDateKey = 'last_reset_date';
  static const String lastBootStepsKey = 'last_boot_steps';
  
  final int stepsAtMidnight;
  final String lastResetDate;
  final int lastBootSteps;
  
  StepTrackingData({
    required this.stepsAtMidnight,
    required this.lastResetDate,
    required this.lastBootSteps,
  });
}
```

### Daily Reset Logic

```dart
Future<void> _resetStepsIfNewDay() async {
  final prefs = await SharedPreferences.getInstance();
  final lastResetDate = prefs.getString('last_reset_date');
  final today = DateTime.now().toIso8601String().split('T')[0];
  
  if (lastResetDate != today) {
    // New day detected - reset baseline
    await prefs.setInt('steps_at_midnight', _stepsSinceBoot);
    await prefs.setString('last_reset_date', today);
    
    setState(() {
      _currentSteps = 0;
    });
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Heart Progress Calculation Accuracy
*For any* daily step count and step goal, the heart progress indicator should display a progress value between 0.0 and 1.0 that equals (daily steps / step goal) clamped to maximum 1.0
**Validates: Requirements 1.2**

### Property 2: Heart Progress Clipping Consistency  
*For any* progress value between 0.0 and 1.0, the heart shape clipping should show the filled portion from bottom to top proportional to the progress percentage
**Validates: Requirements 1.7**

### Property 3: Daily Step Calculation Correctness
*For any* boot step count and stored baseline, the calculated daily steps should equal (boot steps - baseline) and never be negative, defaulting to 0 for invalid calculations
**Validates: Requirements 2.1, 2.2, 2.6**

### Property 4: Day Change Detection and Reset
*For any* date transition from one day to the next, the system should detect the change and reset the step baseline to the current boot steps, setting daily steps to 0
**Validates: Requirements 2.3**

### Property 5: Device Reboot Handling
*For any* scenario where boot steps decrease from the previous reading (indicating device reboot), the system should handle the reset gracefully without losing daily progress tracking capability
**Validates: Requirements 2.4**

### Property 6: Data Persistence Consistency
*For any* step tracking data (steps_at_midnight, last_reset_date), when the data is stored in SharedPreferences, it should be immediately retrievable and persist across app restarts
**Validates: Requirements 2.5, 4.2, 4.6**

### Property 7: Permission State Handling
*For any* permission state (granted, denied, permanently denied, not determined), the system should handle the state appropriately with correct UI feedback and error messages
**Validates: Requirements 3.4, 3.5**

### Property 8: SharedPreferences Error Recovery
*For any* corrupted or missing SharedPreferences data, the system should handle the error gracefully by using default values and continuing to function
**Validates: Requirements 4.7**

### Property 9: Step-Based Calculations
*For any* step count, the estimated distance should equal (steps × 0.0008) km and estimated calories should equal (steps × 0.04) rounded to integer
**Validates: Requirements 6.1, 6.2**

### Property 10: Display Formatting Consistency
*For any* calculated distance and calorie values, distance should display with exactly one decimal place and calories should display as integer values
**Validates: Requirements 6.3, 6.4**

### Property 11: Real-Time Statistics Updates
*For any* change in step count, all derived statistics (distance, calories, progress, status) should update immediately to reflect the new step count
**Validates: Requirements 6.6**

Now I need to analyze the acceptance criteria to determine which ones are testable as properties:

<function_calls>
<invoke name="prework">
<parameter name="featureName">enhanced-step-tracking

## Error Handling

### Permission Errors
- **Activity Recognition Denied**: Show permission request dialog with clear explanation
- **Permanently Denied**: Provide "Open Settings" button to system settings
- **Permission Check Failure**: Display retry mechanism with user-friendly error message

### Pedometer Stream Errors
- **Stream Timeout**: Show "Initializing..." status with retry option
- **Device Not Supported**: Display fallback UI explaining manual activity logging
- **Sensor Unavailable**: Graceful degradation to manual activity tracking only

### Data Persistence Errors
- **SharedPreferences Write Failure**: Log error but continue with in-memory tracking
- **Corrupted Data**: Reset to default values and reinitialize tracking
- **Missing Data**: Use sensible defaults (baseline = current boot steps)

### Calculation Errors
- **Negative Daily Steps**: Clamp to 0 and log calculation issue
- **Invalid Boot Steps**: Use previous valid reading or reset baseline
- **Date Parsing Errors**: Use current date and reset daily tracking

## Testing Strategy

### Dual Testing Approach
The enhanced step tracking system requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests** focus on:
- Specific UI widget presence and styling verification
- Permission dialog display for specific states
- Error handling for known edge cases
- Integration points with existing ActivityProvider
- Heart shape drawing accuracy for specific progress values

**Property-Based Tests** focus on:
- Mathematical calculations across all valid input ranges
- Step calculation logic with randomized boot steps and baselines
- Data persistence behavior across various data states
- Progress calculation accuracy for all step counts and goals
- Real-time update behavior with random step sequences

### Property-Based Testing Configuration
- **Testing Framework**: Use `flutter_test` with `test` package property testing capabilities
- **Minimum Iterations**: 100 iterations per property test to ensure comprehensive coverage
- **Test Tagging**: Each property test tagged with format: **Feature: enhanced-step-tracking, Property {number}: {property_text}**

### Test Coverage Areas

**Heart Progress Indicator Tests:**
- Unit tests for specific UI elements and styling
- Property tests for progress calculation accuracy across all values
- Visual regression tests for heart shape rendering

**Step Calculation Tests:**
- Property tests for daily step calculation logic
- Unit tests for specific edge cases (reboot, negative values)
- Integration tests for SharedPreferences persistence

**Permission Management Tests:**
- Unit tests for each permission state UI
- Property tests for permission state handling logic
- Integration tests for system settings navigation

**Data Persistence Tests:**
- Property tests for SharedPreferences round-trip consistency
- Unit tests for error recovery scenarios
- Integration tests for app restart data continuity

### Testing Dependencies
- `flutter_test`: Core testing framework
- `mockito`: For mocking pedometer streams and SharedPreferences
- `shared_preferences_test`: For testing SharedPreferences functionality
- `integration_test`: For end-to-end step tracking scenarios
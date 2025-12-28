# Requirements Document

## Introduction

The Enhanced Step Tracking system replaces the current basic pedometer functionality in the DiaCare app with a sophisticated step tracking implementation featuring Samsung-style heart-shaped progress indicators, improved daily step calculation logic, better permission handling, and enhanced data persistence. This upgrade transforms the activity tab from basic step counting to a comprehensive daily step tracking experience with proper day-to-day reset functionality.

## Glossary

- **DiaCare_System**: The Flutter-based diabetes management application
- **Activity_Tab**: The physical activity tracking screen within the bottom navigation
- **Heart_Progress_Indicator**: Samsung-style heart-shaped progress visualization for step tracking
- **Daily_Step_Reset**: Logic to properly calculate daily steps vs. steps since device boot
- **Step_Persistence**: SharedPreferences-based storage for step tracking data across app sessions
- **Permission_Handler**: Enhanced permission management with settings dialog integration
- **Boot_Steps**: Raw step count from device sensor since last reboot
- **Daily_Steps**: Calculated steps for the current day (resets at midnight)

## Requirements

### Requirement 1: Heart-Shaped Progress Indicator

**User Story:** As a diabetes patient, I want to see my daily step progress in an attractive heart-shaped indicator, so that I can visualize my physical activity in a health-focused and motivating way.

#### Acceptance Criteria

1. THE Activity_Tab SHALL display a heart-shaped progress indicator (220x220px) showing daily step progress
2. WHEN step progress is calculated, THE Heart_Progress_Indicator SHALL fill proportionally based on daily steps vs. goal
3. THE Heart_Progress_Indicator SHALL use a grey background heart shape with colored foreground based on progress
4. THE Heart_Progress_Indicator SHALL display current step count and goal in the center with white text and shadow
5. THE Heart_Progress_Indicator SHALL use MedicalTheme.activityPurple color for the progress fill
6. THE Heart_Progress_Indicator SHALL be drawn using CustomPaint with proper heart shape bezier curves
7. THE Heart_Progress_Indicator SHALL clip the progress fill from bottom to top based on completion percentage

### Requirement 2: Daily Step Calculation Logic

**User Story:** As a diabetes patient, I want accurate daily step counting that resets at midnight, so that I can track my daily activity goals without confusion from device reboots or multi-day accumulation.

#### Acceptance Criteria

1. THE DiaCare_System SHALL distinguish between boot steps (raw sensor data) and daily steps (calculated for today)
2. WHEN the app receives step count events, THE DiaCare_System SHALL calculate daily steps by subtracting stored baseline from current boot steps
3. THE DiaCare_System SHALL detect new days and reset the step baseline at midnight automatically
4. WHEN the device reboots, THE DiaCare_System SHALL handle step count resets without losing daily progress
5. THE DiaCare_System SHALL store steps_at_midnight and last_reset_date in SharedPreferences for persistence
6. THE DiaCare_System SHALL ensure daily steps never go negative due to calculation errors
7. THE DiaCare_System SHALL update daily step calculations in real-time as new step events arrive

### Requirement 3: Enhanced Permission Management

**User Story:** As a diabetes patient, I want clear guidance when step tracking permissions are needed, so that I can easily enable the necessary permissions and understand why they're required.

#### Acceptance Criteria

1. THE DiaCare_System SHALL check for Activity Recognition permission before initializing pedometer
2. WHEN permission is denied, THE DiaCare_System SHALL show a dialog explaining the need for physical activity permission
3. WHEN permission is permanently denied, THE DiaCare_System SHALL provide an "Open Settings" button to system settings
4. THE DiaCare_System SHALL handle permission states: granted, denied, permanently denied, and not determined
5. THE DiaCare_System SHALL show appropriate error messages for different permission failure scenarios
6. THE DiaCare_System SHALL provide retry functionality when permission issues are resolved
7. WHEN permissions are granted, THE DiaCare_System SHALL automatically reinitialize the pedometer streams

### Requirement 4: Improved Data Persistence

**User Story:** As a diabetes patient, I want my step tracking data to persist across app restarts and device reboots, so that my daily progress is maintained accurately.

#### Acceptance Criteria

1. THE DiaCare_System SHALL use SharedPreferences to store step tracking baseline data
2. THE DiaCare_System SHALL persist steps_at_midnight value for daily calculation reference
3. THE DiaCare_System SHALL store last_boot_steps to handle device reboot scenarios
4. THE DiaCare_System SHALL save last_reset_date to detect day changes for proper daily reset
5. WHEN the app starts, THE DiaCare_System SHALL load persisted data to continue accurate step tracking
6. THE DiaCare_System SHALL update persisted data immediately when step events are received
7. THE DiaCare_System SHALL handle missing or corrupted SharedPreferences data gracefully

### Requirement 5: Enhanced Error Handling and User Feedback

**User Story:** As a diabetes patient, I want clear feedback when step tracking encounters issues, so that I understand what's happening and can take appropriate action.

#### Acceptance Criteria

1. THE DiaCare_System SHALL show loading state while initializing step tracking functionality
2. WHEN step tracking is not supported, THE DiaCare_System SHALL display appropriate fallback UI
3. THE DiaCare_System SHALL provide specific error messages for different failure scenarios
4. THE DiaCare_System SHALL show permission request dialogs with clear explanations
5. WHEN step data is not available, THE DiaCare_System SHALL display "Initializing..." status
6. THE DiaCare_System SHALL handle pedometer stream errors gracefully without crashing
7. THE DiaCare_System SHALL provide retry mechanisms for recoverable errors

### Requirement 6: Step Statistics and Estimates

**User Story:** As a diabetes patient, I want to see estimated distance and calories burned based on my steps, so that I can understand the health impact of my daily activity.

#### Acceptance Criteria

1. THE DiaCare_System SHALL calculate estimated distance using 0.0008 km per step formula
2. THE DiaCare_System SHALL calculate estimated calories using 0.04 calories per step formula
3. THE DiaCare_System SHALL display distance estimate with one decimal place precision
4. THE DiaCare_System SHALL display calorie estimate as integer value
5. THE DiaCare_System SHALL show pedestrian status (walking, stopped, unknown) from pedometer
6. THE DiaCare_System SHALL update all statistics in real-time as step count changes
7. THE DiaCare_System SHALL handle edge cases where step count is zero or unavailable

### Requirement 7: Integration with Existing Activity System

**User Story:** As a diabetes patient, I want the enhanced step tracking to work seamlessly with the existing activity logging system, so that all my physical activity data is coordinated.

#### Acceptance Criteria

1. THE DiaCare_System SHALL maintain compatibility with existing ActivityProvider functionality
2. THE DiaCare_System SHALL preserve all existing quick activity logging buttons and functionality
3. THE DiaCare_System SHALL continue to display today's activity summary from ActivityProvider
4. THE DiaCare_System SHALL show recent activities list using existing ActivityProvider data
5. THE DiaCare_System SHALL maintain the same UI layout structure as the current activity tab
6. THE DiaCare_System SHALL use consistent theming with MedicalTheme.activityPurple throughout
7. THE DiaCare_System SHALL ensure step tracking data complements rather than conflicts with manual activity logs

### Requirement 8: Performance and Resource Management

**User Story:** As a diabetes patient, I want step tracking to work efficiently without draining my device battery or causing performance issues.

#### Acceptance Criteria

1. THE DiaCare_System SHALL properly dispose of pedometer stream subscriptions when the widget is disposed
2. THE DiaCare_System SHALL handle stream subscription lifecycle correctly to prevent memory leaks
3. THE DiaCare_System SHALL limit SharedPreferences writes to essential data updates only
4. THE DiaCare_System SHALL use efficient state management to minimize unnecessary UI rebuilds
5. THE DiaCare_System SHALL handle pedometer stream events asynchronously without blocking the UI
6. THE DiaCare_System SHALL implement proper error boundaries to prevent crashes from affecting other app features
7. THE DiaCare_System SHALL optimize the heart shape drawing to maintain smooth 60fps performance

### Requirement 9: Dependency Management

**User Story:** As a developer, I want the enhanced step tracking to use appropriate dependencies, so that the feature is reliable and maintainable.

#### Acceptance Criteria

1. THE DiaCare_System SHALL use the existing pedometer dependency for step counting functionality
2. THE DiaCare_System SHALL use the existing permission_handler dependency for permission management
3. THE DiaCare_System SHALL add shared_preferences dependency for step data persistence
4. THE DiaCare_System SHALL ensure all dependencies are compatible with existing app dependencies
5. THE DiaCare_System SHALL use provider pattern for state management consistency with existing code
6. THE DiaCare_System SHALL maintain compatibility with existing Flutter and Dart SDK versions
7. THE DiaCare_System SHALL not introduce any conflicting or unnecessary dependencies
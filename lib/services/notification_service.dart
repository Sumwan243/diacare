import 'dart:convert';

import 'package:flutter/material.dart' show debugPrint, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/medication_reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Channels
  static const String _medChannelId = 'med_channel';
  static const String _medEscalationChannelId = 'med_escalation_channel';
  static const String _healthChannelId = 'health_channel';
  static const String _reminderChannelId = 'reminder_channel';

  // Actions
  static const String _actionTaken = 'TAKEN';
  static const String _actionSnooze10 = 'SNOOZE_10';
  static const String _actionDismiss = 'DISMISS';
  static const String _actionView = 'VIEW';

  // Intake log box
  static const String _intakeBoxName = 'med_intake_log_box';
  static const String _notificationLogBox = 'notification_log_box';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tzdata.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (android != null) {
        // Request notification permission (works for all Android versions)
        final permissionGranted = await android.requestNotificationsPermission();
        debugPrint('Notification permission granted: $permissionGranted');
        
        // Request exact alarm permission for Android 12+ (API 31+)
        try {
          final exactAlarmPermission = await android.requestExactAlarmsPermission();
          debugPrint('Exact alarm permission granted: $exactAlarmPermission');
        } catch (e) {
          debugPrint('Exact alarm permission not available or failed: $e');
        }
        
        // Create notification channels with Samsung-optimized settings
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _medChannelId,
            'Medications',
            description: 'Critical medication reminders for your health.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );

        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _medEscalationChannelId,
            'Medication Escalations',
            description: 'Urgent follow-up alerts for missed medications.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );

        // Health alerts channel
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _healthChannelId,
            'Health Alerts',
            description: 'Important health notifications like high glucose or blood pressure.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );

        // Daily reminders channel
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _reminderChannelId,
            'Daily Reminders',
            description: 'Reminders to check glucose, log meals, and daily health summaries.',
            importance: Importance.defaultImportance,
            playSound: true,
            enableVibration: true,
          ),
        );
        
        // Create instant notification channel
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'instant',
            'Instant Alerts',
            description: 'Immediate confirmation messages.',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Create high priority channel for Samsung devices
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_priority',
            'High Priority Health Alerts',
            description: 'Critical health notifications that bypass battery optimization.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );
      }

      _initialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      // Don't throw - let the app continue without notifications
      _initialized = false;
    }
  }

  Future<void> scheduleDailySeries({
    required MedicationReminder reminder,
    required TimeOfDay time,
    required int baseId,
    int daysAhead = 7,
    Duration escalationDelay = const Duration(minutes: 10),
  }) async {
    try {
      if (!_initialized) {
        debugPrint('⚠️ Notification service not initialized, initializing now...');
        await init();
      }
      
      // Check if initialization was successful
      if (!_initialized) {
        debugPrint('❌ Cannot schedule notifications - service failed to initialize');
        throw Exception('Notification service initialization failed');
      }

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('📅 Scheduling ${reminder.name} for ${time.hour}:${time.minute.toString().padLeft(2, '0')} over next $daysAhead days');

      int scheduledCount = 0;
      for (int i = 0; i < daysAhead; i++) {
        final day = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + i,
          time.hour,
          time.minute,
        );

        if (day.isBefore(now)) {
          debugPrint('⏭️ Skipping past time: ${day.toString()}');
          continue;
        }

        final primaryId = _idForDay(baseId, day, kind: _Kind.primary);
        final escalationId = _idForDay(baseId, day, kind: _Kind.escalation);

        final payload = jsonEncode({
          'type': 'med',
          'reminderId': reminder.id,
          'reminderName': reminder.name,
          'scheduledIso': day.toIso8601String(),
          'primaryId': primaryId,
          'escalationId': escalationId,
        });

        final escalationTime = day.add(escalationDelay);

        await _scheduleWithFallback(
          id: primaryId,
          title: 'Medication Reminder',
          body: 'Time to take your ${reminder.name}.',
          when: day,
          details: _primaryDetails(),
          payload: payload,
        );

        await _scheduleWithFallback(
          id: escalationId,
          title: 'Missed Medication?',
          body: 'Please confirm you took ${reminder.name}.',
          when: escalationTime,
          details: _escalationDetails(),
          payload: payload,
        );
        
        scheduledCount++;
        debugPrint('✅ Scheduled notification for ${day.toString()} (ID: $primaryId)');
      }
      
      debugPrint('🎯 Successfully scheduled $scheduledCount notifications for ${reminder.name}');
    } catch (e) {
      debugPrint('❌ Error scheduling medication reminders for ${reminder.name}: $e');
      // Don't throw - let the medication be saved without notifications
      rethrow;
    }
  }

  Future<void> cancelDailySeries({
    required int baseId,
    int daysAhead = 7,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < daysAhead; i++) {
      final day = tz.TZDateTime(tz.local, now.year, now.month, now.day + i);

      final primaryId = _idForDay(baseId, day, kind: _Kind.primary);
      final escalationId = _idForDay(baseId, day, kind: _Kind.escalation);

      await _plugin.cancel(primaryId);
      await _plugin.cancel(escalationId);
    }
  }

  // ==================== HEALTH ALERT NOTIFICATIONS ====================

  Future<void> showHealthAlert({
    required String title,
    required String body,
    String? alertType,
  }) async {
    if (!_initialized) await init();

    final id = _generateNotificationId('health_alert_${alertType ?? 'general'}');

    final payload = jsonEncode({
      'type': 'health_alert',
      'alertType': alertType ?? 'general',
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      id,
      title,
      body,
      _healthAlertDetails(),
      payload: payload,
    );

    await _logNotification('health_alert', alertType ?? 'general');
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _showInstantNotification(title: title, body: body);
  }

  Future<void> showHighGlucoseAlert({
    required double glucoseLevel,
    required String context,
  }) async {
    if (!_initialized) await init();

    final id = _generateNotificationId('high_glucose');

    final payload = jsonEncode({
      'type': 'health_alert',
      'alertType': 'high_glucose',
      'glucoseLevel': glucoseLevel,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      id,
      '⚠️ High Glucose Alert',
      'Your glucose is at ${glucoseLevel.toStringAsFixed(0)} mg/dL ($context). Check your readings and consider taking action.',
      _healthAlertDetails(),
      payload: payload,
    );

    // Log notification
    await _logNotification('high_glucose', glucoseLevel.toString());
  }

  Future<void> showLowGlucoseAlert({
    required double glucoseLevel,
    required String context,
  }) async {
    if (!_initialized) await init();

    final id = _generateNotificationId('low_glucose');

    final payload = jsonEncode({
      'type': 'health_alert',
      'alertType': 'low_glucose',
      'glucoseLevel': glucoseLevel,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      id,
      '⚠️ Low Glucose Alert',
      'Your glucose is at ${glucoseLevel.toStringAsFixed(0)} mg/dL ($context). This requires immediate attention.',
      _healthAlertDetails(),
      payload: payload,
    );

    await _logNotification('low_glucose', glucoseLevel.toString());
  }

  Future<void> showHighBloodPressureAlert({
    required int systolic,
    required int diastolic,
  }) async {
    if (!_initialized) await init();

    final id = _generateNotificationId('high_bp');

    final payload = jsonEncode({
      'type': 'health_alert',
      'alertType': 'high_bp',
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      id,
      '🚨 High Blood Pressure Alert',
      'Your blood pressure is $systolic/$diastolic mmHg. This is elevated - please consult your healthcare provider.',
      _healthAlertDetails(),
      payload: payload,
    );

    await _logNotification('high_bp', '$systolic/$diastolic');
  }

  Future<void> showCriticalBloodPressureAlert({
    required int systolic,
    required int diastolic,
  }) async {
    if (!_initialized) await init();

    final id = _generateNotificationId('critical_bp');

    final payload = jsonEncode({
      'type': 'health_alert',
      'alertType': 'critical_bp',
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      id,
      '🆘 CRITICAL: Blood Pressure',
      'Your blood pressure is dangerously high at $systolic/$diastolic mmHg. Seek medical attention immediately!',
      _healthAlertDetails(),
      payload: payload,
    );

    await _logNotification('critical_bp', '$systolic/$diastolic');
  }

  // ==================== DAILY REMINDER NOTIFICATIONS ====================

  Future<void> scheduleGlucoseCheckReminder({
    required TimeOfDay time,
    required String reminderId,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final id = _generateNotificationId('glucose_reminder_$reminderId');

    final payload = jsonEncode({
      'type': 'reminder',
      'reminderType': 'glucose_check',
      'reminderId': reminderId,
    });

    await _scheduleWithFallback(
      id: id,
      title: 'Glucose Check Reminder',
      body: 'Time to check your blood glucose level!',
      when: scheduledTime,
      details: _reminderDetails(),
      payload: payload,
    );
  }

  Future<void> scheduleMealReminder({
    required TimeOfDay time,
    required String mealType,
    required String reminderId,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final id = _generateNotificationId('meal_reminder_$reminderId');

    final payload = jsonEncode({
      'type': 'reminder',
      'reminderType': 'meal_log',
      'mealType': mealType,
      'reminderId': reminderId,
    });

    await _scheduleWithFallback(
      id: id,
      title: 'Log Your $mealType',
      body: "Don't forget to log your $mealType!",
      when: scheduledTime,
      details: _reminderDetails(),
      payload: payload,
    );
  }

  Future<void> scheduleDailySummary({
    required TimeOfDay time,
    required String summaryId,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final id = _generateNotificationId('daily_summary_$summaryId');

    final payload = jsonEncode({
      'type': 'reminder',
      'reminderType': 'daily_summary',
      'summaryId': summaryId,
    });

    await _scheduleWithFallback(
      id: id,
      title: 'Daily Health Summary',
      body: 'Tap to see your health summary for today!',
      when: scheduledTime,
      details: _reminderDetails(),
      payload: payload,
    );
  }

  Future<void> scheduleWeeklyReport({
    required DateTime dateTime,
    required String reportId,
  }) async {
    if (!_initialized) await init();

    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);

    final id = _generateNotificationId('weekly_report_$reportId');

    final payload = jsonEncode({
      'type': 'reminder',
      'reminderType': 'weekly_report',
      'reportId': reportId,
    });

    await _scheduleWithFallback(
      id: id,
      title: 'Weekly Health Report Ready',
      body: 'Your weekly health report is ready. Tap to view!',
      when: scheduledTime,
      details: _reminderDetails(),
      payload: payload,
    );
  }

  // ==================== CANCEL REMINDERS ====================

  Future<void> cancelReminder({
    required String reminderId,
    required String reminderType,
  }) async {
    final id = _generateNotificationId('${reminderType}_$reminderId');
    await _plugin.cancel(id);
  }

  Future<void> cancelAllHealthAlerts() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _primaryDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _medChannelId,
        'Medications',
        channelDescription: 'Critical medication reminders for your health.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        // Samsung-specific optimizations
        autoCancel: false, // Don't auto-dismiss
        ongoing: false, // Allow swipe to dismiss
        fullScreenIntent: false, // Don't force full screen
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionTaken,
            'Taken',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionSnooze10,
            'Snooze 10m',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _escalationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _medEscalationChannelId,
        'Medication Escalations',
        channelDescription: 'Urgent follow-up alerts for missed medications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        // Samsung-specific optimizations for urgent notifications
        autoCancel: false,
        ongoing: true, // Make it persistent until action taken
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionTaken,
            'Taken',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionDismiss,
            'Dismiss',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _healthAlertDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _healthChannelId,
        'Health Alerts',
        channelDescription: 'Important health notifications like high glucose or blood pressure.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionView,
            'View',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionDismiss,
            'Dismiss',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        'Daily Reminders',
        channelDescription: 'Reminders to check glucose, log meals, and daily health summaries.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionView,
            'View',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionDismiss,
            'Dismiss',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Scheduled notification $id for ${when.toString()}');
    } catch (e) {
      debugPrint('Exact scheduling failed for $id: $e, trying inexact...');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Inexact scheduling succeeded for $id');
      } catch (e2) {
        debugPrint('Both exact and inexact scheduling failed for $id: $e2');
        // Don't throw - let the app continue
      }
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final action = response.actionId ?? '';

    if (data['type'] == 'med') {
      await _handleMedicationNotification(data, action);
    } else if (data['type'] == 'health_alert') {
      // Health alerts can be dismissed or viewed
      if (action == _actionDismiss) {
        await _plugin.cancel(response.id ?? 0);
      }
    } else if (data['type'] == 'reminder') {
      // Reminders can be dismissed or viewed
      if (action == _actionDismiss) {
        await _plugin.cancel(response.id ?? 0);
      }
    }
  }

  Future<void> _handleMedicationNotification(
    Map<String, dynamic> data,
    String action,
  ) async {
    final reminderId = data['reminderId'] as String?;
    final scheduledIso = data['scheduledIso'] as String?;
    final escalationId = (data['escalationId'] as num?)?.toInt();
    final reminderName = data['reminderName'] as String? ?? 'Medication';

    if (reminderId == null || scheduledIso == null) return;

    final scheduled = DateTime.tryParse(scheduledIso);
    if (scheduled == null) return;

    final intakeBox = Hive.box(_intakeBoxName);
    final key = '$reminderId::${scheduled.toIso8601String()}';

    if (action == _actionTaken) {
      await intakeBox.put(key, {
        'reminderId': reminderId,
        'scheduled': scheduled.toIso8601String(),
        'takenAt': DateTime.now().toIso8601String(),
        'status': 'taken',
      });

      try {
        final logBox = Hive.box('medication_logs_box');
        final scheduledTime = TimeOfDay.fromDateTime(scheduled);
        final dateString = DateFormat('yyyy-MM-dd').format(scheduled);
        final logKey = '${reminderId}_${dateString}_${scheduledTime.hour}:${scheduledTime.minute}';

        final log = {
          'id': const Uuid().v4(),
          'medicationId': reminderId,
          'time': DateTime.now().toIso8601String(),
          'taken': true,
        };
        await logBox.put(logKey, log);
      } catch (e) {
        debugPrint('Error syncing to medication_logs_box: $e');
      }

      if (escalationId != null) {
        await _plugin.cancel(escalationId);
      }

      await _showInstantNotification(
        title: 'Recorded',
        body: '$reminderName marked as taken.',
      );
    }

    if (action == _actionSnooze10) {
      if (escalationId == null) return;

      await _plugin.cancel(escalationId);

      final snoozeTime =
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

      await _scheduleWithFallback(
        id: escalationId,
        title: 'Missed Medication?',
        body: 'Please confirm you took $reminderName.',
        when: snoozeTime,
        details: _escalationDetails(),
        payload: jsonEncode(data),
      );
    }
  }

  int _generateNotificationId(String base) {
    return '${base}_${DateTime.now().millisecondsSinceEpoch ~/ 100000}'.hashCode & 0x7fffffff;
  }

  Future<void> _logNotification(String type, String value) async {
    try {
      final logBox = Hive.box(_notificationLogBox);
      await logBox.add({
        'type': type,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }

    Future<void> _showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Instant Alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Shows a test notification to help users verify notification settings
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    
    if (!_initialized) {
      debugPrint('Cannot show test notification - service not initialized');
      return;
    }

    await _showInstantNotification(
      title: 'DiaCare Test Notification',
      body: 'If you see this, notifications are working! Check your battery optimization settings if you don\'t receive medication reminders.',
    );
  }

  /// Provides guidance for Samsung device notification setup
  String getSamsungOptimizationGuidance() {
    return '''
Samsung Device Setup for Reliable Notifications:

1. Battery Optimization:
   • Settings → Apps → DiaCare → Battery → Allow background activity
   • Settings → Device care → Battery → App power management → Apps that won't be put to sleep → Add DiaCare

2. Notification Settings:
   • Settings → Notifications → DiaCare → Allow notifications
   • Settings → Notifications → Advanced settings → Manage notification categories → Enable all DiaCare categories

3. Auto-start Management:
   • Settings → Apps → DiaCare → Permissions → Autostart → Allow

4. Data Saver:
   • Settings → Connections → Data usage → Data saver → Allowed apps → Add DiaCare

For Samsung S10 Plus specifically:
• Go to Settings → Device care → Battery → More battery settings → Adaptive battery → Turn OFF
• Settings → Apps → Special access → Optimize battery usage → All apps → DiaCare → Don't optimize
    ''';
  }

  int _idForDay(int baseId, tz.TZDateTime day, {required _Kind kind}) {
    final dayKey = (day.year * 10000) + (day.month * 100) + day.day;

    int id = (baseId ^ dayKey) & 0x7fffffff;

    if (kind == _Kind.escalation) {
      id = (id ^ 0x40000000) & 0x7fffffff;
    }

    return id == 0 ? 1 : id;
  }
}

enum _Kind { primary, escalation }

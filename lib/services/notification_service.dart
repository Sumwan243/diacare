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

  // Actions
  static const String _actionTaken = 'TAKEN';
  static const String _actionSnooze10 = 'SNOOZE_10';

  // Intake log box
  static const String _intakeBoxName = 'med_intake_log_box';

  Future<void> init() async {
    if (_initialized) return;

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
    await android?.requestNotificationsPermission();

    // Create channels (Android 8+)
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _medChannelId,
          'Medications',
          description: 'Medication reminders.',
          importance: Importance.max,
        ),
      );

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _medEscalationChannelId,
          'Medication Escalations',
          description: 'Follow-up alerts if a dose is not confirmed.',
          importance: Importance.max,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> scheduleDailySeries({
    required MedicationReminder reminder,
    required TimeOfDay time,
    required int baseId,
    int daysAhead = 7,
    Duration escalationDelay = const Duration(minutes: 10),
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < daysAhead; i++) {
      final day = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        time.hour,
        time.minute,
      );

      if (day.isBefore(now)) continue;

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

  NotificationDetails _primaryDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _medChannelId,
        'Medications',
        channelDescription: 'Medication reminders.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
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
        channelDescription: 'Follow-up alerts if not confirmed.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionTaken,
            'Taken',
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
    } catch (_) {
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

    if (data['type'] != 'med') return;

    final reminderId = data['reminderId'] as String?;
    final scheduledIso = data['scheduledIso'] as String?;
    final escalationId = (data['escalationId'] as num?)?.toInt();
    final reminderName = data['reminderName'] as String? ?? 'Medication';

    if (reminderId == null || scheduledIso == null) return;

    final scheduled = DateTime.tryParse(scheduledIso);
    if (scheduled == null) return;

    final intakeBox = Hive.box(_intakeBoxName);

    final key = '$reminderId::${scheduled.toIso8601String()}';
    final action = response.actionId;

    if (action == _actionTaken) {
      // Write to med_intake_log_box (notification storage)
      await intakeBox.put(key, {
        'reminderId': reminderId,
        'scheduled': scheduled.toIso8601String(),
        'takenAt': DateTime.now().toIso8601String(),
        'status': 'taken',
      });

      // Also write to medication_logs_box in the format MedicationLogProvider expects
      // This ensures the UI can find it when checking isDoseTaken
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
        // Continue even if this fails - the notification box is the source of truth
      }

      if (escalationId != null) {
        await _plugin.cancel(escalationId);
      }

      await _showInstantNotification(
        title: 'Recorded',
        body: '$reminderName marked as taken.',
      );
      return;
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
        payload: payload,
      );
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
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
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

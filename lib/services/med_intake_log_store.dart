import 'package:hive/hive.dart';

class MedIntakeLogStore {
  static final Box _box = Hive.box('med_intake_log_box');

  /// Key is reminderId + ISO time so each dose is unique.
  static String _key(String reminderId, DateTime scheduled) =>
      '$reminderId::${scheduled.toIso8601String()}';

  static Future<void> markTaken({
    required String reminderId,
    required DateTime scheduled,
    DateTime? takenAt,
  }) async {
    await _box.put(_key(reminderId, scheduled), {
      'reminderId': reminderId,
      'scheduled': scheduled.toIso8601String(),
      'takenAt': (takenAt ?? DateTime.now()).toIso8601String(),
      'status': 'taken',
    });
  }

  static bool isTaken({
    required String reminderId,
    required DateTime scheduled,
  }) {
    return _box.containsKey(_key(reminderId, scheduled));
  }
}

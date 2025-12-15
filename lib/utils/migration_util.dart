import 'package:hive/hive.dart';

/// A utility to handle data migration and cleanup between app versions.
class MigrationUtil {
  /// Scans the 'medications' box for any reminders stored in an old format
  /// and deletes them to prevent crashes and ensure data consistency.
  static Future<void> cleanupOldReminders() async {
    final box = Hive.box('medications');
    if (box.isEmpty) return; // Nothing to do

    final List<dynamic> keysToDelete = [];

    for (final key in box.keys) {
      final value = box.get(key);

      if (value is Map) {
        // Old reminders might have an invalid ID or an old structure.
        // A key indicator of the old model is having an 'hour' field but no 'times' field.
        final id = value['id'];
        final hasOldStructure = value.containsKey('hour') && !value.containsKey('times');
        final hasInvalidId = id == null || id is! String || id.isEmpty;

        if (hasOldStructure || hasInvalidId) {
          keysToDelete.add(key);
        }
      } else {
        // If the data is not a Map at all, it's invalid.
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      print('Migration: Found and deleted ${keysToDelete.length} old/invalid reminders.');
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    }
  }
}

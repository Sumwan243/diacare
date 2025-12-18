import 'package:flutter/material.dart';

/// Stable 32-bit FNV-1a hash, returned as positive 31-bit int (Android-safe).
int stableHash31(String input) {
  int hash = 0x811c9dc5; // FNV offset basis
  for (final unit in input.codeUnits) {
    // fold 16-bit code unit into two bytes for stability
    final lo = unit & 0xFF;
    final hi = (unit >> 8) & 0xFF;

    hash ^= lo;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;

    hash ^= hi;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  hash &= 0x7FFFFFFF; // 31-bit positive
  return hash == 0 ? 1 : hash;
}

/// Base id for a reminder + specific time-of-day.
/// This stays the same across runs and lets you cancel reliably.
int baseIdForReminderTime(String reminderId, TimeOfDay time) {
  final minutes = time.hour * 60 + time.minute;
  return stableHash31('diacare|med|$reminderId|$minutes');
}

/// Represents a single water intake entry.
class HydrationEntry {
  String id;
  int amount; // in milliliters
  DateTime timestamp;

  HydrationEntry({
    required this.id,
    required this.amount,
    required this.timestamp,
  });

  /// Converts the object to a map for Hive storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Creates an object from a map.
  factory HydrationEntry.fromMap(Map<String, dynamic> map) => HydrationEntry(
        id: map['id'] ?? '',
        amount: map['amount'] ?? 0,
        timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}
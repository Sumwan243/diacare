class GlucoseEntry {
  String id;
  DateTime timestamp;
  double mgDl;
  String note;
  String context;

  GlucoseEntry({
    required this.id,
    required this.timestamp,
    required this.mgDl,
    this.note = '',
    this.context = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'mgDl': mgDl,
        'note': note,
        'context': context,
      };

  factory GlucoseEntry.fromMap(Map m) => GlucoseEntry(
        id: m['id'] ?? '',
        timestamp: DateTime.parse(m['timestamp']),
        mgDl: (m['mgDl'] ?? 0).toDouble(),
        note: m['note'] ?? '',
        context: m['context'] ?? '',
      );
}

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/glucose_entry.dart';

class GlucoseProvider extends ChangeNotifier {
  final Box _box = Hive.box('glucose'); // Use a generic box
  final _uuid = const Uuid();

  List<GlucoseEntry> get entries {
    // Cast the map correctly inside the method
    return _box.values.map((e) => GlucoseEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList().reversed.toList();
  }

  Future<void> addEntry(double mgDl, String context) async {
    final entry = GlucoseEntry(id: _uuid.v4(), timestamp: DateTime.now(), mgDl: mgDl, context: context);
    await _box.add(entry.toMap());
    notifyListeners();
  }

  Future<void> deleteEntry(int index) async {
    final key = _box.keyAt(_box.length - 1 - index);
    await _box.delete(key);
    notifyListeners();
  }
}

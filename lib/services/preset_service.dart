import 'package:hive/hive.dart';
import 'package:diacare/models/meal_preset.dart';

class PresetService {
  static const _boxName = 'meal_presets_box';
  static final PresetService _instance = PresetService._internal();
  factory PresetService() => _instance;
  PresetService._internal();

  Box? _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      return;
    }
    _box = await Hive.openBox(_boxName);
  }

  List<MealPreset> getPresets() {
    if (_box == null) return [];
    return _box!.values.map((v) {
      try {
        return MealPreset.fromMap(Map<String, dynamic>.from(v as Map));
      } catch (_) {
        return null;
      }
    }).whereType<MealPreset>().toList();
  }

  Future<void> savePreset(MealPreset p) async {
    await init();
    await _box!.put(p.id, p.toMap());
  }

  Future<void> deletePreset(String id) async {
    await init();
    await _box!.delete(id);
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  final Box _box = Hive.box('userProfile'); // Use a generic box
  UserProfile? _userProfile;

  UserProfile? get userProfile => _userProfile;

  UserProfileProvider() {
    loadProfile();
  }

  void loadProfile() {
    if (_box.isNotEmpty) {
      final data = _box.getAt(0);
      if (data != null) {
        // Cast the map correctly inside the method
        _userProfile = UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
        notifyListeners();
      }
    }
  }

  Future<void> saveProfile({
    required String name,
    required int age,
    required DiabeticType type,
    double? weight,
    double? height,
  }) async {
    final profile = UserProfile(
      id: _userProfile?.id ?? const Uuid().v4(),
      name: name,
      age: age,
      diabeticType: type,
      weightKg: weight ?? 0,
    );

    await _box.clear();
    await _box.add(profile.toMap());
    _userProfile = profile;
    notifyListeners();
  }
}

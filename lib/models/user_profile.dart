enum DiabeticType { type1, type2, prediabetes, gestational }

class UserProfile {
  String id;
  String name;
  DiabeticType diabeticType;
  double weightKg;
  int age;
  double hypoThreshold;
  double hyperThreshold;

  UserProfile({
    required this.id,
    required this.name,
    this.diabeticType = DiabeticType.type2,
    this.weightKg = 0,
    this.age = 0,
    this.hypoThreshold = 70,
    this.hyperThreshold = 300,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'diabeticType': diabeticType.index,
        'weightKg': weightKg,
        'age': age,
        'hypoThreshold': hypoThreshold,
        'hyperThreshold': hyperThreshold,
      };

  factory UserProfile.fromMap(Map m) => UserProfile(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        diabeticType: DiabeticType.values[(m['diabeticType'] ?? 1)],
        weightKg: (m['weightKg'] ?? 0).toDouble(),
        age: (m['age'] ?? 0) as int,
        hypoThreshold: (m['hypoThreshold'] ?? 70).toDouble(),
        hyperThreshold: (m['hyperThreshold'] ?? 300).toDouble(),
      );
}

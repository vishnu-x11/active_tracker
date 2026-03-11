import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

/// User profile stored in Hive (non-synced preferences)
/// TypeId: 0 - CRITICAL: Never change or reuse this ID
@HiveType(typeId: 0)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final double weight; // kg

  @HiveField(4)
  final double height; // cm

  @HiveField(5)
  final int goalType; // 1-6 from AppConstants

  @HiveField(6)
  final int intensityLevel; // 1-5 from AppConstants

  @HiveField(7)
  final double calorieGoal;

  @HiveField(8)
  final double proteinGoal;

  @HiveField(9)
  final double fatGoal;

  @HiveField(10)
  final double carbsGoal;

  @HiveField(11)
  final int waterGoalMl;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  UserProfileModel({
    required this.userId,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.goalType,
    required this.intensityLevel,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.fatGoal,
    required this.carbsGoal,
    required this.waterGoalMl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this model with updated fields
  UserProfileModel copyWith({
    String? userId,
    String? name,
    int? age,
    double? weight,
    double? height,
    int? goalType,
    int? intensityLevel,
    double? calorieGoal,
    double? proteinGoal,
    double? fatGoal,
    double? carbsGoal,
    int? waterGoalMl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goalType: goalType ?? this.goalType,
      intensityLevel: intensityLevel ?? this.intensityLevel,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(userId: $userId, name: $name, age: $age, weight: $weight, height: $height)';
  }
}
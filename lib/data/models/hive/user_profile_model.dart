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

  @HiveField(14)
  final double burnedCalorieGoal;

  @HiveField(15)
  final String? imageUrl;

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
    this.burnedCalorieGoal = 500.0,
    this.imageUrl,
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
    double? burnedCalorieGoal,
    String? imageUrl,
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
      burnedCalorieGoal: burnedCalorieGoal ?? this.burnedCalorieGoal,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert model to map for SQLite/Sync
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goalType': goalType,
      'intensityLevel': intensityLevel,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'fatGoal': fatGoal,
      'carbsGoal': carbsGoal,
      'waterGoalMl': waterGoalMl,
      'burnedCalorieGoal': burnedCalorieGoal,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create model from map
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      userId: map['userId'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      goalType: map['goalType'] as int,
      intensityLevel: map['intensityLevel'] as int,
      calorieGoal: (map['calorieGoal'] as num).toDouble(),
      proteinGoal: (map['proteinGoal'] as num).toDouble(),
      fatGoal: (map['fatGoal'] as num).toDouble(),
      carbsGoal: (map['carbsGoal'] as num).toDouble(),
      waterGoalMl: map['waterGoalMl'] as int,
      burnedCalorieGoal: (map['burnedCalorieGoal'] as num?)?.toDouble() ?? 500.0,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(userId: $userId, name: $name, age: $age, weight: $weight, height: $height)';
  }
}
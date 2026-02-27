import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 0)
class UserProfileModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double weight; /// kg

  @HiveField(2)
  final double height; /// cm

  @HiveField(3)
  final int age;

  @HiveField(4)
  final String gender; /// 'M' or 'F'

  @HiveField(5)
  final String fitnessGoal;

  @HiveField(6)
  final double kcal; /// target calories per day

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  UserProfileModel({
    required this.name,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.fitnessGoal,
    required this.kcal,
    required this.createdAt,
    this.updatedAt,
  });

  UserProfileModel copyWith({
    String? name,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? fitnessGoal,
    double? kcal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      kcal: kcal ?? this.kcal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
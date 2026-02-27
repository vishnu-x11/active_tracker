import 'package:hive/hive.dart';

part 'bmi_result_model.g.dart';

@HiveType(typeId: 3)
class BmiResultModel {
  @HiveField(0)
  final String dateKey; /// YYYY-MM-DD

  @HiveField(1)
  final double bmi;

  @HiveField(2)
  final double kcal;

  @HiveField(3)
  final double proteinTarget;

  @HiveField(4)
  final double fatTarget;

  @HiveField(5)
  final double carbsTarget;

  @HiveField(6)
  final int goalType;

  @HiveField(7)
  final int intensity;

  @HiveField(8)
  final DateTime createdAt;

  BmiResultModel({
    required this.dateKey,
    required this.bmi,
    required this.kcal,
    required this.proteinTarget,
    required this.fatTarget,
    required this.carbsTarget,
    required this.goalType,
    required this.intensity,
    required this.createdAt,
  });

  BmiResultModel copyWith({
    String? dateKey,
    double? bmi,
    double? kcal,
    double? proteinTarget,
    double? fatTarget,
    double? carbsTarget,
    int? goalType,
    int? intensity,
    DateTime? createdAt,
  }) {
    return BmiResultModel(
      dateKey: dateKey ?? this.dateKey,
      bmi: bmi ?? this.bmi,
      kcal: kcal ?? this.kcal,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      fatTarget: fatTarget ?? this.fatTarget,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      goalType: goalType ?? this.goalType,
      intensity: intensity ?? this.intensity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
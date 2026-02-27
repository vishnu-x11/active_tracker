import 'package:hive/hive.dart';

part 'water_log_model.g.dart';

@HiveType(typeId: 2)
class WaterLogModel {
  @HiveField(0)
  final String dateKey; /// YYYY-MM-DD

  @HiveField(1)
  final double totalIntake; /// ml

  @HiveField(2)
  final DateTime timestamp;

  WaterLogModel({
    required this.dateKey,
    required this.totalIntake,
    required this.timestamp,
  });

  WaterLogModel copyWith({
    String? dateKey,
    double? totalIntake,
    DateTime? timestamp,
  }) {
    return WaterLogModel(
      dateKey: dateKey ?? this.dateKey,
      totalIntake: totalIntake ?? this.totalIntake,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
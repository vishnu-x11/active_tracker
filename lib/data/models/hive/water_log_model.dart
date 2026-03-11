import 'package:hive/hive.dart';

part 'water_log_model.g.dart';

/// Water intake log stored in Hive (non-synced)
/// TypeId: 2 - CRITICAL: Never change or reuse this ID
@HiveType(typeId: 2)
class WaterLogModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String dateKey; // Format: "2025-02-21"

  @HiveField(2)
  final double mlConsumed;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  WaterLogModel({
    required this.userId,
    required this.dateKey,
    required this.mlConsumed,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this model with updated fields
  WaterLogModel copyWith({
    String? userId,
    String? dateKey,
    double? mlConsumed,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterLogModel(
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      mlConsumed: mlConsumed ?? this.mlConsumed,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WaterLogModel(userId: $userId, dateKey: $dateKey, mlConsumed: $mlConsumed)';
  }
}
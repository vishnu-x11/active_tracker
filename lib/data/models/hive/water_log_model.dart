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

  /// Convert model to map for SQLite/Sync
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dateKey': dateKey,
      'mlConsumed': mlConsumed,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create model from map
  factory WaterLogModel.fromMap(Map<String, dynamic> map) {
    return WaterLogModel(
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      mlConsumed: (map['mlConsumed'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'WaterLogModel(userId: $userId, dateKey: $dateKey, mlConsumed: $mlConsumed)';
  }
}
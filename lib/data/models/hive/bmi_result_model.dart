import 'package:hive/hive.dart';

part 'bmi_result_model.g.dart';

/// BMI calculation results stored in Hive (non-synced)
/// TypeId: 3 - CRITICAL: Never change or reuse this ID
@HiveType(typeId: 3)
class BmiResultModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String dateKey; // Format: "2025-02-21"

  @HiveField(2)
  final double bmi;

  @HiveField(3)
  final double weight; // kg

  @HiveField(4)
  final double height; // cm

  @HiveField(5)
  final double dailyCalories;

  @HiveField(6)
  final double proteinGrams;

  @HiveField(7)
  final double fatGrams;

  @HiveField(8)
  final double carbsGrams;

  @HiveField(9)
  final String bmiCategory; // "underweight", "normal", "overweight", "obese"

  @HiveField(10)
  final DateTime timestamp;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  BmiResultModel({
    required this.userId,
    required this.dateKey,
    required this.bmi,
    required this.weight,
    required this.height,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.bmiCategory,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this model with updated fields
  BmiResultModel copyWith({
    String? userId,
    String? dateKey,
    double? bmi,
    double? weight,
    double? height,
    double? dailyCalories,
    double? proteinGrams,
    double? fatGrams,
    double? carbsGrams,
    String? bmiCategory,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BmiResultModel(
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      bmi: bmi ?? this.bmi,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      bmiCategory: bmiCategory ?? this.bmiCategory,
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
      'bmi': bmi,
      'weight': weight,
      'height': height,
      'dailyCalories': dailyCalories,
      'proteinGrams': proteinGrams,
      'fatGrams': fatGrams,
      'carbsGrams': carbsGrams,
      'bmiCategory': bmiCategory,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create model from map
  factory BmiResultModel.fromMap(Map<String, dynamic> map) {
    return BmiResultModel(
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      bmi: (map['bmi'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      dailyCalories: (map['dailyCalories'] as num).toDouble(),
      proteinGrams: (map['proteinGrams'] as num).toDouble(),
      fatGrams: (map['fatGrams'] as num).toDouble(),
      carbsGrams: (map['carbsGrams'] as num).toDouble(),
      bmiCategory: map['bmiCategory'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'BmiResultModel(userId: $userId, dateKey: $dateKey, bmi: $bmi, category: $bmiCategory)';
  }
}
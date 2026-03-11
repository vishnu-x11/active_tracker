/// Daily log summary stored in SQLite (synced to Firebase)
/// Aggregates all daily data in one place for quick access
/// Table: daily_log_summary
class DailyLogSummary {
  final int? id;
  final String userId;
  final String dateKey; // Format: "2025-02-21"
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final double totalWater; // ml
  final int workoutMinutes;
  final int pushups;
  final int pullups;
  final String? mood; // "happy", "neutral", "sad"
  final String? notes;
  final int createdAt; // Unix timestamp
  final int updatedAt; // Unix timestamp

  DailyLogSummary({
    this.id,
    required this.userId,
    required this.dateKey,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalFat = 0,
    this.totalCarbs = 0,
    this.totalWater = 0,
    this.workoutMinutes = 0,
    this.pushups = 0,
    this.pullups = 0,
    this.mood,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dateKey': dateKey,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCarbs': totalCarbs,
      'totalWater': totalWater,
      'workoutMinutes': workoutMinutes,
      'pushups': pushups,
      'pullups': pullups,
      'mood': mood,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from database map
  factory DailyLogSummary.fromMap(Map<String, dynamic> map) {
    return DailyLogSummary(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0,
      totalProtein: (map['totalProtein'] as num?)?.toDouble() ?? 0,
      totalFat: (map['totalFat'] as num?)?.toDouble() ?? 0,
      totalCarbs: (map['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalWater: (map['totalWater'] as num?)?.toDouble() ?? 0,
      workoutMinutes: map['workoutMinutes'] as int? ?? 0,
      pushups: map['pushups'] as int? ?? 0,
      pullups: map['pullups'] as int? ?? 0,
      mood: map['mood'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Create a copy with updated fields
  DailyLogSummary copyWith({
    int? id,
    String? userId,
    String? dateKey,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalCarbs,
    double? totalWater,
    int? workoutMinutes,
    int? pushups,
    int? pullups,
    String? mood,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return DailyLogSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalWater: totalWater ?? this.totalWater,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      pushups: pushups ?? this.pushups,
      pullups: pullups ?? this.pullups,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if calorie goal met (using 90% threshold)
  bool isCalorieGoalMet(double goal) {
    return totalCalories >= (goal * 0.9);
  }

  /// Check if protein goal met (using 90% threshold)
  bool isProteinGoalMet(double goal) {
    return totalProtein >= (goal * 0.9);
  }

  /// Check if water goal met (using 100% threshold)
  bool isWaterGoalMet(double goal) {
    return totalWater >= goal;
  }

  /// Check if workout goal met (assuming 30 min minimum)
  bool isWorkoutGoalMet({int minMinutes = 30}) {
    return workoutMinutes >= minMinutes;
  }

  @override
  String toString() {
    return 'DailyLogSummary(userId: $userId, dateKey: $dateKey, calories: $totalCalories, water: $totalWater, workout: $workoutMinutes min)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DailyLogSummary &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              dateKey == other.dateKey;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ dateKey.hashCode;
}
/// Workout log entry stored in SQLite (synced to Firebase)
/// Table: workout_logs
class WorkoutLog {
  final int? id;
  final String userId;
  final String dateKey; // Format: "2025-02-21"
  final String workoutName;
  final int duration; // minutes
  final double caloriesBurned;
  final String? intensity; // "light", "moderate", "high"
  final String? notes;
  final int timestamp; // Unix timestamp
  final int createdAt; // Unix timestamp
  final int updatedAt; // Unix timestamp

  WorkoutLog({
    this.id,
    required this.userId,
    required this.dateKey,
    required this.workoutName,
    required this.duration,
    required this.caloriesBurned,
    this.intensity,
    this.notes,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dateKey': dateKey,
      'workoutName': workoutName,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'intensity': intensity,
      'notes': notes,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from database map
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      workoutName: map['workoutName'] as String,
      duration: map['duration'] as int,
      caloriesBurned: (map['caloriesBurned'] as num).toDouble(),
      intensity: map['intensity'] as String?,
      notes: map['notes'] as String?,
      timestamp: map['timestamp'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Create a copy with updated fields
  WorkoutLog copyWith({
    int? id,
    String? userId,
    String? dateKey,
    String? workoutName,
    int? duration,
    double? caloriesBurned,
    String? intensity,
    String? notes,
    int? timestamp,
    int? createdAt,
    int? updatedAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      workoutName: workoutName ?? this.workoutName,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WorkoutLog(id: $id, workoutName: $workoutName, duration: $duration, dateKey: $dateKey)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WorkoutLog &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              dateKey == other.dateKey &&
              timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ dateKey.hashCode ^ timestamp.hashCode;
}
/// Exercise entry stored in SQLite (synced to Firebase)
/// Table: exercises
class Exercise {
  final int? id;
  final String userId;
  final String dateKey; // Format: "2025-02-21"
  final String exerciseType; // "pushup", "pullup", custom names
  final int reps;
  final int sets;
  final double? weight; // kg, null for bodyweight exercises
  final int timestamp; // Unix timestamp
  final int createdAt; // Unix timestamp
  final int updatedAt; // Unix timestamp

  Exercise({
    this.id,
    required this.userId,
    required this.dateKey,
    required this.exerciseType,
    required this.reps,
    required this.sets,
    this.weight,
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
      'exerciseType': exerciseType,
      'reps': reps,
      'sets': sets,
      'weight': weight,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from database map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      exerciseType: map['exerciseType'] as String,
      reps: map['reps'] as int,
      sets: map['sets'] as int,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      timestamp: map['timestamp'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Create a copy with updated fields
  Exercise copyWith({
    int? id,
    String? userId,
    String? dateKey,
    String? exerciseType,
    int? reps,
    int? sets,
    double? weight,
    int? timestamp,
    int? createdAt,
    int? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      exerciseType: exerciseType ?? this.exerciseType,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      weight: weight ?? this.weight,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total reps = reps * sets
  int getTotalReps() => reps * sets;

  @override
  String toString() {
    return 'Exercise(id: $id, exerciseType: $exerciseType, reps: $reps, sets: $sets, dateKey: $dateKey)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Exercise &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              dateKey == other.dateKey &&
              timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ dateKey.hashCode ^ timestamp.hashCode;
}
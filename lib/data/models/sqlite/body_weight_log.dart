/// Body weight log entry stored in SQLite (synced to Firebase)
/// Table: body_weight_logs
class BodyWeightLog {
  final int? id;
  final String userId;
  final String dateKey; // Format: "2025-02-21"
  final double weight; // kg
  final int timestamp; // Unix timestamp
  final int createdAt; // Unix timestamp
  final int updatedAt; // Unix timestamp

  BodyWeightLog({
    this.id,
    required this.userId,
    required this.dateKey,
    required this.weight,
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
      'weight': weight,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from database map
  factory BodyWeightLog.fromMap(Map<String, dynamic> map) {
    return BodyWeightLog(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      weight: (map['weight'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Create a copy with updated fields
  BodyWeightLog copyWith({
    int? id,
    String? userId,
    String? dateKey,
    double? weight,
    int? timestamp,
    int? createdAt,
    int? updatedAt,
  }) {
    return BodyWeightLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      weight: weight ?? this.weight,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BodyWeightLog(id: $id, weight: $weight, dateKey: $dateKey)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BodyWeightLog &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              dateKey == other.dateKey;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ dateKey.hashCode;
}
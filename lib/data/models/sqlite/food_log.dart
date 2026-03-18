/// Food log entry stored in SQLite (synced to Firebase)
/// Table: food_logs
class FoodLog {
  final int? id;
  final String userId;
  final String dateKey; // Format: "2025-02-21"
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double quantity;
  final String? unit; // g, ml, piece, serving, etc.
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final int timestamp; // Unix timestamp
  final int createdAt; // Unix timestamp
  final int updatedAt; // Unix timestamp

  FoodLog({
    this.id,
    required this.userId,
    required this.dateKey,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.quantity,
    this.unit,
    this.mealType = 'Breakfast',
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
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'quantity': quantity,
      'unit': unit,
      'mealType': mealType,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from database map
  factory FoodLog.fromMap(Map<String, dynamic> map) {
    return FoodLog(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      foodName: map['foodName'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      mealType: map['mealType'] as String? ?? 'Breakfast',
      timestamp: map['timestamp'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Create a copy with updated fields
  FoodLog copyWith({
    int? id,
    String? userId,
    String? dateKey,
    String? foodName,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? quantity,
    String? unit,
    String? mealType,
    int? timestamp,
    int? createdAt,
    int? updatedAt,
  }) {
    return FoodLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FoodLog(id: $id, foodName: $foodName, calories: $calories, dateKey: $dateKey)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FoodLog &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              dateKey == other.dateKey &&
              timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ dateKey.hashCode ^ timestamp.hashCode;
}
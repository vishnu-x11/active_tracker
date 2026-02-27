import 'package:isar/isar.dart';

part 'food_log.g.dart';

@Collection()
class FoodLog {
  Id? id;

  @Index()
  late String dateKey;

  late String foodName;

  late double quantity;

  late String unit; /// 'g', 'ml', 'serving'

  late double calories;

  late double protein;

  late double fat;

  late double carbs;

  late DateTime timestamp;
}
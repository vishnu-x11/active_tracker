import 'package:isar/isar.dart';

part 'body_weight_log.g.dart';

@Collection()
class BodyWeightLog {
  Id? id;

  @Index()
  late String dateKey;

  late String exerciseType; /// 'push up' or 'pullup'

  late String setsReps;

  late int dailyTotal;

  late DateTime timestamp;
}
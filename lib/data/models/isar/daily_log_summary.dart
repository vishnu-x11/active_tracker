import 'package:isar/isar.dart';

part 'daily_log_summary.g.dart';

@Collection()
class DailyLogSummary {
  Id? id;

  @Index(unique: true, type: IndexType.value)
  late String dateKey;

  late double caloriesConsumed;

  late double proteinConsumed;

  late double fatConsumed;

  late double carbsConsumed;

  late double waterConsumed;

  late bool workoutCompleted;

  late bool noteWritten;

  late List<String> goalsMet;

  late int goalsMetCount;

  late DateTime createdAt;

  late DateTime updatedAt;
}
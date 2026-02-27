import 'package:isar/isar.dart';

part 'workout_log.g.dart';

@Collection()
class WorkoutLog {
  Id? id;

  @Index()
  late String dateKey;

  late String bodyPart;

  late String exerciseName;

  late int sets;

  late int reps;

  late double weight;

  late double duration;

  late String notes;

  late DateTime timestamp;
}
import 'package:active_health/data/models/isar/body_weight_log.dart';
import 'package:active_health/data/models/isar/daily_log_summary.dart';
import 'package:active_health/data/models/isar/exercise.dart';
import 'package:active_health/data/models/isar/food_log.dart';
import 'package:active_health/data/models/isar/workout_log.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';


class IsarManager {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [
        foodLogSchema,
        workoutLogSchema,
        exerciseSchema,
        bodyWeightLogSchema,
        dailyLogSummarySchema,
      ],
      directory: dir.path,
    );

    debugPrint('✅ Isar initialized successfully');
  }

  static Isar getInstance() => isar;

  static Future<void> close() async {
    await isar.close();
  }
}
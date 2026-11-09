import 'dart:convert';

import '../../../../core/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../data_sources/reminder_scheduler.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  const RemindersRepositoryImpl(this._database, this._scheduler);

  final AppDatabase _database;
  final ReminderScheduler _scheduler;

  static const _key = 'reminders';

  @override
  Future<Result<ReminderSettings>> load() async {
    try {
      final raw = await _database.setting(_key);
      if (raw == null) return const Ok(ReminderSettings());
      final j = jsonDecode(raw) as Map<String, Object?>;
      int i(String k, int d) => (j[k] as num?)?.toInt() ?? d;
      bool b(String k) => j[k] as bool? ?? true;
      const d = ReminderSettings();
      return Ok(
        ReminderSettings(
          waterOn: b('waterOn'),
          waterFrom: i('waterFrom', d.waterFrom),
          waterTo: i('waterTo', d.waterTo),
          proteinOn: b('proteinOn'),
          proteinAt: i('proteinAt', d.proteinAt),
          workoutOn: b('workoutOn'),
          workoutAt: i('workoutAt', d.workoutAt),
          workoutDays: {
            for (final x in (j['workoutDays'] as List<Object?>? ?? d.workoutDays.toList())) (x! as num).toInt(),
          },
          streakOn: b('streakOn'),
          streakAt: i('streakAt', d.streakAt),
          weeklyOn: b('weeklyOn'),
          weeklyAt: i('weeklyAt', d.weeklyAt),
        ),
      );
    } catch (e) {
      return Err(StorageFailure("Couldn't load your reminders.", e));
    }
  }

  @override
  Future<Result<void>> save(ReminderSettings s) async {
    try {
      await _database.setSetting(
        _key,
        jsonEncode({
          'waterOn': s.waterOn,
          'waterFrom': s.waterFrom,
          'waterTo': s.waterTo,
          'proteinOn': s.proteinOn,
          'proteinAt': s.proteinAt,
          'workoutOn': s.workoutOn,
          'workoutAt': s.workoutAt,
          'workoutDays': (s.workoutDays.toList()..sort()),
          'streakOn': s.streakOn,
          'streakAt': s.streakAt,
          'weeklyOn': s.weeklyOn,
          'weeklyAt': s.weeklyAt,
        }),
      );
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't save your reminders.", e));
    }
  }

  @override
  Future<Result<void>> schedule(List<PlannedReminder> plan) async {
    try {
      await _scheduler.replaceAll(plan);
      return const Ok(null);
    } catch (e) {
      return Err(SyncFailure("Couldn't schedule reminders on this phone.", e));
    }
  }

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      return Ok(await _scheduler.requestPermission());
    } catch (e) {
      return Err(SyncFailure("Couldn't ask for notification permission.", e));
    }
  }
}

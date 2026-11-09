import '../../../../core/result.dart';
import '../entities/reminder_settings.dart';

abstract interface class RemindersRepository {
  Future<Result<ReminderSettings>> load();
  Future<Result<void>> save(ReminderSettings settings);

  Future<Result<void>> schedule(List<PlannedReminder> plan);

  Future<Result<bool>> requestPermission();
}

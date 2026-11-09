import '../../../../core/result.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/day_totals.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/progress_repository.dart';
import '../data_sources/progress_local_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._local);

  final ProgressLocalDataSource _local;

  static const _readError = "Couldn't load your totals. Pull down to try again.";

  Future<Result<T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Ok(await read());
    } catch (e) {
      return Err(StorageFailure(_readError, e));
    }
  }

  @override
  Future<Result<DayTotals>> dayTotals(String day) => _guard(() => _local.dayTotals(day));

  @override
  Future<Result<Map<String, int>>> burnByDay(String from, String to) => _guard(() => _local.burnByDay(from, to));

  @override
  Future<Result<Set<String>>> activeDays(String from, String to) => _guard(() => _local.activeDays(from, to));

  @override
  Future<Result<List<ActivityItem>>> activities(String from, String to) => _guard(() => _local.activities(from, to));

  @override
  Future<Result<Map<String, DayTotals>>> daySummaries(String from, String to) =>
      _guard(() => _local.daySummaries(from, to));

  @override
  Future<Result<String?>> firstLogDay() => _guard(_local.firstLogDay);

  @override
  Future<Result<List<Goal>>> goals() => _guard(_local.goals);

  @override
  Future<Result<void>> addGoal(Goal goal) => _guard(() => _local.insertGoal(goal));

  @override
  Future<Result<void>> removeGoal(String id) => _guard(() => _local.softDeleteGoal(id));
}

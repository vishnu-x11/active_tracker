import '../../../../core/result.dart';
import '../entities/activity_item.dart';
import '../entities/day_totals.dart';
import '../entities/goal.dart';

abstract interface class ProgressRepository {
  Future<Result<DayTotals>> dayTotals(String day);

  Future<Result<Map<String, int>>> burnByDay(String from, String to);

  Future<Result<Set<String>>> activeDays(String from, String to);

  Future<Result<List<ActivityItem>>> activities(String from, String to);

  Future<Result<Map<String, DayTotals>>> daySummaries(String from, String to);

  Future<Result<String?>> firstLogDay();

  Future<Result<List<Goal>>> goals();
  Future<Result<void>> addGoal(Goal goal);
  Future<Result<void>> removeGoal(String id);
}

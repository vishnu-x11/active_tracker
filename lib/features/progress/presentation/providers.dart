import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/cache_for.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../profile/profile_api.dart';
import '../data/data_sources/progress_local_data_source.dart';
import '../data/repositories/progress_repository_impl.dart';
import '../domain/entities/activity_item.dart';
import '../domain/entities/daily_targets.dart';
import '../domain/entities/day_totals.dart';
import '../domain/entities/week_burn.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/use_cases/get_active_days.dart';
import '../domain/use_cases/get_activities.dart';
import '../domain/use_cases/get_day_totals.dart';
import '../domain/use_cases/get_week_burn.dart';
import 'progress_providers.dart';

final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>(
  (ref) => ProgressLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(ref.watch(progressLocalDataSourceProvider)),
);

final getDayTotalsProvider = Provider((ref) => GetDayTotals(ref.watch(progressRepositoryProvider)));
final getWeekBurnProvider = Provider((ref) => GetWeekBurn(ref.watch(progressRepositoryProvider)));
final getActiveDaysProvider = Provider((ref) => GetActiveDays(ref.watch(progressRepositoryProvider)));
final getActivitiesProvider = Provider((ref) => GetActivities(ref.watch(progressRepositoryProvider)));

const _cache = Duration(minutes: 2);

final dayTotalsProvider = FutureProvider.autoDispose.family<DayTotals, String>((ref, day) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(getDayTotalsProvider)(day)).valueOrThrow();
});

final dayTargetsProvider = FutureProvider.autoDispose.family<DailyTargets?, String>((ref, day) async {
  ref.watch(dataRevisionProvider);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final workoutDay = await ref.watch(dayTotalsProvider(day).selectAsync((t) => t.isWorkoutDay));
  return DailyTargets.forDay(profile, workoutDay: workoutDay);
});

final dayActivitiesProvider = FutureProvider.autoDispose.family<List<ActivityItem>, String>((ref, day) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(getActivitiesProvider)(day, day)).valueOrThrow();
});

final activitiesProvider = FutureProvider.autoDispose.family<List<ActivityItem>, (String, String)>((ref, range) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(getActivitiesProvider)(range.$1, range.$2)).valueOrThrow();
});

final activeDaysProvider = FutureProvider.autoDispose.family<Set<String>, (String, String)>((ref, range) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(getActiveDaysProvider)(range.$1, range.$2)).valueOrThrow();
});

final weekBurnProvider = FutureProvider.autoDispose.family<WeekBurn, String>((ref, monday) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(getWeekBurnProvider)(DateTime.parse(monday))).valueOrThrow();
});

void invalidateDay(Ref ref, String day) {
  ref
    ..invalidate(dayTotalsProvider(day))
    ..invalidate(dayActivitiesProvider(day))
    ..invalidate(activitiesProvider)
    ..invalidate(activeDaysProvider)
    ..invalidate(weekBurnProvider);
  invalidateProgress(ref);
  ref.read(syncControllerProvider.notifier).nudge();
}

void invalidateDayFromWidget(WidgetRef ref, String day) {
  ref
    ..invalidate(dayTotalsProvider(day))
    ..invalidate(dayActivitiesProvider(day))
    ..invalidate(activitiesProvider)
    ..invalidate(activeDaysProvider)
    ..invalidate(weekBurnProvider)
    ..invalidate(daySummariesProvider)
    ..invalidate(firstLogDayProvider)
    ..invalidate(allActivitiesProvider)
    ..invalidate(streakProvider)
    ..invalidate(calendarMonthProvider)
    ..invalidate(goalsProvider);
  ref.read(syncControllerProvider.notifier).nudge();
}

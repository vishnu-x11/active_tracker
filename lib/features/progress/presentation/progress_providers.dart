import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/providers/cache_for.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../profile/profile_api.dart';
import '../domain/entities/activity_item.dart';
import '../domain/entities/day_totals.dart';
import '../domain/entities/goal.dart';
import '../domain/use_cases/progress_rules.dart';
import 'providers.dart';

const _cache = Duration(minutes: 2);

final daySummariesProvider = FutureProvider.autoDispose.family<Map<String, DayTotals>, (String, String)>((
  ref,
  range,
) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(progressRepositoryProvider).daySummaries(range.$1, range.$2)).valueOrThrow();
});

final firstLogDayProvider = FutureProvider.autoDispose<String?>((ref) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  return (await ref.watch(progressRepositoryProvider).firstLogDay()).valueOrThrow();
});

final allActivitiesProvider = FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  ref.watch(dataRevisionProvider);
  ref.cacheFor(_cache);
  final today = ref.watch(todayProvider);
  return (await ref.watch(progressRepositoryProvider).activities('0000-01-01', dayKey(today))).valueOrThrow();
});

final streakProvider = FutureProvider.autoDispose<({int current, int best})>((ref) async {
  ref.watch(dataRevisionProvider);
  final today = ref.watch(todayProvider);
  final active = (await ref.watch(progressRepositoryProvider).activeDays(dayKey(addDays(today, -730)), dayKey(today)))
      .valueOrThrow();
  return ProgressRules.streak(active, today);
});

typedef CalendarDay = ({DateTime date, bool run, bool gym, List<DailyGoal> missed, bool future, bool today});

final calendarMonthProvider = FutureProvider.autoDispose.family<List<CalendarDay>, DateTime>((ref, month) async {
  final today = ref.watch(todayProvider);
  final first = DateTime(month.year, month.month), last = DateTime(month.year, month.month + 1, 0);
  final range = (dayKey(first), dayKey(last));
  final summaries = await ref.watch(daySummariesProvider(range).future);
  final firstLog = await ref.watch(firstLogDayProvider.future);
  final profile = await ref.watch(profileProvider.future);
  final todayKey = dayKey(today);
  return [
    for (var d = first; !d.isAfter(last); d = addDays(d, 1))
      (
        date: d,
        run: (summaries[dayKey(d)]?.runCount ?? 0) > 0,
        gym: (summaries[dayKey(d)]?.gymCount ?? 0) > 0,
        missed: profile == null
            ? const <DailyGoal>[]
            : ProgressRules.missed(
                day: dayKey(d),
                totals: summaries[dayKey(d)],
                profile: profile,
                today: todayKey,
                firstLogDay: firstLog,
              ),
        future: d.isAfter(today),
        today: dayKey(d) == todayKey,
      ),
  ];
});

typedef GoalProgress = ({Goal goal, double done});

final goalsProvider = FutureProvider.autoDispose<List<GoalProgress>>((ref) async {
  ref.watch(dataRevisionProvider);
  final today = ref.watch(todayProvider);
  final goals = (await ref.watch(progressRepositoryProvider).goals()).valueOrThrow();
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  final out = <GoalProgress>[];
  for (final g in goals) {
    final (from, to) = ProgressRules.goalRange(g.period, today);
    final range = (dayKey(from), dayKey(to));
    final days = await ref.watch(daySummariesProvider(range).future);
    final runs = await ref.watch(activitiesProvider(range).future);
    out.add((goal: g, done: ProgressRules.goalDone(g, days, runs, profile)));
  }
  return out;
});

void invalidateProgress(Ref ref) {
  ref
    ..invalidate(daySummariesProvider)
    ..invalidate(firstLogDayProvider)
    ..invalidate(allActivitiesProvider)
    ..invalidate(streakProvider)
    ..invalidate(calendarMonthProvider)
    ..invalidate(goalsProvider);
}

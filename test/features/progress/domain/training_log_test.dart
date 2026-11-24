import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/progress/domain/entities/activity_item.dart';
import 'package:active_tracker/features/progress/domain/entities/goal.dart';
import 'package:active_tracker/features/progress/domain/use_cases/progress_rules.dart';
import 'package:active_tracker/features/progress/domain/use_cases/training_log.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityItem run(String day, {int km = 5, int minutes = 30}) => ActivityItem(
  id: 'r$day',
  type: ActivityType.run,
  day: day,
  startedAt: DateTime.parse(day),
  title: 'Run',
  kcal: 300,
  distanceM: km * 1000,
  movingSec: minutes * 60,
  fromGps: true,
);

ActivityItem gym(String day, {int minutes = 45}) => ActivityItem(
  id: 'g$day',
  type: ActivityType.gym,
  day: day,
  startedAt: DateTime.parse(day),
  title: 'Gym',
  kcal: 400,
  durationMin: minutes,
);

void main() {
  final today = DateTime(2026, 11, 18);

  test('week streak counts weeks in a row and spares the current week', () {
    final s = ProgressRules.weekStreak({'2026-11-10', '2026-11-03', '2026-10-27', '2026-10-06', '2026-10-13'}, today);
    expect(s.current, 3);
    expect(s.best, 3);
    expect(ProgressRules.weekStreak({'2026-11-17'}, today).current, 1);
    expect(ProgressRules.weekStreak({'2026-10-27'}, today).current, 0);
  });

  test('training log groups days into weeks, newest first', () {
    final weeks = TrainingLog.weeks(
      [run('2026-11-16', minutes: 26), gym('2026-11-16'), run('2026-11-11', minutes: 70)],
      today,
      3,
      ActivityFilter.all,
    );
    expect(weeks.first.monday, DateTime(2026, 11, 16));
    expect(weeks.first.minutes, 71);
    expect(weeks.first.days.first.run && weeks.first.days.first.gym, isTrue);
    expect(weeks.first.days[2].today, isTrue);
    expect(weeks.first.days[3].future, isTrue);
    expect(weeks[1].minutes, 70);
    final runsOnly = TrainingLog.weeks([run('2026-11-16'), gym('2026-11-16')], today, 1, ActivityFilter.gym);
    expect(runsOnly.first.minutes, 45);
    expect(TrainingLog.dotStep(26), 1);
    expect(TrainingLog.dotStep(45), 2);
    expect(TrainingLog.dotStep(70), 3);
    expect(TrainingLog.clock(26), '0:26');
    expect(TrainingLog.hm(68), '1h 8m');
  });

  test('trend sums each week oldest to newest', () {
    final items = [run('2026-11-17', km: 4), run('2026-11-10', km: 6), gym('2026-11-10')];
    expect(TrainingLog.trend(items, today, 3, TrendMetric.distance), [0, 6, 4]);
    expect(TrainingLog.trend(items, today, 3, TrendMetric.time), [0, 75, 30]);
    expect(TrainingLog.trend(items, today, 3, TrendMetric.burn), [0, 700, 300]);
  });

  test('suggested weekly goal is 10% over the last four weeks, in 15 minute steps', () {
    final items = [
      for (final d in ['2026-10-20', '2026-10-27', '2026-11-03', '2026-11-10']) run(d, minutes: 80),
    ];
    expect(TrainingLog.suggestWeeklyMinutes(items, today), 90);
    expect(TrainingLog.suggestWeeklyMinutes(const [], today), 60);
  });

  test('a run time goal counts whole moving minutes', () {
    const goal = Goal(id: 'g', kind: GoalKind.runTime, period: GoalPeriod.week, target: 60);
    final done = ProgressRules.goalDone(goal, const {}, [
      run('2026-11-16', minutes: 26),
      gym('2026-11-16'),
    ], const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
    expect(done, 26);
    expect(GoalKind.runTime.title(60), 'Run 1h');
    expect(GoalKind.runTime.title(75), 'Run 1h 15m');
    expect(goalMinutes(45), '45m');
  });
}

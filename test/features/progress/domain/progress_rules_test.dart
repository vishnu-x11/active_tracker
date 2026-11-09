import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/progress/domain/entities/activity_item.dart';
import 'package:active_tracker/features/progress/domain/entities/day_totals.dart';
import 'package:active_tracker/features/progress/domain/entities/goal.dart';
import 'package:active_tracker/features/progress/domain/use_cases/progress_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600);

  group('missed goals (R12)', () {
    List<DailyGoal> missed(String day, DayTotals? t) =>
        ProgressRules.missed(day: day, totals: t, profile: profile, today: '2026-11-05', firstLogDay: '2026-11-01');

    test('a past day under every target misses all three', () {
      expect(missed('2026-11-03', null), [DailyGoal.burn, DailyGoal.water, DailyGoal.protein]);
    });
    test('a day that hit everything (workout day water 3,125) misses none', () {
      const t = DayTotals(day: '2026-11-04', gymKcal: 600, gymCount: 1, waterMl: 3125, proteinG: 120);
      expect(missed('2026-11-04', t), isEmpty);
    });
    test('the workout-day water target is higher', () {
      const t = DayTotals(day: '2026-11-04', gymKcal: 600, gymCount: 1, waterMl: 2700, proteinG: 120);
      expect(missed('2026-11-04', t), [DailyGoal.water]);
    });
    test('today, the future and days before the first log are never marked', () {
      expect(missed('2026-11-05', null), isEmpty);
      expect(missed('2026-11-09', null), isEmpty);
      expect(missed('2026-10-30', null), isEmpty);
    });
  });

  test('streaks: today without a workout keeps the streak; best counts the longest run', () {
    final s = ProgressRules.streak({
      '2026-11-01',
      '2026-11-02',
      '2026-11-03',
      '2026-11-04',
      '2026-10-20',
      '2026-10-21',
    }, DateTime(2026, 11, 5));
    expect((s.current, s.best), (4, 4));
    expect(ProgressRules.streak({'2026-11-02'}, DateTime(2026, 11, 5)).current, 0);
  });

  test('achievements', () {
    ActivityItem run(double km, int hour) => ActivityItem(
      id: '$km$hour',
      type: ActivityType.run,
      day: '2026-11-05',
      startedAt: DateTime(2026, 11, 5, hour),
      title: 'Run',
      kcal: 1,
      distanceM: (km * 1000).round(),
      movingSec: 1800,
    );
    final a = ProgressRules.achievements([run(5.2, 6), run(4, 18)]);
    expect(a.map((x) => x.earned), [true, false, false, false, false]);
    expect(a[1].progress, '9.2 / 200 km');
    expect(a[4].progress, '1 / 5 runs');
  });

  test('goal targets (R14): typed, 1 km and 50 kcal steps that snap', () {
    expect(ProgressRules.parseTarget(GoalKind.runDistance, '12.55'), 12.6);
    expect(ProgressRules.parseTarget(GoalKind.activeBurn, '0'), isNull);
    expect(ProgressRules.stepTarget(GoalKind.runDistance, 12.6, 1), 13);
    expect(ProgressRules.stepTarget(GoalKind.runDistance, 12.6, -1), 12);
    expect(ProgressRules.stepTarget(GoalKind.activeBurn, 3000, 1), 3050);
    expect(ProgressRules.stepTarget(GoalKind.activeBurn, 3020, -1), 3000);
    expect(ProgressRules.stepTarget(GoalKind.activeBurn, 50, -1), 50);
  });
}

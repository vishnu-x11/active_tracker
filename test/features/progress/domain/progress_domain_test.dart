import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/progress/domain/entities/activity_item.dart';
import 'package:active_tracker/features/progress/domain/entities/daily_targets.dart';
import 'package:active_tracker/features/progress/domain/entities/day_totals.dart';
import 'package:active_tracker/features/progress/domain/entities/goal.dart';
import 'package:active_tracker/features/progress/domain/repositories/progress_repository.dart';
import 'package:active_tracker/features/progress/domain/use_cases/get_activities.dart';
import 'package:active_tracker/features/progress/domain/use_cases/get_week_burn.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ProgressRepository {
  Map<String, int> burn = {};
  List<ActivityItem> items = [];
  (String, String)? asked;

  @override
  Future<Result<Map<String, int>>> burnByDay(String from, String to) async {
    asked = (from, to);
    return Ok(burn);
  }

  @override
  Future<Result<List<ActivityItem>>> activities(String from, String to) async => Ok(items);

  @override
  Future<Result<Set<String>>> activeDays(String from, String to) async => const Ok({});

  @override
  Future<Result<DayTotals>> dayTotals(String day) async => Ok(DayTotals(day: day));

  @override
  Future<Result<Map<String, DayTotals>>> daySummaries(String from, String to) async => const Ok({});

  @override
  Future<Result<String?>> firstLogDay() async => const Ok(null);

  @override
  Future<Result<List<Goal>>> goals() async => const Ok([]);

  @override
  Future<Result<void>> addGoal(Goal goal) async => const Ok(null);

  @override
  Future<Result<void>> removeGoal(String id) async => const Ok(null);
}

void main() {
  test('targets: 75 kg gives 2,625 ml (3,125 on workout days) and 120 g; burn is the user target', () {
    const profile = Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 650);
    expect(
      DailyTargets.forDay(profile, workoutDay: false),
      const DailyTargets(burnKcal: 650, waterMl: 2625, proteinG: 120),
    );
    expect(DailyTargets.forDay(profile, workoutDay: true).waterMl, 3125);
    const noBoost = Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600, workoutWaterBoost: false);
    expect(DailyTargets.forDay(noBoost, workoutDay: true).waterMl, 2625);
  });

  test('week burn: Monday to Sunday plus last week, with the change', () async {
    final repo = _FakeRepo()
      ..burn = {'2026-11-02': 655, '2026-11-04': 993, '2026-11-05': 1117, '2026-10-27': 1000, '2026-10-30': 1468};
    final week = (await GetWeekBurn(repo)(DateTime(2026, 11, 5))).valueOrNull!;
    expect(repo.asked, ('2026-10-26', '2026-11-08'));
    expect(week.monday, '2026-11-02');
    expect(week.days, [655, 0, 993, 1117, 0, 0, 0]);
    expect(week.total, 2765);
    expect(week.changePct, 12);
  });

  test('no change shown when last week was empty', () async {
    final week = (await GetWeekBurn(_FakeRepo()..burn = {'2026-11-02': 100})(DateTime(2026, 11, 8))).valueOrNull!;
    expect(week.changePct, isNull);
  });

  test('activities filter', () async {
    final repo = _FakeRepo()
      ..items = [
        ActivityItem(id: 'g', type: ActivityType.gym, day: 'd', startedAt: DateTime(2026), title: 'G', kcal: 1),
        ActivityItem(id: 'r', type: ActivityType.run, day: 'd', startedAt: DateTime(2026), title: 'R', kcal: 1),
      ];
    expect((await GetActivities(repo)('a', 'b', filter: ActivityFilter.run)).valueOrNull!.map((a) => a.id), ['r']);
    expect((await GetActivities(repo)('a', 'b')).valueOrNull, hasLength(2));
  });
}

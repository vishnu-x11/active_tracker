import 'package:active_tracker/features/activity/presentation/states/activity_state.dart';
import 'package:active_tracker/features/activity/presentation/states/activity_view.dart';
import 'package:active_tracker/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 5);
  ActivityItem gym(String day, int kcal, int h, {int minutes = 120}) => ActivityItem(
    id: 'g$day$h',
    type: ActivityType.gym,
    day: day,
    startedAt: DateTime.parse(day).add(Duration(hours: h)),
    title: 'Gym',
    kcal: kcal,
    durationMin: minutes,
    intensity: 'moderate',
  );
  ActivityItem run(String day, int kcal, int h, double km) => ActivityItem(
    id: 'r$day$h',
    type: ActivityType.run,
    day: day,
    startedAt: DateTime.parse(day).add(Duration(hours: h)),
    title: 'Run',
    kcal: kcal,
    distanceM: (km * 1000).round(),
    movingSec: 1800,
  );
  final items = [
    gym('2026-11-05', 712, 18),
    run('2026-11-05', 405, 6, 5.2),
    gym('2026-11-04', 588, 18, minutes: 110),
    run('2026-11-04', 405, 6, 5.2),
    gym('2026-11-02', 655, 19, minutes: 115),
    run('2026-11-01', 312, 7, 4.0),
  ];

  ActivityView view(ActivityState s, [DateTime? selected]) =>
      ActivityView.from(items: items, state: s, selected: selected ?? today, today: today);

  test('all days: grouped by day newest first with day totals; tiles for this week', () {
    final v = view(const ActivityState());
    expect(v.groups.map((g) => g.label), ['Today · Thu, 5 Nov', 'Wed, 4 Nov', 'Mon, 2 Nov', 'Sun, 1 Nov']);
    expect(v.groups.map((g) => g.totalKcal), [1117, 993, 655, 312]);
    expect(v.tiles.map((t) => t.value), ['3', '2', '2,765']);
  });

  test('filters change the tiles', () {
    expect(view(const ActivityState(filter: ActivityFilter.run)).tiles.map((t) => t.value), ['2', '10.4', '810']);
    expect(view(const ActivityState(filter: ActivityFilter.gym)).tiles.map((t) => t.value), ['3', '5h 45m', '1,955']);
    expect(
      view(
        const ActivityState(filter: ActivityFilter.gym),
      ).groups.expand((g) => g.items).every((a) => a.type == ActivityType.gym),
      isTrue,
    );
  });

  test('a picked day shows only that day', () {
    final v = view(const ActivityState(allDays: false), DateTime(2026, 11, 4));
    expect(v.groups.single.label, 'Wed, 4 Nov');
    expect(v.tiles.map((t) => t.value), ['1', '5.2', '993']);
  });

  test('empty texts', () {
    expect(view(const ActivityState(allDays: false), DateTime(2026, 11, 3)).emptyTitle, 'Nothing logged this day');
    expect(view(const ActivityState(allDays: false), DateTime(2026, 11, 9)).emptyTitle, 'This day is still ahead');
  });
}

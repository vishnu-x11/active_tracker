import '../../../../core/dates.dart';
import '../../../profile/domain/entities/profile.dart';
import '../entities/activity_item.dart';
import '../entities/daily_targets.dart';
import '../entities/day_totals.dart';
import '../entities/goal.dart';

enum DailyGoal { burn, water, protein }

abstract final class ProgressRules {
  static List<DailyGoal> missed({
    required String day,
    required DayTotals? totals,
    required Profile profile,
    required String today,
    required String? firstLogDay,
  }) {
    if (firstLogDay == null || day.compareTo(today) >= 0 || day.compareTo(firstLogDay) < 0) return const [];
    final t = totals ?? DayTotals(day: day);
    final target = DailyTargets.forDay(profile, workoutDay: t.isWorkoutDay);
    return [
      if (t.burnKcal < target.burnKcal) DailyGoal.burn,
      if (t.waterMl < target.waterMl) DailyGoal.water,
      if (t.proteinG < target.proteinG) DailyGoal.protein,
    ];
  }

  static ({int current, int best}) streak(Set<String> activeDays, DateTime today) {
    var current = 0;
    var d = activeDays.contains(dayKey(today)) ? today : addDays(today, -1);
    while (activeDays.contains(dayKey(d))) {
      current++;
      d = addDays(d, -1);
    }
    final sorted = activeDays.toList()..sort();
    var best = 0, run = 0;
    String? prev;
    for (final k in sorted) {
      run = prev != null && dayKey(addDays(DateTime.parse(prev), 1)) == k ? run + 1 : 1;
      if (run > best) best = run;
      prev = k;
    }
    return (current: current, best: best < current ? current : best);
  }

  static List<({String name, String description, bool earned, String progress})> achievements(List<ActivityItem> runs) {
    final r = runs.where((a) => a.type == ActivityType.run).toList();
    final longest = r.fold(0.0, (m, a) => a.km > m ? a.km : m);
    final total = r.fold(0.0, (m, a) => m + a.km);
    final byMonth = <String, int>{};
    for (final a in r) {
      byMonth.update(a.day.substring(0, 7), (v) => v + 1, ifAbsent: () => 1);
    }
    final bestMonth = byMonth.values.fold(0, (m, v) => v > m ? v : m);
    final early = r.where((a) => a.startedAt.hour < 7).length;
    String km(double v) => v.toStringAsFixed(1);
    return [
      (
        name: '5K Club',
        description: 'Run 5 km in one go',
        earned: longest >= 5,
        progress: 'Best ${km(longest)} / 5 km',
      ),
      (name: '200 km', description: 'Total running distance', earned: total >= 200, progress: '${km(total)} / 200 km'),
      (
        name: 'Consistent',
        description: '10 runs in a month',
        earned: bestMonth >= 10,
        progress: '$bestMonth / 10 runs',
      ),
      (
        name: 'First 10K',
        description: 'Run 10 km in one go',
        earned: longest >= 10,
        progress: 'Best ${km(longest)} / 10 km',
      ),
      (name: 'Early Bird', description: '5 runs before 7 AM', earned: early >= 5, progress: '$early / 5 runs'),
    ];
  }

  static (DateTime, DateTime) goalRange(GoalPeriod period, DateTime today) => period == GoalPeriod.week
      ? (mondayOf(today), addDays(mondayOf(today), 6))
      : (DateTime(today.year, today.month), DateTime(today.year, today.month + 1, 0));

  static double goalDone(Goal goal, Map<String, DayTotals> days, List<ActivityItem> runs, Profile profile) {
    switch (goal.kind) {
      case GoalKind.gymSessions:
        return days.values.fold(0, (a, t) => a + t.gymCount);
      case GoalKind.runDistance:
        return runs.where((a) => a.type == ActivityType.run).fold(0.0, (a, r) => a + r.km);
      case GoalKind.activeBurn:
        return days.values.fold(0, (a, t) => a + t.burnKcal);
      case GoalKind.proteinDays:
        return days.values
            .where((t) => t.proteinG >= DailyTargets.forDay(profile, workoutDay: t.isWorkoutDay).proteinG)
            .length
            .toDouble();
      case GoalKind.waterDays:
        return days.values
            .where((t) => t.waterMl >= DailyTargets.forDay(profile, workoutDay: t.isWorkoutDay).waterMl)
            .length
            .toDouble();
    }
  }

  static double? parseTarget(GoalKind kind, String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null) return null;
    final rounded = kind.decimals ? (v * 10).round() / 10 : v.roundToDouble();
    return rounded > 0 ? rounded : null;
  }

  static double stepTarget(GoalKind kind, double current, int dir) {
    final s = kind.step;
    final next = dir > 0 ? ((current / s).floor() + 1) * s : ((current / s).ceil() - 1) * s;
    return next < s ? s.toDouble() : next.toDouble();
  }
}

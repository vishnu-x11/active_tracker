import '../../../../core/dates.dart';
import '../entities/activity_item.dart';

typedef LogDay = ({DateTime date, int minutes, bool run, bool gym, bool today, bool future});
typedef LogWeek = ({DateTime monday, int minutes, List<LogDay> days});

enum TrendMetric { distance, time, burn }

abstract final class TrainingLog {
  static int minutes(ActivityItem a) =>
      a.type == ActivityType.run ? ((a.movingSec ?? 0) / 60).round() : a.durationMin ?? 0;

  static List<LogWeek> weeks(List<ActivityItem> items, DateTime today, int count, ActivityFilter filter) {
    final byDay = <String, List<ActivityItem>>{};
    for (final a in items) {
      if (filter.allows(a.type)) byDay.putIfAbsent(a.day, () => []).add(a);
    }
    final todayKey = dayKey(today);
    final thisMonday = mondayOf(today);
    return [
      for (var w = 0; w < count; w++)
        () {
          final monday = addDays(thisMonday, -7 * w);
          final days = <LogDay>[
            for (var i = 0; i < 7; i++)
              () {
                final d = addDays(monday, i);
                final list = byDay[dayKey(d)] ?? const <ActivityItem>[];
                return (
                  date: d,
                  minutes: list.fold(0, (a, x) => a + minutes(x)),
                  run: list.any((x) => x.type == ActivityType.run),
                  gym: list.any((x) => x.type == ActivityType.gym),
                  today: dayKey(d) == todayKey,
                  future: d.isAfter(today),
                );
              }(),
          ];
          return (monday: monday, minutes: days.fold(0, (a, d) => a + d.minutes), days: days);
        }(),
    ];
  }

  static int dotStep(int minutes) => minutes <= 0
      ? 0
      : minutes < 30
      ? 1
      : minutes < 60
      ? 2
      : 3;

  static String hm(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';

  static String clock(int minutes) => '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  static List<double> trend(List<ActivityItem> items, DateTime today, int weeks, TrendMetric metric) {
    final first = addDays(mondayOf(today), -7 * (weeks - 1));
    final out = List<double>.filled(weeks, 0);
    for (final a in items) {
      final d = DateTime.parse(a.day);
      if (d.isBefore(first) || d.isAfter(today)) continue;
      final i = mondayOf(d).difference(first).inDays ~/ 7;
      if (i < 0 || i >= weeks) continue;
      out[i] += switch (metric) {
        TrendMetric.distance => a.type == ActivityType.run ? a.km : 0,
        TrendMetric.time => minutes(a).toDouble(),
        TrendMetric.burn => a.kcal.toDouble(),
      };
    }
    return out;
  }

  static int runMinutes(List<ActivityItem> items, DateTime from, DateTime before) => items
      .where((a) => a.type == ActivityType.run)
      .where((a) => !DateTime.parse(a.day).isBefore(from) && DateTime.parse(a.day).isBefore(before))
      .fold(0, (s, a) => s + minutes(a));

  static int suggestWeeklyMinutes(List<ActivityItem> items, DateTime today) {
    final monday = mondayOf(today);
    final average = runMinutes(items, addDays(monday, -28), monday) / 4;
    final target = (average * 1.1 / 15).round() * 15;
    return target < 60 ? 60 : target;
  }
}

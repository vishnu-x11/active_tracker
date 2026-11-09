import '../../../../core/dates.dart';
import '../../../progress/progress.dart';
import 'activity_state.dart';

enum TileKind { gym, run, distance, time, burn }

class TileData {
  const TileData(this.kind, this.value, this.label, {this.unit = ''});

  final TileKind kind;
  final String value;
  final String unit;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is TileData && other.kind == kind && other.value == value && other.unit == unit && other.label == label;

  @override
  int get hashCode => Object.hash(kind, value, unit, label);
}

class ActivityGroup {
  const ActivityGroup({required this.day, required this.label, required this.totalKcal, required this.items});

  final String day;
  final String label;
  final int totalKcal;
  final List<ActivityItem> items;
}

class ActivityView {
  const ActivityView({required this.tiles, required this.groups, required this.emptyTitle, required this.emptyHint});

  final List<TileData> tiles;
  final List<ActivityGroup> groups;
  final String emptyTitle;
  final String emptyHint;

  static DateTime rangeStart(DateTime today) => DateTime(today.year, today.month - 1);

  static DateTime rangeEnd(DateTime today) => DateTime(today.year, today.month + 1, 0);

  static String dayLabel(String day, DateTime today) {
    final d = DateTime.parse(day);
    return day == dayKey(today) ? 'Today · ${shortDate(d)}' : shortDate(d);
  }

  static String hoursMinutes(int minutes) => '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  factory ActivityView.from({
    required List<ActivityItem> items,
    required ActivityState state,
    required DateTime selected,
    required DateTime today,
  }) {
    final selectedKey = dayKey(selected);
    int kcal(Iterable<ActivityItem> xs) => xs.fold(0, (a, x) => a + x.kcal);
    double km(Iterable<ActivityItem> xs) => xs.fold(0.0, (a, x) => a + x.km);
    Iterable<ActivityItem> ofType(Iterable<ActivityItem> xs, ActivityType t) => xs.where((x) => x.type == t);

    final List<TileData> tiles;
    if (!state.allDays) {
      final day = items.where((x) => x.day == selectedKey);
      tiles = [
        TileData(TileKind.gym, '${ofType(day, ActivityType.gym).length}', 'Gym sessions'),
        TileData(TileKind.distance, km(ofType(day, ActivityType.run)).toStringAsFixed(1), 'Run distance', unit: 'km'),
        TileData(TileKind.burn, _thousands(kcal(day)), 'kcal burned'),
      ];
    } else {
      final monday = dayKey(mondayOf(today));
      final week = items.where((x) => x.day.compareTo(monday) >= 0);
      final runs = ofType(week, ActivityType.run), gyms = ofType(week, ActivityType.gym);
      tiles = switch (state.filter) {
        ActivityFilter.run => [
          TileData(TileKind.run, '${runs.length}', 'Runs this week'),
          TileData(TileKind.distance, km(runs).toStringAsFixed(1), 'Distance', unit: 'km'),
          TileData(TileKind.burn, _thousands(kcal(runs)), 'kcal'),
        ],
        ActivityFilter.gym => [
          TileData(TileKind.gym, '${gyms.length}', 'Sessions this week'),
          TileData(TileKind.time, hoursMinutes(gyms.fold(0, (a, x) => a + (x.durationMin ?? 0))), 'Time in gym'),
          TileData(TileKind.burn, _thousands(kcal(gyms)), 'kcal'),
        ],
        ActivityFilter.all => [
          TileData(TileKind.gym, '${gyms.length}', 'Gym this week'),
          TileData(TileKind.run, '${runs.length}', 'Runs this week'),
          TileData(TileKind.burn, _thousands(kcal(week)), 'kcal this week'),
        ],
      };
    }

    final groups = <ActivityGroup>[];
    for (final x in items) {
      if (!state.filter.allows(x.type) || (!state.allDays && x.day != selectedKey)) continue;
      if (groups.isEmpty || groups.last.day != x.day) {
        groups.add(ActivityGroup(day: x.day, label: dayLabel(x.day, today), totalKcal: 0, items: []));
      }
      final g = groups.removeLast();
      groups.add(ActivityGroup(day: g.day, label: g.label, totalKcal: g.totalKcal + x.kcal, items: [...g.items, x]));
    }

    final future = !state.allDays && selected.isAfter(today);
    return ActivityView(
      tiles: tiles,
      groups: groups,
      emptyTitle: state.allDays ? 'No workouts yet' : (future ? 'This day is still ahead' : 'Nothing logged this day'),
      emptyHint: future ? 'Pick today or an earlier day.' : 'Tap + to log a gym session or a run.',
    );
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

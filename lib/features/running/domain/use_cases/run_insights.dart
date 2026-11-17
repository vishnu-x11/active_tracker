import 'dart:math' as math;

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../entities/pace_zones.dart';
import '../entities/run_analysis.dart';
import '../entities/run_settings.dart';
import '../entities/track_point.dart';

enum RaceTarget {
  k5('5K', 5000, 1000),
  k10('10K', 10000, 3000),
  half('Half-Marathon', 21097, 5000),
  full('Marathon', 42195, 5000);

  const RaceTarget(this.label, this.meters, this.minSourceM);
  final String label;
  final int meters;
  final int minSourceM;
}

typedef Prediction = ({double? seconds, int remaining, DateTime from, DateTime to});

abstract final class RacePredictor {
  static const windowDays = 60;
  static const runsNeeded = 5;
  static const exponent = 1.06;

  static double riegel(double seconds, num fromM, num toM) => seconds * math.pow(toM / fromM, exponent);

  static Prediction predict(List<RunAnalysis> runs, RaceTarget target, DateTime asOf) {
    final to = dateOnly(asOf), from = addDays(to, -(windowDays - 1));
    final end = addDays(to, 1);
    final pool = [
      for (final r in runs)
        if (!r.startedAt.isBefore(from) && r.startedAt.isBefore(end) && r.distanceM >= target.minSourceM) r,
    ];
    if (pool.length < runsNeeded) return (seconds: null, remaining: runsNeeded - pool.length, from: from, to: to);
    double? best;
    for (final r in pool) {
      final sources = <(num, double)>[
        for (final e in r.efforts.entries)
          if (e.key >= target.minSourceM) (e.key, e.value.seconds),
        if (r.movingSec > 0) (r.distanceM, r.movingSec.toDouble()),
      ];
      for (final (m, t) in sources) {
        final p = riegel(t, m, target.meters);
        if (best == null || p < best) best = p;
      }
    }
    return (seconds: best, remaining: 0, from: from, to: to);
  }

  static List<double?> series(List<RunAnalysis> runs, RaceTarget target, DateTime from, DateTime to) => [
    for (var d = dateOnly(from); !d.isAfter(to); d = addDays(d, 1)) predict(runs, target, d).seconds,
  ];

  static double? change(List<RunAnalysis> runs, RaceTarget target, DateTime today, {int days = 30}) {
    final now = predict(runs, target, today).seconds, before = predict(runs, target, addDays(today, -days)).seconds;
    return now == null || before == null ? null : now - before;
  }

  static int thresholdPace(List<RunAnalysis> runs, DateTime today) {
    final s = predict(runs, RaceTarget.k10, today).seconds;
    return s == null
        ? PaceZones.defaultThreshold
        : (s / 10).round().clamp(PaceZones.paceRange.min, PaceZones.paceRange.max);
  }
}

abstract final class ZoneReport {
  static List<double> seconds(List<RunAnalysis> runs, PaceZones zones, DateTime from, DateTime to) {
    final out = List<double>.filled(6, 0);
    final start = dateOnly(from), end = addDays(dateOnly(to), 1);
    for (final r in runs) {
      if (r.startedAt.isBefore(start) || !r.startedAt.isBefore(end)) continue;
      r.paceBins.forEach((pace, secs) => out[zones.zoneOf(pace.toDouble()) - 1] += secs);
    }
    return out;
  }

  static List<double> shares(List<double> secs) {
    final total = secs.fold(0.0, (a, b) => a + b);
    return [for (final s in secs) total == 0 ? 0.0 : s / total];
  }

  static int? topZone(List<double> secs) {
    if (secs.every((s) => s == 0)) return null;
    var top = 0;
    for (var i = 1; i < secs.length; i++) {
      if (secs[i] > secs[top]) top = i;
    }
    return top + 1;
  }

  static String? insight(List<double> current, List<double> previous, String period) {
    final top = topZone(current);
    if (top == null) return null;
    final cur = shares(current), prev = shares(previous);
    if (topZone(previous) == null) {
      return 'Most of your running $period was in Zone $top (${PaceZones.names[top - 1]}). ${_tip(top, true)}';
    }
    var zone = 1;
    for (var z = 2; z <= 6; z++) {
      if ((cur[z - 1] - prev[z - 1]).abs() > (cur[zone - 1] - prev[zone - 1]).abs()) zone = z;
    }
    final delta = ((cur[zone - 1] - prev[zone - 1]) * 100).round();
    if (delta == 0) return 'Your time in each zone held steady $period. ${_tip(top, true)}';
    final up = delta > 0;
    return 'Your Zone $zone time ${up ? 'increased' : 'decreased'} by ${delta.abs()}% $period. ${_tip(zone, up)}';
  }

  static String _tip(int zone, bool up) => switch (zone) {
    1 ||
    2 => up ? 'Easy running builds your aerobic base.' : 'Keep most runs easy so you recover between the hard days.',
    3 =>
      up
          ? 'Tempo running builds stamina; balance it with easy days.'
          : 'A steady tempo run now and then builds stamina.',
    4 =>
      up
          ? 'Threshold work lifts the pace you can hold for longer.'
          : 'A threshold session can lift the pace you can hold.',
    _ =>
      up ? 'Hard efforts add up; plan an easy day after them.' : 'Occasional intervals can help sharpen top-end speed.',
  };
}

typedef EffortRank = ({Effort effort, int rank, double seconds, double? delta, int end});

abstract final class EffortRanks {
  static List<EffortRank> forRun(List<RunAnalysis> runs, String runId) {
    final me = runs.where((r) => r.runId == runId).firstOrNull;
    if (me == null) return const [];
    final out = <EffortRank>[];
    for (final e in Effort.values) {
      final mine = me.efforts[e.meters];
      if (mine == null) continue;
      final others = [
        for (final r in runs)
          if (r.runId != runId)
            if (r.efforts[e.meters] case final o?) o.seconds,
      ]..sort();
      final rank = 1 + others.where((t) => t < mine.seconds).length;
      if (rank > 3) continue;
      final delta = others.isEmpty ? null : (rank == 1 ? others.first - mine.seconds : mine.seconds - others.first);
      out.add((effort: e, rank: rank, seconds: mine.seconds, delta: delta, end: mine.end));
    }
    out.sort((a, b) => a.rank != b.rank ? a.rank.compareTo(b.rank) : b.effort.meters.compareTo(a.effort.meters));
    return out;
  }

  static ({double seconds, String runId, DateTime date})? best(List<RunAnalysis> runs, Effort effort) {
    ({double seconds, String runId, DateTime date})? out;
    for (final r in runs) {
      final e = r.efforts[effort.meters];
      if (e != null && (out == null || e.seconds < out.seconds)) {
        out = (seconds: e.seconds, runId: r.runId, date: r.startedAt);
      }
    }
    return out;
  }

  static String ordinal(int rank) => switch (rank) {
    1 => 'Fastest',
    2 => '2nd fastest',
    3 => '3rd fastest',
    _ => '${rank}th fastest',
  };
}

enum SuggestionType {
  recovery('Recovery Run'),
  easy('Easy Run'),
  intervals('Intervals'),
  long('Long Run');

  const SuggestionType(this.label);
  final String label;
}

class SuggestedWorkout {
  const SuggestedWorkout({
    required this.type,
    required this.km,
    required this.paceSec,
    required this.blurb,
    required this.workout,
  });

  final SuggestionType type;
  final double km;
  final int paceSec;
  final String blurb;
  final RunWorkout workout;

  @override
  bool operator ==(Object other) =>
      other is SuggestedWorkout &&
      other.type == type &&
      other.km == km &&
      other.paceSec == paceSec &&
      other.blurb == blurb &&
      other.workout == workout;

  @override
  int get hashCode => Object.hash(type, km, paceSec, blurb, workout);
}

abstract final class WorkoutSuggester {
  static double _half(double km) => (km * 2).round() / 2;

  static List<SuggestedWorkout> suggest(List<RunAnalysis> runs, {required int thresholdSec, required DateTime today}) {
    final day = dateOnly(today), end = addDays(day, 1);
    bool within(RunAnalysis r, int days) => !r.startedAt.isBefore(addDays(day, -days)) && r.startedAt.isBefore(end);
    final last28 = runs.where((r) => within(r, 27)).toList();
    final last7 = runs.where((r) => within(r, 6)).toList();
    final avgKm = last28.isEmpty ? 5.0 : last28.fold(0.0, (a, r) => a + r.km) / last28.length;
    final weeklyKm = last28.fold(0.0, (a, r) => a + r.km) / 4;
    final easyKm = _half(avgKm.clamp(3, 15));
    final recoveryKm = _half(math.max(2, easyKm * 0.7));
    final longKm = _half(math.min(30, math.max(easyKm * 1.4, weeklyKm * 0.25)));
    final workM = avgKm >= 8 ? 800 : 400;
    final t = thresholdSec;
    int pace(double f) => (t * f).round().clamp(RunWorkout.paceRange.min, RunWorkout.paceRange.max);
    final intervals = const RunWorkout().copyWith(kind: WorkoutKind.intervals, reps: 6, workM: workM, restSec: 90);
    final byType = {
      SuggestionType.recovery: SuggestedWorkout(
        type: SuggestionType.recovery,
        km: recoveryKm,
        paceSec: pace(1.30),
        blurb: 'Keep the legs moving today without adding stress. Stay relaxed and conversational.',
        workout: RunWorkout(kind: WorkoutKind.targetPace, targetPaceSec: pace(1.30)),
      ),
      SuggestionType.easy: SuggestedWorkout(
        type: SuggestionType.easy,
        km: easyKm,
        paceSec: pace(1.18),
        blurb: 'Build your aerobic base at a pace you could hold a conversation at.',
        workout: RunWorkout(kind: WorkoutKind.targetPace, targetPaceSec: pace(1.18)),
      ),
      SuggestionType.intervals: SuggestedWorkout(
        type: SuggestionType.intervals,
        km: _half((intervals.reps * workM + 4000) / 1000),
        paceSec: pace(0.93),
        blurb:
            '${intervals.reps} × $workM m at ${formatPace(pace(0.93).toDouble())} /km with ${intervals.restSec} s easy '
            'jogs, after a 10 min warm-up. Sharpens your speed.',
        workout: intervals,
      ),
      SuggestionType.long: SuggestedWorkout(
        type: SuggestionType.long,
        km: longKm,
        paceSec: pace(1.15),
        blurb: 'Your longest run of the week builds endurance. Go slow and steady the whole way.',
        workout: RunWorkout(kind: WorkoutKind.targetPace, targetPaceSec: pace(1.15)),
      ),
    };
    final lastRun = runs
        .where((r) => within(r, 1))
        .fold<RunAnalysis?>(null, (a, r) => a == null || r.startedAt.isAfter(a.startedAt) ? r : a);
    final hard = lastRun != null && ((lastRun.effort ?? 0) >= 4 || lastRun.paceSecPerKm < t * 1.03);
    final hadLong = last7.any((r) => r.km >= longKm * 0.9);
    final hadFast = last7.any((r) => r.efforts[1000] != null && r.efforts[1000]!.seconds < t);
    final first = hard
        ? SuggestionType.recovery
        : !hadLong && day.weekday >= DateTime.friday
        ? SuggestionType.long
        : !hadFast && last7.isNotEmpty
        ? SuggestionType.intervals
        : SuggestionType.easy;
    return [
      byType[first]!,
      for (final t in SuggestionType.values)
        if (t != first) byType[t]!,
    ];
  }
}

import 'package:active_tracker/features/running/domain/entities/pace_zones.dart';
import 'package:active_tracker/features/running/domain/entities/run_analysis.dart';
import 'package:active_tracker/features/running/domain/entities/run_settings.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_insights.dart';
import 'package:active_tracker/features/running/domain/use_cases/track_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gps_test.dart' show track;

RunAnalysis analysis(
  String id,
  DateTime at, {
  int meters = 5000,
  int seconds = 1500,
  Map<int, EffortSpan> efforts = const {},
  Map<int, double> bins = const {},
  int? effort,
}) => RunAnalysis(
  runId: id,
  startedAt: at,
  distanceM: meters,
  movingSec: seconds,
  efforts: efforts,
  paceBins: bins,
  effort: effort,
);

void main() {
  final today = DateTime(2026, 11, 16);

  group('TrackMath', () {
    test('bestSpan finds the fastest stretch and where it ends', () {
      final slow = track(101);
      final fast = track(100, stepS: 2, startT: 300000 + 2000, startLat: 12.9 + 1010 / 111195);
      final span = TrackMath.bestSpan([...slow, ...fast], 1000)!;
      expect(span.seconds, closeTo(200, 1));
      expect(span.end, greaterThan(150));
    });

    test('paceSeconds buckets moving time by rolling pace', () {
      final bins = TrackMath.paceSeconds(track(101));
      expect(bins.keys, [300]);
      expect(bins[300], closeTo(300, 0.1));
    });
  });

  group('RacePredictor', () {
    test('needs five long-enough runs in 60 days', () {
      final runs = [for (var i = 0; i < 4; i++) analysis('r$i', today.subtract(Duration(days: i * 3)))];
      final p = RacePredictor.predict(runs, RaceTarget.k10, today);
      expect(p.seconds, isNull);
      expect(p.remaining, 1);
    });

    test('scales the best effort with Riegel', () {
      final runs = [
        for (var i = 0; i < 5; i++)
          analysis('r$i', today.subtract(Duration(days: i * 3)), efforts: {5000: (seconds: 1500, end: 10)}),
      ];
      final p = RacePredictor.predict(runs, RaceTarget.k10, today);
      expect(p.seconds, closeTo(3127.4, 0.5));
      expect(RacePredictor.thresholdPace(runs, today), 313);
    });

    test('change compares today with 30 days ago', () {
      final old = [for (var i = 0; i < 5; i++) analysis('o$i', today.subtract(Duration(days: 35 + i)), seconds: 1600)];
      final recent = [for (var i = 0; i < 5; i++) analysis('n$i', today.subtract(Duration(days: i)))];
      final change = RacePredictor.change([...old, ...recent], RaceTarget.k5, today)!;
      expect(change, closeTo(-100, 0.5));
    });
  });

  group('PaceZones', () {
    test('auto bounds come from the threshold pace', () {
      const z = PaceZones(thresholdSec: 300);
      expect(z.effective, [267, 284, 309, 345, 390]);
      expect(z.zoneOf(250), 6);
      expect(z.zoneOf(300), 4);
      expect(z.zoneOf(500), 1);
      expect(z.range(6), '<4:27');
      expect(z.range(4), '4:44-5:09');
      expect(z.range(1), '>6:30');
    });

    test('manual bounds must get slower zone by zone', () {
      expect(PaceZones.validate(300, [270, 290, 310, 350, 400]), isNull);
      expect(PaceZones.validate(300, [270, 260, 310, 350, 400]), contains('slower'));
      expect(
        PaceZones.fromMap({
          'auto': false,
          'threshold': 300,
          'bounds': [1, 2],
        }).bounds,
        isEmpty,
      );
    });
  });

  group('ZoneReport', () {
    const zones = PaceZones(thresholdSec: 300);

    test('sums time in each zone inside the range', () {
      final runs = [
        analysis('a', today, bins: {250: 60, 300: 120, 500: 20}),
        analysis('b', today.subtract(const Duration(days: 40)), bins: {300: 999}),
      ];
      final secs = ZoneReport.seconds(runs, zones, today.subtract(const Duration(days: 6)), today);
      expect(secs, [20, 0, 0, 120, 0, 60]);
      expect(ZoneReport.topZone(secs), 4);
    });

    test('the insight names the zone that moved most', () {
      final text = ZoneReport.insight([0, 0, 0, 100, 0, 0], [0, 0, 0, 50, 0, 50], 'this month')!;
      expect(text, startsWith('Your Zone 4 time increased by 50% this month.'));
      final down = ZoneReport.insight([0, 0, 0, 100, 0, 0], [0, 0, 0, 0, 100, 0], 'this month')!;
      expect(down, contains('Zone 4'));
      expect(ZoneReport.insight([0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0], 'x'), isNull);
    });
  });

  group('EffortRanks', () {
    test('ranks a run against all runs and gives the gap', () {
      final runs = [
        analysis('a', today, efforts: {1000: (seconds: 300, end: 5), 400: (seconds: 100, end: 2)}),
        analysis('b', today, efforts: {1000: (seconds: 291, end: 7), 400: (seconds: 110, end: 3)}),
        analysis('c', today, efforts: {1000: (seconds: 310, end: 9)}),
      ];
      final a = EffortRanks.forRun(runs, 'a');
      expect(a.first.effort, Effort.m400);
      expect(a.first.rank, 1);
      expect(a.first.delta, 10);
      expect(a[1].effort, Effort.k1);
      expect(a[1].rank, 2);
      expect(a[1].delta, 9);
      expect(EffortRanks.best(runs, Effort.k1)!.runId, 'b');
    });
  });

  group('WorkoutSuggester', () {
    test('a hard run yesterday makes recovery the pick', () {
      final runs = [analysis('a', today.subtract(const Duration(days: 1)), effort: 5, seconds: 2000)];
      final list = WorkoutSuggester.suggest(runs, thresholdSec: 300, today: today);
      expect(list.first.type, SuggestionType.recovery);
      expect(list.first.paceSec, 390);
      expect(list.map((s) => s.type).toSet(), SuggestionType.values.toSet());
      final intervals = list.firstWhere((s) => s.type == SuggestionType.intervals);
      expect(intervals.workout.kind, WorkoutKind.intervals);
    });

    test('with no runs it suggests an easy run on a weekday', () {
      final list = WorkoutSuggester.suggest(const [], thresholdSec: 360, today: today);
      expect(list.first.type, SuggestionType.easy);
      expect(list.first.km, 5);
    });
  });
}

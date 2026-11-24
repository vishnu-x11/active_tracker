import 'package:active_tracker/features/running/domain/entities/run_analysis.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_breakdown.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_insights.dart';
import 'package:flutter_test/flutter_test.dart';

const _mPerDeg = 111195.0;

List<TrackPoint> _run(List<({double meters, int seconds, double alt})> legs, {int startT = 0}) {
  final pts = <TrackPoint>[TrackPoint(lat: 0, lng: 0, t: startT, alt: legs.first.alt)];
  var m = 0.0, t = startT;
  for (final leg in legs) {
    final steps = leg.seconds;
    for (var i = 1; i <= steps; i++) {
      m += leg.meters / steps;
      t += 1000;
      pts.add(TrackPoint(lat: m / _mPerDeg, lng: 0, t: t, alt: leg.alt));
    }
  }
  return pts;
}

void main() {
  test('splits each whole km with its pace and climb, and keeps the last part as a short split', () {
    final b = RunBreakdown.of(
      _run([
        (meters: 1000, seconds: 300, alt: 10),
        (meters: 1000, seconds: 270, alt: 14),
        (meters: 600, seconds: 150, alt: 14),
      ]),
    );
    expect(b.splits.map((s) => s.km), [1, 1, closeTo(0.6, 0.001)]);
    expect(b.splits.map((s) => s.seconds.round()), [300, 270, 150]);
    expect(b.splits[1].elevationM, greaterThan(2));
    expect(b.splits[2].elevationM, closeTo(0, 0.5));
    expect(b.fastestSplitPace, closeTo(250, 1));
    expect(b.elapsedSec, 720);
    expect(b.minAltM, 10);
    expect(b.maxAltM, 14);
    expect(b.hasElevation, isTrue);
  });

  test('a pause counts towards elapsed time but not towards split or chart pace', () {
    final first = _run([(meters: 1000, seconds: 300, alt: 5)]);
    final second = [
      for (final p in _run([(meters: 1000, seconds: 300, alt: 5)], startT: 420000))
        TrackPoint(lat: p.lat + 1000 / _mPerDeg, lng: 0, t: p.t, alt: p.alt, segment: 1),
    ];
    final b = RunBreakdown.of([...first, ...second]);
    expect(b.elapsedSec, 720);
    expect(b.splits.map((s) => s.seconds.round()), [300, 300]);
    expect(b.pace.every((p) => p.value == null || (p.value! > 295 && p.value! < 305)), isTrue);
  });

  test('a run without altitude has no elevation section', () {
    final pts = [
      for (final p in _run([(meters: 1200, seconds: 360, alt: 0)])) TrackPoint(lat: p.lat, lng: 0, t: p.t),
    ];
    final b = RunBreakdown.of(pts);
    expect(b.hasElevation, isFalse);
    expect(b.splits.every((s) => s.elevationM == null), isTrue);
  });

  test('results list every best effort in the run with its all-time rank', () {
    RunAnalysis run(String id, Map<int, double> efforts) => RunAnalysis(
      runId: id,
      startedAt: DateTime(2026, 11, 20),
      distanceM: 3000,
      movingSec: 900,
      efforts: {for (final e in efforts.entries) e.key: (seconds: e.value, end: 0)},
      paceBins: const {},
    );
    final runs = [
      run('a', {400: 90, 1000: 250}),
      run('b', {400: 80, 1000: 260}),
      run('c', {400: 85, 1000: 240}),
      run('me', {400: 95, 1000: 245}),
    ];
    final results = EffortRanks.results(runs, 'me');
    expect(results.map((r) => (r.effort, r.rank)), [(Effort.k1, 2), (Effort.m400, 4)]);
  });
}

import 'dart:math';

import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/gps_filter.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_replay.dart';
import 'package:active_tracker/features/running/domain/use_cases/track_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gps_test.dart' show track;

const _mPerDegLat = 111195.0;

GpsFix fix(double northM, {double eastM = 0, required int t, double accuracy = 5, double speed = 0, double? alt}) =>
    GpsFix(
      TrackPoint(
        lat: 12.9 + northM / _mPerDegLat,
        lng: 77.6 + eastM / (_mPerDegLat * cos(12.9 * pi / 180)),
        t: t,
        alt: alt,
      ),
      accuracy: accuracy,
      speed: speed,
    );

List<TrackPoint> kept(GpsFilter f, Iterable<GpsFix> fixes) => [
  for (final x in fixes)
    if (f.accept(x) case final r? when r.keep) r.point,
];

void main() {
  group('GpsFilter', () {
    test('a clean straight run keeps its distance', () {
      final f = GpsFilter();
      final pts = kept(f, [for (var i = 0; i <= 100; i++) fix(i * 10, t: i * 3000, accuracy: 0)]);
      expect(pts, hasLength(101));
      expect(TrackMath.distance(pts), closeTo(1000, 1));
    });

    test('jitter while standing still adds almost no distance', () {
      final f = GpsFilter();
      final rnd = Random(7);
      final pts = kept(f, [
        for (var i = 0; i < 120; i++)
          fix(rnd.nextDouble() * 6 - 3, eastM: rnd.nextDouble() * 6 - 3, t: i * 1000, accuracy: 8, speed: 0.2),
      ]);
      expect(TrackMath.distance(pts), lessThan(12));
    });

    test('a noisy run comes out close to the true distance', () {
      final f = GpsFilter();
      final rnd = Random(3);
      final pts = kept(f, [
        for (var i = 0; i <= 300; i++)
          fix(i * 3 + rnd.nextDouble() * 4 - 2, eastM: rnd.nextDouble() * 4 - 2, t: i * 1000, accuracy: 6, speed: 3),
      ]);
      expect(TrackMath.distance(pts), closeTo(900, 45));
    });

    test('inaccurate fixes and impossible jumps are rejected', () {
      final f = GpsFilter();
      expect(f.accept(fix(0, t: 0, accuracy: 40)), isNull);
      expect(f.accept(fix(0, t: 1000))?.keep, isTrue);
      expect(f.accept(fix(10, t: 2000))?.keep, isTrue);
      expect(f.accept(fix(300, t: 3000)), isNull);
      expect(f.accept(fix(20, t: 4000))?.keep, isTrue);
      expect(f.accept(fix(20, t: 4000)), isNull);
      expect(f.accept(fix(500, t: 400000))?.keep, isTrue);
    });

    test('cut lets a new segment start anywhere; altitude is smoothed', () {
      final f = GpsFilter();
      f.accept(fix(0, t: 0, alt: 10));
      f.accept(fix(10, t: 3000, alt: 30));
      f.cut();
      final r = f.accept(fix(5000, t: 4000, alt: 30))!;
      expect(r.keep, isTrue);
      expect(r.point.alt, closeTo(18.75, 0.01));
    });
  });

  group('RunReplay', () {
    test('frames follow moving time with distance and pace', () {
      final r = RunReplay(track(101));
      expect(r.playable, isTrue);
      expect(r.totalMeters, closeTo(1000, 1));
      expect(r.totalSeconds, 300);
      expect(r.duration().inSeconds, 15);
      final start = r.at(0);
      expect(start.meters, 0);
      expect(start.paceSecPerKm, isNull);
      final mid = r.at(0.5);
      expect(mid.meters, closeTo(500, 1));
      expect(mid.seconds, 150);
      expect(mid.paceSecPerKm, closeTo(300, 2));
      expect(mid.lat, closeTo(12.9 + 500 / _mPerDegLat, 1e-6));
      final end = r.at(1);
      expect(end.meters, closeTo(1000, 1));
      expect(end.index, 100);
    });

    test('a pause is skipped, not animated', () {
      final a = track(51);
      final b = track(51, startT: 3600 * 1000, segment: 1, startLat: 13.5);
      final r = RunReplay([...a, ...b]);
      expect(r.totalSeconds, 300);
      final justAfter = r.at(151 / 300);
      expect(justAfter.lat, closeTo(13.5 + 10 / 3 / _mPerDegLat, 1e-6));
      expect(justAfter.meters, closeTo(503.3, 0.5));
    });

    test('a long run is compressed to at most 45 seconds', () {
      expect(RunReplay(track(2001)).duration().inSeconds, 45);
      expect(RunReplay(const []).playable, isFalse);
    });
  });
}

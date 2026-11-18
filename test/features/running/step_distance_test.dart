import 'package:active_tracker/features/running/domain/entities/recording.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/step_distance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stride is learned from GPS metres per step; noise and too few steps are ignored', () {
    final s = StrideModel();
    expect(s.strideM, StrideModel.defaultStrideM);
    s.learn(40, 32);
    expect(s.learned, isFalse);
    s.learn(500, 40);
    s.learn(3, 30);
    s.learn(40, 32);
    expect(s.learned, isTrue);
    expect(s.strideM, closeTo(1.25, 1e-9));
  });

  test('cadence gives steps per second over the recent window and goes quiet when steps stop', () {
    final c = StepCadence();
    c.add(0, 100);
    expect(c.stepsPerSecond(0), isNull);
    c.add(10000, 130);
    expect(c.stepsPerSecond(10000), closeTo(3, 1e-9));
    expect(c.stepsPerSecond(19000), isNull);
  });

  test('a gap counts steps from where GPS was last good; on reconnect the longer estimate wins', () {
    final g = GapDistance();
    g.steps(50);
    expect(g.stepCount, 0);
    g.begin(100);
    g.steps(160);
    expect(g.meters(1.25), 75);
    expect(GapDistance.bridge(stepMeters: 75, straightMeters: 60), 15);
    expect(GapDistance.bridge(stepMeters: 75, straightMeters: 90), 0);
    g.close();
    g.steps(500);
    expect(g.stepCount, 0);
  });

  test('an unfinished recording keeps the distance estimated from steps', () {
    final r = Recording(
      points: const [
        TrackPoint(lat: 12.9, lng: 77.6, t: 0),
        TrackPoint(lat: 12.9 + 100 / 111195, lng: 77.6, t: 30000),
      ],
      segment: 0,
      movingMs: 30000,
      savedAt: DateTime(2026, 11, 18),
      extraM: 80,
    );
    final back = Recording.fromMap(r.toMap());
    expect(back.extraM, 80);
    expect(back.meters, closeTo(180, 0.5));
  });
}

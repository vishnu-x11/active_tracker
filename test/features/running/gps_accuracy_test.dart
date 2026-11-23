import 'dart:math';

import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/gps_filter.dart';
import 'package:active_tracker/features/running/domain/use_cases/track_math.dart';
import 'package:flutter_test/flutter_test.dart';

const _mPerDegLat = 111195.0;
final _mPerDegLng = _mPerDegLat * cos(12.9 * pi / 180);

typedef Sample = ({double x, double y, double heading});

List<Sample> trail({
  required double speed,
  required int seconds,
  required double turnRadius,
  required double straight,
}) {
  final out = <Sample>[];
  var x = 0.0, y = 0.0, h = 0.0, run = 0.0, turning = false, turned = 0.0, dir = 1.0;
  for (var s = 0; s <= seconds; s++) {
    out.add((x: x, y: y, heading: h));
    final d = speed;
    if (!turning) {
      run += d;
      if (run >= straight) {
        turning = true;
        turned = 0;
      }
    } else {
      final dh = d / turnRadius * dir;
      h += dh;
      turned += dh.abs();
      if (turned >= pi) {
        turning = false;
        run = 0;
        dir = -dir;
      }
    }
    x += d * sin(h);
    y += d * cos(h);
  }
  return out;
}

double truthMeters(List<Sample> s) {
  var m = 0.0;
  for (var i = 1; i < s.length; i++) {
    m += sqrt(pow(s[i].x - s[i - 1].x, 2) + pow(s[i].y - s[i - 1].y, 2));
  }
  return m;
}

List<GpsFix> noisy(
  List<Sample> s, {
  required int seed,
  double bias = 4,
  double white = 1.5,
  double accuracy = 12,
  double speed = 3,
  double headingNoise = 4,
}) {
  final r = Random(seed);
  double g() => sqrt(-2 * log(r.nextDouble() + 1e-12)) * cos(2 * pi * r.nextDouble());
  var bx = 0.0, by = 0.0;
  const a = 0.9;
  final k = sqrt(1 - a * a);
  return [
    for (final (i, p) in s.indexed)
      () {
        bx = a * bx + k * bias * g();
        by = a * by + k * bias * g();
        final ex = p.x + bx + white * g();
        final ny = p.y + by + white * g();
        final hd = (p.heading * 180 / pi + headingNoise * g()) % 360;
        return GpsFix(
          TrackPoint(lat: 12.9 + ny / _mPerDegLat, lng: 77.6 + ex / _mPerDegLng, t: i * 1000),
          accuracy: accuracy,
          speed: max(0, speed + 0.15 * g()),
          heading: hd < 0 ? hd + 360 : hd,
        );
      }(),
  ];
}

double filtered(List<GpsFix> fixes, {GpsFilter? filter}) {
  final f = filter ?? GpsFilter();
  final pts = [
    for (final x in fixes)
      if (f.accept(x) case final r? when r.keep) r.point,
  ];
  return TrackMath.distance(pts);
}

double meanError(
  List<Sample> s, {
  double speed = 3,
  double headingNoise = 4,
  double bias = 4,
  double accuracy = 12,
  bool heading = true,
}) {
  final truth = truthMeters(s);
  var sum = 0.0;
  for (var seed = 1; seed <= 4; seed++) {
    final fixes = [
      for (final f in noisy(s, seed: seed, speed: speed, headingNoise: headingNoise, bias: bias, accuracy: accuracy))
        heading ? f : GpsFix(f.point, accuracy: f.accuracy, speed: f.speed),
    ];
    sum += filtered(fixes) / truth - 1;
  }
  return sum / 4;
}

void main() {
  final trails = {
    'tight switchbacks': trail(speed: 3, seconds: 1800, turnRadius: 8, straight: 30),
    'winding trail': trail(speed: 3, seconds: 1800, turnRadius: 15, straight: 60),
    'gentle curves': trail(speed: 3, seconds: 1800, turnRadius: 30, straight: 150),
    'straight road': trail(speed: 3, seconds: 1800, turnRadius: 1e9, straight: 1e9),
  };

  for (final MapEntry(key: name, value: s) in trails.entries) {
    test('$name: distance within 2% of the truth', () {
      expect(meanError(s).abs(), lessThan(0.02));
    });

    test('$name: still within 3.5% with poor GPS under trees', () {
      expect(meanError(s, headingNoise: 12, bias: 6, accuracy: 15).abs(), lessThan(0.035));
    });
  }

  test('slow jog on a winding trail stays within 2%', () {
    expect(meanError(trail(speed: 1.5, seconds: 1800, turnRadius: 15, straight: 60), speed: 1.5).abs(), lessThan(0.02));
  });

  test('without heading data a small loop is no longer cut short', () {
    final loop = trail(speed: 2.7, seconds: 2000, turnRadius: 12, straight: 85);
    expect(meanError(loop, speed: 2.7, heading: false).abs(), lessThan(0.05));
  });

  for (final MapEntry(key: name, value: s) in trails.entries) {
    test('$name without heading data stays within 5%', () {
      expect(meanError(s, heading: false).abs(), lessThan(0.05));
    });
  }
}

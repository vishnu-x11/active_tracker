import 'dart:math' as math;

import '../entities/track_point.dart';
import 'track_math.dart';

typedef RunSplit = ({double km, double seconds, double? elevationM});

typedef ProfilePoint = ({double km, double? value});

class RunBreakdown {
  const RunBreakdown({
    required this.splits,
    required this.pace,
    required this.elevation,
    required this.elapsedSec,
    required this.minAltM,
    required this.maxAltM,
  });

  static const empty = RunBreakdown(splits: [], pace: [], elevation: [], elapsedSec: 0, minAltM: null, maxAltM: null);

  static const profileSteps = 160;
  static const smoothSteps = 2;
  static const minPaceSec = 120.0;
  static const maxPaceSec = 1200.0;
  static const altWindow = 4;

  final List<RunSplit> splits;
  final List<ProfilePoint> pace;
  final List<ProfilePoint> elevation;
  final int elapsedSec;
  final double? minAltM;
  final double? maxAltM;

  bool get hasElevation => minAltM != null && maxAltM != null && elevation.length >= 2;

  double? get fastestSplitPace {
    double? best;
    for (final s in splits) {
      if (s.km <= 0 || s.seconds <= 0) continue;
      final pace = s.seconds / s.km;
      if (best == null || pace < best) best = pace;
    }
    return best;
  }

  static RunBreakdown of(List<TrackPoint> pts) {
    if (pts.length < 2) return empty;
    final d = TrackMath.cumulative(pts), s = TrackMath.movingSeconds(pts);
    final alts = _smoothAlts([for (final p in pts) p.alt]);
    final known = [for (final a in alts) ?a];
    return RunBreakdown(
      splits: _splits(d, s, alts),
      pace: _pace(d, s),
      elevation: known.length < 2 ? const [] : _elevation(d, alts),
      elapsedSec: ((pts.last.t - pts.first.t) / 1000).round(),
      minAltM: known.isEmpty ? null : known.reduce(math.min),
      maxAltM: known.isEmpty ? null : known.reduce(math.max),
    );
  }

  static List<double?> _smoothAlts(List<double?> raw) => [
    for (var i = 0; i < raw.length; i++)
      if (raw[i] == null)
        null
      else
        _mean([for (var j = math.max(0, i - altWindow); j <= math.min(raw.length - 1, i + altWindow); j++) ?raw[j]]),
  ];

  static double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  static double _at(List<double> d, List<double> v, double meters) {
    if (meters <= d.first) return v.first;
    if (meters >= d.last) return v.last;
    var lo = 0, hi = d.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (d[mid] < meters) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = d[hi] - d[lo];
    final f = span == 0 ? 0.0 : (meters - d[lo]) / span;
    return v[lo] + f * (v[hi] - v[lo]);
  }

  static double? _altAt(List<double> d, List<double?> alts, double meters) {
    double? before, after;
    var beforeD = 0.0, afterD = 0.0;
    for (var i = 0; i < d.length; i++) {
      final a = alts[i];
      if (a == null) continue;
      if (d[i] <= meters) {
        before = a;
        beforeD = d[i];
      } else {
        after = a;
        afterD = d[i];
        break;
      }
    }
    if (before == null) return after;
    if (after == null || afterD == beforeD) return before;
    return before + (meters - beforeD) / (afterD - beforeD) * (after - before);
  }

  static List<RunSplit> _splits(List<double> d, List<double> s, List<double?> alts) {
    final total = d.last;
    if (total <= 0) return const [];
    final hasAlt = alts.any((a) => a != null);
    final out = <RunSplit>[];
    var from = 0.0;
    while (from < total) {
      final to = math.min(from + 1000, total);
      if (to - from <= 50 && out.isNotEmpty) break;
      final secs = _at(d, s, to) - _at(d, s, from);
      double? elev;
      if (hasAlt) {
        final a = _altAt(d, alts, from), b = _altAt(d, alts, to);
        if (a != null && b != null) elev = b - a;
      }
      out.add((km: (to - from) / 1000, seconds: secs, elevationM: elev));
      from = to;
    }
    return out;
  }

  static List<ProfilePoint> _pace(List<double> d, List<double> s) {
    final total = d.last;
    if (total < 50) return const [];
    final step = total / profileSteps;
    final raw = <double?>[];
    for (var k = 0; k < profileSteps; k++) {
      final secs = _at(d, s, (k + 1) * step) - _at(d, s, k * step);
      raw.add(secs <= 0 ? null : secs / (step / 1000));
    }
    return [
      for (var k = 0; k < profileSteps; k++)
        (km: (k + 0.5) * step / 1000, value: _smooth(raw, k)?.clamp(minPaceSec, maxPaceSec)),
    ];
  }

  static double? _smooth(List<double?> raw, int k) {
    var secs = 0.0, n = 0;
    for (var j = math.max(0, k - smoothSteps); j <= math.min(raw.length - 1, k + smoothSteps); j++) {
      final v = raw[j];
      if (v == null) continue;
      secs += v;
      n++;
    }
    return n == 0 ? null : secs / n;
  }

  static List<ProfilePoint> _elevation(List<double> d, List<double?> alts) {
    final total = d.last;
    if (total <= 0) return const [];
    final step = total / profileSteps;
    return [for (var k = 0; k <= profileSteps; k++) (km: k * step / 1000, value: _altAt(d, alts, k * step))];
  }
}

import 'dart:math' as math;

import '../entities/track_point.dart';

abstract final class TrackMath {
  static double meters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a.toDouble()));
  }

  static List<double> cumulative(List<TrackPoint> pts) {
    final out = <double>[];
    var total = 0.0;
    for (var i = 0; i < pts.length; i++) {
      if (i > 0 && pts[i].segment == pts[i - 1].segment) {
        total += meters(pts[i - 1].lat, pts[i - 1].lng, pts[i].lat, pts[i].lng);
      }
      out.add(total);
    }
    return out;
  }

  static List<double> movingSeconds(List<TrackPoint> pts) {
    final out = <double>[];
    var total = 0.0;
    for (var i = 0; i < pts.length; i++) {
      if (i > 0 && pts[i].segment == pts[i - 1].segment) total += (pts[i].t - pts[i - 1].t) / 1000;
      out.add(total);
    }
    return out;
  }

  static double distance(List<TrackPoint> pts) => pts.isEmpty ? 0 : cumulative(pts).last;

  static int elevationGain(List<TrackPoint> pts, {double threshold = 3}) {
    var gain = 0.0;
    double? low;
    for (final p in pts) {
      final a = p.alt;
      if (a == null) continue;
      if (low == null || a < low) {
        low = a;
      } else if (a - low >= threshold) {
        gain += a - low;
        low = a;
      }
    }
    return gain.round();
  }

  static List<({double km, double seconds})> splits(List<TrackPoint> pts) {
    if (pts.length < 2) return const [];
    final d = cumulative(pts), s = movingSeconds(pts);
    final out = <({double km, double seconds})>[];
    var lastTime = 0.0;
    var mark = 1000.0;
    for (var i = 1; i < pts.length; i++) {
      while (d[i] >= mark && d[i] > d[i - 1]) {
        final f = (mark - d[i - 1]) / (d[i] - d[i - 1]);
        final t = s[i - 1] + f * (s[i] - s[i - 1]);
        out.add((km: 1, seconds: t - lastTime));
        lastTime = t;
        mark += 1000;
      }
    }
    final rest = d.last - (mark - 1000);
    if (rest > 50) out.add((km: rest / 1000, seconds: s.last - lastTime));
    return out;
  }

  static double? bestEffort(List<TrackPoint> pts, int meters) => bestSpan(pts, meters)?.seconds;

  static ({double seconds, int end})? bestSpan(
    List<TrackPoint> pts,
    int meters, {
    List<double>? cumulativeM,
    List<double>? movingS,
  }) {
    if (pts.length < 2) return null;
    final d = cumulativeM ?? cumulative(pts), s = movingS ?? movingSeconds(pts);
    if (d.last < meters) return null;
    double? best;
    var end = 0;
    var j = 0;
    for (var i = 1; i < pts.length; i++) {
      final need = d[i] - meters;
      if (need < 0) continue;
      while (j + 1 < i && d[j + 1] <= need) {
        j++;
      }
      final span = d[j + 1] - d[j];
      final f = span == 0 ? 0.0 : ((need - d[j]) / span).clamp(0.0, 1.0);
      final start = s[j] + f * (s[j + 1] - s[j]);
      final t = s[i] - start;
      if (t > 0 && (best == null || t < best)) {
        best = t;
        end = i;
      }
    }
    return best == null ? null : (seconds: best, end: end);
  }

  static Map<int, double> paceSeconds(List<TrackPoint> pts, {int windowS = 30, int binS = 5}) {
    final out = <int, double>{};
    if (pts.length < 2) return out;
    final d = cumulative(pts);
    var j = 0;
    for (var i = 1; i < pts.length; i++) {
      if (pts[i].segment != pts[i - 1].segment) continue;
      final dt = (pts[i].t - pts[i - 1].t) / 1000;
      if (dt <= 0 || dt > 60) continue;
      if (pts[j].segment != pts[i].segment) j = i - 1;
      while (j + 1 < i && pts[i].t - pts[j + 1].t >= windowS * 1000) {
        j++;
      }
      final dist = d[i] - d[j];
      if (dist < 1) continue;
      final pace = (pts[i].t - pts[j].t) / 1000 / (dist / 1000);
      final key = ((pace / binS).round() * binS).clamp(60, 1800);
      out[key] = (out[key] ?? 0) + dt;
    }
    return out;
  }

  static Map<Effort, double> bestEfforts(List<TrackPoint> pts) => {
    for (final e in Effort.values)
      if (bestEffort(pts, e.meters) case final t?) e: t,
  };
}

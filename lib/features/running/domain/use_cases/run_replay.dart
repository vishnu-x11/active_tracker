import '../entities/track_point.dart';
import 'track_math.dart';

class ReplayFrame {
  const ReplayFrame({
    required this.lat,
    required this.lng,
    required this.meters,
    required this.seconds,
    required this.index,
    this.paceSecPerKm,
    this.altitude,
  });

  final double lat;
  final double lng;
  final double meters;
  final double seconds;
  final int index;
  final double? paceSecPerKm;
  final double? altitude;
}

class RunReplay {
  RunReplay(this.points) : _d = TrackMath.cumulative(points), _s = TrackMath.movingSeconds(points);

  final List<TrackPoint> points;
  final List<double> _d;
  final List<double> _s;

  static const paceWindowSec = 60.0;

  double get totalMeters => _d.isEmpty ? 0 : _d.last;
  double get totalSeconds => _s.isEmpty ? 0 : _s.last;
  bool get playable => points.length >= 2 && totalSeconds > 0;

  Duration duration({double speedUp = 40, int minSec = 15, int maxSec = 45}) =>
      Duration(seconds: (totalSeconds / speedUp).round().clamp(minSec, maxSec));

  int _indexAt(double t) {
    var lo = 0, hi = _s.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_s[mid] < t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  ReplayFrame at(double progress) {
    if (points.isEmpty) return const ReplayFrame(lat: 0, lng: 0, meters: 0, seconds: 0, index: 0);
    final t = progress.clamp(0.0, 1.0) * totalSeconds;
    final i = _indexAt(t);
    if (i == 0) {
      final p = points.first;
      return ReplayFrame(lat: p.lat, lng: p.lng, meters: 0, seconds: 0, index: 0, altitude: p.alt);
    }
    final a = points[i - 1], b = points[i];
    final span = _s[i] - _s[i - 1];
    final f = a.segment != b.segment || span <= 0 ? 1.0 : ((t - _s[i - 1]) / span).clamp(0.0, 1.0);
    final meters = _d[i - 1] + f * (_d[i] - _d[i - 1]);
    final alt = a.alt != null && b.alt != null ? a.alt! + f * (b.alt! - a.alt!) : b.alt ?? a.alt;
    final j = _indexAt(t - paceWindowSec);
    final from = j > 0 && _s[j] > t - paceWindowSec ? j - 1 : j;
    final dM = meters - _d[from], dS = t - _s[from];
    return ReplayFrame(
      lat: a.lat + f * (b.lat - a.lat),
      lng: a.lng + f * (b.lng - a.lng),
      meters: meters,
      seconds: t,
      index: i,
      paceSecPerKm: dM < 20 || dS <= 0 ? null : dS / (dM / 1000),
      altitude: alt,
    );
  }
}

import '../entities/gps_fix.dart';
import '../entities/track_point.dart';
import 'track_math.dart';

class FilteredFix {
  const FilteredFix(this.point, {required this.keep});

  final TrackPoint point;
  final bool keep;
}

class GpsFilter {
  GpsFilter({this.maxAccuracyM = 25, this.maxSpeedMps = 10, this.minStepM = 3, this.processNoiseMps = 6});

  final double maxAccuracyM;
  final double maxSpeedMps;
  final double minStepM;
  final double processNoiseMps;

  static const minReportedSpeed = 0.3;
  static const minProcessNoiseMps = 1.5;
  static const maxProcessNoiseMps = 8.0;
  static const stepPerAccuracy = 0.4;

  double? _lat;
  double? _lng;
  double? _alt;
  double _variance = -1;
  int _t = 0;
  TrackPoint? _last;

  TrackPoint? get last => _last;

  void reset() {
    _variance = -1;
    _lat = null;
    _lng = null;
    _alt = null;
    _last = null;
  }

  void cut() => _last = null;

  void mark(TrackPoint p) => _last = p;

  FilteredFix? accept(GpsFix fix) {
    if (fix.accuracy > maxAccuracyM) return null;
    final p = fix.point;
    final last = _last;
    if (last != null) {
      final dt = (p.t - last.t) / 1000;
      if (dt <= 0) return null;
      if (TrackMath.meters(last.lat, last.lng, p.lat, p.lng) / dt > maxSpeedMps) return null;
    }
    final acc = fix.accuracy;
    if (_variance < 0 || _lat == null || _lng == null) {
      _lat = p.lat;
      _lng = p.lng;
      _variance = acc * acc;
    } else {
      final dt = (p.t - _t) / 1000;
      final q = fix.speed > minReportedSpeed
          ? fix.speed.clamp(minProcessNoiseMps, maxProcessNoiseMps)
          : processNoiseMps;
      if (dt > 0) _variance += dt * q * q;
      final denom = _variance + acc * acc;
      final k = denom == 0 ? 1.0 : _variance / denom;
      _lat = _lat! + k * (p.lat - _lat!);
      _lng = _lng! + k * (p.lng - _lng!);
      _variance = (1 - k) * _variance;
    }
    _t = p.t;
    if (p.alt case final a?) _alt = _alt == null ? a : _alt! + 0.25 * (a - _alt!);
    final out = TrackPoint(lat: _lat!, lng: _lng!, alt: _alt, t: p.t, segment: p.segment);
    final step = acc * stepPerAccuracy > minStepM ? acc * stepPerAccuracy : minStepM;
    final keep = last == null || TrackMath.meters(last.lat, last.lng, out.lat, out.lng) >= step;
    if (keep) _last = out;
    return FilteredFix(out, keep: keep);
  }
}

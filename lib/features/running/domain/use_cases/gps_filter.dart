import 'dart:math' as math;

import '../entities/gps_fix.dart';
import '../entities/track_point.dart';
import 'track_math.dart';

class FilteredFix {
  const FilteredFix(this.point, {required this.keep, this.passed = false});

  final TrackPoint point;
  final bool keep;
  final bool passed;
}

class GpsFilter {
  GpsFilter({
    this.maxAccuracyM = 25,
    this.maxSpeedMps = 10,
    this.minStepM = 3,
    this.processNoiseMps = 6,
    this.velocityNoiseMps = 0.8,
    this.movingStepM = 5,
    this.fallbackAccuracyScale = 0.4,
    this.passAccuracyM = 12,
    this.passJitterM = 2.5,
    this.passStepM = 2,
  });

  final double maxAccuracyM;
  final double maxSpeedMps;
  final double minStepM;
  final double processNoiseMps;
  final double velocityNoiseMps;
  final double movingStepM;
  final double fallbackAccuracyScale;
  final double passAccuracyM;
  final double passJitterM;
  final double passStepM;

  static const minReportedSpeed = 0.3;
  static const minProcessNoiseMps = 1.5;
  static const maxProcessNoiseMps = 8.0;
  static const stepPerAccuracy = 0.4;
  static const headingSpeed = 1.0;
  static const jitterWeight = 0.2;
  static const jitterMinSamples = 3;
  static const jitterMaxGapMs = 3000;
  static const _mPerDegLat = 111195.0;

  double? _lat;
  double? _lng;
  double? _alt;
  double _variance = -1;
  int _t = 0;
  (double, double)? _velocity;
  TrackPoint? _last;
  TrackPoint? _raw1;
  TrackPoint? _raw2;
  double? _jitterSq;
  int _jitterSamples = 0;

  TrackPoint? get last => _last;

  double? get jitterM => _jitterSq == null ? null : math.sqrt(_jitterSq!);

  bool get smooth => _jitterSamples >= jitterMinSamples && (jitterM ?? double.infinity) <= passJitterM;

  void reset() {
    _variance = -1;
    _lat = null;
    _lng = null;
    _alt = null;
    _velocity = null;
    _last = null;
    _raw1 = null;
    _raw2 = null;
    _jitterSq = null;
    _jitterSamples = 0;
  }

  void cut() {
    _last = null;
    _velocity = null;
    _raw1 = null;
    _raw2 = null;
  }

  void mark(TrackPoint p) => _last = p;

  static (double, double)? _velocityOf(GpsFix fix) {
    final h = fix.heading;
    if (h == null || fix.speed < headingSpeed) return null;
    final r = h * math.pi / 180;
    return (fix.speed * math.cos(r), fix.speed * math.sin(r));
  }

  void _trackJitter(TrackPoint p) {
    final a = _raw2, b = _raw1;
    if (b != null && p.t - b.t > jitterMaxGapMs) {
      _raw2 = null;
      _raw1 = p;
      return;
    }
    if (a != null && b != null && b.t > a.t) {
      final r = (p.t - b.t) / (b.t - a.t);
      final e = TrackMath.meters(b.lat + (b.lat - a.lat) * r, b.lng + (b.lng - a.lng) * r, p.lat, p.lng);
      _jitterSq = _jitterSq == null ? e * e : _jitterSq! + jitterWeight * (e * e - _jitterSq!);
      _jitterSamples++;
    }
    _raw2 = b;
    _raw1 = p;
  }

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
    _trackJitter(p);
    final v = _velocityOf(fix);
    final pass = fix.speed >= headingSpeed && acc <= passAccuracyM && smooth;
    if (pass || _variance < 0 || _lat == null || _lng == null) {
      _lat = p.lat;
      _lng = p.lng;
      _variance = acc * acc;
    } else {
      final dt = (p.t - _t) / 1000;
      if (dt > 0) {
        final prev = _velocity;
        if (v != null && prev != null) {
          final north = (v.$1 + prev.$1) / 2 * dt;
          final east = (v.$2 + prev.$2) / 2 * dt;
          _lat = _lat! + north / _mPerDegLat;
          _lng = _lng! + east / (_mPerDegLat * math.cos(_lat! * math.pi / 180));
          _variance += dt * velocityNoiseMps * velocityNoiseMps;
        } else {
          final q = fix.speed > minReportedSpeed
              ? fix.speed.clamp(minProcessNoiseMps, maxProcessNoiseMps)
              : processNoiseMps;
          _variance += dt * q * q;
        }
      }
      final r = v == null && fix.speed >= headingSpeed ? acc * fallbackAccuracyScale : acc;
      final denom = _variance + r * r;
      final k = denom == 0 ? 1.0 : _variance / denom;
      _lat = _lat! + k * (p.lat - _lat!);
      _lng = _lng! + k * (p.lng - _lng!);
      _variance = (1 - k) * _variance;
    }
    _velocity = v;
    _t = p.t;
    if (p.alt case final a?) _alt = _alt == null ? a : _alt! + 0.25 * (a - _alt!);
    final out = TrackPoint(lat: _lat!, lng: _lng!, alt: _alt, t: p.t, segment: p.segment);
    final step = pass ? passStepM : (v != null ? movingStepM : math.max(acc * stepPerAccuracy, minStepM));
    final keep = last == null || TrackMath.meters(last.lat, last.lng, out.lat, out.lng) >= step;
    if (keep) _last = out;
    return FilteredFix(out, keep: keep, passed: pass);
  }
}

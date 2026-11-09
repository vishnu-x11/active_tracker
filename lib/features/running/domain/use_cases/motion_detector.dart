import '../entities/track_point.dart';
import 'track_math.dart';

class MotionDetector {
  MotionDetector({this.moveM = 5, this.stillMs = 8000});

  final double moveM;
  final int stillMs;

  TrackPoint? _anchor;
  int? _lastMoveMs;

  int? get lastMoveMs => _lastMoveMs;

  void reset(int nowMs, [TrackPoint? at]) {
    _anchor = at;
    _lastMoveMs = nowMs;
  }

  bool onFix(TrackPoint p, int nowMs) {
    final a = _anchor;
    if (a == null || TrackMath.meters(a.lat, a.lng, p.lat, p.lng) >= moveM) {
      _anchor = p;
      _lastMoveMs = nowMs;
      return a != null;
    }
    return false;
  }

  bool isStill(int nowMs) => _lastMoveMs != null && nowMs - _lastMoveMs! >= stillMs;
}

import '../entities/track_point.dart';
import 'track_math.dart';

class MotionDetector {
  MotionDetector({this.moveM = 5, this.stillMs = 8000, this.lostMs = 5000, this.movingSpeed = 1.2});

  final double moveM;
  final int stillMs;
  final int lostMs;
  final double movingSpeed;

  TrackPoint? _anchor;
  int? _lastMoveMs;
  int? _lastFixMs;

  int? get lastMoveMs => _lastMoveMs;

  void reset(int nowMs, [TrackPoint? at]) {
    _anchor = at;
    _lastMoveMs = nowMs;
    _lastFixMs = null;
  }

  bool onFix(TrackPoint p, int nowMs, {double speed = 0}) {
    _lastFixMs = nowMs;
    final a = _anchor;
    if (a == null || speed >= movingSpeed || TrackMath.meters(a.lat, a.lng, p.lat, p.lng) >= moveM) {
      _anchor = p;
      _lastMoveMs = nowMs;
      return a != null;
    }
    return false;
  }

  bool isStill(int nowMs) =>
      _lastMoveMs != null && _lastFixMs != null && nowMs - _lastFixMs! <= lostMs && nowMs - _lastMoveMs! >= stillMs;
}

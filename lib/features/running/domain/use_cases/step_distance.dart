class StrideModel {
  StrideModel({this.fallbackM = defaultStrideM});

  static const defaultStrideM = 0.9;
  static const minSteps = 60;
  static const minM = 0.4;
  static const maxM = 2.2;

  final double fallbackM;
  double _meters = 0;
  int _steps = 0;

  bool get learned => _steps >= minSteps;

  double get strideM => learned ? (_meters / _steps).clamp(minM, maxM) : fallbackM;

  void learn(double meters, int steps) {
    if (steps <= 0 || meters <= 0) return;
    final per = meters / steps;
    if (per < minM || per > maxM) return;
    _meters += meters;
    _steps += steps;
  }

  void reset() {
    _meters = 0;
    _steps = 0;
  }
}

class StepCadence {
  StepCadence({this.windowMs = 20000, this.staleMs = 8000});

  final int windowMs;
  final int staleMs;
  final _samples = <(int, int)>[];

  void add(int tMs, int total) {
    _samples.add((tMs, total));
    while (_samples.length > 2 && tMs - _samples.first.$1 > windowMs) {
      _samples.removeAt(0);
    }
  }

  double? stepsPerSecond(int nowMs) {
    if (_samples.length < 2) return null;
    final (t0, s0) = _samples.first;
    final (t1, s1) = _samples.last;
    if (nowMs - t1 > staleMs || t1 <= t0) return null;
    return (s1 - s0) / ((t1 - t0) / 1000);
  }

  void clear() => _samples.clear();
}

class GapDistance {
  bool _open = false;
  int? _from;
  int _last = 0;

  bool get open => _open;

  void begin(int? steps) {
    _open = true;
    _from = steps;
    _last = steps ?? 0;
  }

  void steps(int total) {
    if (!_open) return;
    _from ??= total;
    _last = total;
  }

  int get stepCount => _from == null ? 0 : (_last - _from!).clamp(0, 1 << 30);

  double meters(double strideM) => stepCount * strideM;

  void close() {
    _open = false;
    _from = null;
    _last = 0;
  }

  static double bridge({required double stepMeters, required double straightMeters}) =>
      stepMeters > straightMeters ? stepMeters - straightMeters : 0;
}

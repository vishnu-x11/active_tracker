class SpeedWindow {
  SpeedWindow({this.windowMs = 12000, this.minSamples = 3, this.trim = 0.2});

  final int windowMs;
  final int minSamples;
  final double trim;

  final _samples = <(int, double)>[];

  void add(int atMs, double speed) {
    _samples.add((atMs, speed));
    _drop(atMs);
  }

  void clear() => _samples.clear();

  double? value(int nowMs) {
    _drop(nowMs);
    if (_samples.length < minSamples) return null;
    final sorted = [for (final s in _samples) s.$2]..sort();
    final cut = (sorted.length * trim).floor();
    final kept = sorted.sublist(cut, sorted.length - cut);
    return kept.reduce((a, b) => a + b) / kept.length;
  }

  void _drop(int nowMs) => _samples.removeWhere((s) => nowMs - s.$1 > windowMs);
}

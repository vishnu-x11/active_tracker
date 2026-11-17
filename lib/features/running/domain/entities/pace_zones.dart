import '../../../../core/formulas/formulas.dart';

class PaceZones {
  const PaceZones({this.auto = true, this.thresholdSec = defaultThreshold, this.bounds = const []});

  final bool auto;
  final int thresholdSec;
  final List<int> bounds;

  static const defaultThreshold = 360;
  static const names = ['Recovery', 'Endurance', 'Tempo', 'Threshold', 'VO2 max', 'Anaerobic'];
  static const factors = [0.89, 0.946, 1.03, 1.15, 1.30];
  static const paceRange = (min: 120, max: 1200);

  static List<int> autoBounds(int threshold) => [for (final f in factors) (threshold * f).round()];

  List<int> get effective => auto || bounds.length != factors.length ? autoBounds(thresholdSec) : bounds;

  int zoneOf(double pace) {
    final b = effective;
    for (var i = 0; i < b.length; i++) {
      if (pace < b[i]) return 6 - i;
    }
    return 1;
  }

  String range(int zone) {
    final b = effective;
    if (zone == 6) return '<${formatPace(b[0].toDouble())}';
    if (zone == 1) return '>${formatPace(b[4].toDouble())}';
    return '${formatPace(b[5 - zone].toDouble())}-${formatPace(b[6 - zone].toDouble())}';
  }

  static String? validate(int threshold, List<int> bounds) {
    if (threshold < paceRange.min || threshold > paceRange.max) {
      return 'Threshold pace must be between 2:00 and 20:00 /km.';
    }
    if (bounds.length != factors.length) return 'Every zone needs a boundary.';
    for (var i = 0; i < bounds.length; i++) {
      if (bounds[i] < paceRange.min || bounds[i] > paceRange.max) return 'Paces must be between 2:00 and 20:00 /km.';
      if (i > 0 && bounds[i] <= bounds[i - 1]) return 'Each zone must be slower than the one above it.';
    }
    return null;
  }

  PaceZones copyWith({bool? auto, int? thresholdSec, List<int>? bounds}) => PaceZones(
    auto: auto ?? this.auto,
    thresholdSec: thresholdSec ?? this.thresholdSec,
    bounds: bounds ?? this.bounds,
  );

  Map<String, Object?> toMap() => {'auto': auto, 'threshold': thresholdSec, 'bounds': bounds};

  static PaceZones fromMap(Map<String, Object?> m) {
    final threshold = m['threshold'] is int ? m['threshold']! as int : defaultThreshold;
    final bounds = m['bounds'] is List
        ? [
            for (final v in m['bounds']! as List)
              if (v is int) v,
          ]
        : const <int>[];
    return PaceZones(
      auto: m['auto'] as bool? ?? true,
      thresholdSec: threshold.clamp(paceRange.min, paceRange.max),
      bounds: validate(threshold, bounds) == null ? bounds : const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaceZones &&
      other.auto == auto &&
      other.thresholdSec == thresholdSec &&
      other.bounds.length == bounds.length &&
      Iterable<int>.generate(bounds.length).every((i) => other.bounds[i] == bounds[i]);

  @override
  int get hashCode => Object.hash(auto, thresholdSec, Object.hashAll(bounds));
}

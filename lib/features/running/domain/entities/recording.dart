import 'track_point.dart';
import '../use_cases/track_math.dart';

class Recording {
  const Recording({required this.points, required this.segment, required this.movingMs, required this.savedAt});

  final List<TrackPoint> points;
  final int segment;
  final int movingMs;
  final DateTime savedAt;

  double get meters => TrackMath.distance(points);

  Map<String, Object?> toMap() => {
    'segment': segment,
    'movingMs': movingMs,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'points': [
      for (final p in points) [p.lat, p.lng, p.alt, p.t, p.segment],
    ],
  };

  static Recording fromMap(Map<String, Object?> m) => Recording(
    segment: (m['segment'] as num?)?.toInt() ?? 0,
    movingMs: (m['movingMs'] as num?)?.toInt() ?? 0,
    savedAt: DateTime.fromMillisecondsSinceEpoch((m['savedAt'] as num?)?.toInt() ?? 0),
    points: [
      for (final raw in (m['points'] as List? ?? const []).cast<List<Object?>>())
        TrackPoint(
          lat: (raw[0]! as num).toDouble(),
          lng: (raw[1]! as num).toDouble(),
          alt: (raw[2] as num?)?.toDouble(),
          t: (raw[3]! as num).toInt(),
          segment: (raw[4] as num?)?.toInt() ?? 0,
        ),
    ],
  );
}

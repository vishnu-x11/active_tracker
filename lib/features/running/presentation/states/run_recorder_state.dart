import '../../data/data_sources/location_source.dart';
import '../../domain/entities/run_settings.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/track_math.dart';
import '../../domain/use_cases/voice_cues.dart';

enum RecorderStatus {
  ready,
  recording,
  paused,
  autoPaused;

  bool get stopped => this == paused || this == autoPaused;
}

class RunRecorderState {
  const RunRecorderState({
    this.status = RecorderStatus.ready,
    this.points = const [],
    this.segment = 0,
    this.elapsedMs = 0,
    this.problem,
    this.error,
    this.saving = false,
    this.draftId,
    this.weightKg = 75,
    this.here,
    this.settings = const RunSettings(),
    this.coach,
  });

  final RecorderStatus status;
  final List<TrackPoint> points;

  final int segment;

  final int elapsedMs;
  final LocationProblem? problem;
  final String? error;
  final bool saving;

  final String? draftId;
  final double weightKg;

  final TrackPoint? here;

  final RunSettings settings;
  final CoachView? coach;

  double get meters => TrackMath.distance(points);
  double get km => meters / 1000;
  int get kcal => (1.04 * weightKg * km).floor();

  double? get currentPace {
    final seg = points.where((p) => p.segment == segment).toList();
    if (seg.length < 2) return null;
    final end = seg.last;
    final start = seg.lastWhere((p) => end.t - p.t >= 30000, orElse: () => seg.first);
    final d = TrackMath.distance([start, ...seg.skipWhile((p) => p != start).skip(1)]);
    final s = (end.t - start.t) / 1000;
    return d < 20 || s <= 0 ? null : s / (d / 1000);
  }

  double? get avgPace => km < 0.02 || elapsedMs == 0 ? null : (elapsedMs / 1000) / km;

  RunRecorderState copyWith({
    RecorderStatus? status,
    List<TrackPoint>? points,
    int? segment,
    int? elapsedMs,
    LocationProblem? Function()? problem,
    String? Function()? error,
    bool? saving,
    String? draftId,
    double? weightKg,
    TrackPoint? here,
    RunSettings? settings,
    CoachView? Function()? coach,
  }) => RunRecorderState(
    status: status ?? this.status,
    points: points ?? this.points,
    segment: segment ?? this.segment,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    problem: problem != null ? problem() : this.problem,
    error: error != null ? error() : this.error,
    saving: saving ?? this.saving,
    draftId: draftId ?? this.draftId,
    weightKg: weightKg ?? this.weightKg,
    here: here ?? this.here,
    settings: settings ?? this.settings,
    coach: coach != null ? coach() : this.coach,
  );

  @override
  bool operator ==(Object other) =>
      other is RunRecorderState &&
      other.status == status &&
      identical(other.points, points) &&
      other.segment == segment &&
      other.elapsedMs == elapsedMs &&
      other.problem == problem &&
      other.error == error &&
      other.saving == saving &&
      other.draftId == draftId &&
      other.weightKg == weightKg &&
      other.here == here &&
      other.settings == settings &&
      other.coach == coach;

  @override
  int get hashCode => Object.hash(
    status,
    identityHashCode(points),
    segment,
    elapsedMs,
    problem,
    error,
    saving,
    draftId,
    weightKg,
    here,
    settings,
    coach,
  );
}

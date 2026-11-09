import 'dart:isolate';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../entities/run.dart';
import '../entities/track_point.dart';
import '../repositories/track_repository.dart';
import 'track_math.dart';

class SaveRunDraft {
  const SaveRunDraft(this._repository, {required this.newId});

  final TrackRepository _repository;
  final String Function() newId;

  static const minMeters = 10;

  Future<Result<String>> call({
    required List<TrackPoint> points,
    required double weightKg,
    required String title,
  }) async {
    final meters = TrackMath.distance(points);
    final secs = TrackMath.movingSeconds(points).lastOrNull?.round() ?? 0;
    if (points.length < 2 || meters < minMeters || secs == 0) {
      return const Err(ValidationFailure('Too short to save. Move a little further, then finish.'));
    }
    final start = DateTime.fromMillisecondsSinceEpoch(points.first.t);
    final draft = Run(
      id: newId(),
      day: dayKey(start),
      startedAt: start,
      title: title,
      type: RunType.outdoor,
      source: RunSource.gps,
      distanceM: meters.round(),
      movingSec: secs,
      weightKg: weightKg,
      kcal: runKcal(weightKg: weightKg, km: meters / 1000),
      elevationM: TrackMath.elevationGain(points),
      draft: true,
    );
    return switch (await _repository.saveDraft(draft, points)) {
      Ok() => Ok(draft.id),
      Err(:final failure) => Err(failure),
    };
  }
}

typedef PersonalRecord = ({Effort effort, double seconds, String runId, DateTime date});

class GetPersonalRecords {
  const GetPersonalRecords(this._repository);

  final TrackRepository _repository;

  Future<Result<Map<Effort, PersonalRecord>>> call() async {
    final runs = await _repository.gpsRuns();
    if (runs case Err(:final failure)) return Err(failure);
    final tracks = <(Run, List<TrackPoint>)>[];
    for (final r in runs.valueOrNull!) {
      final pts = await _repository.points(r.id);
      if (pts case Ok(:final value)) tracks.add((r, value));
    }
    final result = await Isolate.run(() {
      final best = <Effort, PersonalRecord>{};
      for (final (run, pts) in tracks) {
        TrackMath.bestEfforts(pts).forEach((e, s) {
          final cur = best[e];
          if (cur == null || s < cur.seconds) best[e] = (effort: e, seconds: s, runId: run.id, date: run.startedAt);
        });
      }
      return best;
    });
    return Ok(result);
  }

  static List<Effort> newIn(String runId, Map<Effort, PersonalRecord> records) => [
    for (final r in records.values)
      if (r.runId == runId) r.effort,
  ];
}

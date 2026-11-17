import 'dart:isolate';

import '../../../../core/result.dart';
import '../entities/pace_zones.dart';
import '../entities/run.dart';
import '../entities/run_analysis.dart';
import '../entities/track_point.dart';
import '../repositories/pace_zones_repository.dart';
import '../repositories/track_repository.dart';
import 'track_math.dart';

abstract final class RunAnalyzer {
  static const version = 1;
  static const distances = [400, 1000, 3000, 5000, 10000, 21097, 42195];

  static TrackAnalysis track(List<TrackPoint> pts) {
    final d = TrackMath.cumulative(pts), s = TrackMath.movingSeconds(pts);
    return TrackAnalysis(
      efforts: {
        for (final m in distances)
          if (TrackMath.bestSpan(pts, m, cumulativeM: d, movingS: s) case final span?) m: span,
      },
      paceBins: TrackMath.paceSeconds(pts),
    );
  }

  static RunAnalysis compose(Run run, TrackAnalysis track) => RunAnalysis(
    runId: run.id,
    startedAt: run.startedAt,
    distanceM: run.distanceM,
    movingSec: run.movingSec,
    effort: run.effort,
    efforts: track.efforts,
    paceBins: track.paceBins,
  );

  static RunAnalysis analyse(Run run, List<TrackPoint> pts) => compose(run, track(pts));
}

class AnalyseRuns {
  const AnalyseRuns(this._repository);

  final TrackRepository _repository;

  Future<Result<List<RunAnalysis>>> call() async {
    final loaded = await _repository.gpsRuns();
    if (loaded case Err(:final failure)) return Err(failure);
    final runs = loaded.valueOrNull!;
    final stored = {...?(await _repository.analyses(RunAnalyzer.version)).valueOrNull};
    final missing = <(String, List<TrackPoint>)>[];
    for (final r in runs) {
      if (stored.containsKey(r.id)) continue;
      final pts = await _repository.points(r.id);
      if (pts case Ok(:final value)) missing.add((r.id, value));
    }
    if (missing.isNotEmpty) {
      final fresh = await Isolate.run(() => {for (final (id, pts) in missing) id: RunAnalyzer.track(pts)});
      await _repository.saveAnalyses(fresh, RunAnalyzer.version);
      stored.addAll(fresh);
    }
    return Ok([
      for (final r in runs)
        if (stored[r.id] case final t?) RunAnalyzer.compose(r, t),
    ]);
  }
}

class GetPaceZones {
  const GetPaceZones(this._repository);
  final PaceZonesRepository _repository;

  Future<Result<PaceZones>> call() => _repository.load();
}

class SavePaceZones {
  const SavePaceZones(this._repository);
  final PaceZonesRepository _repository;

  Future<Result<void>> call(PaceZones zones) {
    if (!zones.auto) {
      if (PaceZones.validate(zones.thresholdSec, zones.bounds) case final message?) {
        return Future.value(Err(ValidationFailure(message)));
      }
    }
    return _repository.save(zones);
  }
}

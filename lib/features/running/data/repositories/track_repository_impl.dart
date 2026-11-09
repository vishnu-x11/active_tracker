import '../../../../core/result.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/track_repository.dart';
import '../data_sources/track_local_data_source.dart';

class TrackRepositoryImpl implements TrackRepository {
  const TrackRepositoryImpl(this._local);

  final TrackLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() call, String message) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(StorageFailure(message, e));
    }
  }

  @override
  Future<Result<void>> saveDraft(Run draft, List<TrackPoint> points) =>
      _guard(() => _local.saveDraft(draft, points), "Couldn't keep the recording. Please try again.");

  @override
  Future<Result<List<TrackPoint>>> points(String runId) =>
      _guard(() => _local.points(runId), "Couldn't load the route.");

  @override
  Future<Result<List<Run>>> gpsRuns() => _guard(_local.gpsRuns, "Couldn't load your runs.");
}

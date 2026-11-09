import '../../../../core/result.dart';
import '../entities/run.dart';
import '../entities/track_point.dart';

abstract interface class TrackRepository {
  Future<Result<void>> saveDraft(Run draft, List<TrackPoint> points);
  Future<Result<List<TrackPoint>>> points(String runId);
  Future<Result<List<Run>>> gpsRuns();
}

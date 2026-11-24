import '../../../../core/result.dart';
import '../entities/run.dart';
import '../entities/run_analysis.dart';
import '../entities/track_point.dart';

abstract interface class TrackRepository {
  Future<Result<void>> saveRecorded(Run run, List<TrackPoint> points);
  Future<Result<List<TrackPoint>>> points(String runId);
  Future<Result<List<Run>>> gpsRuns();
  Future<Result<Map<String, TrackAnalysis>>> analyses(int version);
  Future<Result<void>> saveAnalyses(Map<String, TrackAnalysis> analyses, int version);
}

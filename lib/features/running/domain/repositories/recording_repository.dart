import '../../../../core/result.dart';
import '../entities/raw_fix.dart';
import '../entities/recording.dart';

abstract interface class RecordingRepository {
  Future<Result<Recording?>> load();

  Future<Result<void>> save(Recording recording);

  Future<Result<void>> appendFixes(List<RawFix> fixes);

  Future<Result<void>> clear();
}

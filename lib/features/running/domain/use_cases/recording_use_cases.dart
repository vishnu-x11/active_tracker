import '../../../../core/result.dart';
import '../entities/raw_fix.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class GetUnfinishedRecording {
  const GetUnfinishedRecording(this._repository);
  final RecordingRepository _repository;

  Future<Result<Recording?>> call() async {
    final result = await _repository.load();
    return switch (result) {
      Ok(value: final r?) when r.points.isEmpty => _drop(),
      _ => result,
    };
  }

  Future<Result<Recording?>> _drop() async {
    await _repository.clear();
    return const Ok(null);
  }
}

class SaveRecordingProgress {
  const SaveRecordingProgress(this._repository);
  final RecordingRepository _repository;

  Future<Result<void>> call(Recording recording) => _repository.save(recording);
}

class ClearRecording {
  const ClearRecording(this._repository);
  final RecordingRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}

class AppendRawFixes {
  const AppendRawFixes(this._repository);
  final RecordingRepository _repository;

  Future<Result<void>> call(List<RawFix> fixes) => _repository.appendFixes(fixes);
}

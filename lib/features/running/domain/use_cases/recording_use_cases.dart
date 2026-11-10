import '../../../../core/result.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class GetUnfinishedRecording {
  const GetUnfinishedRecording(this._repository);
  final RecordingRepository _repository;

  static const maxAge = Duration(hours: 24);

  Future<Result<Recording?>> call({required DateTime now}) async {
    final result = await _repository.load();
    return switch (result) {
      Ok(value: final r?) when r.points.isEmpty || now.difference(r.savedAt) > maxAge => _drop(),
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

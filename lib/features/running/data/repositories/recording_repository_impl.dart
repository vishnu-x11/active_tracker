import 'dart:convert';

import '../../../../core/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  const RecordingRepositoryImpl(this._database);

  final AppDatabase _database;

  static const _key = 'run.recording';

  @override
  Future<Result<Recording?>> load() async {
    try {
      final raw = await _database.setting(_key);
      if (raw == null) return const Ok(null);
      return Ok(Recording.fromMap((jsonDecode(raw) as Map).cast<String, Object?>()));
    } catch (e) {
      return Err(StorageFailure("Couldn't read the unfinished run.", e));
    }
  }

  @override
  Future<Result<void>> save(Recording recording) async {
    try {
      await _database.setSetting(_key, jsonEncode(recording.toMap()));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't save the run in progress.", e));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _database.deleteSetting(_key);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't clear the unfinished run.", e));
    }
  }
}

import 'dart:convert';

import '../../../../core/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/raw_fix.dart';
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
  Future<Result<void>> appendFixes(List<RawFix> fixes) async {
    if (fixes.isEmpty) return const Ok(null);
    try {
      await _database.db.transaction((txn) async {
        final top = await txn.rawQuery('SELECT MAX(seq) AS seq FROM ${Tables.runFixes} WHERE run_sync_id = ?', [
          AppDatabase.recordingFixesId,
        ]);
        var seq = ((top.single['seq'] as int?) ?? -1) + 1;
        final batch = txn.batch();
        for (final r in fixes) {
          final f = r.fix;
          batch.insert(Tables.runFixes, {
            'run_sync_id': AppDatabase.recordingFixesId,
            'seq': seq++,
            'at': r.at,
            't': f.point.t,
            'lat': f.point.lat,
            'lng': f.point.lng,
            'alt': f.point.alt,
            'acc': f.accuracy,
            'speed': f.speed,
            'heading': f.heading,
          });
        }
        await batch.commit(noResult: true);
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't log the GPS readings.", e));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _database.db.delete(Tables.runFixes, where: 'run_sync_id = ?', whereArgs: [AppDatabase.recordingFixesId]);
      await _database.deleteSetting(_key);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't clear the unfinished run.", e));
    }
  }
}

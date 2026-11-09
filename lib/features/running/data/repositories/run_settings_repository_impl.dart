import 'dart:convert';

import '../../../../core/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/run_settings.dart';
import '../../domain/repositories/run_settings_repository.dart';

class RunSettingsRepositoryImpl implements RunSettingsRepository {
  const RunSettingsRepositoryImpl(this._database);

  final AppDatabase _database;

  static const _key = 'run.settings';

  @override
  Future<Result<RunSettings>> load() async {
    try {
      final raw = await _database.setting(_key);
      if (raw == null) return const Ok(RunSettings());
      return Ok(RunSettings.fromMap((jsonDecode(raw) as Map).cast<String, Object?>()));
    } catch (e) {
      return const Ok(RunSettings());
    }
  }

  @override
  Future<Result<void>> save(RunSettings settings) async {
    try {
      await _database.setSetting(_key, jsonEncode(settings.toMap()));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't save the run settings.", e));
    }
  }
}

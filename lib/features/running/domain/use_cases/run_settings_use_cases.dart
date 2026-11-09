import '../../../../core/result.dart';
import '../entities/run_settings.dart';
import '../repositories/run_settings_repository.dart';

class GetRunSettings {
  const GetRunSettings(this._repository);
  final RunSettingsRepository _repository;

  Future<Result<RunSettings>> call() => _repository.load();
}

class SaveRunSettings {
  const SaveRunSettings(this._repository);
  final RunSettingsRepository _repository;

  Future<Result<void>> call(RunSettings settings) => _repository.save(settings);
}

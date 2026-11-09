import '../../../../core/result.dart';
import '../entities/run_settings.dart';

abstract interface class RunSettingsRepository {
  Future<Result<RunSettings>> load();

  Future<Result<void>> save(RunSettings settings);
}

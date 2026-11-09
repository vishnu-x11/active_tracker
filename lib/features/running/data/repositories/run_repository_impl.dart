import '../../../../core/result.dart';
import '../../domain/entities/run.dart';
import '../../domain/repositories/run_repository.dart';
import '../data_sources/run_local_data_source.dart';

class RunRepositoryImpl implements RunRepository {
  const RunRepositoryImpl(this._local);

  final RunLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() call, String message) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(StorageFailure(message, e));
    }
  }

  @override
  Future<Result<Run?>> get(String id) => _guard(() => _local.get(id), "Couldn't open this run.");

  @override
  Future<Result<void>> save(Run run) => _guard(() => _local.upsert(run), "Couldn't save the run. Please try again.");

  @override
  Future<Result<void>> delete(String id) => _guard(() => _local.softDelete(id), "Couldn't delete the run.");
}

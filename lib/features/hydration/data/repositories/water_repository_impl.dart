import '../../../../core/result.dart';
import '../../domain/entities/water_entry.dart';
import '../../domain/repositories/water_repository.dart';
import '../data_sources/water_local_data_source.dart';

class WaterRepositoryImpl implements WaterRepository {
  const WaterRepositoryImpl(this._local);

  final WaterLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() call, String message) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(StorageFailure(message, e));
    }
  }

  @override
  Future<Result<void>> add(WaterEntry entry) =>
      _guard(() => _local.insert(entry), "Couldn't add the drink. Try again.");

  @override
  Future<Result<void>> delete(String id) => _guard(() => _local.softDelete(id), "Couldn't remove the drink.");

  @override
  Future<Result<List<WaterEntry>>> entriesFor(String day) =>
      _guard(() => _local.entriesFor(day), "Couldn't load today's drinks.");
}

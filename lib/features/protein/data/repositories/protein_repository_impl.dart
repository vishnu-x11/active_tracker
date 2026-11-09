import '../../../../core/result.dart';
import '../../domain/entities/protein.dart';
import '../../domain/repositories/protein_repository.dart';
import '../data_sources/protein_local_data_source.dart';

class ProteinRepositoryImpl implements ProteinRepository {
  const ProteinRepositoryImpl(this._local);

  final ProteinLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() call, String message) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(StorageFailure(message, e));
    }
  }

  @override
  Future<Result<void>> add(ProteinEntry entry) =>
      _guard(() => _local.insert(entry), "Couldn't log the protein. Try again.");

  @override
  Future<Result<void>> delete(String id) => _guard(() => _local.softDelete(id), "Couldn't remove the entry.");

  @override
  Future<Result<List<ProteinEntry>>> entriesFor(String day) =>
      _guard(() => _local.entriesFor(day), "Couldn't load today's protein.");

  @override
  Future<Result<List<Food>>> foods() => _guard(_local.foods, "Couldn't load your foods.");

  @override
  Future<Result<void>> saveFood(Food food) => _guard(() => _local.insertFood(food), "Couldn't save the food.");
}

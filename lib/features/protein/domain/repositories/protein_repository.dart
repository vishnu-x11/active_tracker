import '../../../../core/result.dart';
import '../entities/protein.dart';

abstract interface class ProteinRepository {
  Future<Result<void>> add(ProteinEntry entry);
  Future<Result<void>> delete(String id);

  Future<Result<List<ProteinEntry>>> entriesFor(String day);

  Future<Result<List<Food>>> foods();
  Future<Result<void>> saveFood(Food food);
}

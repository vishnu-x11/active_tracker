import '../../../../core/result.dart';
import '../entities/water_entry.dart';

abstract interface class WaterRepository {
  Future<Result<void>> add(WaterEntry entry);
  Future<Result<void>> delete(String id);

  Future<Result<List<WaterEntry>>> entriesFor(String day);
}

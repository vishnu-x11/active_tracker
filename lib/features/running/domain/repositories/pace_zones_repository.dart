import '../../../../core/result.dart';
import '../entities/pace_zones.dart';

abstract interface class PaceZonesRepository {
  Future<Result<PaceZones>> load();

  Future<Result<void>> save(PaceZones zones);
}

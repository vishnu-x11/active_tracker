import '../../../../core/result.dart';
import '../entities/run.dart';

abstract interface class RunRepository {
  Future<Result<Run?>> get(String id);

  Future<Result<void>> save(Run run);

  Future<Result<void>> delete(String id);
}

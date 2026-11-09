import '../../../../core/result.dart';
import '../entities/run.dart';
import '../repositories/run_repository.dart';

class GetRun {
  const GetRun(this._repository);
  final RunRepository _repository;

  Future<Result<Run?>> call(String id) => _repository.get(id);
}

class DeleteRun {
  const DeleteRun(this._repository);
  final RunRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

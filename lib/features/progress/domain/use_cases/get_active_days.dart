import '../../../../core/result.dart';
import '../repositories/progress_repository.dart';

class GetActiveDays {
  const GetActiveDays(this._repository);

  final ProgressRepository _repository;

  Future<Result<Set<String>>> call(String from, String to) => _repository.activeDays(from, to);
}

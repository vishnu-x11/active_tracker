import '../../../../core/result.dart';
import '../entities/day_totals.dart';
import '../repositories/progress_repository.dart';

class GetDayTotals {
  const GetDayTotals(this._repository);

  final ProgressRepository _repository;

  Future<Result<DayTotals>> call(String day) => _repository.dayTotals(day);
}

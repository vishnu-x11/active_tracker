import '../../../../core/dates.dart';
import '../../../../core/result.dart';
import '../entities/week_burn.dart';
import '../repositories/progress_repository.dart';

class GetWeekBurn {
  const GetWeekBurn(this._repository);

  final ProgressRepository _repository;

  Future<Result<WeekBurn>> call(DateTime day) async {
    final monday = mondayOf(day);
    final previousMonday = addDays(monday, -7);
    final sunday = addDays(monday, 6);
    final result = await _repository.burnByDay(dayKey(previousMonday), dayKey(sunday));
    return switch (result) {
      Ok(value: final byDay) => Ok(
        WeekBurn(
          monday: dayKey(monday),
          days: [for (var i = 0; i < 7; i++) byDay[dayKey(addDays(monday, i))] ?? 0],
          previousTotal: [
            for (var i = 0; i < 7; i++) byDay[dayKey(addDays(previousMonday, i))] ?? 0,
          ].fold(0, (a, b) => a + b),
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}

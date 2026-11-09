import '../../../../core/dates.dart';
import '../../../../core/result.dart';
import '../entities/water_entry.dart';
import '../repositories/water_repository.dart';

class LogWater {
  const LogWater(this._repository, {required this.newId, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final WaterRepository _repository;
  final String Function() newId;
  final DateTime Function() _now;

  static const maxMl = 5000;

  static int? toMl(String text, WaterUnit unit) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null) return null;
    return (unit == WaterUnit.l ? v * 1000 : v).round();
  }

  static String? problem(String text, WaterUnit unit) {
    if (text.trim().isEmpty) return 'Enter an amount';
    final ml = toMl(text, unit);
    if (ml == null) return 'Enter a number';
    if (ml < 1) return 'Enter at least 1 ml';
    if (ml > maxMl) return 'One entry can be at most 5 L';
    return null;
  }

  Future<Result<WaterEntry>> call(String text, WaterUnit unit) async {
    final issue = problem(text, unit);
    if (issue != null) return Err(ValidationFailure(issue));
    final now = _now();
    final entry = WaterEntry(id: newId(), day: dayKey(now), at: now, ml: toMl(text, unit)!);
    return switch (await _repository.add(entry)) {
      Ok() => Ok(entry),
      Err(:final failure) => Err(failure),
    };
  }
}

class DeleteWater {
  const DeleteWater(this._repository);
  final WaterRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

class GetWaterDay {
  const GetWaterDay(this._repository);
  final WaterRepository _repository;

  Future<Result<List<WaterEntry>>> call(String day) => _repository.entriesFor(day);
}

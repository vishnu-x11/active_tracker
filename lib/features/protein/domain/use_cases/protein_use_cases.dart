import '../../../../core/dates.dart';
import '../../../../core/result.dart';
import '../entities/protein.dart';
import '../repositories/protein_repository.dart';

class LogProtein {
  const LogProtein(this._repository, {required this.newId, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final ProteinRepository _repository;
  final String Function() newId;
  final DateTime Function() _now;

  static const maxGrams = 200.0;

  static double? grams(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  static String? problem({
    required String gramsText,
    required String food,
    required bool saveFood,
    DateTime? at,
    DateTime? now,
  }) {
    final g = grams(gramsText);
    if (gramsText.trim().isEmpty) return 'Enter the grams of protein';
    if (g == null || g < 0.1) return 'Enter at least 0.1 g';
    if (g > maxGrams) return 'One entry can be at most 200 g';
    if (saveFood && food.trim().isEmpty) return 'Name the food to save it';
    if (at != null && now != null && at.isAfter(now)) return "The time can't be in the future";
    return null;
  }

  Future<Result<ProteinEntry>> call({
    required String gramsText,
    String food = '',
    DateTime? at,
    bool saveFood = false,
  }) async {
    final now = _now();
    final when = at ?? now;
    final issue = problem(gramsText: gramsText, food: food, saveFood: saveFood, at: when, now: now);
    if (issue != null) return Err(ValidationFailure(issue));
    final g = (grams(gramsText)! * 10).round() / 10;
    final name = food.trim();
    final entry = ProteinEntry(id: newId(), day: dayKey(when), at: when, grams: g, food: name.isEmpty ? null : name);
    if (saveFood) {
      final saved = await _repository.saveFood(Food(id: newId(), name: name, serving: 'custom', grams: g));
      if (saved case Err(:final failure)) return Err(failure);
    }
    return switch (await _repository.add(entry)) {
      Ok() => Ok(entry),
      Err(:final failure) => Err(failure),
    };
  }
}

class DeleteProtein {
  const DeleteProtein(this._repository);
  final ProteinRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

class GetProteinDay {
  const GetProteinDay(this._repository);
  final ProteinRepository _repository;

  Future<Result<List<ProteinEntry>>> call(String day) => _repository.entriesFor(day);
}

class GetFoods {
  const GetFoods(this._repository);
  final ProteinRepository _repository;

  Future<Result<List<Food>>> call() async => switch (await _repository.foods()) {
    Ok(:final value) => Ok([
      ...value,
      ...Food.starters.where((s) => !value.any((f) => f.name.toLowerCase() == s.name.toLowerCase())),
    ]),
    Err(:final failure) => Err(failure),
  };
}

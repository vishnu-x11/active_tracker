import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../entities/exercise.dart';
import '../entities/gym_session.dart';
import '../entities/muscle_groups.dart';
import '../repositories/gym_repository.dart';

class SaveGymSession {
  const SaveGymSession(this._repository, {required this.newId, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final GymRepository _repository;
  final String Function() newId;
  final DateTime Function() _now;

  static const maxMinutes = 600;

  static int estimate({
    required GymIntensity intensity,
    required List<String> groups,
    required double weightKg,
    required int minutes,
  }) => groups.isEmpty
      ? 0
      : gymKcal(
          intensity: intensity,
          groups: groups,
          weightKg: weightKg,
          duration: Duration(minutes: minutes),
        );

  static String? problem({
    required List<String> groups,
    required int minutes,
    required DateTime startedAt,
    required DateTime now,
    List<ExerciseLog> exercises = const [],
  }) {
    if (exercises.any((e) => e.sets.any((s) => s.reps != 0 && !s.valid))) {
      return 'Check your sets: 1-100 reps and up to 1000 kg';
    }
    if (groups.isEmpty) return 'Pick at least one muscle group';
    if (minutes <= 0) return 'Enter how long you trained';
    if (minutes > maxMinutes) return 'A session can be at most 10 hours';
    if (startedAt.isAfter(now)) return "The start time can't be in the future";
    return null;
  }

  Future<Result<GymSession>> call({
    String? id,
    required DateTime startedAt,
    required int minutes,
    required List<String> groups,
    required GymIntensity intensity,
    required double weightKg,
    List<ExerciseLog> exercises = const [],
  }) async {
    final kept = [
      for (final e in exercises)
        if (e.sets.where((s) => s.reps != 0).toList() case final sets when sets.isNotEmpty) e.copyWith(sets: sets),
    ];
    groups = {...groups, ...kept.map((e) => e.group)}.toList();
    final issue = problem(groups: groups, minutes: minutes, startedAt: startedAt, now: _now(), exercises: kept);
    if (issue != null) return Err(ValidationFailure(issue));
    final session = GymSession(
      id: id ?? newId(),
      day: dayKey(startedAt),
      startedAt: startedAt,
      title: MuscleGroups.title(groups),
      durationMin: minutes,
      intensity: intensity,
      muscleGroups: List.unmodifiable(groups),
      weightKg: weightKg,
      kcal: estimate(intensity: intensity, groups: groups, weightKg: weightKg, minutes: minutes),
      exercises: List.unmodifiable(kept),
    );
    return switch (await _repository.save(session)) {
      Ok() => Ok(session),
      Err(:final failure) => Err(failure),
    };
  }
}

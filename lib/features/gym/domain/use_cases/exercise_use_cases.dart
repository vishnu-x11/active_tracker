import '../../../../core/result.dart';
import '../entities/exercise.dart';
import '../repositories/gym_repository.dart';

class GetExerciseHistory {
  const GetExerciseHistory(this._repository);
  final GymRepository _repository;

  Future<Result<Map<String, ExerciseHistory>>> call({String? excludeId}) async {
    final result = await _repository.withExercises();
    if (result case Err(:final failure)) return Err(failure);
    final sessions = [...result.valueOrNull!.where((s) => s.id != excludeId)]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final out = <String, ExerciseHistory>{};
    for (final s in sessions) {
      for (final e in s.exercises) {
        if (e.sets.isEmpty) continue;
        final cur = out[e.key];
        out[e.key] = cur == null
            ? ExerciseHistory(lastSets: e.sets, lastDate: s.startedAt, best1rm: e.best1rm)
            : ExerciseHistory(
                lastSets: cur.lastSets,
                lastDate: cur.lastDate,
                best1rm: e.best1rm > cur.best1rm ? e.best1rm : cur.best1rm,
              );
      }
    }
    return Ok(out);
  }
}

class GetRoutines {
  const GetRoutines(this._repository);
  final GymRepository _repository;

  Future<Result<List<Routine>>> call() => _repository.routines();
}

class SaveRoutine {
  const SaveRoutine(this._repository, {required this.newId});
  final GymRepository _repository;
  final String Function() newId;

  Future<Result<Routine>> call(String name, List<ExerciseLog> exercises, {required List<Routine> existing}) async {
    final n = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return const Err(ValidationFailure('Give the routine a name'));
    if (n.length > Routine.maxNameLength) return const Err(ValidationFailure('Keep it under 30 characters'));
    if (exercises.isEmpty) return const Err(ValidationFailure('Add at least one exercise first'));
    final same = existing.where((r) => r.name.toLowerCase() == n.toLowerCase()).firstOrNull;
    final routine = Routine(
      id: same?.id ?? newId(),
      name: n,
      exercises: [
        for (final e in exercises)
          RoutineExercise(name: e.name, group: e.group, sets: e.sets.isEmpty ? 3 : e.sets.length),
      ],
    );
    return switch (await _repository.saveRoutine(routine)) {
      Ok() => Ok(routine),
      Err(:final failure) => Err(failure),
    };
  }
}

class DeleteRoutine {
  const DeleteRoutine(this._repository);
  final GymRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteRoutine(id);
}

abstract final class StartRoutine {
  static List<ExerciseLog> exercises(Routine routine, Map<String, ExerciseHistory> history) => [
    for (final e in routine.exercises)
      ExerciseLog(
        name: e.name,
        group: e.group,
        sets: [
          for (var i = 0; i < e.sets; i++)
            switch (history[e.name.toLowerCase()]?.lastSets) {
              final last? when last.isNotEmpty => last[i < last.length ? i : last.length - 1].copyWith(done: false),
              _ => const SetEntry(kg: 0, reps: 0),
            },
        ],
      ),
  ];
}

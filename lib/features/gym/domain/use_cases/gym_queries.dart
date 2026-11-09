import '../../../../core/result.dart';
import '../entities/gym_session.dart';
import '../entities/muscle_groups.dart';
import '../repositories/gym_repository.dart';

class GetGymSession {
  const GetGymSession(this._repository);
  final GymRepository _repository;

  Future<Result<GymSession?>> call(String id) => _repository.get(id);
}

class DeleteGymSession {
  const DeleteGymSession(this._repository);
  final GymRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

class GetCustomMuscleGroups {
  const GetCustomMuscleGroups(this._repository);
  final GymRepository _repository;

  Future<Result<List<String>>> call() => _repository.customGroups();
}

class AddCustomMuscleGroup {
  const AddCustomMuscleGroup(this._repository);
  final GymRepository _repository;

  Future<Result<String>> call(String name, {required List<String> existing}) async {
    final n = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return const Err(ValidationFailure('Type a name for the group'));
    if (n.length > MuscleGroups.maxCustomLength) return const Err(ValidationFailure('Keep it under 24 characters'));
    final taken = [...MuscleGroups.builtIn.values, ...existing].any((e) => e.toLowerCase() == n.toLowerCase());
    if (taken) return const Err(ValidationFailure('That group is already in the list'));
    return switch (await _repository.addCustomGroup(n)) {
      Ok() => Ok(n),
      Err(:final failure) => Err(failure),
    };
  }
}

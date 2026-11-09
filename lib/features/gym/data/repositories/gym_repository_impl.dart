import '../../../../core/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/gym_session.dart';
import '../../domain/repositories/gym_repository.dart';
import '../data_sources/gym_local_data_source.dart';

class GymRepositoryImpl implements GymRepository {
  const GymRepositoryImpl(this._local, {required this.newId});

  final GymLocalDataSource _local;
  final String Function() newId;

  Future<Result<T>> _guard<T>(Future<T> Function() call, String message) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(StorageFailure(message, e));
    }
  }

  @override
  Future<Result<GymSession?>> get(String id) => _guard(() => _local.get(id), "Couldn't open this session.");

  @override
  Future<Result<void>> save(GymSession session) =>
      _guard(() => _local.upsert(session), "Couldn't save the session. Please try again.");

  @override
  Future<Result<void>> delete(String id) => _guard(() => _local.softDelete(id), "Couldn't delete the session.");

  @override
  Future<Result<List<String>>> customGroups() => _guard(_local.customGroups, "Couldn't load your groups.");

  @override
  Future<Result<void>> addCustomGroup(String name) =>
      _guard(() => _local.addCustomGroup(newId(), name), "Couldn't add the group.");

  @override
  Future<Result<List<GymSession>>> since(DateTime from) =>
      _guard(() => _local.since(from), "Couldn't load your recent sessions.");

  @override
  Future<Result<List<GymSession>>> withExercises() =>
      _guard(_local.withExercises, "Couldn't load your exercise history.");

  @override
  Future<Result<List<Routine>>> routines() => _guard(_local.routines, "Couldn't load your routines.");

  @override
  Future<Result<void>> saveRoutine(Routine routine) =>
      _guard(() => _local.upsertRoutine(routine), "Couldn't save the routine.");

  @override
  Future<Result<void>> deleteRoutine(String id) =>
      _guard(() => _local.deleteRoutine(id), "Couldn't delete the routine.");
}

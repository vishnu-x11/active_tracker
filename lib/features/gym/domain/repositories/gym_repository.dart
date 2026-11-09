import '../../../../core/result.dart';
import '../entities/exercise.dart';
import '../entities/gym_session.dart';

abstract interface class GymRepository {
  Future<Result<GymSession?>> get(String id);

  Future<Result<void>> save(GymSession session);

  Future<Result<void>> delete(String id);

  Future<Result<List<String>>> customGroups();
  Future<Result<void>> addCustomGroup(String name);

  Future<Result<List<GymSession>>> since(DateTime from);

  Future<Result<List<GymSession>>> withExercises();

  Future<Result<List<Routine>>> routines();
  Future<Result<void>> saveRoutine(Routine routine);
  Future<Result<void>> deleteRoutine(String id);
}

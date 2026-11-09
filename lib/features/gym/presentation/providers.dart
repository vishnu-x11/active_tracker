import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../data/data_sources/gym_local_data_source.dart';
import '../data/repositories/gym_repository_impl.dart';
import '../domain/entities/gym_session.dart';
import '../domain/repositories/gym_repository.dart';
import '../domain/entities/exercise.dart';
import '../domain/use_cases/exercise_use_cases.dart';
import '../domain/use_cases/gym_queries.dart';
import '../domain/use_cases/muscle_recovery.dart';
import '../domain/use_cases/save_gym_session.dart';

final gymLocalDataSourceProvider = Provider<GymLocalDataSource>(
  (ref) => GymLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);

final gymRepositoryProvider = Provider<GymRepository>(
  (ref) => GymRepositoryImpl(ref.watch(gymLocalDataSourceProvider), newId: ref.watch(newIdProvider)),
);

final saveGymSessionProvider = Provider(
  (ref) => SaveGymSession(ref.watch(gymRepositoryProvider), newId: ref.watch(newIdProvider)),
);
final getGymSessionProvider = Provider((ref) => GetGymSession(ref.watch(gymRepositoryProvider)));
final deleteGymSessionProvider = Provider((ref) => DeleteGymSession(ref.watch(gymRepositoryProvider)));
final getCustomMuscleGroupsProvider = Provider((ref) => GetCustomMuscleGroups(ref.watch(gymRepositoryProvider)));
final addCustomMuscleGroupProvider = Provider((ref) => AddCustomMuscleGroup(ref.watch(gymRepositoryProvider)));

final gymSessionProvider = FutureProvider.autoDispose.family<GymSession?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getGymSessionProvider)(id)).valueOrThrow();
});

final getExerciseHistoryProvider = Provider((ref) => GetExerciseHistory(ref.watch(gymRepositoryProvider)));
final getRoutinesProvider = Provider((ref) => GetRoutines(ref.watch(gymRepositoryProvider)));
final saveRoutineProvider = Provider(
  (ref) => SaveRoutine(ref.watch(gymRepositoryProvider), newId: ref.watch(newIdProvider)),
);
final deleteRoutineProvider = Provider((ref) => DeleteRoutine(ref.watch(gymRepositoryProvider)));
final getMuscleRecoveryProvider = Provider((ref) => GetMuscleRecovery(ref.watch(gymRepositoryProvider)));

final routinesProvider = FutureProvider.autoDispose<List<Routine>>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getRoutinesProvider)()).valueOrThrow();
});

final muscleRecoveryProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getMuscleRecoveryProvider)()).valueOrThrow();
});

final gymClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../data/data_sources/location_source.dart';
import '../data/data_sources/step_source.dart';
import '../data/data_sources/run_local_data_source.dart';
import '../data/data_sources/speaker.dart';
import '../data/data_sources/track_local_data_source.dart';
import '../data/repositories/pace_zones_repository_impl.dart';
import '../data/repositories/track_repository_impl.dart';
import '../data/repositories/run_repository_impl.dart';
import '../data/repositories/recording_repository_impl.dart';
import '../data/repositories/run_settings_repository_impl.dart';
import '../domain/entities/pace_zones.dart';
import '../domain/entities/run.dart';
import '../domain/entities/run_analysis.dart';
import '../domain/entities/track_point.dart';
import '../domain/repositories/run_repository.dart';
import '../domain/repositories/recording_repository.dart';
import '../domain/repositories/pace_zones_repository.dart';
import '../domain/repositories/run_settings_repository.dart';
import '../domain/repositories/track_repository.dart';
import '../domain/use_cases/analyse_runs.dart';
import '../domain/use_cases/gps_use_cases.dart';
import '../domain/use_cases/run_insights.dart';
import '../domain/use_cases/run_queries.dart';
import '../domain/use_cases/recording_use_cases.dart';
import '../domain/use_cases/run_settings_use_cases.dart';
import '../domain/use_cases/save_run.dart';

final runLocalDataSourceProvider = Provider<RunLocalDataSource>(
  (ref) => RunLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);

final runRepositoryProvider = Provider<RunRepository>(
  (ref) => RunRepositoryImpl(ref.watch(runLocalDataSourceProvider)),
);

final saveRunProvider = Provider((ref) => SaveRun(ref.watch(runRepositoryProvider), newId: ref.watch(newIdProvider)));
final getRunProvider = Provider((ref) => GetRun(ref.watch(runRepositoryProvider)));
final deleteRunProvider = Provider((ref) => DeleteRun(ref.watch(runRepositoryProvider)));

final runProvider = FutureProvider.autoDispose.family<Run?, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getRunProvider)(id)).valueOrThrow();
});

final locationSourceProvider = Provider<LocationSource>((ref) => const GeolocatorLocationSource());
final stepSourceProvider = Provider<StepSource>((ref) => const PedometerStepSource());

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepositoryImpl(TrackLocalDataSourceImpl(ref.watch(appDatabaseProvider))),
);

final saveRecordedRunProvider = Provider(
  (ref) => SaveRecordedRun(ref.watch(trackRepositoryProvider), newId: ref.watch(newIdProvider)),
);
final getPersonalRecordsProvider = Provider((ref) => GetPersonalRecords(ref.watch(trackRepositoryProvider)));

final runTrackProvider = FutureProvider.autoDispose.family<List<TrackPoint>, String>((ref, id) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(trackRepositoryProvider).points(id)).valueOrThrow();
});

final personalRecordsProvider = FutureProvider.autoDispose<Map<Effort, PersonalRecord>>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getPersonalRecordsProvider)()).valueOrThrow();
});

final runSettingsRepositoryProvider = Provider<RunSettingsRepository>(
  (ref) => RunSettingsRepositoryImpl(ref.watch(appDatabaseProvider)),
);
final getRunSettingsProvider = Provider((ref) => GetRunSettings(ref.watch(runSettingsRepositoryProvider)));
final saveRunSettingsProvider = Provider((ref) => SaveRunSettings(ref.watch(runSettingsRepositoryProvider)));

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());

final recorderClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(ref.watch(appDatabaseProvider)),
);
final getUnfinishedRecordingProvider = Provider(
  (ref) => GetUnfinishedRecording(ref.watch(recordingRepositoryProvider)),
);
final saveRecordingProgressProvider = Provider((ref) => SaveRecordingProgress(ref.watch(recordingRepositoryProvider)));
final clearRecordingProvider = Provider((ref) => ClearRecording(ref.watch(recordingRepositoryProvider)));
final appendRawFixesProvider = Provider((ref) => AppendRawFixes(ref.watch(recordingRepositoryProvider)));

final analyseRunsProvider = Provider((ref) => AnalyseRuns(ref.watch(trackRepositoryProvider)));

final runAnalysesProvider = FutureProvider.autoDispose<List<RunAnalysis>>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(analyseRunsProvider)()).valueOrThrow();
});

final paceZonesRepositoryProvider = Provider<PaceZonesRepository>((ref) {
  ref.listen(currentUidProvider, (_, _) {});
  return PaceZonesRepositoryImpl(ref.watch(appDatabaseProvider), uid: () => ref.read(currentUidProvider.future));
});
final getPaceZonesProvider = Provider((ref) => GetPaceZones(ref.watch(paceZonesRepositoryProvider)));
final savePaceZonesProvider = Provider((ref) => SavePaceZones(ref.watch(paceZonesRepositoryProvider)));

final savedPaceZonesProvider = FutureProvider.autoDispose<PaceZones>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getPaceZonesProvider)()).valueOrThrow();
});

final paceZonesProvider = FutureProvider.autoDispose<PaceZones>((ref) async {
  final saved = await ref.watch(savedPaceZonesProvider.future);
  if (!saved.auto) return saved;
  final runs = await ref.watch(runAnalysesProvider.future);
  return saved.copyWith(thresholdSec: RacePredictor.thresholdPace(runs, ref.watch(todayProvider)));
});

final suggestedWorkoutsProvider = FutureProvider.autoDispose<List<SuggestedWorkout>>((ref) async {
  final runs = await ref.watch(runAnalysesProvider.future);
  final zones = await ref.watch(paceZonesProvider.future);
  return WorkoutSuggester.suggest(runs, thresholdSec: zones.thresholdSec, today: ref.watch(todayProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../data/data_sources/location_source.dart';
import '../data/data_sources/run_local_data_source.dart';
import '../data/data_sources/speaker.dart';
import '../data/data_sources/track_local_data_source.dart';
import '../data/repositories/track_repository_impl.dart';
import '../data/repositories/run_repository_impl.dart';
import '../data/repositories/run_settings_repository_impl.dart';
import '../domain/entities/run.dart';
import '../domain/entities/track_point.dart';
import '../domain/repositories/run_repository.dart';
import '../domain/repositories/run_settings_repository.dart';
import '../domain/repositories/track_repository.dart';
import '../domain/use_cases/gps_use_cases.dart';
import '../domain/use_cases/run_queries.dart';
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

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepositoryImpl(TrackLocalDataSourceImpl(ref.watch(appDatabaseProvider))),
);

final saveRunDraftProvider = Provider(
  (ref) => SaveRunDraft(ref.watch(trackRepositoryProvider), newId: ref.watch(newIdProvider)),
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

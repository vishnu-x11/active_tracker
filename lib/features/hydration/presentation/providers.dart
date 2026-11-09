import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../data/data_sources/water_local_data_source.dart';
import '../data/repositories/water_repository_impl.dart';
import '../domain/entities/water_entry.dart';
import '../domain/repositories/water_repository.dart';
import '../domain/use_cases/water_use_cases.dart';

final waterLocalDataSourceProvider = Provider<WaterLocalDataSource>(
  (ref) => WaterLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);
final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => WaterRepositoryImpl(ref.watch(waterLocalDataSourceProvider)),
);
final logWaterProvider = Provider(
  (ref) => LogWater(ref.watch(waterRepositoryProvider), newId: ref.watch(newIdProvider)),
);
final deleteWaterProvider = Provider((ref) => DeleteWater(ref.watch(waterRepositoryProvider)));
final getWaterDayProvider = Provider((ref) => GetWaterDay(ref.watch(waterRepositoryProvider)));

final waterDayProvider = FutureProvider.autoDispose.family<List<WaterEntry>, String>((ref, day) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getWaterDayProvider)(day)).valueOrThrow();
});

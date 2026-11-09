import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../data/data_sources/protein_local_data_source.dart';
import '../data/repositories/protein_repository_impl.dart';
import '../domain/entities/protein.dart';
import '../domain/repositories/protein_repository.dart';
import '../domain/use_cases/protein_use_cases.dart';

final proteinLocalDataSourceProvider = Provider<ProteinLocalDataSource>(
  (ref) => ProteinLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);
final proteinRepositoryProvider = Provider<ProteinRepository>(
  (ref) => ProteinRepositoryImpl(ref.watch(proteinLocalDataSourceProvider)),
);
final logProteinProvider = Provider(
  (ref) => LogProtein(ref.watch(proteinRepositoryProvider), newId: ref.watch(newIdProvider)),
);
final deleteProteinProvider = Provider((ref) => DeleteProtein(ref.watch(proteinRepositoryProvider)));
final getProteinDayProvider = Provider((ref) => GetProteinDay(ref.watch(proteinRepositoryProvider)));
final getFoodsProvider = Provider((ref) => GetFoods(ref.watch(proteinRepositoryProvider)));

final proteinDayProvider = FutureProvider.autoDispose.family<List<ProteinEntry>, String>((ref, day) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getProteinDayProvider)(day)).valueOrThrow();
});

final foodsProvider = FutureProvider.autoDispose<List<Food>>((ref) async {
  ref.watch(dataRevisionProvider);
  return (await ref.watch(getFoodsProvider)()).valueOrThrow();
});

import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/running/data/data_sources/track_local_data_source.dart';
import 'package:active_tracker/features/running/data/repositories/pace_zones_repository_impl.dart';
import 'package:active_tracker/features/running/data/repositories/track_repository_impl.dart';
import 'package:active_tracker/features/running/domain/entities/pace_zones.dart';
import 'package:active_tracker/features/running/domain/use_cases/analyse_runs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/seed.dart';
import 'gps_test.dart' show track;

void main() {
  sqfliteFfiInit();
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    for (final t in Tables.all.reversed) {
      await db.db.delete(t);
    }
  });
  tearDown(() => db.close());

  test('run analysis is computed once, stored, then read back without the GPS points', () async {
    await Seed(db).run(DateTime(2026, 11, 10, 7), kcal: 80, km: 1.2, seconds: 360);
    for (final (n, p) in track(121).indexed) {
      await db.db.insert(Tables.runPoints, {'run_sync_id': 'r0', 'seq': n, 'lat': p.lat, 'lng': p.lng, 't': p.t});
    }
    final analyse = AnalyseRuns(TrackRepositoryImpl(TrackLocalDataSourceImpl(db)));
    final first = (await analyse()).valueOrThrow().single;
    expect(first.efforts[1000]!.seconds, closeTo(300, 1));
    expect((await db.db.query(Tables.runAnalysis)).single['version'], RunAnalyzer.version);

    await db.db.delete(Tables.runPoints);
    await db.db.update(Tables.runs, {'effort': 4});
    final second = (await analyse()).valueOrThrow().single;
    expect(second.efforts[1000]!.seconds, first.efforts[1000]!.seconds);
    expect(second.efforts[1000]!.end, first.efforts[1000]!.end);
    expect(second.paceBins, first.paceBins);
    expect(second.effort, 4);

    await db.db.update(Tables.runAnalysis, {'version': 0});
    expect((await analyse()).valueOrThrow().single.efforts, isEmpty);
  });

  test('pace zones live on the profile, sync with it and survive a profile edit', () async {
    final profiles = ProfileLocalDataSourceImpl(db);
    final zones = PaceZonesRepositoryImpl(db, uid: () async => 'u', now: () => 50);
    const custom = PaceZones(auto: false, thresholdSec: 300, bounds: [267, 284, 309, 345, 390]);
    expect((await zones.save(custom)).isOk, isFalse);

    await profiles.upsert('u', const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
    await db.db.update(Tables.profile, {'synced': 1});
    expect((await zones.load()).valueOrThrow(), const PaceZones());
    expect(await zones.save(custom), isA<Ok<void>>());
    final row = (await db.db.query(Tables.profile)).single;
    expect(row['synced'], 0);
    expect(row['updated_at'], 50);

    await profiles.upsert('u', const Profile(weightKg: 74, heightCm: 178, burnTargetKcal: 650));
    expect((await zones.load()).valueOrThrow(), custom);
    expect((await profiles.get('u'))!.weightKg, 74);
  });
}

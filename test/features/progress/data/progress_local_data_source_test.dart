import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/progress/data/data_sources/progress_local_data_source.dart';
import 'package:active_tracker/features/progress/domain/entities/activity_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/seed.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  late Seed seed;
  late ProgressLocalDataSourceImpl source;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    for (final t in [Tables.gymSessions, Tables.runs, Tables.water, Tables.protein]) {
      await db.db.delete(t);
    }
    seed = Seed(db);
    source = ProgressLocalDataSourceImpl(db);
  });

  final thu = DateTime(2026, 11, 5);

  test('day totals: the design example', () async {
    await seed.gym(thu.add(const Duration(hours: 18, minutes: 30)), kcal: 712);
    await seed.run(thu.add(const Duration(hours: 6, minutes: 45)), kcal: 405);
    for (final ml in [500, 500, 250, 500]) {
      await seed.water(thu.add(const Duration(hours: 9)), ml);
    }
    await seed.protein(thu.add(const Duration(hours: 13)), 86);

    final t = await source.dayTotals('2026-11-05');
    expect(t.burnKcal, 1117);
    expect((t.gymCount, t.runCount), (1, 1));
    expect(t.waterMl, 1750);
    expect(t.proteinG, 86);
    expect(t.isWorkoutDay, isTrue);
  });

  test('deleted rows and GPS drafts never count; a run override wins', () async {
    await seed.gym(thu, kcal: 500, deleted: true);
    await seed.run(thu, kcal: 405, draft: true);
    await seed.run(thu, kcal: 405, override: 450);

    final t = await source.dayTotals('2026-11-05');
    expect(t.gymKcal, 0);
    expect(t.runKcal, 450);
    expect(t.runCount, 1);
    expect((await source.activities('2026-11-05', '2026-11-05')).single.kcal, 450);
  });

  test('an empty day is all zeros', () async {
    final t = await source.dayTotals('2026-11-06');
    expect((t.burnKcal, t.waterMl, t.proteinG, t.isWorkoutDay), (0, 0, 0.0, false));
  });

  test('burn by day, active days and activities over a range', () async {
    await seed.run(DateTime(2026, 11, 1, 7, 30), kcal: 312, title: 'Sunday Run');
    await seed.gym(DateTime(2026, 11, 2, 19), kcal: 655, title: 'Legs');
    await seed.gym(DateTime(2026, 11, 4, 18, 15), kcal: 588, title: 'Back + Biceps');
    await seed.run(DateTime(2026, 11, 4, 6, 40), kcal: 405, gps: false);
    await seed.water(DateTime(2026, 11, 3, 9), 500);

    expect(await source.burnByDay('2026-11-01', '2026-11-04'), {
      '2026-11-01': 312,
      '2026-11-02': 655,
      '2026-11-04': 993,
    });
    expect(await source.activeDays('2026-11-02', '2026-11-30'), {'2026-11-02', '2026-11-04'});

    final list = await source.activities('2026-11-01', '2026-11-05');
    expect(list.map((a) => a.title), ['Back + Biceps', 'Morning Run', 'Legs', 'Sunday Run']);
    expect(list[1].type, ActivityType.run);
    expect(list[1].fromGps, isFalse);
    expect(list[0].durationMin, 120);
  });
}

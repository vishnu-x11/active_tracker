import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/running/data/data_sources/run_local_data_source.dart';
import 'package:active_tracker/features/running/data/repositories/run_repository_impl.dart';
import 'package:active_tracker/features/running/domain/entities/run.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_metrics.dart';
import 'package:active_tracker/features/running/domain/use_cases/save_run.dart';
import 'package:active_tracker/features/running/running_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/pump.dart';

void main() {
  sqfliteFfiInit();

  group('any two of three', () {
    test('distance + time give the pace', () => expect(RunMetrics.paceFor('5.20', '29:35'), '5:41'));
    test('pace gives the time', () => expect(RunMetrics.timeForPace('10', '5:30'), '55:00'));
    test('long runs show hours', () => expect(RunMetrics.clock(3725), '1:02:05'));
    test('bad input gives nothing', () {
      expect(RunMetrics.paceFor('0', '29:35'), isNull);
      expect(RunMetrics.paceFor('5', '29:75'), isNull);
    });
  });

  group('SaveRun', () {
    late AppDatabase db;
    late RunRepositoryImpl repo;
    late SaveRun save;
    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      await db.db.delete(Tables.runs);
      repo = RunRepositoryImpl(RunLocalDataSourceImpl(db));
      save = SaveRun(repo, newId: () => 'r1', now: () => DateTime(2026, 11, 6));
    });

    Future<Result<Run>> go({String kcal = '', String km = '5.20', String time = '29:35', String? id}) => save(
      id: id,
      title: 'Morning Run',
      type: RunType.outdoor,
      source: RunSource.manual,
      kmText: km,
      timeText: time,
      startedAt: DateTime(2026, 11, 5, 6, 45),
      weightKg: 75,
      effort: 3,
      kcalText: kcal,
    );

    test('5.2 km at 75 kg is 405 kcal (rounded down)', () async {
      final r = (await go()).valueOrNull!;
      expect((r.kcal, r.kcalOverride, r.kcalShown), (405, null, 405));
      expect((await repo.get('r1')).valueOrNull, r);
    });

    test('a watch value overrides; typing the estimate itself does not', () async {
      expect((await go(kcal: '450')).valueOrNull!.kcalShown, 450);
      expect((await go(kcal: '405')).valueOrNull!.kcalOverride, isNull);
    });

    test('validation', () async {
      String? msg(Result<Run> r) => r is Err<Run> ? r.failure.message : null;
      expect(msg(await go(km: '0')), 'Enter a distance above 0 km');
      expect(msg(await go(time: '')), 'Enter the moving time, e.g. 29:35');
      expect(msg(await go(time: '5:00')), 'That pace is faster than 2:00 /km. Check the distance and time');
      expect(msg(await go(kcal: '0')), 'Calories must be a whole number above 0');
    });

    test('saving again keeps the GPS points (no replace-cascade)', () async {
      await go();
      await db.db.insert(Tables.runPoints, {'run_sync_id': 'r1', 'seq': 0, 'lat': 1.0, 'lng': 2.0, 't': 0});
      await go(id: 'r1', kcal: '420');
      expect(await db.db.query(Tables.runPoints), hasLength(1));
    });
  });

  testWidgets('type distance and time → pace and kcal → save → detail', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 5400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      await db.db.delete(Tables.runs);
      await ProfileLocalDataSourceImpl(db).upsert('u', const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
      return db;
    });
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) =>
              TextButton(onPressed: () => context.push(RunRoutes.newRun), child: const Text('open')),
        ),
        ...RunRoutes.routes(),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          currentUidProvider.overrideWith((ref) => Stream.value('u')),
          newIdProvider.overrideWithValue(() => 'run-1'),
        ],
        child: MaterialApp.router(
          theme: ThemeData(extensions: const [AppPalette.light]),
          routerConfig: router,
        ),
      ),
    );
    await settleWithIo(tester);
    await tester.tap(find.text('open'));
    await settleWithIo(tester);
    expect(find.text('Log run'), findsOneWidget);
    expect(find.text('Going for a run now?'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '5.00'), '5.20');
    await tester.enterText(find.widgetWithText(TextField, 'h:mm:ss'), '29:35');
    await tester.pumpAndSettle();
    expect(find.text('5:41'), findsOneWidget);
    expect(find.text('Save run  ·  405 kcal'), findsOneWidget);

    await tester.tap(find.text('Save run  ·  405 kcal'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('5.20 km'), findsOneWidget);
    expect(find.textContaining('Logged manually'), findsOneWidget);
  });
}

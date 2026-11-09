import 'package:active_tracker/core/formulas/formulas.dart';
import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/gym/data/data_sources/gym_local_data_source.dart';
import 'package:active_tracker/features/gym/data/repositories/gym_repository_impl.dart';
import 'package:active_tracker/features/gym/domain/entities/muscle_groups.dart';
import 'package:active_tracker/features/gym/domain/use_cases/gym_queries.dart';
import 'package:active_tracker/features/gym/domain/use_cases/save_gym_session.dart';
import 'package:active_tracker/features/gym/gym_routes.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/progress/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/pump.dart';

void main() {
  sqfliteFfiInit();

  group('rules', () {
    test('the design example: shoulders + triceps, moderate, 2 h, 75 kg = 712 kcal', () {
      expect(
        SaveGymSession.estimate(
          intensity: GymIntensity.moderate,
          groups: ['shoulders', 'triceps'],
          weightKg: 75,
          minutes: 120,
        ),
        712,
      );
    });

    test('titles', () {
      expect(MuscleGroups.title(['shoulders', 'triceps']), 'Shoulders + Triceps');
      expect(MuscleGroups.title(['chest', 'back', 'legs', 'Glutes']), 'Chest + Back + 2 more');
    });

    test('problems', () {
      final now = DateTime(2026, 11, 5, 20);
      String? p(List<String> g, int m, DateTime s) =>
          SaveGymSession.problem(groups: g, minutes: m, startedAt: s, now: now);
      expect(p([], 60, now), 'Pick at least one muscle group');
      expect(p(['legs'], 0, now), 'Enter how long you trained');
      expect(p(['legs'], 601, now), 'A session can be at most 10 hours');
      expect(p(['legs'], 60, now.add(const Duration(hours: 1))), "The start time can't be in the future");
      expect(p(['legs'], 60, now), isNull);
    });
  });

  group('storage', () {
    late AppDatabase db;
    late GymRepositoryImpl repo;
    var n = 0;
    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      await db.db.delete(Tables.gymSessions);
      await db.db.delete(Tables.presets);
      repo = GymRepositoryImpl(GymLocalDataSourceImpl(db), newId: () => 'id${n++}');
    });

    test('save, read back, then soft delete', () async {
      final save = SaveGymSession(repo, newId: () => 's1', now: () => DateTime(2026, 11, 6));
      final saved = (await save(
        startedAt: DateTime(2026, 11, 5, 18, 30),
        minutes: 120,
        groups: ['shoulders', 'triceps'],
        intensity: GymIntensity.moderate,
        weightKg: 75,
      )).valueOrNull!;
      expect((await repo.get('s1')).valueOrNull, saved);
      expect(saved.day, '2026-11-05');

      await DeleteGymSession(repo)('s1');
      expect((await repo.get('s1')).valueOrNull, isNull);
      final row = (await db.db.query(Tables.gymSessions)).single;
      expect((row['deleted'], row['synced']), (1, 0));
    });

    test('custom groups: added once, case-insensitively unique', () async {
      final add = AddCustomMuscleGroup(repo);
      expect((await add('  Glutes ', existing: [])).valueOrNull, 'Glutes');
      final again = await add('glutes', existing: ['Glutes']);
      expect((again as Err).failure.message, 'That group is already in the list');
      expect((await add('chest', existing: [])) is Err, isTrue);
      expect((await GetCustomMuscleGroups(repo)()).valueOrNull, ['Glutes']);
    });
  });

  testWidgets('log → detail → delete, and Home sees it', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 4200)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      await db.db.delete(Tables.gymSessions);
      await ProfileLocalDataSourceImpl(db).upsert('u', const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
      return db;
    });
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Consumer(
            builder: (context, ref, _) {
              final kcal = ref.watch(dayTotalsProvider(dayKey(DateTime.now())).select((v) => v.value?.burnKcal));
              return Scaffold(
                body: Column(
                  children: [
                    Text('burn ${kcal ?? '-'}'),
                    TextButton(onPressed: () => context.push(GymRoutes.newSession), child: const Text('open')),
                  ],
                ),
              );
            },
          ),
        ),
        ...GymRoutes.routes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          currentUidProvider.overrideWith((ref) => Stream.value('u')),
          newIdProvider.overrideWithValue(() => 'session-1'),
        ],
        child: MaterialApp.router(
          theme: ThemeData(extensions: const [AppPalette.dark]),
          routerConfig: router,
        ),
      ),
    );
    await settleWithIo(tester);
    expect(find.text('burn 0'), findsOneWidget);

    await tester.tap(find.text('open'));
    await settleWithIo(tester);
    expect(find.text('Log gym session'), findsOneWidget);

    await tester.tap(find.text('Save session  ·  0 kcal'));
    await settleWithIo(tester);
    expect(find.text('Pick at least one muscle group'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Shoulders'));
    await tester.tap(find.bySemanticsLabel('Triceps'));
    await tester.tap(find.text('2h'));
    await tester.pumpAndSettle();
    expect(find.text('712 kcal'), findsOneWidget);

    await tester.tap(find.text('Save session  ·  712 kcal'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('Shoulders + Triceps'), findsOneWidget);
    expect(find.text('Muscle split'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('burn 0'), findsOneWidget);
  });
}

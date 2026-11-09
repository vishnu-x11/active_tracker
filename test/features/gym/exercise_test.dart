import 'dart:typed_data';

import 'package:active_tracker/core/formulas/formulas.dart';
import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/share/image_sharer.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/gym/data/data_sources/gym_local_data_source.dart';
import 'package:active_tracker/features/gym/data/repositories/gym_repository_impl.dart';
import 'package:active_tracker/features/gym/domain/entities/exercise.dart';
import 'package:active_tracker/features/gym/domain/entities/gym_session.dart';
import 'package:active_tracker/features/gym/domain/use_cases/exercise_use_cases.dart';
import 'package:active_tracker/features/gym/domain/use_cases/muscle_recovery.dart';
import 'package:active_tracker/features/gym/domain/use_cases/save_gym_session.dart';
import 'package:active_tracker/features/gym/gym_routes.dart';
import 'package:active_tracker/features/gym/presentation/states/gym_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';

GymSession session(
  String id,
  DateTime start, {
  List<String> groups = const ['chest'],
  int minutes = 60,
  GymIntensity intensity = GymIntensity.moderate,
  List<ExerciseLog> exercises = const [],
}) => GymSession(
  id: id,
  day: '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
  startedAt: start,
  title: 'Chest',
  durationMin: minutes,
  intensity: intensity,
  muscleGroups: groups,
  weightKg: 75,
  kcal: 300,
  exercises: exercises,
);

ExerciseLog bench(List<(double, int)> sets) => ExerciseLog(
  name: 'Bench press',
  group: 'chest',
  sets: [for (final (kg, reps) in sets) SetEntry(kg: kg, reps: reps, done: true)],
);

class FakeSharer implements ImageSharer {
  final shared = <(Uint8List, String)>[];

  @override
  Future<void> sharePng(Uint8List bytes, {required String name, String? text}) async => shared.add((bytes, name));
}

void main() {
  sqfliteFfiInit();

  test('estimated 1RM and volume', () {
    expect(const SetEntry(kg: 100, reps: 1).oneRepMax, 100);
    expect(const SetEntry(kg: 90, reps: 5).oneRepMax, 105);
    expect(bench([(60, 8), (60, 8)]).volume, 960);
  });

  group('storage', () {
    late AppDatabase db;
    late GymRepositoryImpl repo;
    var n = 0;
    setUp(() async {
      db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      for (final t in [Tables.gymSessions, Tables.routines]) {
        await db.db.delete(t);
      }
      repo = GymRepositoryImpl(GymLocalDataSourceImpl(db), newId: () => 'id${n++}');
    });

    test('exercises are saved with the session; empty sets are dropped and groups filled in', () async {
      final save = SaveGymSession(repo, newId: () => 's1', now: () => DateTime(2026, 11, 9));
      final saved = (await save(
        startedAt: DateTime(2026, 11, 8, 18),
        minutes: 60,
        groups: const [],
        intensity: GymIntensity.hard,
        weightKg: 75,
        exercises: const [
          ExerciseLog(name: 'Bench press', group: 'chest', sets: [SetEntry(kg: 60, reps: 8), SetEntry(kg: 0, reps: 0)]),
          ExerciseLog(name: 'Plank', group: 'core', sets: [SetEntry(kg: 0, reps: 0)]),
        ],
      )).valueOrNull!;
      expect(saved.muscleGroups, ['chest']);
      expect(saved.exercises.single.sets, const [SetEntry(kg: 60, reps: 8)]);
      final back = (await repo.get('s1')).valueOrNull!;
      expect(back.exercises.single.sets.single.kg, 60);
      expect(back.volume, 480);

      final bad = await save(
        startedAt: DateTime(2026, 11, 8, 18),
        minutes: 60,
        groups: const ['chest'],
        intensity: GymIntensity.hard,
        weightKg: 75,
        exercises: [
          bench([(60, 101)]),
        ],
      );
      expect((bad as Err).failure.message, 'Check your sets: 1-100 reps and up to 1000 kg');
    });

    test('history: last sets come from the newest session, best 1RM from all of them', () async {
      final local = GymLocalDataSourceImpl(db);
      await local.upsert(
        session(
          'old',
          DateTime(2026, 11, 1),
          exercises: [
            bench([(100, 1)]),
          ],
        ),
      );
      await local.upsert(
        session(
          'new',
          DateTime(2026, 11, 5),
          exercises: [
            bench([(80, 5), (80, 4)]),
          ],
        ),
      );
      final h = (await GetExerciseHistory(repo)()).valueOrNull!['bench press']!;
      expect(h.lastSets.map((s) => s.reps), [5, 4]);
      expect(h.best1rm, closeTo(100, 0.01));
      expect(h.lastDate, DateTime(2026, 11, 5));
      final without = (await GetExerciseHistory(repo)(excludeId: 'new')).valueOrNull!['bench press']!;
      expect(without.lastSets.single.kg, 100);
    });

    test('routines: validate, overwrite by name, start with last weights, delete', () async {
      final save = SaveRoutine(repo, newId: () => 'r${n++}');
      expect(((await save(' ', [bench([])], existing: const [])) as Err).failure.message, 'Give the routine a name');
      expect(
        ((await save('Push', const [], existing: const [])) as Err).failure.message,
        'Add at least one exercise first',
      );
      final first = (await save('Push day', [
        bench([(60, 8), (60, 8), (60, 8)]),
      ], existing: const [])).valueOrNull!;
      final again = (await save('push DAY', [bench([])], existing: [first])).valueOrNull!;
      expect(again.id, first.id);
      final all = (await GetRoutines(repo)()).valueOrNull!;
      expect(all.single.exercises.single.sets, 3);

      final started = StartRoutine.exercises(all.single, {
        'bench press': ExerciseHistory(
          lastSets: const [SetEntry(kg: 70, reps: 6, done: true)],
          lastDate: DateTime(2026, 11, 5),
          best1rm: 84,
        ),
      });
      expect(started.single.sets, List.filled(3, const SetEntry(kg: 70, reps: 6)));

      await DeleteRoutine(repo)(first.id);
      expect((await GetRoutines(repo)()).valueOrNull, isEmpty);
    });
  });

  test('a PR is a done set whose 1RM beats every earlier one', () {
    final state = GymFormState(
      day: DateTime(2026, 11, 9),
      startMinute: 600,
      history: {'bench press': ExerciseHistory(lastSets: const [], lastDate: DateTime(2026, 11, 1), best1rm: 100)},
      exercises: [
        bench([(90, 5), (90, 4), (95, 5)]),
      ],
    );
    expect(state.isPr(0, 0), isTrue);
    expect(state.isPr(0, 1), isFalse);
    expect(state.isPr(0, 2), isTrue);
    final noHistory = GymFormState(
      day: DateTime(2026, 11, 9),
      startMinute: 600,
      exercises: [
        bench([(200, 1)]),
      ],
    );
    expect(noHistory.isPr(0, 0), isFalse);
  });

  group('muscle recovery', () {
    final now = DateTime(2026, 11, 9, 20);

    test('hard legs that ended 24 h ago are 37 % recovered', () {
      final r = MuscleRecovery.compute([
        session('a', now.subtract(const Duration(hours: 25)), groups: ['legs'], intensity: GymIntensity.hard),
      ], now);
      expect(r['legs'], 37);
      expect(r['chest'], 100);
    });

    test('full body loads every group; sessions combine; old ones are ignored', () {
      final r = MuscleRecovery.compute([
        session('a', now.subtract(const Duration(hours: 13)), groups: ['full_body']),
        session('b', now.subtract(const Duration(hours: 25)), groups: ['legs'], intensity: GymIntensity.hard),
        session('c', now.subtract(const Duration(days: 5)), groups: ['chest'], intensity: GymIntensity.hard),
      ], now);
      expect(r['chest'], 58);
      expect(r['legs'], 21);
      expect(r.keys, MuscleRecovery.mapped);
    });
  });

  testWidgets('log sets: last time shown, PR flagged, rest timer, saved to the detail', (tester) async {
    await pumpFeature(
      tester,
      routes: GymRoutes.routes,
      initial: GymRoutes.newSession,
      seed: (db) => GymLocalDataSourceImpl(db).upsert(
        session(
          'past',
          DateTime(2026, 11, 1, 18),
          exercises: [
            bench([(60, 8)]),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench press'));
    await settleWithIo(tester);
    expect(find.text('Last time: 60 kg × 8 · 1 sets'), findsOneWidget);
    final kg = find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '60');
    expect(kg, findsOneWidget);
    await tester.enterText(kg, '70');
    await tester.pump();

    await tester.tap(find.byTooltip('Mark set 1 done'));
    await tester.pump();
    expect(find.text('PR'), findsOneWidget);
    expect(find.text('New PR: Bench press 70 kg × 8'), findsOneWidget);
    expect(find.textContaining('Rest 1:'), findsOneWidget);
    await tester.tap(find.text('+15'));
    await tester.pump();
    expect(find.textContaining('Rest 1:4'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(find.textContaining('Rest '), findsNothing);

    await tester.tap(find.text('Add set'));
    await tester.pump();
    expect(find.byTooltip('Mark set 2 done'), findsOneWidget);
    expect(find.text('Volume 1,120 kg'), findsOneWidget);

    await tester.tap(find.textContaining('Save session'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('70 kg × 8'), findsNWidgets(2));
    expect(find.text('Muscle recovery'), findsOneWidget);
  });

  testWidgets('save as routine, then start a new session from it', (tester) async {
    await pumpFeature(tester, routes: GymRoutes.routes, initial: GymRoutes.newSession);
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Zercher squat');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Legs'));
    await settleWithIo(tester);
    expect(find.text('Zercher squat'), findsOneWidget);

    await tester.tap(find.text('Save as routine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Leg day');
    await tester.tap(find.text('Save'));
    await settleWithIo(tester);
    expect(find.text('Saved routine “Leg day”'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Zercher squat'));
    await settleWithIo(tester);
    await tester.tap(find.text('Leg day · 1'));
    await settleWithIo(tester);
    expect(find.text('Zercher squat'), findsOneWidget);
  });

  testWidgets('recovery screen and sharing a session as an image', (tester) async {
    final sharer = FakeSharer();
    await pumpFeature(
      tester,
      routes: GymRoutes.routes,
      initial: GymRoutes.detail('s'),
      overrides: [imageSharerProvider.overrideWithValue(sharer)],
      seed: (db) => GymLocalDataSourceImpl(db).upsert(
        session(
          's',
          DateTime.now().subtract(const Duration(hours: 2)),
          groups: ['back'],
          exercises: [
            const ExerciseLog(name: 'Deadlift', group: 'back', sets: [SetEntry(kg: 140, reps: 5, done: true)]),
          ],
        ),
      ),
    );
    await tester.tap(find.byTooltip('Share session'));
    await tester.pumpAndSettle();
    expect(find.text('Share image'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Share image'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(sharer.shared.single.$2, 'gym-s');
    expect(sharer.shared.single.$1.sublist(1, 4), 'PNG'.codeUnits);

    await tester.tap(find.text('Muscle recovery'));
    await settleWithIo(tester);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Recovering'), findsOneWidget);
    expect(find.text('100%'), findsNWidgets(6));
  });
}

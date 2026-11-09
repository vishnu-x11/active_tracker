import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/sync/remote_store.dart';
import 'package:active_tracker/core/sync/sync_engine.dart';
import 'package:active_tracker/features/gym/data/data_sources/gym_local_data_source.dart';
import 'package:active_tracker/features/gym/domain/entities/exercise.dart';
import 'package:active_tracker/features/gym/domain/entities/gym_session.dart';
import 'package:active_tracker/core/formulas/formulas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/seed.dart';

class FakeRemote implements RemoteStore {
  final docs = <String, Map<String, Map<String, Object?>>>{};

  bool _nested(Object? v) => v is List && v.any((x) => x is List || _nested(x)) || v is Map && v.values.any(_nested);

  @override
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data) async {
    if (data.values.any(_nested)) throw ArgumentError('Invalid data. Nested arrays are not supported');
    (docs['$uid/$collection'] ??= {})[id] = {...data};
  }

  @override
  Future<List<Map<String, Object?>>> changedSince(String uid, String collection, int since) async =>
      ((docs['$uid/$collection'] ?? {}).values.where((d) => (d['updated_at']! as num) > since).toList()
        ..sort((a, b) => (a['updated_at']! as num).compareTo(b['updated_at']! as num)));
}

void main() {
  sqfliteFfiInit();
  var n = 0;
  Future<AppDatabase> device() =>
      AppDatabase.open(path: 'file:dev${n++}?mode=memory&cache=shared', factory: databaseFactoryFfi);

  test('a gym session and a run with its route move from phone A to phone B', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    final s = Seed(a);
    await s.gym(DateTime(2026, 11, 5, 18), kcal: 712);
    await s.run(DateTime(2026, 11, 5, 6), kcal: 405);
    final runId = (await a.db.query(Tables.runs)).single['sync_id']! as String;
    await a.db.insert(Tables.runPoints, {'run_sync_id': runId, 'seq': 0, 'lat': 1.0, 'lng': 2.0, 't': 5, 'segment': 0});
    await s.run(DateTime(2026, 11, 5, 7), kcal: 100, draft: true);

    final pushed = await SyncEngine(a, remote).sync('u1');
    expect(pushed.pushed, 2);
    expect((await a.db.query(Tables.gymSessions)).single['synced'], 1);

    final pulled = await SyncEngine(b, remote).sync('u1');
    expect(pulled.pulled, 2);
    expect((await b.db.query(Tables.gymSessions)).single['kcal'], 712);
    expect((await b.db.query(Tables.runPoints)).single['lat'], 1.0);
  });

  test('logged sets and routines reach the second phone', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    final local = GymLocalDataSourceImpl(a, now: () => 3000);
    await local.upsert(
      GymSession(
        id: 'g1',
        day: '2026-11-08',
        startedAt: DateTime(2026, 11, 8, 18),
        title: 'Chest',
        durationMin: 60,
        intensity: GymIntensity.hard,
        muscleGroups: const ['chest'],
        weightKg: 75,
        kcal: 400,
        exercises: const [
          ExerciseLog(name: 'Bench press', group: 'chest', sets: [SetEntry(kg: 80, reps: 5, done: true)]),
        ],
      ),
    );
    await local.upsertRoutine(
      const Routine(
        id: 'r1',
        name: 'Push day',
        exercises: [RoutineExercise(name: 'Bench press', group: 'chest', sets: 3)],
      ),
    );
    expect((await SyncEngine(a, remote).sync('u1')).pushed, 2);
    expect((await SyncEngine(b, remote).sync('u1')).pulled, 2);
    final fromB = GymLocalDataSourceImpl(b);
    expect((await fromB.get('g1'))!.exercises.single.sets.single.kg, 80);
    expect((await fromB.routines()).single.name, 'Push day');
  });

  test('a delete travels as a tombstone; a newer local edit is not overwritten', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await Seed(a).water(DateTime(2026, 11, 5, 9), 500);
    await SyncEngine(a, remote).sync('u1');
    await SyncEngine(b, remote).sync('u1');

    await a.db.update(Tables.water, {'deleted': 1, 'synced': 0, 'updated_at': 5000});
    await SyncEngine(a, remote).sync('u1');
    await SyncEngine(b, remote).sync('u1');
    expect((await b.db.query(Tables.water)).single['deleted'], 1);

    await b.db.update(Tables.water, {'ml': 750, 'deleted': 0, 'synced': 0, 'updated_at': 6000});
    await SyncEngine(b, remote).sync('u1');
    expect((await b.db.query(Tables.water)).single['ml'], 750);
    await SyncEngine(a, remote).sync('u1');
    expect((await a.db.query(Tables.water)).single['ml'], 750);
  });

  test("another account signing in never receives the first account's logs", () async {
    final remote = FakeRemote();
    final a = await device();
    await Seed(a).protein(DateTime(2026, 11, 5, 13), 30);
    await SyncEngine(a, remote).sync('first');
    await SyncEngine(a, remote).sync('second');
    expect(await a.db.query(Tables.protein), isEmpty);
    expect(remote.docs['second/${Tables.protein}'], isNull);
    await SyncEngine(a, remote).sync('first');
    expect((await a.db.query(Tables.protein)).single['grams'], 30);
  });

  test('a new phone gets the existing profile back instead of onboarding again', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await a.db.insert(Tables.profile, {
      'uid': 'u1',
      'weight_kg': 80.0,
      'height_cm': 180.0,
      'burn_target_kcal': 700,
      'updated_at': 5,
      'deleted': 0,
      'synced': 0,
    });
    await SyncEngine(a, remote).sync('u1');
    expect(await SyncEngine(b, remote).restoreProfile('u1'), isTrue);
    expect((await b.db.query(Tables.profile)).single['burn_target_kcal'], 700);
    expect(await SyncEngine(b, remote).restoreProfile('nobody'), isFalse);
  });

  test('one row that cannot be pushed does not stop the others', () async {
    final remote = _Flaky();
    final a = await device();
    final s = Seed(a);
    await s.water(DateTime(2026, 11, 5, 9), 500);
    await s.protein(DateTime(2026, 11, 5, 13), 30);
    await expectLater(SyncEngine(a, remote).sync('u1'), throwsA(isA<StateError>()));
    expect((await a.db.query(Tables.protein)).single['synced'], 1);
    expect((await a.db.query(Tables.water)).single['synced'], 0);
  });
}

class _Flaky extends FakeRemote {
  @override
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data) async {
    if (collection == Tables.water) throw StateError('offline for water');
    return super.put(uid, collection, id, data);
  }
}

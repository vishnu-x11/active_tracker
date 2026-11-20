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

  final users = <String, Map<String, Object?>>{};

  @override
  Future<void> putUser(String uid, Map<String, Object?> data) async => (users[uid] ??= {}).addAll(data);

  @override
  Future<void> delete(String uid, String collection, String id) async => docs['$uid/$collection']?.remove(id);

  @override
  Future<Map<String, Object?>?> get(String uid, String collection, String id) async => docs['$uid/$collection']?[id];

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

  test('pace zones travel with the profile and survive a profile from an older app', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    Map<String, Object?> profile(int at) => {
      'uid': 'u1',
      'weight_kg': 80.0,
      'height_cm': 180.0,
      'burn_target_kcal': 700,
      'updated_at': at,
      'deleted': 0,
      'synced': 0,
    };
    await a.db.insert(Tables.profile, {...profile(5), 'pace_zones': '{"auto":false}'});
    await b.db.insert(Tables.profile, {...profile(1), 'synced': 1});
    await SyncEngine(a, remote).sync('u1');
    await SyncEngine(b, remote).sync('u1');
    expect((await b.db.query(Tables.profile)).single['pace_zones'], '{"auto":false}');

    await remote.put('u1', Tables.profile, 'me', profile(9)..remove('synced'));
    await SyncEngine(b, remote).sync('u1');
    final row = (await b.db.query(Tables.profile)).single;
    expect(row['updated_at'], 9);
    expect(row['pace_zones'], '{"auto":false}');
  });

  test('a long run route is uploaded in parts and arrives whole and in order', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await Seed(a).run(DateTime(2026, 11, 5, 6), kcal: 2400);
    final runId = (await a.db.query(Tables.runs)).single['sync_id']! as String;
    final batch = a.db.batch();
    for (var i = 0; i < 2500; i++) {
      batch.insert(Tables.runPoints, {
        'run_sync_id': runId,
        'seq': i,
        'lat': 10 + i / 1e5,
        'lng': 76.0,
        't': i * 1000,
        'segment': 0,
      });
    }
    await batch.commit(noResult: true);

    await SyncEngine(a, remote).sync('u1');
    final runDoc = remote.docs['u1/${Tables.runs}']![runId]!;
    expect(runDoc.containsKey('points'), isFalse);
    expect(runDoc['route_parts'], 3);
    final parts = remote.docs['u1/${SyncEngine.routeCollection(runId)}']!;
    expect(parts.keys, ['0', '1', '2']);
    expect([for (final p in parts.values) (p['points']! as List).length], [1000, 1000, 500]);

    await SyncEngine(b, remote).sync('u1');
    final pts = await b.db.query(Tables.runPoints, orderBy: 'seq');
    expect(pts.length, 2500);
    expect(pts.first['t'], 0);
    expect(pts.last['t'], 2499000);
    expect([for (final p in pts) p['seq']], List.generate(2500, (i) => i));
  });

  test('a run uploaded by an older version, with its route inside the run, still downloads', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await Seed(a).run(DateTime(2026, 11, 5, 6), kcal: 300);
    final row = (await a.db.query(Tables.runs)).single;
    final id = row['sync_id']! as String;
    await remote.put('u1', Tables.runs, id, {
      ...({...row}..remove('synced')),
      'points': [
        {'la': 1.0, 'ln': 2.0, 'al': null, 't': 5, 's': 0},
        {'la': 1.1, 'ln': 2.1, 'al': null, 't': 6, 's': 0},
      ],
    });
    await SyncEngine(b, remote).sync('u1');
    expect([for (final p in await b.db.query(Tables.runPoints, orderBy: 'seq')) p['lat']], [1.0, 1.1]);
  });

  test('a run whose route parts are missing is retried later instead of saved without its route', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await Seed(a).run(DateTime(2026, 11, 5, 6), kcal: 300);
    final row = (await a.db.query(Tables.runs)).single;
    await remote.put('u1', Tables.runs, row['sync_id']! as String, {
      ...({...row}..remove('synced')),
      'route_parts': 1,
    });
    await expectLater(SyncEngine(b, remote).sync('u1'), throwsA(isA<StateError>()));
    expect(await b.db.query(Tables.runs), isEmpty);
  });

  test('run settings and reminders follow the account to a new phone, and the newer change wins', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await a.setSetting('run.settings', '{"voice":false}');
    await a.setSetting('reminders', '{"waterOn":false}');
    await a.setSetting('run.recording', '{"points":[]}');
    await SyncEngine(a, remote).sync('u1');
    expect(remote.docs['u1/${SyncEngine.settingsCollection}']!.keys, unorderedEquals(['run.settings', 'reminders']));

    final pulled = await SyncEngine(b, remote).sync('u1');
    expect(pulled.pulled, 2);
    expect(await b.setting('run.settings'), '{"voice":false}');
    expect(await b.setting('reminders'), '{"waterOn":false}');
    expect(await b.setting('run.recording'), isNull);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.setSetting('run.settings', '{"voice":true}');
    await SyncEngine(b, remote).sync('u1');
    await SyncEngine(a, remote).sync('u1');
    expect(await a.setting('run.settings'), '{"voice":true}');

    await a.setSetting('reminders', '{"waterOn":true}');
    await SyncEngine(b, remote).sync('u1');
    expect(await b.setting('reminders'), '{"waterOn":false}', reason: 'not pushed yet from A');
  });

  test("signing in with another account drops the first account's run settings", () async {
    final remote = FakeRemote();
    final a = await device();
    await a.setSetting('run.settings', '{"voice":false}');
    await SyncEngine(a, remote).sync('first');
    await SyncEngine(a, remote).sync('second');
    expect(await a.setting('run.settings'), isNull);
    await SyncEngine(a, remote).sync('first');
    expect(await a.setting('run.settings'), '{"voice":false}');
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

  test('the profile is saved under the user name and the user folder shows name and email', () async {
    final remote = FakeRemote();
    final a = await device(), b = await device();
    await a.db.insert(Tables.profile, {
      'uid': 'u1',
      'weight_kg': 70.0,
      'height_cm': 175.0,
      'updated_at': 5,
      'deleted': 0,
      'synced': 0,
    });
    await SyncEngine(a, remote).sync('u1');
    expect(remote.docs['u1/profile']!.keys, ['me'], reason: 'an older app saved it as me');

    var name = 'Vishnu P V';
    SyncAccount account() => (name: name, email: 'runner@example.com');
    await SyncEngine(a, remote, account: account).sync('u1');
    expect(remote.docs['u1/profile']!.keys, ['Vishnu P V']);
    expect(remote.docs['u1/profile']!['Vishnu P V']!['email'], 'runner@example.com');
    expect(remote.users['u1'], containsPair('name', 'Vishnu P V'));
    expect(remote.users['u1'], containsPair('email', 'runner@example.com'));

    name = 'Vishnu/Runner';
    await SyncEngine(a, remote, account: account).sync('u1');
    expect(remote.docs['u1/profile']!.keys, ['Vishnu-Runner'], reason: 'a renamed account moves the entry');
    expect(remote.users['u1'], containsPair('name', 'Vishnu/Runner'));

    expect(await SyncEngine(b, remote, account: account).restoreProfile('u1'), isTrue);
    expect((await b.db.query(Tables.profile)).single['weight_kg'], 70.0);
  });

  test('without a name the email is used, and with neither it stays me', () {
    expect(SyncEngine.profileDocId((name: '  ', email: 'a@b.com')), 'a@b.com');
    expect(SyncEngine.profileDocId((name: null, email: null)), 'me');
    expect(SyncEngine.profileDocId((name: '__x__', email: null)), 'me');
  });
}

class _Flaky extends FakeRemote {
  @override
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data) async {
    if (collection == Tables.water) throw StateError('offline for water');
    return super.put(uid, collection, id, data);
  }
}

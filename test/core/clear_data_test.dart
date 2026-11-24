import 'package:active_tracker/app/clear_data.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/sync/sync_controller.dart';
import 'package:active_tracker/core/sync/sync_engine.dart';
import 'package:active_tracker/features/profile/profile_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/app_harness.dart';
import '../helpers/pump.dart';
import '../helpers/seed.dart';
import 'sync_engine_test.dart' show FakeRemote;

class _Offline extends FakeRemote {
  @override
  Future<List<String>> ids(String uid, String collection) => throw StateError('offline');

  @override
  Future<void> wipe(String uid, String collection) => throw StateError('offline');
}

Future<void> _seed(AppDatabase db, {String uid = 'u1'}) async {
  final s = Seed(db);
  await db.db.insert(Tables.profile, {
    'uid': uid,
    'weight_kg': 75.0,
    'height_cm': 178.0,
    'updated_at': 5,
    'deleted': 0,
    'synced': 0,
  });
  await s.gym(DateTime(2026, 11, 20, 18), kcal: 400);
  await s.run(DateTime(2026, 11, 21, 6), kcal: 300);
  final runId = (await db.db.query(Tables.runs)).single['sync_id']! as String;
  await db.db.insert(Tables.runPoints, {'run_sync_id': runId, 'seq': 0, 'lat': 1.0, 'lng': 2.0, 't': 5, 'segment': 0});
  await db.db.insert(Tables.runFixes, {
    'run_sync_id': runId,
    'seq': 0,
    'at': 5,
    't': 5,
    'lat': 1.0,
    'lng': 2.0,
    'acc': 4.0,
    'speed': 2.5,
  });
  await db.db.insert(Tables.runFixes, {
    'run_sync_id': AppDatabase.recordingFixesId,
    'seq': 0,
    'at': 9,
    't': 9,
    'lat': 1.0,
    'lng': 2.0,
    'acc': 4.0,
    'speed': 2.5,
  });
  await s.water(DateTime(2026, 11, 21, 9), 330);
  await s.protein(DateTime(2026, 11, 21, 13), 30);
  await db.setSetting('reminders', '{"waterOn":false}');
  await db.setSetting('run.recording', '{}');
}

Future<Map<String, int>> _counts(AppDatabase db) async => {
  for (final t in Tables.all)
    if (t != Tables.settings) t: (await db.db.query(t)).length,
};

const _logs = [Tables.runs, Tables.runPoints, Tables.gymSessions, Tables.water, Tables.protein];

void main() {
  sqfliteFfiInit();
  var n = 0;
  Future<AppDatabase> device() =>
      AppDatabase.open(path: 'file:clear${n++}?mode=memory&cache=shared', factory: databaseFactoryFfi);

  test('clearing removes runs, gym, water and protein logs from the cloud and the phone, and nothing else', () async {
    final remote = FakeRemote();
    final db = await device();
    await _seed(db);
    await SyncEngine(db, remote, account: () => (name: 'Vishnu', email: 'v@x.com')).sync('u1');
    for (final c in SyncEngine.logs) {
      expect(remote.docs['u1/$c'], isNotEmpty, reason: c);
    }
    final runId = remote.docs['u1/${Tables.runs}']!.keys.single;
    expect(remote.docs['u1/${SyncEngine.routeCollection(runId)}'], isNotEmpty);

    await SyncEngine(db, remote).clear('u1');

    for (final c in [...SyncEngine.logs, SyncEngine.routeCollection(runId), SyncEngine.fixesCollection(runId)]) {
      expect(remote.docs['u1/$c'] ?? const {}, isEmpty, reason: c);
    }
    expect(remote.docs['u1/${Tables.profile}'], isNotEmpty);
    expect(remote.docs['u1/${SyncEngine.settingsCollection}'], isNotEmpty);
    expect(remote.users['u1'], isNotNull);

    final counts = await _counts(db);
    for (final t in _logs) {
      expect(counts[t], 0, reason: t);
    }
    expect(counts[Tables.profile], 1);
    expect((await db.db.query(Tables.runFixes)).single['run_sync_id'], AppDatabase.recordingFixesId);
    expect(await db.setting('reminders'), isNotNull);
    expect(await db.setting('run.recording'), isNotNull);
  });

  test('another account in the cloud is left alone', () async {
    final remote = FakeRemote();
    final mine = await device(), theirs = await device();
    await _seed(mine);
    await _seed(theirs, uid: 'u2');
    await SyncEngine(mine, remote).sync('u1');
    await SyncEngine(theirs, remote).sync('u2');

    await SyncEngine(mine, remote).clear('u1');

    expect(remote.docs['u2/${Tables.runs}'], hasLength(1));
    expect(remote.docs['u2/${Tables.profile}'], isNotEmpty);
  });

  test('without a connection nothing on the phone is deleted', () async {
    final db = await device();
    await _seed(db);
    final before = await _counts(db);

    await expectLater(SyncEngine(db, _Offline()).clear('u1'), throwsStateError);

    expect(await _counts(db), before);
    expect(await db.setting('reminders'), isNotNull);
  });

  testWidgets('Clear data asks first: Cancel keeps everything, Clear deletes the logs only', (tester) async {
    final remote = FakeRemote();
    final db = await pumpFeature(
      tester,
      routes: [
        ShellRoute(
          builder: (c, s, child) => Scaffold(body: child),
          routes: [
            ProfileRoutes.tab(
              accountRows: [
                Builder(
                  builder: (context) => ProfileAccountRow(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear data',
                    danger: true,
                    onTap: () => clearData(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      initial: ProfileRoutes.profile,
      height: 5000,
      overrides: [remoteStoreProvider.overrideWithValue(remote)],
    );
    await tester.runAsync(() => Seed(db).gym(DateTime(2026, 11, 20, 18), kcal: 400));

    await tester.tap(find.text('Clear data'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all your data?'), findsOneWidget);
    expect(find.text('Clearing data will permanently delete user data linked with this account.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.byTooltip('Close'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await settleWithIo(tester);
    expect(await tester.runAsync(() => db.db.query(Tables.gymSessions)), hasLength(1));

    await tester.tap(find.text('Clear data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Your data was cleared.'), findsOneWidget);
    expect(find.byType(PopScope<Object?>), findsNothing);
    expect(await tester.runAsync(() => db.db.query(Tables.gymSessions)), isEmpty);
    expect(await tester.runAsync(() => db.db.query(Tables.profile)), hasLength(1));
    expect(find.text('Test User'), findsOneWidget);
  });
}

import 'dart:io';

import 'package:active_tracker/core/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase app;

  setUp(() async {
    app = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
  });
  tearDown(() => app.close());

  test('creates every table', () async {
    final rows = await app.db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final names = rows.map((r) => r['name']).toSet();
    expect(
      names,
      containsAll([
        Tables.profile,
        Tables.gymSessions,
        Tables.runs,
        Tables.runPoints,
        Tables.runAnalysis,
        Tables.water,
        Tables.protein,
        Tables.presets,
        Tables.goals,
      ]),
    );
  });

  test('water entries reject amounts outside 1 ml to 5 L', () async {
    Future<void> insert(int ml) =>
        app.db.insert(Tables.water, {'sync_id': 'w$ml', 'day': '2026-11-05', 'at': 0, 'ml': ml, 'updated_at': 0});
    await insert(330);
    await expectLater(insert(0), throwsA(isA<DatabaseException>()));
    await expectLater(insert(5001), throwsA(isA<DatabaseException>()));
  });

  test('deleting a run removes its GPS points', () async {
    await app.db.insert(Tables.runs, {
      'sync_id': 'r1',
      'day': '2026-11-05',
      'started_at': 0,
      'title': 'Morning Run',
      'run_type': 'outdoor',
      'source': 'gps',
      'distance_m': 5200,
      'moving_sec': 1775,
      'weight_kg': 75,
      'kcal': 405,
      'updated_at': 0,
    });
    await app.db.insert(Tables.runPoints, {'run_sync_id': 'r1', 'seq': 0, 'lat': 0, 'lng': 0, 't': 0});
    await app.db.delete(Tables.runs, where: 'sync_id = ?', whereArgs: ['r1']);
    expect(await app.db.query(Tables.runPoints), isEmpty);
  });

  test('upgrading from version 6 adds run analysis and moves pace zones onto the profile', () async {
    final dir = await Directory.systemTemp.createTemp('at_db');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/v6.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
          await db.execute('''
            CREATE TABLE profile (
              uid TEXT PRIMARY KEY, weight_kg REAL NOT NULL, height_cm REAL NOT NULL, photo TEXT,
              updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, synced INTEGER NOT NULL DEFAULT 0
            )''');
          await db.insert('profile', {'uid': 'u', 'weight_kg': 75, 'height_cm': 178, 'updated_at': 1, 'synced': 1});
          await db.insert('app_settings', {'key': 'run.zones', 'value': '{"auto":false}'});
        },
      ),
    );
    await old.close();
    final upgraded = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    addTearDown(upgraded.close);
    final profile = (await upgraded.db.query(Tables.profile)).single;
    expect(profile['pace_zones'], '{"auto":false}');
    expect(profile['synced'], 0);
    expect(await upgraded.setting('run.zones'), isNull);
    expect(await upgraded.db.query(Tables.runAnalysis), isEmpty);
  });

  test('upgrading from version 7 lets run settings and reminders sync, other settings stay local', () async {
    final dir = await Directory.systemTemp.createTemp('at_db');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/v7.db';
    final fresh = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    await fresh.db.execute('DROP TABLE ${Tables.settings}');
    await fresh.db.execute('CREATE TABLE ${Tables.settings} (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await fresh.db.insert(Tables.settings, {'key': 'run.settings', 'value': '{"voice":false}'});
    await fresh.db.insert(Tables.settings, {'key': 'sync.owner', 'value': 'u'});
    await fresh.db.setVersion(7);
    await fresh.close();

    final upgraded = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    addTearDown(upgraded.close);
    final rows = {for (final r in await upgraded.db.query(Tables.settings)) r['key']: r};
    expect(rows['run.settings']!['synced'], 0);
    expect(rows['run.settings']!['updated_at'], greaterThan(0));
    expect(rows['sync.owner']!['synced'], 1);
    expect(await upgraded.setting('run.settings'), '{"voice":false}');
  });

  test('upgrading from version 8 adds the GPS reading log and keeps existing runs', () async {
    final dir = await Directory.systemTemp.createTemp('at_db');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/v8.db';
    final fresh = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    await fresh.db.execute('DROP TABLE ${Tables.runFixes}');
    await fresh.db.insert(Tables.settings, {'key': 'sync.owner', 'value': 'u'});
    await fresh.db.setVersion(8);
    await fresh.close();

    final upgraded = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    addTearDown(upgraded.close);
    expect(await upgraded.db.query(Tables.runFixes), isEmpty);
    expect(await upgraded.setting('sync.owner'), 'u');
  });
}

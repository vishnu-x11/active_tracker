import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/sync/sync_engine.dart';
import 'package:active_tracker/features/running/data/data_sources/track_local_data_source.dart';
import 'package:active_tracker/features/running/data/repositories/recording_repository_impl.dart';
import 'package:active_tracker/features/running/data/repositories/track_repository_impl.dart';
import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:active_tracker/features/running/domain/entities/raw_fix.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/gps_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/sync_engine_test.dart' show FakeRemote;
import 'gps_test.dart' show track;

List<RawFix> fixes(int from, int count) => [
  for (var i = from; i < from + count; i++)
    RawFix(
      GpsFix(
        TrackPoint(lat: 10 + i * 1e-5, lng: 76, t: i * 1000),
        accuracy: 4,
        speed: 2.6,
        heading: i.isEven ? 90 : null,
      ),
      at: i * 1000 + 50,
    ),
];

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  late RecordingRepositoryImpl recording;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    recording = RecordingRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<String> finish(String id) async {
    final saved = await SaveRunDraft(TrackRepositoryImpl(TrackLocalDataSourceImpl(db)), newId: () => id)(
      points: track(11),
      weightKg: 70,
      title: 'Morning Run',
    );
    return (saved as Ok<String>).value;
  }

  test('every GPS reading is logged in order and moves onto the saved run', () async {
    await recording.appendFixes(fixes(0, 3));
    await recording.appendFixes(fixes(3, 2));
    final id = await finish('run1');
    final rows = await db.db.query(Tables.runFixes, orderBy: 'seq');
    expect(rows.map((r) => r['run_sync_id']).toSet(), {id});
    expect(rows.map((r) => r['seq']), [0, 1, 2, 3, 4]);
    expect(rows.map((r) => r['t']), [0, 1000, 2000, 3000, 4000]);
    expect(rows.first['at'], 50);
    expect(rows.first['heading'], 90);
    expect(rows[1]['heading'], isNull);
    expect(rows.first['acc'], 4);
    expect(rows.first['speed'], 2.6);
  });

  test('a discarded recording leaves no readings behind', () async {
    await recording.appendFixes(fixes(0, 3));
    await recording.clear();
    expect(await db.db.query(Tables.runFixes), isEmpty);
  });

  test('readings of a deleted draft are cleaned up when the next run is saved', () async {
    await recording.appendFixes(fixes(0, 2));
    await finish('old');
    await db.db.delete(Tables.runs, where: 'sync_id = ?', whereArgs: ['old']);
    await recording.appendFixes(fixes(10, 2));
    await finish('new');
    expect((await db.db.query(Tables.runFixes)).map((r) => r['run_sync_id']).toSet(), {'new'});
  });

  test('the readings are uploaded with the run, in parts', () async {
    await recording.appendFixes(fixes(0, SyncEngine.fixPart + 5));
    final id = await finish('run1');
    await db.db.update(Tables.runs, {'draft': 0});
    final remote = FakeRemote();
    await SyncEngine(db, remote).sync('u1');
    expect(remote.docs['u1/${Tables.runs}']![id]!['fix_parts'], 2);
    final parts = remote.docs['u1/${SyncEngine.fixesCollection(id)}']!;
    expect((parts['0']!['fixes']! as List).length, SyncEngine.fixPart);
    final last = (parts['1']!['fixes']! as List).last as Map;
    expect(last['t'], (SyncEngine.fixPart + 4) * 1000);
    expect(last['ac'], 4);
    expect(last['sp'], 2.6);
  });
}

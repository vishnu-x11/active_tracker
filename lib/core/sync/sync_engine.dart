import 'package:sqflite/sqflite.dart';

import '../storage/app_database.dart';
import 'remote_store.dart';

typedef SyncReport = ({int pushed, int pulled});

class SyncEngine {
  SyncEngine(this._database, this._remote);

  final AppDatabase _database;
  final RemoteStore _remote;

  static const synced = [
    Tables.gymSessions,
    Tables.runs,
    Tables.water,
    Tables.protein,
    Tables.presets,
    Tables.goals,
    Tables.routines,
  ];
  static const _owner = 'sync.owner';
  static String _pullKey(String table) => 'sync.pulled.$table';

  Database get _db => _database.db;
  final _columns = <String, Set<String>>{};

  Future<Set<String>> _cols(String table) async =>
      _columns[table] ??= {for (final r in await _db.rawQuery('PRAGMA table_info($table)')) r['name']! as String};

  Future<SyncReport> sync(String uid) async {
    await _claim(uid);
    _failed = null;
    final pushed = await _push(uid);
    final pulled = await _pull(uid);
    if (_failed case final e?) throw e;
    return (pushed: pushed, pulled: pulled);
  }

  Object? _failed;

  Future<bool> _put(String uid, String table, String id, Map<String, Object?> doc) async {
    try {
      await _remote.put(uid, table, id, doc);
      return true;
    } catch (e) {
      _failed ??= e;
      return false;
    }
  }

  Future<bool> restoreProfile(String uid) async {
    await _claim(uid);
    final docs = await _remote.changedSince(uid, Tables.profile, 0);
    if (docs.isEmpty) return false;
    final cols = await _cols(Tables.profile);
    final doc = docs.last;
    await _db.insert(Tables.profile, {
      for (final e in doc.entries)
        if (cols.contains(e.key)) e.key: e.value,
      'uid': uid,
      'synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  Future<void> _claim(String uid) async {
    final owner = await _database.setting(_owner);
    if (owner == uid) return;
    if (owner != null) {
      await _db.transaction((txn) async {
        for (final t in [...synced, Tables.runPoints]) {
          await txn.delete(t);
        }
        await txn.delete(Tables.settings, where: "key LIKE 'sync.pulled.%'");
      });
    }
    await _database.setSetting(_owner, uid);
  }

  Future<int> _push(String uid) async {
    var n = 0;
    for (final table in synced) {
      final rows = await _db.query(table, where: table == Tables.runs ? 'synced = 0 AND draft = 0' : 'synced = 0');
      for (final row in rows) {
        final id = row['sync_id']! as String;
        final doc = {...row}..remove('synced');
        if (table == Tables.runs) doc['points'] = await _pointsOf(id);
        if (!await _put(uid, table, id, doc)) continue;
        await _db.update(
          table,
          {'synced': 1},
          where: 'sync_id = ? AND updated_at = ?',
          whereArgs: [id, row['updated_at']],
        );
        n++;
      }
    }
    final profile = await _db.query(Tables.profile, where: 'uid = ? AND synced = 0', whereArgs: [uid]);
    for (final row in profile) {
      if (!await _put(uid, Tables.profile, 'me', {...row}..remove('synced'))) continue;
      await _db.update(
        Tables.profile,
        {'synced': 1},
        where: 'uid = ? AND updated_at = ?',
        whereArgs: [uid, row['updated_at']],
      );
      n++;
    }
    return n;
  }

  Future<List<Map<String, Object?>>> _pointsOf(String runId) async => [
    for (final p in await _db.query(Tables.runPoints, where: 'run_sync_id = ?', whereArgs: [runId], orderBy: 'seq'))
      {'la': p['lat'], 'ln': p['lng'], 'al': p['alt'], 't': p['t'], 's': p['segment']},
  ];

  Future<int> _pull(String uid) async {
    var n = 0;
    for (final table in [...synced, Tables.profile]) {
      final since = int.tryParse(await _database.setting(_pullKey(table)) ?? '') ?? 0;
      final docs = await _remote.changedSince(uid, table, since);
      if (docs.isEmpty) continue;
      final cols = await _cols(table);
      var newest = since;
      for (final doc in docs) {
        final updated = (doc['updated_at']! as num).toInt();
        if (updated > newest) newest = updated;
        final key = table == Tables.profile ? 'uid' : 'sync_id';
        final id = table == Tables.profile ? uid : doc['sync_id']! as String;
        final local = await _db.query(table, columns: ['updated_at', 'synced'], where: '$key = ?', whereArgs: [id]);
        final keepLocal =
            local.isNotEmpty && ((local.single['updated_at']! as int) >= updated || local.single['synced'] == 0);
        if (keepLocal) continue;
        final row = {
          for (final e in doc.entries)
            if (cols.contains(e.key)) e.key: e.value,
          key: id,
          'synced': 1,
        };
        await _db.transaction((txn) async {
          if (table == Tables.runs) await txn.delete(Tables.runPoints, where: 'run_sync_id = ?', whereArgs: [id]);
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
          final pts = table == Tables.runs ? doc['points'] : null;
          if (pts is List<Object?>) {
            final batch = txn.batch();
            for (final (i, raw) in pts.indexed) {
              final p = raw! as Map<Object?, Object?>;
              batch.insert(Tables.runPoints, {
                'run_sync_id': id,
                'seq': i,
                'lat': p['la'],
                'lng': p['ln'],
                'alt': p['al'],
                't': p['t'],
                'segment': p['s'] ?? 0,
              });
            }
            await batch.commit(noResult: true);
          }
        });
        n++;
      }
      await _database.setSetting(_pullKey(table), '$newest');
    }
    return n;
  }
}

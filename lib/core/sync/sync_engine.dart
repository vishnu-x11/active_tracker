import 'package:sqflite/sqflite.dart';

import '../storage/app_database.dart';
import 'remote_store.dart';

typedef SyncReport = ({int pushed, int pulled});

typedef SyncAccount = ({String? name, String? email});

class SyncEngine {
  SyncEngine(this._database, this._remote, {SyncAccount Function()? account})
    : _account = account ?? (() => (name: null, email: null));

  final AppDatabase _database;
  final RemoteStore _remote;
  final SyncAccount Function() _account;

  static const synced = [
    Tables.gymSessions,
    Tables.runs,
    Tables.water,
    Tables.protein,
    Tables.presets,
    Tables.goals,
    Tables.routines,
  ];
  static const settingsCollection = 'settings';
  static const routePart = 1000;
  static String routeCollection(String runId) => '${Tables.runs}/$runId/route';
  static const fixPart = 1000;
  static String fixesCollection(String runId) => '${Tables.runs}/$runId/fixes';
  static const _owner = 'sync.owner';
  static const _profileDoc = 'sync.profile_doc';
  static const _userDoc = 'sync.user_doc';
  static const legacyProfileDoc = 'me';

  static String profileDocId(SyncAccount account) {
    for (final candidate in [account.name, account.email]) {
      final id = (candidate ?? '').trim().replaceAll('/', '-');
      if (id.isEmpty || id == '.' || id == '..' || (id.startsWith('__') && id.endsWith('__'))) continue;
      return id;
    }
    return legacyProfileDoc;
  }

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

  static const logs = [Tables.runs, Tables.gymSessions, Tables.water, Tables.protein];

  Future<void> clear(String uid) async {
    await _claim(uid);
    for (final id in await _remote.ids(uid, Tables.runs)) {
      await _remote.wipe(uid, routeCollection(id));
      await _remote.wipe(uid, fixesCollection(id));
    }
    for (final collection in logs) {
      await _remote.wipe(uid, collection);
    }
    await _db.transaction((txn) async {
      for (final t in [...logs, Tables.runPoints, Tables.runAnalysis]) {
        await txn.delete(t);
      }
      await txn.delete(Tables.runFixes, where: 'run_sync_id != ?', whereArgs: [AppDatabase.recordingFixesId]);
    });
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
        for (final t in [...synced, Tables.runPoints, Tables.runFixes]) {
          await txn.delete(t);
        }
        await txn.delete(Tables.settings, where: "key LIKE 'sync.pulled.%'");
        await txn.delete(Tables.settings, where: 'key IN (?, ?)', whereArgs: [_profileDoc, _userDoc]);
        await txn.delete(
          Tables.settings,
          where: 'key IN (${List.filled(AppDatabase.syncedSettings.length, '?').join(', ')})',
          whereArgs: AppDatabase.syncedSettings,
        );
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
        if (table == Tables.runs && !await _putRoute(uid, id, row, doc)) continue;
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
    n += await _pushSettings(uid);
    final account = _account();
    final docId = profileDocId(account);
    final previous = await _database.setting(_profileDoc) ?? legacyProfileDoc;
    final moved = previous != docId;
    final profile = await _db.query(
      Tables.profile,
      where: moved ? 'uid = ?' : 'uid = ? AND synced = 0',
      whereArgs: [uid],
    );
    for (final row in profile) {
      final doc = {...row}..remove('synced');
      if (account.name case final name?) doc['name'] = name;
      if (account.email case final email?) doc['email'] = email;
      if (!await _put(uid, Tables.profile, docId, doc)) continue;
      if (moved && !await _delete(uid, Tables.profile, previous)) continue;
      await _database.setSetting(_profileDoc, docId);
      await _db.update(
        Tables.profile,
        {'synced': 1},
        where: 'uid = ? AND updated_at = ?',
        whereArgs: [uid, row['updated_at']],
      );
      n++;
    }
    await _pushUser(uid, account);
    return n;
  }

  Future<void> _pushUser(String uid, SyncAccount account) async {
    if (account.name == null && account.email == null) return;
    final key = '${account.name ?? ''}|${account.email ?? ''}';
    if (await _database.setting(_userDoc) == key) return;
    try {
      await _remote.putUser(uid, {
        'name': account.name,
        'email': account.email,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _failed ??= e;
      return;
    }
    await _database.setSetting(_userDoc, key);
  }

  Future<bool> _delete(String uid, String table, String id) async {
    try {
      await _remote.delete(uid, table, id);
      return true;
    } catch (e) {
      _failed ??= e;
      return false;
    }
  }

  Future<bool> _putRoute(String uid, String id, Map<String, Object?> row, Map<String, Object?> doc) async {
    final points = row['deleted'] == 1 ? const <Map<String, Object?>>[] : await _pointsOf(id);
    final parts = (points.length / routePart).ceil();
    for (var i = 0; i < parts; i++) {
      final end = (i + 1) * routePart < points.length ? (i + 1) * routePart : points.length;
      final ok = await _put(uid, routeCollection(id), '$i', {'i': i, 'points': points.sublist(i * routePart, end)});
      if (!ok) return false;
    }
    doc['route_parts'] = parts;
    if (row['deleted'] == 1) return true;
    final fixes = await _fixesOf(id);
    if (fixes.isEmpty) return true;
    final fixParts = (fixes.length / fixPart).ceil();
    for (var i = 0; i < fixParts; i++) {
      final end = (i + 1) * fixPart < fixes.length ? (i + 1) * fixPart : fixes.length;
      final ok = await _put(uid, fixesCollection(id), '$i', {'i': i, 'fixes': fixes.sublist(i * fixPart, end)});
      if (!ok) return false;
    }
    doc['fix_parts'] = fixParts;
    return true;
  }

  Future<List<Map<String, Object?>>> _fixesOf(String runId) async => [
    for (final f in await _db.query(Tables.runFixes, where: 'run_sync_id = ?', whereArgs: [runId], orderBy: 'seq'))
      {
        'a': f['at'],
        't': f['t'],
        'la': f['lat'],
        'ln': f['lng'],
        'al': f['alt'],
        'ac': f['acc'],
        'sp': f['speed'],
        'h': f['heading'],
      },
  ];

  Future<List<Object?>?> _routeOf(String uid, String id, Map<String, Object?> doc) async {
    if (doc['points'] case final List<Object?> legacy) return legacy;
    final parts = (doc['route_parts'] as num?)?.toInt() ?? 0;
    final out = <Object?>[];
    for (var i = 0; i < parts; i++) {
      final part = await _remote.get(uid, routeCollection(id), '$i');
      if (part?['points'] case final List<Object?> pts) {
        out.addAll(pts);
      } else {
        return null;
      }
    }
    return out;
  }

  String get _settingKeys => List.filled(AppDatabase.syncedSettings.length, '?').join(', ');

  Future<int> _pushSettings(String uid) async {
    var n = 0;
    final rows = await _db.query(
      Tables.settings,
      where: 'synced = 0 AND key IN ($_settingKeys)',
      whereArgs: AppDatabase.syncedSettings,
    );
    for (final row in rows) {
      final key = row['key']! as String;
      final doc = {'key': key, 'value': row['value'], 'updated_at': row['updated_at']};
      if (!await _put(uid, settingsCollection, key, doc)) continue;
      await _db.update(
        Tables.settings,
        {'synced': 1},
        where: 'key = ? AND updated_at = ?',
        whereArgs: [key, row['updated_at']],
      );
      n++;
    }
    return n;
  }

  Future<int> _pullSettings(String uid) async {
    const pullKey = 'sync.pulled.$settingsCollection';
    final since = int.tryParse(await _database.setting(pullKey) ?? '') ?? 0;
    final docs = await _remote.changedSince(uid, settingsCollection, since);
    if (docs.isEmpty) return 0;
    var n = 0;
    var newest = since;
    for (final doc in docs) {
      final updated = (doc['updated_at']! as num).toInt();
      if (updated > newest) newest = updated;
      final key = doc['key'] as String?;
      final value = doc['value'] as String?;
      if (key == null || value == null || !AppDatabase.syncedSettings.contains(key)) continue;
      final local = await _db.query(
        Tables.settings,
        columns: ['updated_at', 'synced'],
        where: 'key = ?',
        whereArgs: [key],
      );
      final keepLocal =
          local.isNotEmpty && ((local.single['updated_at']! as int) >= updated || local.single['synced'] == 0);
      if (keepLocal) continue;
      await _db.insert(Tables.settings, {
        'key': key,
        'value': value,
        'updated_at': updated,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      n++;
    }
    await _database.setSetting(pullKey, '$newest');
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
        final previous = newest;
        if (updated > newest) newest = updated;
        final key = table == Tables.profile ? 'uid' : 'sync_id';
        final id = table == Tables.profile ? uid : doc['sync_id']! as String;
        final local = await _db.query(table, columns: ['updated_at', 'synced'], where: '$key = ?', whereArgs: [id]);
        final keepLocal =
            local.isNotEmpty && ((local.single['updated_at']! as int) >= updated || local.single['synced'] == 0);
        if (keepLocal) continue;
        final route = table == Tables.runs ? await _routeOf(uid, id, doc) : null;
        if (table == Tables.runs && route == null) {
          _failed ??= StateError('Route of run $id is not uploaded yet');
          newest = previous;
          break;
        }
        final row = {
          for (final e in doc.entries)
            if (cols.contains(e.key)) e.key: e.value,
          key: id,
          'synced': 1,
        };
        await _db.transaction((txn) async {
          if (table == Tables.runs) await txn.delete(Tables.runPoints, where: 'run_sync_id = ?', whereArgs: [id]);
          if (table == Tables.profile && local.isNotEmpty) {
            await txn.update(table, row, where: '$key = ?', whereArgs: [id]);
          } else {
            await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          final pts = route;
          if (pts != null) {
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
    return n + await _pullSettings(uid);
  }
}

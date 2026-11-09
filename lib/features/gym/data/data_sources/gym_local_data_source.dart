import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/gym_session.dart';
import '../models/gym_session_model.dart';

abstract interface class GymLocalDataSource {
  Future<GymSession?> get(String id);
  Future<void> upsert(GymSession session);
  Future<void> softDelete(String id);
  Future<List<String>> customGroups();
  Future<void> addCustomGroup(String id, String name);
  Future<List<GymSession>> since(DateTime from);
  Future<List<GymSession>> withExercises();
  Future<List<Routine>> routines();
  Future<void> upsertRoutine(Routine routine);
  Future<void> deleteRoutine(String id);
}

class GymLocalDataSourceImpl implements GymLocalDataSource {
  GymLocalDataSourceImpl(this._database, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final int Function() _now;

  @override
  Future<GymSession?> get(String id) async {
    final rows = await _database.db.query(Tables.gymSessions, where: 'sync_id = ? AND deleted = 0', whereArgs: [id]);
    return rows.isEmpty ? null : rows.single.toGymSession();
  }

  @override
  Future<void> upsert(GymSession session) =>
      _database.db.insert(Tables.gymSessions, session.toRow(_now()), conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> softDelete(String id) => _database.db.update(
    Tables.gymSessions,
    {'deleted': 1, 'synced': 0, 'updated_at': _now()},
    where: 'sync_id = ?',
    whereArgs: [id],
  );

  @override
  Future<List<String>> customGroups() async {
    final rows = await _database.db.query(
      Tables.presets,
      columns: ['label'],
      where: "kind = 'muscle_group' AND deleted = 0",
      orderBy: 'sort, updated_at',
    );
    return [for (final r in rows) r['label']! as String];
  }

  @override
  Future<void> addCustomGroup(String id, String name) => _database.db.insert(Tables.presets, {
    'sync_id': id,
    'kind': 'muscle_group',
    'label': name,
    'sort': 0,
    'updated_at': _now(),
    'deleted': 0,
    'synced': 0,
  });

  @override
  Future<List<GymSession>> since(DateTime from) async => [
    for (final r in await _database.db.query(
      Tables.gymSessions,
      where: 'started_at >= ? AND deleted = 0',
      whereArgs: [from.millisecondsSinceEpoch],
    ))
      r.toGymSession(),
  ];

  @override
  Future<List<GymSession>> withExercises() async => [
    for (final r in await _database.db.query(
      Tables.gymSessions,
      where: 'exercises IS NOT NULL AND deleted = 0',
      orderBy: 'started_at DESC',
      limit: 200,
    ))
      r.toGymSession(),
  ];

  @override
  Future<List<Routine>> routines() async => [
    for (final r in await _database.db.query(Tables.routines, where: 'deleted = 0', orderBy: 'name COLLATE NOCASE'))
      r.toRoutine(),
  ];

  @override
  Future<void> upsertRoutine(Routine routine) =>
      _database.db.insert(Tables.routines, routine.toRow(_now()), conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> deleteRoutine(String id) => _database.db.update(
    Tables.routines,
    {'deleted': 1, 'synced': 0, 'updated_at': _now()},
    where: 'sync_id = ?',
    whereArgs: [id],
  );
}

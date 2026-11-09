import '../../../../core/storage/app_database.dart';
import '../../domain/entities/run.dart';
import '../models/run_model.dart';

abstract interface class RunLocalDataSource {
  Future<Run?> get(String id);
  Future<void> upsert(Run run);
  Future<void> softDelete(String id);
}

class RunLocalDataSourceImpl implements RunLocalDataSource {
  RunLocalDataSourceImpl(this._database, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final int Function() _now;

  @override
  Future<Run?> get(String id) async {
    final rows = await _database.db.query(Tables.runs, where: 'sync_id = ? AND deleted = 0', whereArgs: [id]);
    return rows.isEmpty ? null : rows.single.toRun();
  }

  @override
  Future<void> upsert(Run run) => _database.db.transaction((txn) async {
    final row = run.toRow(_now());
    final updated = await txn.update(Tables.runs, row, where: 'sync_id = ?', whereArgs: [run.id]);
    if (updated == 0) await txn.insert(Tables.runs, row);
  });

  @override
  Future<void> softDelete(String id) => _database.db.update(
    Tables.runs,
    {'deleted': 1, 'synced': 0, 'updated_at': _now()},
    where: 'sync_id = ?',
    whereArgs: [id],
  );
}

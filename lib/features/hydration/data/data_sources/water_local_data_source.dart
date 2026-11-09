import '../../../../core/storage/app_database.dart';
import '../../domain/entities/water_entry.dart';

abstract interface class WaterLocalDataSource {
  Future<void> insert(WaterEntry entry);
  Future<void> softDelete(String id);
  Future<List<WaterEntry>> entriesFor(String day);
}

class WaterLocalDataSourceImpl implements WaterLocalDataSource {
  WaterLocalDataSourceImpl(this._database, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final int Function() _now;

  @override
  Future<void> insert(WaterEntry e) => _database.db.insert(Tables.water, {
    'sync_id': e.id,
    'day': e.day,
    'at': e.at.millisecondsSinceEpoch,
    'ml': e.ml,
    'updated_at': _now(),
    'deleted': 0,
    'synced': 0,
  });

  @override
  Future<void> softDelete(String id) => _database.db.update(
    Tables.water,
    {'deleted': 1, 'synced': 0, 'updated_at': _now()},
    where: 'sync_id = ?',
    whereArgs: [id],
  );

  @override
  Future<List<WaterEntry>> entriesFor(String day) async {
    final rows = await _database.db.query(
      Tables.water,
      where: 'day = ? AND deleted = 0',
      whereArgs: [day],
      orderBy: 'at DESC',
    );
    return [
      for (final r in rows)
        WaterEntry(
          id: r['sync_id']! as String,
          day: r['day']! as String,
          at: DateTime.fromMillisecondsSinceEpoch(r['at']! as int),
          ml: r['ml']! as int,
        ),
    ];
  }
}

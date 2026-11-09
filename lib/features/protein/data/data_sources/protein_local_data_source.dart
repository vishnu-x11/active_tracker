import '../../../../core/storage/app_database.dart';
import '../../domain/entities/protein.dart';

abstract interface class ProteinLocalDataSource {
  Future<void> insert(ProteinEntry entry);
  Future<void> softDelete(String id);
  Future<List<ProteinEntry>> entriesFor(String day);
  Future<List<Food>> foods();
  Future<void> insertFood(Food food);
}

class ProteinLocalDataSourceImpl implements ProteinLocalDataSource {
  ProteinLocalDataSourceImpl(this._database, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final int Function() _now;

  Map<String, Object?> get _fresh => {'updated_at': _now(), 'deleted': 0, 'synced': 0};

  @override
  Future<void> insert(ProteinEntry e) => _database.db.insert(Tables.protein, {
    'sync_id': e.id,
    'day': e.day,
    'at': e.at.millisecondsSinceEpoch,
    'grams': e.grams,
    'food': e.food,
    ..._fresh,
  });

  @override
  Future<void> softDelete(String id) => _database.db.update(
    Tables.protein,
    {'deleted': 1, 'synced': 0, 'updated_at': _now()},
    where: 'sync_id = ?',
    whereArgs: [id],
  );

  @override
  Future<List<ProteinEntry>> entriesFor(String day) async {
    final rows = await _database.db.query(
      Tables.protein,
      where: 'day = ? AND deleted = 0',
      whereArgs: [day],
      orderBy: 'at DESC',
    );
    return [
      for (final r in rows)
        ProteinEntry(
          id: r['sync_id']! as String,
          day: r['day']! as String,
          at: DateTime.fromMillisecondsSinceEpoch(r['at']! as int),
          grams: (r['grams']! as num).toDouble(),
          food: r['food'] as String?,
        ),
    ];
  }

  @override
  Future<List<Food>> foods() async {
    final rows = await _database.db.query(
      Tables.presets,
      where: "kind = 'food' AND deleted = 0",
      orderBy: 'updated_at DESC',
    );
    return [
      for (final r in rows)
        Food(
          id: r['sync_id']! as String,
          name: r['label']! as String,
          serving: (r['unit'] as String?) ?? 'custom',
          grams: (r['value']! as num).toDouble(),
        ),
    ];
  }

  @override
  Future<void> insertFood(Food f) => _database.db.insert(Tables.presets, {
    'sync_id': f.id,
    'kind': 'food',
    'label': f.name,
    'value': f.grams,
    'unit': f.serving,
    'sort': 0,
    ..._fresh,
  });
}

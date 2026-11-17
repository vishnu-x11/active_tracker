import 'dart:convert';

import '../../../../core/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/pace_zones.dart';
import '../../domain/repositories/pace_zones_repository.dart';

class PaceZonesRepositoryImpl implements PaceZonesRepository {
  PaceZonesRepositoryImpl(this._database, {required this.uid, int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final Future<String?> Function() uid;
  final int Function() _now;

  static const column = 'pace_zones';

  @override
  Future<Result<PaceZones>> load() async {
    try {
      final id = await uid();
      if (id == null) return const Ok(PaceZones());
      final rows = await _database.db.query(Tables.profile, columns: [column], where: 'uid = ?', whereArgs: [id]);
      final raw = rows.firstOrNull?[column] as String?;
      if (raw == null) return const Ok(PaceZones());
      return Ok(PaceZones.fromMap((jsonDecode(raw) as Map).cast<String, Object?>()));
    } catch (e) {
      return const Ok(PaceZones());
    }
  }

  @override
  Future<Result<void>> save(PaceZones zones) async {
    try {
      final id = await uid();
      final updated = id == null
          ? 0
          : await _database.db.update(
              Tables.profile,
              {column: jsonEncode(zones.toMap()), 'synced': 0, 'updated_at': _now()},
              where: 'uid = ?',
              whereArgs: [id],
            );
      if (updated == 0) return const Err(StorageFailure("Couldn't save your zones. Finish your profile first."));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't save your zones.", e));
    }
  }
}

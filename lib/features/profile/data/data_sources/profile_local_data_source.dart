import '../../../../core/storage/app_database.dart';
import '../../domain/entities/profile.dart';
import '../models/profile_model.dart';

abstract interface class ProfileLocalDataSource {
  Future<Profile?> get(String uid);
  Future<void> upsert(String uid, Profile profile);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  ProfileLocalDataSourceImpl(this._database, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _database;
  final int Function() _now;

  @override
  Future<Profile?> get(String uid) async {
    final rows = await _database.db.query(
      Tables.profile,
      where: '${ProfileColumns.uid} = ? AND deleted = 0',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first.toProfile();
  }

  @override
  Future<void> upsert(String uid, Profile profile) => _database.db.transaction((txn) async {
    final row = profile.toRow(uid, _now());
    final updated = await txn.update(
      Tables.profile,
      {...row, 'deleted': 0},
      where: '${ProfileColumns.uid} = ?',
      whereArgs: [uid],
    );
    if (updated == 0) await txn.insert(Tables.profile, row);
  });
}

import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  late ProfileRepositoryImpl repo;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    repo = ProfileRepositoryImpl(ProfileLocalDataSourceImpl(db, now: () => 1000));
  });
  tearDown(() => db.close());

  const profile = Profile(weightKg: 75, heightCm: 178, age: 29, sex: Sex.male, burnTargetKcal: 600);

  test('save then get returns the same profile, per user', () async {
    expect((await repo.get('u1')).valueOrNull, isNull);
    expect(await repo.save('u1', profile), isA<Ok<void>>());
    expect((await repo.get('u1')).valueOrNull, profile);
    expect((await repo.get('u2')).valueOrNull, isNull);
  });

  test('saving again replaces the row and marks it unsynced', () async {
    await repo.save('u1', profile);
    await repo.save('u1', const Profile(weightKg: 80, heightCm: 178, burnTargetKcal: 700));
    final rows = await db.db.query(Tables.profile);
    expect(rows, hasLength(1));
    expect(rows.single['weight_kg'], 80);
    expect(rows.single['synced'], 0);
    expect(rows.single['updated_at'], 1000);
  });

  test('a database error becomes a StorageFailure', () async {
    await db.close();
    final r = await repo.get('u1');
    expect((r as Err).failure, isA<StorageFailure>());
  });
}

import '../../../../core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_local_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._local);

  final ProfileLocalDataSource _local;

  @override
  Future<Result<Profile?>> get(String uid) async {
    try {
      return Ok(await _local.get(uid));
    } catch (e) {
      return Err(StorageFailure("Couldn't read your profile.", e));
    }
  }

  @override
  Future<Result<void>> save(String uid, Profile profile) async {
    try {
      await _local.upsert(uid, profile);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure("Couldn't save your profile. Please try again.", e));
    }
  }
}

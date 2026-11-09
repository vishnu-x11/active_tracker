import '../../../../core/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<Profile?>> get(String uid);

  Future<Result<void>> save(String uid, Profile profile);
}

import '../../../../core/result.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile?>> call(String uid) => _repository.get(uid);
}

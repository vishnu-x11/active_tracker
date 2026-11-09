import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/profile/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  final saved = <String, Profile>{};
  Result<void>? saveResult;

  @override
  Future<Result<Profile?>> get(String uid) async => Ok(saved[uid]);

  @override
  Future<Result<void>> save(String uid, Profile profile) async {
    if (saveResult case final r?) return r;
    saved[uid] = profile;
    return const Ok(null);
  }
}

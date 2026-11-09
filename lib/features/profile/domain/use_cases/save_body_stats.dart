import '../../../../core/result.dart';
import '../entities/body_stats_rules.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class SaveBodyStats {
  const SaveBodyStats(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile>> call({
    required String uid,
    required String weight,
    required String height,
    required String age,
    required Sex? sex,
    required String burnTarget,
  }) async {
    final problem =
        BodyStatsRules.weight(weight) ??
        BodyStatsRules.height(height) ??
        BodyStatsRules.age(age) ??
        BodyStatsRules.burnTarget(burnTarget);
    if (problem != null) return Err(ValidationFailure(problem));
    final profile = Profile(
      weightKg: BodyStatsRules.parseDecimal(weight)!,
      heightCm: BodyStatsRules.parseDecimal(height)!,
      age: BodyStatsRules.parseWhole(age),
      sex: sex,
      burnTargetKcal: BodyStatsRules.parseWhole(burnTarget)!,
    );
    return switch (await _repository.save(uid, profile)) {
      Ok() => Ok(profile),
      Err(:final failure) => Err(failure),
    };
  }
}

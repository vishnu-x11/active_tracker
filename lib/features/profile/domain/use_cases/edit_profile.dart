import '../../../../core/result.dart';
import '../entities/body_stats_rules.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

enum ProfileField { weight, height, burnTarget, proteinRatio, waterPerKg }

class EditProfile {
  const EditProfile(this._repository);

  final ProfileRepository _repository;

  static String? problem(ProfileField field, String text) => switch (field) {
    ProfileField.weight => BodyStatsRules.weight(text),
    ProfileField.height => BodyStatsRules.height(text),
    ProfileField.burnTarget => BodyStatsRules.burnTarget(text),
    ProfileField.proteinRatio => BodyStatsRules.proteinRatio(text),
    ProfileField.waterPerKg => BodyStatsRules.waterPerKg(text),
  };

  Future<Result<Profile>> call(String uid, Profile current, ProfileField field, String text) async {
    final issue = problem(field, text);
    if (issue != null) return Err(ValidationFailure(issue));
    final d = BodyStatsRules.parseDecimal(text), w = BodyStatsRules.parseWhole(text);
    return save(uid, switch (field) {
      ProfileField.weight => current.copyWith(weightKg: d),
      ProfileField.height => current.copyWith(heightCm: d),
      ProfileField.burnTarget => current.copyWith(burnTargetKcal: w),
      ProfileField.proteinRatio => current.copyWith(proteinGPerKg: d),
      ProfileField.waterPerKg => current.copyWith(waterMlPerKg: w),
    });
  }

  Future<Result<Profile>> save(String uid, Profile updated) async => switch (await _repository.save(uid, updated)) {
    Ok() => Ok(updated),
    Err(:final failure) => Err(failure),
  };
}

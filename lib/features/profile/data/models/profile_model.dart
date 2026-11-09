import '../../domain/entities/profile.dart';

abstract final class ProfileColumns {
  static const uid = 'uid';
  static const weightKg = 'weight_kg';
  static const heightCm = 'height_cm';
  static const age = 'age';
  static const sex = 'sex';
  static const burnTarget = 'burn_target_kcal';
  static const proteinGPerKg = 'protein_g_per_kg';
  static const waterMlPerKg = 'water_ml_per_kg';
  static const workoutBoost = 'workout_water_boost';
  static const theme = 'theme_mode';
  static const photo = 'photo';
  static const updatedAt = 'updated_at';
  static const synced = 'synced';
}

extension ProfileRowToEntity on Map<String, Object?> {
  Profile toProfile() => Profile(
    weightKg: (this[ProfileColumns.weightKg]! as num).toDouble(),
    heightCm: (this[ProfileColumns.heightCm]! as num).toDouble(),
    age: this[ProfileColumns.age] as int?,
    sex: switch (this[ProfileColumns.sex]) {
      final String name => Sex.values.where((s) => s.name == name).firstOrNull,
      _ => null,
    },
    burnTargetKcal: this[ProfileColumns.burnTarget]! as int,
    proteinGPerKg: (this[ProfileColumns.proteinGPerKg]! as num).toDouble(),
    waterMlPerKg: this[ProfileColumns.waterMlPerKg]! as int,
    workoutWaterBoost: this[ProfileColumns.workoutBoost] == 1,
    theme: ThemePreference.values.firstWhere(
      (t) => t.name == this[ProfileColumns.theme],
      orElse: () => ThemePreference.system,
    ),
    photo: this[ProfileColumns.photo] as String?,
  );
}

extension ProfileToRow on Profile {
  Map<String, Object?> toRow(String uid, int updatedAt) => {
    ProfileColumns.uid: uid,
    ProfileColumns.weightKg: weightKg,
    ProfileColumns.heightCm: heightCm,
    ProfileColumns.age: age,
    ProfileColumns.sex: sex?.name,
    ProfileColumns.burnTarget: burnTargetKcal,
    ProfileColumns.proteinGPerKg: proteinGPerKg,
    ProfileColumns.waterMlPerKg: waterMlPerKg,
    ProfileColumns.workoutBoost: workoutWaterBoost ? 1 : 0,
    ProfileColumns.theme: theme.name,
    ProfileColumns.photo: photo,
    ProfileColumns.updatedAt: updatedAt,
    ProfileColumns.synced: 0,
  };
}

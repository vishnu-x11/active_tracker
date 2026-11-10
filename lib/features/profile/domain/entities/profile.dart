enum Sex {
  male('Male'),
  female('Female'),
  notSaid('Prefer not to say');

  const Sex(this.label);
  final String label;
}

enum ThemePreference { system, light, dark }

class Profile {
  const Profile({
    required this.weightKg,
    required this.heightCm,
    this.age,
    this.sex,
    required this.burnTargetKcal,
    this.proteinGPerKg = 1.6,
    this.waterMlPerKg = 35,
    this.workoutWaterBoost = true,
    this.theme = ThemePreference.system,
    this.photo,
  });

  final double weightKg;
  final double heightCm;
  final int? age;
  final Sex? sex;

  final int burnTargetKcal;
  final double proteinGPerKg;
  final int waterMlPerKg;

  final bool workoutWaterBoost;
  final ThemePreference theme;

  final String? photo;

  Profile copyWith({
    double? weightKg,
    double? heightCm,
    int? Function()? age,
    Sex? Function()? sex,
    int? burnTargetKcal,
    double? proteinGPerKg,
    int? waterMlPerKg,
    bool? workoutWaterBoost,
    ThemePreference? theme,
    String? Function()? photo,
  }) => Profile(
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    age: age != null ? age() : this.age,
    sex: sex != null ? sex() : this.sex,
    burnTargetKcal: burnTargetKcal ?? this.burnTargetKcal,
    proteinGPerKg: proteinGPerKg ?? this.proteinGPerKg,
    waterMlPerKg: waterMlPerKg ?? this.waterMlPerKg,
    workoutWaterBoost: workoutWaterBoost ?? this.workoutWaterBoost,
    theme: theme ?? this.theme,
    photo: photo != null ? photo() : this.photo,
  );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.weightKg == weightKg &&
      other.heightCm == heightCm &&
      other.age == age &&
      other.sex == sex &&
      other.burnTargetKcal == burnTargetKcal &&
      other.proteinGPerKg == proteinGPerKg &&
      other.waterMlPerKg == waterMlPerKg &&
      other.workoutWaterBoost == workoutWaterBoost &&
      other.theme == theme &&
      other.photo == photo;

  @override
  int get hashCode => Object.hash(
    weightKg,
    heightCm,
    age,
    sex,
    burnTargetKcal,
    proteinGPerKg,
    waterMlPerKg,
    workoutWaterBoost,
    theme,
    photo,
  );
}

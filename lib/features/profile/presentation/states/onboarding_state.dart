import '../../../../core/formulas/formulas.dart';
import '../../domain/entities/body_stats_rules.dart';
import '../../domain/entities/profile.dart';

class OnboardingState {
  const OnboardingState({
    this.weight = '',
    this.height = '',
    this.age = '',
    this.sex,
    this.burnTarget = '$defaultBurnTargetKcal',
    this.showBodyErrors = false,
    this.showBurnError = false,
    this.saving = false,
    this.error,
  });

  final String weight;
  final String height;
  final String age;
  final Sex? sex;

  final String burnTarget;
  final bool showBodyErrors;
  final bool showBurnError;
  final bool saving;
  final String? error;

  String? get weightError => showBodyErrors ? BodyStatsRules.weight(weight) : null;
  String? get heightError => showBodyErrors ? BodyStatsRules.height(height) : null;
  String? get ageError => showBodyErrors ? BodyStatsRules.age(age) : null;
  String? get burnError => showBurnError ? BodyStatsRules.burnTarget(burnTarget) : null;

  bool get bodyValid =>
      BodyStatsRules.weight(weight) == null && BodyStatsRules.height(height) == null && BodyStatsRules.age(age) == null;

  double? get _kg => BodyStatsRules.weight(weight) == null ? BodyStatsRules.parseDecimal(weight) : null;
  double? get _cm => BodyStatsRules.height(height) == null ? BodyStatsRules.parseDecimal(height) : null;

  double? get bmiValue => _kg != null && _cm != null ? bmi(weightKg: _kg!, heightCm: _cm!) : null;
  String? get bmiLabel => switch (bmiValue) {
    null => null,
    < 18.5 => 'Under',
    < 25 => 'Healthy',
    < 30 => 'Over',
    _ => 'Obese',
  };
  int? get proteinG => _kg == null ? null : proteinTargetG(weightKg: _kg!);
  int? get waterMl => _kg == null ? null : waterTargetMl(weightKg: _kg!, workoutDay: false);

  int? get gymHourKcal => _kg == null
      ? null
      : gymKcal(intensity: GymIntensity.moderate, groups: const [], weightKg: _kg!, duration: const Duration(hours: 1));

  OnboardingState copyWith({
    String? weight,
    String? height,
    String? age,
    Sex? Function()? sex,
    String? burnTarget,
    bool? showBodyErrors,
    bool? showBurnError,
    bool? saving,
    String? Function()? error,
  }) => OnboardingState(
    weight: weight ?? this.weight,
    height: height ?? this.height,
    age: age ?? this.age,
    sex: sex != null ? sex() : this.sex,
    burnTarget: burnTarget ?? this.burnTarget,
    showBodyErrors: showBodyErrors ?? this.showBodyErrors,
    showBurnError: showBurnError ?? this.showBurnError,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is OnboardingState &&
      other.weight == weight &&
      other.height == height &&
      other.age == age &&
      other.sex == sex &&
      other.burnTarget == burnTarget &&
      other.showBodyErrors == showBodyErrors &&
      other.showBurnError == showBurnError &&
      other.saving == saving &&
      other.error == error;

  @override
  int get hashCode => Object.hash(weight, height, age, sex, burnTarget, showBodyErrors, showBurnError, saving, error);
}

import '../../../../core/formulas/formulas.dart';
import '../../../profile/domain/entities/profile.dart';

class DailyTargets {
  const DailyTargets({required this.burnKcal, required this.waterMl, required this.proteinG});

  factory DailyTargets.forDay(Profile profile, {required bool workoutDay}) => DailyTargets(
    burnKcal: profile.burnTargetKcal,
    waterMl: waterTargetMl(
      weightKg: profile.weightKg,
      workoutDay: workoutDay && profile.workoutWaterBoost,
      mlPerKg: profile.waterMlPerKg,
    ),
    proteinG: proteinTargetG(weightKg: profile.weightKg, gPerKg: profile.proteinGPerKg),
  );

  final int burnKcal;
  final int waterMl;
  final int proteinG;

  @override
  bool operator ==(Object other) =>
      other is DailyTargets && other.burnKcal == burnKcal && other.waterMl == waterMl && other.proteinG == proteinG;

  @override
  int get hashCode => Object.hash(burnKcal, waterMl, proteinG);
}

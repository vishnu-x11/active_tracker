import '../../../../core/formulas/formulas.dart';
import 'exercise.dart';

class GymSession {
  const GymSession({
    required this.id,
    required this.day,
    required this.startedAt,
    required this.title,
    required this.durationMin,
    required this.intensity,
    required this.muscleGroups,
    required this.weightKg,
    required this.kcal,
    this.exercises = const [],
  });

  final String id;
  final String day;
  final DateTime startedAt;
  final String title;
  final int durationMin;
  final GymIntensity intensity;
  final List<String> muscleGroups;
  final double weightKg;
  final int kcal;
  final List<ExerciseLog> exercises;

  double get volume => exercises.fold(0, (a, e) => a + e.volume);

  double get met => gymMet(intensity, muscleGroups);

  @override
  bool operator ==(Object other) =>
      other is GymSession &&
      other.id == id &&
      other.day == day &&
      other.startedAt == startedAt &&
      other.title == title &&
      other.durationMin == durationMin &&
      other.intensity == intensity &&
      other.muscleGroups.join(',') == muscleGroups.join(',') &&
      other.weightKg == weightKg &&
      other.kcal == kcal &&
      Object.hashAll(other.exercises) == Object.hashAll(exercises);

  @override
  int get hashCode => Object.hash(
    id,
    day,
    startedAt,
    title,
    durationMin,
    intensity,
    muscleGroups.join(','),
    weightKg,
    kcal,
    Object.hashAll(exercises),
  );
}

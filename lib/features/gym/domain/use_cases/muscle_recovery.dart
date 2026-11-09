import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../entities/gym_session.dart';
import '../repositories/gym_repository.dart';

abstract final class MuscleRecovery {
  static const mapped = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs', 'core'];

  static const hours = {GymIntensity.light: 36.0, GymIntensity.moderate: 48.0, GymIntensity.hard: 72.0};
  static const load = {GymIntensity.light: 0.6, GymIntensity.moderate: 1.0, GymIntensity.hard: 1.4};

  static const window = Duration(hours: 72);
  static const fullBodyShare = 0.7;

  static double fatigue(GymSession s) => (0.3 + 0.5 * (s.durationMin / 60) * load[s.intensity]!).clamp(0.0, 0.95);

  static Map<String, int> compute(Iterable<GymSession> sessions, DateTime now) {
    final fresh = {for (final g in mapped) g: 1.0};
    for (final s in sessions) {
      final elapsed = now.difference(s.startedAt.add(Duration(minutes: s.durationMin))).inMinutes / 60;
      final r = hours[s.intensity]!;
      if (elapsed < 0 || elapsed >= r) continue;
      final left = fatigue(s) * (1 - elapsed / r);
      final hits = <String, double>{};
      for (final g in s.muscleGroups) {
        if (g == 'full_body') {
          for (final m in mapped) {
            hits[m] = (hits[m] ?? 0) < fullBodyShare ? fullBodyShare : hits[m]!;
          }
        } else if (fresh.containsKey(g)) {
          hits[g] = 1;
        }
      }
      hits.forEach((g, share) => fresh[g] = fresh[g]! * (1 - left * share));
    }
    return {for (final e in fresh.entries) e.key: (e.value * 100).round()};
  }
}

class GetMuscleRecovery {
  const GetMuscleRecovery(this._repository, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final GymRepository _repository;
  final DateTime Function() _now;

  Future<Result<Map<String, int>>> call() async {
    final now = _now();
    final result = await _repository.since(now.subtract(MuscleRecovery.window + const Duration(hours: 12)));
    return switch (result) {
      Ok(:final value) => Ok(MuscleRecovery.compute(value, now)),
      Err(:final failure) => Err(failure),
    };
  }
}

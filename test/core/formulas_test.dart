import 'package:active_tracker/core/formulas/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gym', () {
    test('2 h moderate shoulders + triceps at 75 kg is 712 kcal', () {
      expect(gymMet(GymIntensity.moderate, ['shoulders', 'triceps']), closeTo(4.75, 1e-9));
      expect(
        gymKcal(
          intensity: GymIntensity.moderate,
          groups: ['shoulders', 'triceps'],
          weightKg: 75,
          duration: const Duration(hours: 2),
        ),
        712,
      );
    });

    test('custom groups count as factor 1.0', () {
      expect(gymMet(GymIntensity.light, ['glutes']), closeTo(3.5, 1e-9));
    });

    test('no groups falls back to the base MET', () {
      expect(gymMet(GymIntensity.hard, const []), 6.0);
    });
  });

  group('run', () {
    test('5.2 km at 75 kg is 405 kcal', () {
      expect(runKcal(weightKg: 75, km: 5.2), 405);
      expect(runKcal(weightKg: 75, km: 4.0), 312);
    });

    test('5.2 km in 29:35 is 5:41 /km', () {
      final pace = paceSecPerKm(km: 5.2, time: const Duration(minutes: 29, seconds: 35))!;
      expect(formatPace(pace), '5:41');
    });

    test('any two of distance, time and pace give the third', () {
      expect(timeFromPace(km: 10, paceSecPerKm: 360), const Duration(hours: 1));
      expect(kmFromPace(time: const Duration(hours: 1), paceSecPerKm: 360), closeTo(10, 1e-9));
    });

    test('zero distance has no pace', () {
      expect(paceSecPerKm(km: 0, time: const Duration(minutes: 5)), isNull);
    });

    test('speed is 10.5 km/h for the sample run', () {
      expect(speedKmh(km: 5.2, time: const Duration(minutes: 29, seconds: 35)), closeTo(10.55, 0.01));
    });
  });

  group('targets', () {
    test('water: 2,625 ml on a rest day, 3,125 ml on a workout day', () {
      expect(waterTargetMl(weightKg: 75, workoutDay: false), 2625);
      expect(waterTargetMl(weightKg: 75, workoutDay: true), 3125);
    });

    test('protein: 120 g at 1.6 g/kg', () {
      expect(proteinTargetG(weightKg: 75), 120);
    });

    test('BMI for 75 kg, 178 cm is 23.7', () {
      expect(bmi(weightKg: 75, heightCm: 178), closeTo(23.67, 0.01));
    });
  });

  group('parseClock', () {
    test('accepts h:mm:ss, mm:ss and minutes', () {
      expect(parseClock('1:02:03'), const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(parseClock('29:35'), const Duration(minutes: 29, seconds: 35));
      expect(parseClock('45'), const Duration(minutes: 45));
    });

    test('rejects bad input', () {
      expect(parseClock('5:75'), isNull);
      expect(parseClock('abc'), isNull);
      expect(parseClock('1:2:3:4'), isNull);
    });
  });
}

enum GymIntensity {
  light(3.5),
  moderate(5.0),
  hard(6.0);

  const GymIntensity(this.baseMet);
  final double baseMet;
}

const Map<String, double> muscleGroupFactor = {
  'legs': 1.15,
  'back': 1.15,
  'full_body': 1.15,
  'chest': 1.05,
  'shoulders': 1.0,
  'biceps': 0.9,
  'triceps': 0.9,
  'core': 0.9,
  'cardio': 1.4,
};

double gymMet(GymIntensity intensity, Iterable<String> groups) {
  final list = groups.toList();
  if (list.isEmpty) return intensity.baseMet;
  final avg = list.map((g) => muscleGroupFactor[g] ?? 1.0).reduce((a, b) => a + b) / list.length;
  return intensity.baseMet * avg;
}

int gymKcal({
  required GymIntensity intensity,
  required Iterable<String> groups,
  required double weightKg,
  required Duration duration,
}) {
  final hours = duration.inSeconds / 3600;
  return (gymMet(intensity, groups) * weightKg * hours).floor();
}

int runKcal({required double weightKg, required double km}) => (1.04 * weightKg * km).floor();

double? paceSecPerKm({required double km, required Duration time}) => km <= 0 ? null : time.inSeconds / km;

Duration timeFromPace({required double km, required double paceSecPerKm}) =>
    Duration(seconds: (km * paceSecPerKm).round());

double kmFromPace({required Duration time, required double paceSecPerKm}) =>
    paceSecPerKm <= 0 ? 0 : time.inSeconds / paceSecPerKm;

double speedKmh({required double km, required Duration time}) => time.inSeconds == 0 ? 0 : km / (time.inSeconds / 3600);

int waterTargetMl({required double weightKg, required bool workoutDay, int mlPerKg = 35}) =>
    (mlPerKg * weightKg).round() + (workoutDay ? 500 : 0);

int proteinTargetG({required double weightKg, double gPerKg = 1.6}) => (gPerKg * weightKg).round();

const int defaultBurnTargetKcal = 600;

double bmi({required double weightKg, required double heightCm}) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

String formatPace(double secPerKm) {
  final total = secPerKm.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

Duration? parseClock(String input) {
  final parts = input.trim().split(':');
  if (parts.isEmpty || parts.length > 3) return null;
  final nums = parts.map(int.tryParse).toList();
  if (nums.any((n) => n == null || n < 0)) return null;
  final n = nums.cast<int>();
  return switch (n.length) {
    1 => Duration(minutes: n[0]),
    2 => n[1] < 60 ? Duration(minutes: n[0], seconds: n[1]) : null,
    _ => n[1] < 60 && n[2] < 60 ? Duration(hours: n[0], minutes: n[1], seconds: n[2]) : null,
  };
}

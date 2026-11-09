class SetEntry {
  const SetEntry({required this.kg, required this.reps, this.done = false});

  final double kg;
  final int reps;
  final bool done;

  static const maxKg = 1000.0;
  static const maxReps = 100;

  bool get valid => reps > 0 && reps <= maxReps && kg >= 0 && kg <= maxKg;
  double get volume => kg * reps;
  double get oneRepMax => reps <= 0 ? 0 : (reps == 1 ? kg : kg * (1 + reps / 30));

  SetEntry copyWith({double? kg, int? reps, bool? done}) =>
      SetEntry(kg: kg ?? this.kg, reps: reps ?? this.reps, done: done ?? this.done);

  Map<String, Object?> toMap() => {'kg': kg, 'r': reps};

  static SetEntry fromMap(Map<String, Object?> m) =>
      SetEntry(kg: (m['kg'] as num? ?? 0).toDouble(), reps: (m['r'] as num? ?? 0).toInt(), done: true);

  @override
  bool operator ==(Object other) => other is SetEntry && other.kg == kg && other.reps == reps && other.done == done;

  @override
  int get hashCode => Object.hash(kg, reps, done);
}

class ExerciseLog {
  const ExerciseLog({required this.name, required this.group, this.sets = const []});

  final String name;
  final String group;
  final List<SetEntry> sets;

  String get key => name.toLowerCase();
  double get volume => sets.fold(0, (a, s) => a + s.volume);
  double get best1rm => sets.fold(0, (a, s) => s.oneRepMax > a ? s.oneRepMax : a);

  ExerciseLog copyWith({List<SetEntry>? sets}) => ExerciseLog(name: name, group: group, sets: sets ?? this.sets);

  Map<String, Object?> toMap() => {
    'n': name,
    'g': group,
    's': [for (final s in sets) s.toMap()],
  };

  static ExerciseLog fromMap(Map<String, Object?> m) => ExerciseLog(
    name: m['n']! as String,
    group: m['g'] as String? ?? 'full_body',
    sets: [
      for (final s in (m['s'] as List<Object?>? ?? const [])) SetEntry.fromMap((s! as Map).cast<String, Object?>()),
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is ExerciseLog &&
      other.name == name &&
      other.group == group &&
      other.sets.length == sets.length &&
      [for (var i = 0; i < sets.length; i++) other.sets[i] == sets[i]].every((e) => e);

  @override
  int get hashCode => Object.hash(name, group, Object.hashAll(sets));
}

class ExerciseHistory {
  const ExerciseHistory({required this.lastSets, required this.lastDate, required this.best1rm});

  final List<SetEntry> lastSets;
  final DateTime lastDate;
  final double best1rm;
}

abstract final class ExerciseLibrary {
  static const builtIn = <(String, String)>[
    ('Bench press', 'chest'),
    ('Incline dumbbell press', 'chest'),
    ('Push-up', 'chest'),
    ('Chest fly', 'chest'),
    ('Deadlift', 'back'),
    ('Pull-up', 'back'),
    ('Lat pulldown', 'back'),
    ('Barbell row', 'back'),
    ('Seated cable row', 'back'),
    ('Overhead press', 'shoulders'),
    ('Lateral raise', 'shoulders'),
    ('Face pull', 'shoulders'),
    ('Barbell curl', 'biceps'),
    ('Dumbbell curl', 'biceps'),
    ('Hammer curl', 'biceps'),
    ('Triceps pushdown', 'triceps'),
    ('Skull crusher', 'triceps'),
    ('Dips', 'triceps'),
    ('Back squat', 'legs'),
    ('Front squat', 'legs'),
    ('Leg press', 'legs'),
    ('Romanian deadlift', 'legs'),
    ('Lunge', 'legs'),
    ('Leg curl', 'legs'),
    ('Leg extension', 'legs'),
    ('Calf raise', 'legs'),
    ('Hip thrust', 'legs'),
    ('Plank', 'core'),
    ('Hanging leg raise', 'core'),
    ('Cable crunch', 'core'),
    ('Kettlebell swing', 'full_body'),
    ('Clean and press', 'full_body'),
  ];

  static String? groupOf(String name) {
    final key = name.toLowerCase();
    return builtIn.where((e) => e.$1.toLowerCase() == key).firstOrNull?.$2;
  }

  static const maxNameLength = 40;
}

class RoutineExercise {
  const RoutineExercise({required this.name, required this.group, required this.sets});

  final String name;
  final String group;
  final int sets;

  Map<String, Object?> toMap() => {'n': name, 'g': group, 'c': sets};

  static RoutineExercise fromMap(Map<String, Object?> m) => RoutineExercise(
    name: m['n']! as String,
    group: m['g'] as String? ?? 'full_body',
    sets: (m['c'] as num? ?? 3).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is RoutineExercise && other.name == name && other.group == group && other.sets == sets;

  @override
  int get hashCode => Object.hash(name, group, sets);
}

class Routine {
  const Routine({required this.id, required this.name, required this.exercises});

  final String id;
  final String name;
  final List<RoutineExercise> exercises;

  static const maxNameLength = 30;

  @override
  bool operator ==(Object other) =>
      other is Routine &&
      other.id == id &&
      other.name == name &&
      Object.hashAll(other.exercises) == Object.hashAll(exercises);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(exercises));
}

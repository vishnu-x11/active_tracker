import 'dart:convert';

import '../../../../core/formulas/formulas.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/gym_session.dart';

extension GymRowToEntity on Map<String, Object?> {
  GymSession toGymSession() => GymSession(
    id: this['sync_id']! as String,
    day: this['day']! as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(this['started_at']! as int),
    title: this['title']! as String,
    durationMin: this['duration_min']! as int,
    intensity: GymIntensity.values.firstWhere((i) => i.name == this['intensity'], orElse: () => GymIntensity.moderate),
    muscleGroups: (jsonDecode(this['muscle_groups']! as String) as List<Object?>).cast<String>(),
    weightKg: (this['weight_kg']! as num).toDouble(),
    kcal: this['kcal']! as int,
    exercises: switch (this['exercises']) {
      final String raw when raw.isNotEmpty => [
        for (final e in jsonDecode(raw) as List<Object?>) ExerciseLog.fromMap((e! as Map).cast<String, Object?>()),
      ],
      _ => const [],
    },
  );
}

extension GymSessionToRow on GymSession {
  Map<String, Object?> toRow(int updatedAt) => {
    'sync_id': id,
    'day': day,
    'started_at': startedAt.millisecondsSinceEpoch,
    'title': title,
    'duration_min': durationMin,
    'intensity': intensity.name,
    'muscle_groups': jsonEncode(muscleGroups),
    'weight_kg': weightKg,
    'kcal': kcal,
    'exercises': exercises.isEmpty ? null : jsonEncode([for (final e in exercises) e.toMap()]),
    'updated_at': updatedAt,
    'deleted': 0,
    'synced': 0,
  };
}

extension RoutineRowToEntity on Map<String, Object?> {
  Routine toRoutine() => Routine(
    id: this['sync_id']! as String,
    name: this['name']! as String,
    exercises: [
      for (final e in jsonDecode(this['exercises']! as String) as List<Object?>)
        RoutineExercise.fromMap((e! as Map).cast<String, Object?>()),
    ],
  );
}

extension RoutineToRow on Routine {
  Map<String, Object?> toRow(int updatedAt) => {
    'sync_id': id,
    'name': name,
    'exercises': jsonEncode([for (final e in exercises) e.toMap()]),
    'updated_at': updatedAt,
    'deleted': 0,
    'synced': 0,
  };
}

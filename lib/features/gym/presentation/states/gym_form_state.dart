import '../../../../core/formulas/formulas.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/use_cases/save_gym_session.dart';

class GymFormState {
  const GymFormState({
    required this.day,
    required this.startMinute,
    this.minutes = 60,
    this.groups = const [],
    this.customGroups = const [],
    this.intensity = GymIntensity.moderate,
    this.weightKg = 75,
    this.loading = false,
    this.showErrors = false,
    this.saving = false,
    this.error,
    this.groupError,
    this.savedId,
    this.exercises = const [],
    this.history = const {},
    this.routines = const [],
    this.restSec = 90,
    this.restUntil,
    this.notice,
    this.routineError,
  });

  final DateTime day;

  final int startMinute;
  final int minutes;

  final List<String> groups;
  final List<String> customGroups;
  final GymIntensity intensity;
  final double weightKg;

  final bool loading;
  final bool showErrors;
  final bool saving;
  final String? error;

  final String? groupError;

  final String? savedId;

  final List<ExerciseLog> exercises;
  final Map<String, ExerciseHistory> history;
  final List<Routine> routines;
  final int restSec;
  final DateTime? restUntil;
  final String? notice;
  final String? routineError;

  double get volume => exercises.fold(0, (a, e) => a + e.volume);

  bool isPr(int exercise, int set) {
    final e = exercises.elementAtOrNull(exercise);
    final s = e?.sets.elementAtOrNull(set);
    if (e == null || s == null) return false;
    final before = history[e.key]?.best1rm;
    if (!s.done || before == null || !s.valid) return false;
    var best = before;
    for (var j = 0; j < set; j++) {
      if (e.sets[j].done && e.sets[j].oneRepMax > best) best = e.sets[j].oneRepMax;
    }
    return s.oneRepMax > best;
  }

  static const presets = [45, 60, 90, 120];

  DateTime get startedAt => day.add(Duration(minutes: startMinute));
  int get kcal => SaveGymSession.estimate(intensity: intensity, groups: groups, weightKg: weightKg, minutes: minutes);
  double get met => gymMet(intensity, groups);

  String? problem(DateTime now) => showErrors
      ? SaveGymSession.problem(
          groups: {...groups, ...exercises.map((e) => e.group)}.toList(),
          minutes: minutes,
          startedAt: startedAt,
          now: now,
          exercises: exercises,
        )
      : null;

  GymFormState copyWith({
    DateTime? day,
    int? startMinute,
    int? minutes,
    List<String>? groups,
    List<String>? customGroups,
    GymIntensity? intensity,
    double? weightKg,
    bool? loading,
    bool? showErrors,
    bool? saving,
    String? Function()? error,
    String? Function()? groupError,
    String? savedId,
    List<ExerciseLog>? exercises,
    Map<String, ExerciseHistory>? history,
    List<Routine>? routines,
    int? restSec,
    DateTime? Function()? restUntil,
    String? Function()? notice,
    String? Function()? routineError,
  }) => GymFormState(
    day: day ?? this.day,
    startMinute: startMinute ?? this.startMinute,
    minutes: minutes ?? this.minutes,
    groups: groups ?? this.groups,
    customGroups: customGroups ?? this.customGroups,
    intensity: intensity ?? this.intensity,
    weightKg: weightKg ?? this.weightKg,
    loading: loading ?? this.loading,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
    groupError: groupError != null ? groupError() : this.groupError,
    savedId: savedId ?? this.savedId,
    exercises: exercises ?? this.exercises,
    history: history ?? this.history,
    routines: routines ?? this.routines,
    restSec: restSec ?? this.restSec,
    restUntil: restUntil != null ? restUntil() : this.restUntil,
    notice: notice != null ? notice() : this.notice,
    routineError: routineError != null ? routineError() : this.routineError,
  );

  @override
  bool operator ==(Object other) =>
      other is GymFormState &&
      other.day == day &&
      other.startMinute == startMinute &&
      other.minutes == minutes &&
      other.groups.join(',') == groups.join(',') &&
      other.customGroups.join(',') == customGroups.join(',') &&
      other.intensity == intensity &&
      other.weightKg == weightKg &&
      other.loading == loading &&
      other.showErrors == showErrors &&
      other.saving == saving &&
      other.error == error &&
      other.groupError == groupError &&
      other.savedId == savedId &&
      Object.hashAll(other.exercises) == Object.hashAll(exercises) &&
      identical(other.history, history) &&
      identical(other.routines, routines) &&
      other.restSec == restSec &&
      other.restUntil == restUntil &&
      other.notice == notice &&
      other.routineError == routineError;

  @override
  int get hashCode => Object.hash(
    day,
    startMinute,
    minutes,
    groups.join(','),
    customGroups.join(','),
    intensity,
    weightKg,
    loading,
    showErrors,
    saving,
    error,
    groupError,
    savedId,
    Object.hashAll(exercises),
    identityHashCode(history),
    identityHashCode(routines),
    restSec,
    restUntil,
    notice,
    routineError,
  );
}

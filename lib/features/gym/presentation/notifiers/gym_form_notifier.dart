import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../profile/profile_api.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/use_cases/exercise_use_cases.dart';
import '../../domain/use_cases/save_gym_session.dart';
import '../providers.dart';
import '../states/gym_form_state.dart';

final gymFormProvider = NotifierProvider.autoDispose.family<GymFormNotifier, GymFormState, String?>(
  GymFormNotifier.new,
);

class GymFormNotifier extends Notifier<GymFormState> {
  GymFormNotifier(this.id);

  final String? id;

  String? _originalDay;

  @override
  GymFormState build() {
    final now = DateTime.now();
    final end = now.hour * 60 + now.minute - now.minute % 5;
    ref.listen(profileProvider, (_, _) {});
    final initial = GymFormState(
      day: dateOnly(now),
      startMinute: (end - 60).clamp(0, 24 * 60 - 1),
      loading: id != null,
    );
    Future.microtask(_load);
    return initial;
  }

  Future<void> _load() async {
    final profile = await ref.read(profileProvider.future);
    final custom = (await ref.read(getCustomMuscleGroupsProvider)()).valueOrNull ?? const <String>[];
    final history = (await ref.read(getExerciseHistoryProvider)(excludeId: id)).valueOrNull ?? const {};
    final routines = (await ref.read(getRoutinesProvider)()).valueOrNull ?? const <Routine>[];
    if (!ref.mounted) return;
    state = state.copyWith(weightKg: profile?.weightKg, customGroups: custom, history: history, routines: routines);
    final editing = id;
    if (editing == null) return;
    final result = await ref.read(getGymSessionProvider)(editing);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final s?):
        _originalDay = s.day;
        state = state.copyWith(
          loading: false,
          day: dateOnly(s.startedAt),
          startMinute: s.startedAt.hour * 60 + s.startedAt.minute,
          minutes: s.durationMin,
          groups: s.muscleGroups,
          intensity: s.intensity,
          weightKg: s.weightKg,
          exercises: s.exercises,
          customGroups: {...custom, ...s.muscleGroups.where((g) => !_isBuiltIn(g))}.toList(),
        );
      case Ok():
        state = state.copyWith(loading: false, error: () => 'This session no longer exists.');
      case Err(:final failure):
        state = state.copyWith(loading: false, error: () => failure.message);
    }
  }

  static bool _isBuiltIn(String g) => muscleGroupFactor.containsKey(g);

  void setDay(DateTime d) => state = state.copyWith(day: dateOnly(d));
  void setStart(int minuteOfDay) => state = state.copyWith(startMinute: minuteOfDay);
  void setMinutes(int m) => state = state.copyWith(minutes: m.clamp(0, SaveGymSession.maxMinutes));

  void step(int by) => setMinutes(state.minutes + by < 15 ? 15 : state.minutes + by);
  void setIntensity(GymIntensity i) => state = state.copyWith(intensity: i);

  void toggleGroup(String key) {
    final g = [...state.groups];
    g.contains(key) ? g.remove(key) : g.add(key);
    state = state.copyWith(groups: g);
  }

  Future<bool> addCustomGroup(String name) async {
    final result = await ref.read(addCustomMuscleGroupProvider)(name, existing: state.customGroups);
    if (!ref.mounted) return false;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          customGroups: [...state.customGroups, value],
          groups: [...state.groups, value],
          groupError: () => null,
        );
        return true;
      case Err(:final failure):
        state = state.copyWith(groupError: () => failure.message);
        return false;
    }
  }

  Future<void> save() async {
    if (state.saving || state.loading) return;
    state = state.copyWith(showErrors: true, saving: true, error: () => null);
    final result = await ref.read(saveGymSessionProvider)(
      id: id,
      startedAt: state.startedAt,
      minutes: state.minutes,
      groups: state.groups,
      intensity: state.intensity,
      weightKg: state.weightKg,
      exercises: state.exercises,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        invalidateDay(ref, value.day);
        if (_originalDay != null && _originalDay != value.day) invalidateDay(ref, _originalDay!);
        ref.invalidate(gymSessionProvider(value.id));
        state = state.copyWith(saving: false, savedId: value.id);
      case Err(failure: ValidationFailure()):
        state = state.copyWith(saving: false);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
    }
  }

  DateTime Function() get _clock => ref.read(gymClockProvider);

  void addExercise(String name, String group) {
    final last = state.history[name.toLowerCase()]?.lastSets.firstOrNull;
    final first = last?.copyWith(done: false) ?? const SetEntry(kg: 0, reps: 0);
    state = state.copyWith(
      exercises: [
        ...state.exercises,
        ExerciseLog(name: name, group: group, sets: [first]),
      ],
      groups: state.groups.contains(group) ? null : [...state.groups, group],
    );
  }

  void removeExercise(int i) => state = state.copyWith(exercises: [...state.exercises]..removeAt(i));

  void _setSets(int i, List<SetEntry> sets) {
    final list = [...state.exercises];
    list[i] = list[i].copyWith(sets: sets);
    state = state.copyWith(exercises: list);
  }

  void addSet(int i) {
    final e = state.exercises[i];
    final last = state.history[e.key]?.lastSets;
    final next = e.sets.length < (last?.length ?? 0)
        ? last![e.sets.length].copyWith(done: false)
        : (e.sets.lastOrNull?.copyWith(done: false) ?? const SetEntry(kg: 0, reps: 0));
    _setSets(i, [...e.sets, next]);
  }

  void removeSet(int i, int j) {
    final sets = [...state.exercises[i].sets]..removeAt(j);
    sets.isEmpty ? removeExercise(i) : _setSets(i, sets);
  }

  void updateSet(int i, int j, {double? kg, int? reps}) {
    final sets = [...state.exercises[i].sets];
    sets[j] = sets[j].copyWith(kg: kg, reps: reps);
    _setSets(i, sets);
  }

  void toggleDone(int i, int j) {
    final sets = [...state.exercises[i].sets];
    final s = sets[j];
    if (!s.done && s.reps <= 0) {
      state = state.copyWith(notice: () => 'Enter the reps first');
      return;
    }
    sets[j] = s.copyWith(done: !s.done);
    _setSets(i, sets);
    if (!sets[j].done) return;
    final e = state.exercises[i];
    state = state.copyWith(
      restUntil: () => _clock().add(Duration(seconds: state.restSec)),
      notice: () => state.isPr(i, j) ? 'New PR: ${e.name} ${_kg(sets[j].kg)} kg × ${sets[j].reps}' : null,
    );
  }

  static String _kg(double kg) => kg == kg.roundToDouble() ? '${kg.round()}' : '$kg';

  void clearNotice() => state = state.copyWith(notice: () => null);

  void setRest(int seconds) {
    final sec = seconds.clamp(15, 600);
    final until = state.restUntil;
    state = state.copyWith(
      restSec: sec,
      restUntil: until == null ? null : () => until.add(Duration(seconds: sec - state.restSec)),
    );
  }

  void skipRest() => state = state.copyWith(restUntil: () => null);

  void startRoutine(Routine routine) {
    final exercises = StartRoutine.exercises(routine, state.history);
    state = state.copyWith(exercises: exercises, groups: {...state.groups, ...exercises.map((e) => e.group)}.toList());
  }

  Future<bool> saveRoutine(String name) async {
    final result = await ref.read(saveRoutineProvider)(name, state.exercises, existing: state.routines);
    if (!ref.mounted) return false;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          routines: [...state.routines.where((r) => r.id != value.id), value],
          routineError: () => null,
          notice: () => 'Saved routine “${value.name}”',
        );
        ref.invalidate(routinesProvider);
        return true;
      case Err(:final failure):
        state = state.copyWith(routineError: () => failure.message);
        return false;
    }
  }

  void clearRoutineError() => state = state.copyWith(routineError: () => null);

  Future<void> deleteRoutine(String id) async {
    final result = await ref.read(deleteRoutineProvider)(id);
    if (!ref.mounted) return;
    if (result case Ok()) {
      state = state.copyWith(routines: state.routines.where((r) => r.id != id).toList());
      ref.invalidate(routinesProvider);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../profile/profile_api.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/run.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../providers.dart';
import '../states/run_form_state.dart';

final runFormProvider = NotifierProvider.autoDispose.family<RunFormNotifier, RunFormState, String?>(
  RunFormNotifier.new,
);

class RunFormNotifier extends Notifier<RunFormState> {
  RunFormNotifier(this.id);

  final String? id;
  String? _originalDay;

  @override
  RunFormState build() {
    ref.listen(profileProvider, (_, _) {});
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    Future.microtask(_load);
    return RunFormState(
      day: dateOnly(now),
      startMinute: (minute - 30 - minute % 5).clamp(0, 24 * 60 - 1),
      title: _defaultTitle(now.hour),
      loading: id != null,
    );
  }

  static String _defaultTitle(int hour) => hour < 11
      ? 'Morning Run'
      : hour < 14
      ? 'Lunch Run'
      : hour < 19
      ? 'Evening Run'
      : 'Night Run';

  Future<void> _load() async {
    final profile = await ref.read(profileProvider.future);
    if (!ref.mounted) return;
    state = state.copyWith(weightKg: profile?.weightKg);
    final editing = id;
    if (editing == null) return;
    final result = await ref.read(getRunProvider)(editing);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final r?):
        _originalDay = r.draft ? null : r.day;
        state = state.copyWith(
          loading: false,
          source: r.source,
          isDraft: r.draft,
          title: r.title,
          type: r.type,
          day: dateOnly(r.startedAt),
          startMinute: r.startedAt.hour * 60 + r.startedAt.minute,
          kmText: r.km.toStringAsFixed(2),
          timeText: RunMetrics.clock(r.movingSec),
          paceText: formatPace(r.paceSecPerKm),
          effort: r.effort ?? 3,
          kcalText: r.kcalOverride?.toString() ?? '',
          elevationM: () => r.elevationM,
          weightKg: r.draft ? null : r.weightKg,
        );
      case Ok():
        state = state.copyWith(loading: false, error: () => 'This run no longer exists.');
      case Err(:final failure):
        state = state.copyWith(loading: false, error: () => failure.message);
    }
  }

  void setTitle(String v) => state = state.copyWith(title: v);
  void setType(RunType t) => state = state.copyWith(type: t);
  void setEffort(int e) => state = state.copyWith(effort: e);
  void setKcal(String v) => state = state.copyWith(kcalText: v);
  void setDay(DateTime d) => state = state.copyWith(day: dateOnly(d));
  void setStart(int minuteOfDay) => state = state.copyWith(startMinute: minuteOfDay);

  void setKm(String v) =>
      state = state.copyWith(kmText: v, paceText: RunMetrics.paceFor(v, state.timeText) ?? state.paceText);
  void setTime(String v) =>
      state = state.copyWith(timeText: v, paceText: RunMetrics.paceFor(state.kmText, v) ?? state.paceText);
  void setPace(String v) =>
      state = state.copyWith(paceText: v, timeText: RunMetrics.timeForPace(state.kmText, v) ?? state.timeText);

  void stepKm(int dir) {
    final next = ((state.km ?? 0) * 10).round() + dir;
    setKm((next < 1 ? 0.1 : next / 10).toStringAsFixed(2));
  }

  void stepTime(int dir) {
    final next = (state.seconds ?? 0) + dir * 15;
    setTime(RunMetrics.clock(next < 60 ? 60 : next));
  }

  Future<void> switchToManual() async {
    if (!state.locked) return;
    if (state.isDraft && id != null) await ref.read(deleteRunProvider)(id!);
    if (!ref.mounted) return;
    state = state.copyWith(source: RunSource.manual, isDraft: false, elevationM: () => null);
  }

  Future<void> save() async {
    if (state.saving || state.loading) return;
    state = state.copyWith(showErrors: true, saving: true, error: () => null);
    final keepId = state.locked || (id != null && !state.isDraft && _originalDay != null) ? id : null;
    final result = await ref.read(saveRunProvider)(
      id: keepId,
      title: state.title,
      type: state.type,
      source: state.source,
      kmText: state.kmText,
      timeText: state.timeText,
      startedAt: state.startedAt,
      weightKg: state.weightKg,
      effort: state.effort,
      kcalText: state.kcalText,
      elevationM: state.elevationM,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        invalidateDay(ref, value.day);
        if (_originalDay != null && _originalDay != value.day) invalidateDay(ref, _originalDay!);
        ref
          ..invalidate(runProvider(value.id))
          ..invalidate(personalRecordsProvider);
        state = state.copyWith(saving: false, savedId: value.id);
      case Err(failure: ValidationFailure()):
        state = state.copyWith(saving: false);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
    }
  }
}

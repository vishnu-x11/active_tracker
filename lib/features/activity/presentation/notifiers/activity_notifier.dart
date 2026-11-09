import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../progress/progress.dart';
import '../states/activity_state.dart';
import '../states/activity_view.dart';

final activityProvider = NotifierProvider<ActivityNotifier, ActivityState>(ActivityNotifier.new);

class ActivityNotifier extends Notifier<ActivityState> {
  @override
  ActivityState build() => const ActivityState();

  void setFilter(ActivityFilter f) => state = state.copyWith(filter: f);

  void pickDay(DateTime day) {
    final selected = ref.read(selectedDayProvider);
    if (!state.allDays && dayKey(selected) == dayKey(day)) {
      state = state.copyWith(allDays: true);
      return;
    }
    ref.read(selectedDayProvider.notifier).select(day);
    state = state.copyWith(allDays: false);
  }

  void showAll() => state = state.copyWith(allDays: true);

  void goToday() {
    ref.read(selectedDayProvider.notifier).today();
    state = state.copyWith(allDays: false);
  }
}

final _rangeActivitiesProvider = Provider.autoDispose<AsyncValue<List<ActivityItem>>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(activitiesProvider((dayKey(ActivityView.rangeStart(today)), dayKey(today))));
});

final activityViewProvider = Provider.autoDispose<AsyncValue<ActivityView>>((ref) {
  final state = ref.watch(activityProvider);
  final selected = ref.watch(selectedDayProvider);
  final today = ref.watch(todayProvider);
  return ref
      .watch(_rangeActivitiesProvider)
      .whenData((items) => ActivityView.from(items: items, state: state, selected: selected, today: today));
});

final stripActiveDaysProvider = Provider.autoDispose<Set<String>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(activeDaysProvider((dayKey(ActivityView.rangeStart(today)), dayKey(today)))).value ?? const {};
});

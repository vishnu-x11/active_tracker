import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/result.dart';
import '../../progress/progress.dart';
import '../data/data_sources/reminder_scheduler.dart';
import '../data/repositories/reminders_repository_impl.dart';
import '../domain/entities/reminder_settings.dart';
import '../domain/repositories/reminders_repository.dart';
import '../domain/use_cases/plan_reminders.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalNotificationScheduler());

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepositoryImpl(ref.watch(appDatabaseProvider), ref.watch(reminderSchedulerProvider)),
);

final reminderSettingsProvider = AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async => (await ref.watch(remindersRepositoryProvider).load()).valueOrThrow();

  Future<void> change(ReminderSettings Function(ReminderSettings) apply) async {
    final current = state.value;
    if (current == null) return;
    final next = apply(current);
    state = AsyncData(next);
    if (next.problem != null) return;
    if (next.activeCount > current.activeCount || current.activeCount == 0) {
      await ref.read(remindersRepositoryProvider).requestPermission();
    }
    await ref.read(remindersRepositoryProvider).save(next);
  }
}

final reminderPlannerProvider = NotifierProvider<ReminderPlanner, DateTime?>(ReminderPlanner.new);

class ReminderPlanner extends Notifier<DateTime?> {
  Timer? _debounce;
  bool _started = false;

  @override
  DateTime? build() {
    ref.onDispose(() => _debounce?.cancel());
    return null;
  }

  static const firstDelay = Duration(seconds: 8);

  void start() {
    if (_started) return;
    _started = true;
    _debounce = Timer(firstDelay, () => _listen());
  }

  void _listen() {
    void later(Object? _, Object? _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), () => unawaited(plan()));
    }

    ref
      ..listen(reminderSettingsProvider, later)
      ..listen(currentUidProvider, later)
      ..listen(todayProvider, later, fireImmediately: true);
    ref.listen(todayProvider, (_, today) {
      final day = dayKey(today);
      ref
        ..listen(dayTotalsProvider(day), later)
        ..listen(dayTargetsProvider(day), later)
        ..listen(streakProvider, later);
    }, fireImmediately: true);
  }

  Future<void> plan() async {
    final settings = ref.read(reminderSettingsProvider).value;
    if (settings == null || settings.problem != null) return;
    final signedIn = ref.read(currentUidProvider).value != null;
    final day = dayKey(ref.read(todayProvider));
    final totals = ref.read(dayTotalsProvider(day)).value;
    final targets = ref.read(dayTargetsProvider(day)).value;
    final status = (
      waterMl: totals?.waterMl ?? 0,
      waterTarget: targets?.waterMl,
      proteinG: totals?.proteinG ?? 0,
      proteinTarget: targets?.proteinG,
      workedOut: totals?.isWorkoutDay ?? false,
      streak: ref.read(streakProvider).value?.current ?? 0,
    );
    final planned = signedIn ? PlanReminders.call(settings, status, DateTime.now()) : const <PlannedReminder>[];
    final result = await ref.read(remindersRepositoryProvider).schedule(planned);
    if (ref.mounted && result is Ok<void>) state = DateTime.now();
  }
}

final suggestedWorkoutDaysProvider = Provider.autoDispose<List<int>>((ref) {
  final today = ref.watch(todayProvider);
  final since = dayKey(addDays(today, -28));
  final counts = <int, int>{};
  for (final a in ref.watch(allActivitiesProvider).value ?? const <ActivityItem>[]) {
    if (a.day.compareTo(since) >= 0) counts.update(a.startedAt.weekday, (v) => v + 1, ifAbsent: () => 1);
  }
  return (counts.entries.where((e) => e.value >= 2).map((e) => e.key).toList()..sort());
});

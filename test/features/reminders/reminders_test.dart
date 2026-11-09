import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/reminders/data/data_sources/reminder_scheduler.dart';
import 'package:active_tracker/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:active_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:active_tracker/features/reminders/domain/use_cases/plan_reminders.dart';
import 'package:active_tracker/features/reminders/presentation/providers.dart';
import 'package:active_tracker/features/reminders/reminders_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';

class FakeScheduler implements ReminderScheduler {
  List<PlannedReminder> scheduled = [];
  int asked = 0;

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async => scheduled = plan;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return true;
  }
}

void main() {
  sqfliteFfiInit();
  final now = DateTime(2026, 11, 5, 10, 30);
  const behind = (waterMl: 500, waterTarget: 3125, proteinG: 40.0, proteinTarget: 120, workedOut: false, streak: 4);

  test('today: water every 2 h from the next slot, protein, workout (Thu), streak at risk', () {
    final plan = PlanReminders.call(const ReminderSettings(), behind, now);
    final today = plan.where((r) => r.at.day == 5).toList();
    expect(today.where((r) => r.title == 'Time for some water').map((r) => r.at.hour), [11, 13, 15, 17, 19, 21]);
    expect(today.where((r) => r.title == 'Protein check').single.body, contains('40 of 120 g'));
    expect(today.where((r) => r.title == 'Workout day'), hasLength(1));
    expect(today.where((r) => r.title == 'Streak at risk').single.body, contains('4-day streak'));
    expect(plan.every((r) => r.at.isAfter(now)), isTrue);
    expect(plan.map((r) => r.id).toSet().length, plan.length);
  });

  test('targets met or workout logged: those nudges are dropped for today only', () {
    const done = (waterMl: 3200, waterTarget: 3125, proteinG: 130.0, proteinTarget: 120, workedOut: true, streak: 5);
    final plan = PlanReminders.call(const ReminderSettings(), done, now);
    final today = plan.where((r) => r.at.day == 5);
    expect(today, isEmpty);
    expect(plan.where((r) => r.at.day == 6 && r.title == 'Time for some water'), isNotEmpty);
  });

  test('workout only on picked days; weekly report on Monday; off means none', () {
    final plan = PlanReminders.call(const ReminderSettings(), behind, now);
    expect(plan.where((r) => r.title == 'Workout day').map((r) => r.at.weekday).toSet(), {1, 3, 4});
    expect(plan.where((r) => r.title.startsWith('Your weekly')).single.at, DateTime(2026, 11, 9, 8));
    const off = ReminderSettings(waterOn: false, proteinOn: false, workoutOn: false, streakOn: false, weeklyOn: false);
    expect(PlanReminders.call(off, behind, now), isEmpty);
  });

  test('settings are saved and read back; bad combinations are reported', () async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    final repo = RemindersRepositoryImpl(db, FakeScheduler());
    const s = ReminderSettings(waterFrom: 8 * 60, workoutDays: {2, 6}, weeklyOn: false);
    await repo.save(s);
    expect((await repo.load()).valueOrNull, s);
    expect(s.copyWith(waterTo: 7 * 60).problem, 'Water nudges: the end time must be after the start time.');
    expect(s.copyWith(workoutDays: {}).problem, 'Pick at least one day for workout reminders.');
  });

  testWidgets('switches save at once; an empty day list is shown, not saved', (tester) async {
    final scheduler = FakeScheduler();
    final db = await pumpFeature(
      tester,
      routes: [ReminderRoutes.route],
      initial: ReminderRoutes.reminders,
      height: 5000,
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    );
    await settleWithIo(tester);
    expect(find.text('5  of 5 reminders on'), findsOneWidget);
    expect(find.textContaining('Quiet'), findsNothing);

    await tester.tap(find.byType(Switch).first);
    await settleWithIo(tester);
    expect(find.text('4  of 5 reminders on'), findsOneWidget);

    for (final d in ['Monday', 'Wednesday', 'Thursday']) {
      await tester.tap(find.bySemanticsLabel(d));
      await settleWithIo(tester);
    }
    expect(find.text('Pick at least one day for workout reminders.'), findsOneWidget);
    final saved = await tester.runAsync(() => db.setting('reminders'));
    expect(saved, contains('"waterOn":false'));
    expect(saved, contains('"workoutDays":[4]'));
  });
}

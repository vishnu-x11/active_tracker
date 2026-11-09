import '../../../../core/dates.dart';
import '../entities/reminder_settings.dart';

abstract final class PlanReminders {
  static const days = 7;

  static List<PlannedReminder> call(ReminderSettings s, TodayStatus today, DateTime now) {
    final out = <PlannedReminder>[];
    final midnight = dateOnly(now);
    void add(int id, DateTime at, String title, String body) {
      if (at.isAfter(now)) out.add(PlannedReminder(id: id, at: at, title: title, body: body));
    }

    for (var d = 0; d < days; d++) {
      final day = addDays(midnight, d);
      DateTime at(int minute) => day.add(Duration(minutes: minute));
      final isToday = d == 0;

      if (s.waterOn && !(isToday && today.waterTarget != null && today.waterMl >= today.waterTarget!)) {
        var i = 0;
        for (var m = s.waterFrom; m <= s.waterTo && i < 12; m += 120, i++) {
          add(
            1000 + d * 20 + i,
            at(m),
            'Time for some water',
            isToday && today.waterTarget != null
                ? '${today.waterMl} of ${today.waterTarget} ml so far today.'
                : 'A glass now keeps you on track for today.',
          );
        }
      }
      if (s.proteinOn && !(isToday && today.proteinTarget != null && today.proteinG >= today.proteinTarget!)) {
        add(
          2000 + d,
          at(s.proteinAt),
          'Protein check',
          isToday && today.proteinTarget != null
              ? '${today.proteinG.round()} of ${today.proteinTarget} g so far. A protein snack closes the gap.'
              : 'Check how close you are to your protein target.',
        );
      }
      if (s.workoutOn && s.workoutDays.contains(day.weekday) && !(isToday && today.workedOut)) {
        add(3000 + d, at(s.workoutAt), 'Workout day', 'Nothing logged yet today. A gym session or a run?');
      }
      if (isToday && s.streakOn && today.streak > 0 && !today.workedOut) {
        add(
          4000,
          at(s.streakAt),
          'Streak at risk',
          'Your ${today.streak}-day streak ends tonight. Log a workout to keep it.',
        );
      }
      if (s.weeklyOn && day.weekday == DateTime.monday) {
        add(5000 + d, at(s.weeklyAt), 'Your weekly report is ready', 'See last week: burn, runs, gym and targets hit.');
      }
    }
    return out;
  }
}

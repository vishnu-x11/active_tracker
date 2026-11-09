import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../domain/entities/reminder_settings.dart';
import '../providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(reminderSettingsProvider).value;
    final n = ref.read(reminderSettingsProvider.notifier);
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: s == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    FormHeader(title: 'Reminders', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    Text('ACTIVE', style: AppText.eyebrow.copyWith(color: p.sub)),
                    Text.rich(
                      TextSpan(
                        text: '${s.activeCount}',
                        children: [
                          TextSpan(
                            text: '  of 5 reminders on',
                            style: AppText.title.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                      style: AppText.display.copyWith(fontSize: 34, color: p.text),
                    ),
                    if (s.problem != null) ...[const SizedBox(height: 10), FormMessage(text: s.problem!)],
                    const SizedBox(height: 16),
                    Text('NUDGES', style: AppText.eyebrow.copyWith(color: p.sub)),
                    const SizedBox(height: 8),
                    Glass(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          _Nudge(
                            icon: Icons.water_drop_rounded,
                            colors: Metric.water,
                            name: 'Water nudges',
                            detail:
                                'Every 2 h from ${_t(s.waterFrom)} to ${_t(s.waterTo)}, only when you are behind target',
                            on: s.waterOn,
                            onToggle: (v) => n.change((x) => x.copyWith(waterOn: v)),
                            times: [
                              ('From', s.waterFrom, (m) => n.change((x) => x.copyWith(waterFrom: m))),
                              ('To', s.waterTo, (m) => n.change((x) => x.copyWith(waterTo: m))),
                            ],
                          ),
                          _Nudge(
                            icon: Icons.egg_alt_rounded,
                            colors: Metric.protein,
                            name: 'Protein check',
                            detail: '${_t(s.proteinAt)} if you are under your protein target',
                            on: s.proteinOn,
                            onToggle: (v) => n.change((x) => x.copyWith(proteinOn: v)),
                            times: [('At', s.proteinAt, (m) => n.change((x) => x.copyWith(proteinAt: m)))],
                          ),
                          _Nudge(
                            icon: Icons.fitness_center_rounded,
                            colors: Metric.burn,
                            name: 'Workout reminder',
                            detail: 'On your workout days at ${_t(s.workoutAt)}, if nothing is logged yet',
                            on: s.workoutOn,
                            onToggle: (v) => n.change((x) => x.copyWith(workoutOn: v)),
                            times: const [],
                          ),
                          _Nudge(
                            icon: Icons.local_fire_department_rounded,
                            colors: Metric.burn,
                            name: 'Streak at risk',
                            detail: '${_t(s.streakAt)} when today would break your streak',
                            on: s.streakOn,
                            onToggle: (v) => n.change((x) => x.copyWith(streakOn: v)),
                            times: [('At', s.streakAt, (m) => n.change((x) => x.copyWith(streakAt: m)))],
                          ),
                          _Nudge(
                            icon: Icons.calendar_month_rounded,
                            colors: Metric.run,
                            name: 'Weekly report',
                            detail: 'Monday ${_t(s.weeklyAt)}',
                            on: s.weeklyOn,
                            onToggle: (v) => n.change((x) => x.copyWith(weeklyOn: v)),
                            times: [('Monday at', s.weeklyAt, (m) => n.change((x) => x.copyWith(weeklyAt: m)))],
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: s.workoutOn ? 1 : 0.45,
                      child: _WorkoutDays(settings: s),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _t(int minute) => clockTime(DateTime(2000).add(Duration(minutes: minute)));
}

class _Nudge extends StatelessWidget {
  const _Nudge({
    required this.icon,
    required this.colors,
    required this.name,
    required this.detail,
    required this.on,
    required this.onToggle,
    required this.times,
    this.last = false,
  });

  final IconData icon;
  final List<Color> colors;
  final String name;
  final String detail;
  final bool on;
  final ValueChanged<bool> onToggle;
  final List<(String, int, ValueChanged<int>)> times;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.hair)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: icon, colors: colors, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                    ),
                    Text(detail, style: AppText.small.copyWith(fontSize: 12, color: p.sub)),
                  ],
                ),
              ),
              Switch(value: on, onChanged: onToggle, activeThumbColor: Colors.white, activeTrackColor: Metric.cta.last),
            ],
          ),
          if (on && times.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Row(
                children: [
                  for (final (i, (label, minute, set)) in times.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: PickerField(
                        label: label,
                        value: RemindersScreen._t(minute),
                        icon: Icons.schedule_rounded,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
                          );
                          if (t != null) set(t.hour * 60 + t.minute);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutDays extends ConsumerWidget {
  const _WorkoutDays({required this.settings});

  final ReminderSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final n = ref.read(reminderSettingsProvider.notifier);
    final suggested = ref.watch(suggestedWorkoutDaysProvider);
    final days = (settings.workoutDays.toList()..sort()).map((d) => weekdayShort[d - 1]).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('WORKOUT DAYS', style: AppText.eyebrow.copyWith(color: p.sub)),
        const SizedBox(height: 8),
        Glass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remind me at',
                          style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                        ),
                        Text(
                          days.isEmpty ? 'No days picked' : '$days · ${RemindersScreen._t(settings.workoutAt)}',
                          style: AppText.small.copyWith(fontSize: 12, color: p.sub),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: PickerField(
                      label: 'Time',
                      value: RemindersScreen._t(settings.workoutAt),
                      icon: Icons.schedule_rounded,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: settings.workoutAt ~/ 60, minute: settings.workoutAt % 60),
                        );
                        if (t != null) await n.change((x) => x.copyWith(workoutAt: t.hour * 60 + t.minute));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var d = 1; d <= 7; d++) ...[
                    if (d > 1) const SizedBox(width: 6),
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: settings.workoutDays.contains(d),
                        label: weekdayLong(DateTime(2024, 1, d)),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => n.change((x) {
                            final next = {...x.workoutDays};
                            next.contains(d) ? next.remove(d) : next.add(d);
                            return x.copyWith(workoutDays: next);
                          }),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: settings.workoutDays.contains(d)
                                  ? const LinearGradient(colors: Metric.cta)
                                  : null,
                              color: settings.workoutDays.contains(d) ? null : p.text.withValues(alpha: 0.06),
                            ),
                            child: Text(
                              weekdayShort[d - 1][0],
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: settings.workoutDays.contains(d) ? Colors.white : p.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                suggested.isEmpty
                    ? 'Log a few workouts and we will suggest your usual days.'
                    : 'Suggested from your last 4 weeks: ${suggested.map((d) => weekdayShort[d - 1]).join(', ')}.',
                style: AppText.small.copyWith(fontSize: 12, color: p.sub),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/segmented.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/use_cases/progress_rules.dart';
import '../../progress_routes.dart';
import '../progress_providers.dart';
import '../widgets/activity_calendar.dart';

enum _Period { week, month, year }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _Period _period = _Period.month;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final all = ref.watch(allActivitiesProvider).value ?? const <ActivityItem>[];
    final from = switch (_period) {
      _Period.week => dayKey(mondayOf(today)),
      _Period.month => dayKey(DateTime(today.year, today.month)),
      _Period.year => dayKey(DateTime(today.year)),
    };
    final runs = all.where((a) => a.type == ActivityType.run && a.day.compareTo(from) >= 0).toList();
    final km = runs.fold(0.0, (a, r) => a + r.km);
    final secs = runs.fold(0, (a, r) => a + (r.movingSec ?? 0));
    final streak = ref.watch(streakProvider).value;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, tabBarInset),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Running · ${shortDate(today)}',
                      style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                    ),
                    Text('Progress', style: AppText.display.copyWith(color: p.text)),
                  ],
                ),
              ),
              for (final a in widget.actions) ...[a, const SizedBox(width: 8)],
              GlassIconButton(
                icon: Icons.flag_rounded,
                tooltip: 'Goals',
                onPressed: () => context.push(ProgressRoutes.goals),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icons.bar_chart_rounded,
                tooltip: 'Weekly report',
                onPressed: () => context.push(ProgressRoutes.week),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassSegmented<_Period>(
            options: const [(_Period.week, 'Week'), (_Period.month, 'Month'), (_Period.year, 'Year')],
            value: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 16),
          Glass(
            radius: 28,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => context.push(ProgressRoutes.streaks),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const IconTile(icon: Icons.local_fire_department_rounded, colors: Metric.burn, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACTIVE STREAK', style: AppText.eyebrow.copyWith(color: p.sub)),
                          Text.rich(
                            TextSpan(
                              text: '${streak?.current ?? 0}',
                              children: [
                                TextSpan(
                                  text: ' days',
                                  style: AppText.title.copyWith(color: p.sub),
                                ),
                              ],
                            ),
                            style: AppText.display.copyWith(fontSize: 34, color: p.text),
                          ),
                          Text(
                            'Best ${streak?.best ?? 0} days · ${(streak?.current ?? 0) > 0 ? 'keep it going!' : 'log a workout to start one'}',
                            style: AppText.small.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.sub),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.directions_run_rounded,
                  colors: Metric.run,
                  value: '${runs.length}',
                  label: 'Runs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.route_rounded,
                  colors: Metric.run,
                  value: km.toStringAsFixed(1),
                  unit: 'km',
                  label: 'Distance',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.schedule_rounded,
                  colors: Metric.run,
                  value: secs >= 3600 ? '${secs ~/ 3600}h ${(secs % 3600) ~/ 60}m' : '${secs ~/ 60}m',
                  label: 'Time',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActivityCalendar(today: today),
          const SizedBox(height: 20),
          _Achievements(all: all),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.all});

  final List<ActivityItem> all;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final list = ProgressRules.achievements(all);
    final earned = list.where((a) => a.earned).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Achievements',
            children: [
              TextSpan(
                text: ' $earned of ${list.length}',
                style: TextStyle(fontWeight: FontWeight.w500, color: p.sub),
              ),
            ],
          ),
          style: AppText.section.copyWith(color: p.text),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(190),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = list[i];
              return SizedBox(
                width: 124,
                child: Semantics(
                  container: true,
                  label: '${a.name}, ${a.description}, ${a.earned ? 'earned' : a.progress}',
                  excludeSemantics: true,
                  child: Glass(
                    blur: false,
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: a.earned ? const LinearGradient(colors: Metric.burn) : null,
                            color: a.earned ? null : p.text.withValues(alpha: 0.08),
                            boxShadow: a.earned
                                ? [
                                    BoxShadow(
                                      color: Metric.burn.last.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(Icons.emoji_events_rounded, color: a.earned ? Colors.white : p.sub),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.name,
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                        ),
                        Flexible(
                          child: Text(
                            a.description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.tab.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          a.earned ? 'Earned' : a.progress,
                          style: AppText.tab.copyWith(color: a.earned ? p.accentText : p.sub),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../profile/profile_api.dart';
import '../../../../core/widgets/buttons.dart';
import '../../domain/entities/daily_targets.dart';
import '../../domain/entities/day_totals.dart';
import '../progress_providers.dart';
import '../providers.dart';

final _n = NumberFormat.decimalPattern('en_US');

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  int _back = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final monday = addDays(mondayOf(today), -7 * _back);
    final sunday = addDays(monday, 6);
    final week = ref.watch(weekBurnProvider(dayKey(monday))).value;
    final days = ref.watch(daySummariesProvider((dayKey(monday), dayKey(sunday)))).value ?? const {};
    final runs = ref.watch(activitiesProvider((dayKey(monday), dayKey(sunday)))).value ?? const [];
    final profile = ref.watch(profileProvider).value;
    final burns = week?.days ?? List.filled(7, 0);
    final top = burns.fold(0, (a, b) => a > b ? a : b);
    final best = top == 0 ? null : burns.indexOf(top);
    final gym = days.values.fold(0, (a, t) => a + t.gymCount);
    final km = runs.where((a) => a.km > 0).fold(0.0, (a, r) => a + r.km);
    int hit(bool Function(DailyTargets, DayTotals) ok) => profile == null
        ? 0
        : days.values.where((t) => ok(DailyTargets.forDay(profile, workoutDay: t.isWorkoutDay), t)).length;
    final proteinDays = hit((tg, t) => t.proteinG >= tg.proteinG);
    final waterDays = hit((tg, t) => t.waterMl >= tg.waterMl);
    final change = week?.changePct;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Weekly report', onBack: () => context.pop()),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: _back < 52 ? () => setState(() => _back++) : null,
                    icon: Icon(Icons.chevron_left_rounded, color: p.text),
                  ),
                  Expanded(
                    child: Text(
                      '${monday.day} ${monthShort[monday.month - 1]} – ${sunday.day} ${monthShort[sunday.month - 1]}',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: _back > 0 ? () => setState(() => _back--) : null,
                    icon: Icon(Icons.chevron_right_rounded, color: _back > 0 ? p.text : p.hair),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Glass(
                radius: 32,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BURNED THIS WEEK', style: AppText.eyebrow.copyWith(color: p.sub)),
                    Text.rich(
                      TextSpan(
                        text: _n.format(week?.total ?? 0),
                        children: [
                          TextSpan(
                            text: ' kcal',
                            style: AppText.title.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                      style: AppText.hero.copyWith(fontSize: 46, color: p.text),
                    ),
                    if (change != null)
                      Text(
                        '${change >= 0 ? '+' : ''}$change% vs the week before',
                        style: AppText.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: change >= 0 ? p.goodFg : p.sub,
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 7; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                label: '${weekdayShort[i]} ${burns[i]} kcal${i == best ? ', best day' : ''}',
                                excludeSemantics: true,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (burns[i] > 0)
                                      FittedBox(
                                        child: Text('${burns[i]}', style: AppText.tab.copyWith(color: p.sub)),
                                      ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      height: top == 0 ? 6 : (burns[i] / top * 110).clamp(6, 110).toDouble(),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: i == best
                                            ? const LinearGradient(
                                                colors: Metric.burn,
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : null,
                                        color: i == best ? null : p.text.withValues(alpha: burns[i] > 0 ? 0.14 : 0.06),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(weekdayShort[i][0], style: AppText.tab.copyWith(color: p.sub)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(112),
                ),
                children: [
                  StatTile(
                    icon: Icons.fitness_center_rounded,
                    colors: Metric.burn,
                    value: '$gym',
                    label: 'Gym sessions',
                  ),
                  StatTile(
                    icon: Icons.route_rounded,
                    colors: Metric.run,
                    value: km.toStringAsFixed(1),
                    unit: 'km',
                    label: 'Running',
                  ),
                  StatTile(
                    icon: Icons.egg_alt_rounded,
                    colors: Metric.protein,
                    value: '$proteinDays/7',
                    label: 'Protein target days',
                  ),
                  StatTile(
                    icon: Icons.water_drop_rounded,
                    colors: Metric.water,
                    value: '$waterDays/7',
                    label: 'Water target days',
                  ),
                ],
              ),
              if (best != null) ...[
                const SizedBox(height: 12),
                Glass(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.emoji_events_rounded, colors: Metric.burn),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Best day: ${weekdayLong(addDays(monday, best))}, ${_n.format(top)} kcal',
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

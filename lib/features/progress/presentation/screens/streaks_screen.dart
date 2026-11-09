import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../progress_providers.dart';

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final streak = ref.watch(streakProvider).value;
    final first = DateTime(today.year, today.month), last = DateTime(today.year, today.month + 1, 0);
    final days = ref.watch(daySummariesProvider((dayKey(first), dayKey(last)))).value ?? const {};
    final active = days.values.where((t) => t.workouts > 0).length;
    Color heat(int kcal) => kcal >= 900
        ? Metric.burn.last
        : kcal >= 500
        ? Metric.burn.first
        : kcal > 0
        ? Metric.burn.first.withValues(alpha: 0.4)
        : p.text.withValues(alpha: 0.06);
    final lead = first.weekday - 1;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Streaks', onBack: () => context.pop()),
              const SizedBox(height: 16),
              Glass(
                radius: 32,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const IconTile(icon: Icons.local_fire_department_rounded, colors: Metric.burn, size: 64),
                    const SizedBox(height: 12),
                    Text('${streak?.current ?? 0}', style: AppText.hero.copyWith(fontSize: 64, color: p.text)),
                    Text('day streak', style: AppText.title.copyWith(color: p.sub)),
                    const SizedBox(height: 6),
                    Text(
                      'A day counts when you log a gym session or a run. Today can still be logged.',
                      textAlign: TextAlign.center,
                      style: AppText.small.copyWith(color: p.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.emoji_events_rounded,
                      colors: Metric.burn,
                      value: '${streak?.best ?? 0}',
                      label: 'Best streak',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.event_available_rounded,
                      colors: Metric.run,
                      value: '$active',
                      label: 'Active days in ${monthShort[today.month - 1]}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${monthLong[today.month - 1]} ${today.year}', style: AppText.section.copyWith(color: p.text)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final w in weekdayShort)
                          Expanded(
                            child: Center(
                              child: Text(w, style: AppText.tab.copyWith(color: p.sub)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [
                        for (var i = 0; i < lead; i++) const SizedBox(),
                        for (var d = first; !d.isAfter(last); d = addDays(d, 1))
                          Semantics(
                            label: '${d.day} ${monthLong[d.month - 1]}, ${days[dayKey(d)]?.burnKcal ?? 0} kcal',
                            excludeSemantics: true,
                            child: Opacity(
                              opacity: d.isAfter(today) ? 0.4 : 1,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: heat(days[dayKey(d)]?.burnKcal ?? 0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: dayKey(d) == dayKey(today) ? Border.all(color: p.accentText, width: 2) : null,
                                ),
                                child: Text('${d.day}', style: AppText.tab.copyWith(color: p.text)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        for (final (label, kcal) in [('Under 500', 1), ('500-900', 500), ('900+ kcal', 900)])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: heat(kcal), borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 6),
                              Text(label, style: AppText.tab.copyWith(fontSize: 12, color: p.sub)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

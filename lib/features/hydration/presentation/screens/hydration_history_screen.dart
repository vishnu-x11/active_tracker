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
import '../../../progress/progress.dart';
import '../widgets/goal_ring.dart';

final _n = NumberFormat.decimalPattern('en_US');

class HydrationHistoryScreen extends ConsumerStatefulWidget {
  const HydrationHistoryScreen({super.key});

  @override
  ConsumerState<HydrationHistoryScreen> createState() => _HydrationHistoryScreenState();
}

class _HydrationHistoryScreenState extends ConsumerState<HydrationHistoryScreen> {
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    var days = [for (var i = 0; i < 7; i++) addDays(today, -i)];
    if (!_newestFirst) days = days.reversed.toList();
    final week = [for (final d in days) ref.watch(dayTotalsProvider(dayKey(d)).select((v) => v.value?.waterMl ?? 0))];
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Hydration History', onBack: () => context.pop()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Last 7 days',
                        children: [
                          TextSpan(
                            text: ' · ${(week.fold(0, (a, b) => a + b) / 1000).toStringAsFixed(1)} L',
                            style: TextStyle(fontWeight: FontWeight.w500, color: p.sub),
                          ),
                        ],
                      ),
                      style: AppText.section.copyWith(color: p.text),
                    ),
                  ),
                  Glass(
                    kind: GlassKind.control,
                    radius: 22,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => setState(() => _newestFirst = !_newestFirst),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              _newestFirst ? 'Newest first' : 'Oldest first',
                              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.text),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.swap_vert_rounded, size: 16, color: p.accentText),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 0,
                runSpacing: 6,
                children: [
                  for (final (name, color) in [
                    ('WATER', Metric.waterDot),
                    ('BURN', Metric.burnDot),
                    ('PROTEIN', Metric.proteinDot),
                  ]) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(name, style: AppText.eyebrow.copyWith(color: p.sub)),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              for (final d in days) ...[_DayCard(day: d, today: today), const SizedBox(height: 12)],
              Text(
                'History keeps the last 7 days. Older days still count towards streaks and the weekly report.',
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(color: p.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final key = dayKey(day);
    final totals = ref.watch(dayTotalsProvider(key)).value;
    final targets = ref.watch(dayTargetsProvider(key)).value;
    int pct(num v, int? t) => t == null || t == 0 ? 0 : (v * 100 / t).round();
    final ring = MediaQuery.sizeOf(context).width < 360 ? 40.0 : 48.0;
    return Glass(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key == dayKey(today) ? 'Today, ${day.day} ${monthShort[day.month - 1]}' : shortDate(day),
            style: AppText.cardTitle.copyWith(fontSize: 15, color: p.text),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          text: _n.format(totals?.waterMl ?? 0),
                          children: [
                            TextSpan(
                              text: ' ml',
                              style: AppText.body.copyWith(color: p.sub),
                            ),
                          ],
                        ),
                        style: AppText.display.copyWith(color: p.text),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DayKindLabel(workouts: totals?.workouts ?? 0),
                  ],
                ),
              ),
              GoalRing(
                label: 'Water',
                size: ring,
                pct: pct(totals?.waterMl ?? 0, targets?.waterMl),
                colors: Metric.water,
                track: p.tracks[1],
              ),
              const SizedBox(width: 8),
              GoalRing(
                label: 'Burn',
                size: ring,
                pct: pct(totals?.burnKcal ?? 0, targets?.burnKcal),
                colors: Metric.burn,
                track: p.tracks[0],
              ),
              const SizedBox(width: 8),
              GoalRing(
                label: 'Protein',
                size: ring,
                pct: pct(totals?.proteinG ?? 0, targets?.proteinG),
                colors: Metric.protein,
                track: p.tracks[2],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

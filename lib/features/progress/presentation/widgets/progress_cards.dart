import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/result.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/line_chart.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/goal.dart';
import '../../domain/use_cases/training_log.dart';
import '../../progress_routes.dart';
import '../progress_providers.dart';
import '../providers.dart';
import 'log_dot.dart';

class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.all, required this.today});

  final List<ActivityItem> all;
  final DateTime today;

  static const weeks = 13;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  TrendMetric _metric = TrendMetric.distance;

  String _fmt(double v) => switch (_metric) {
    TrendMetric.distance => '${v.toStringAsFixed(1)} km',
    TrendMetric.time => TrainingLog.hm(v.round()),
    TrendMetric.burn => '${v.round()} kcal',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = TrainingLog.trend(widget.all, widget.today, TrendCard.weeks, _metric);
    final first = addDays(mondayOf(widget.today), -7 * (TrendCard.weeks - 1));
    final labels = <int, String>{
      for (var i = 0; i < TrendCard.weeks; i++)
        if (addDays(first, 7 * i).day <= 7) i: monthShort[addDays(first, 7 * i).month - 1],
    };
    return Glass(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('LAST 3 MONTHS', style: AppText.eyebrow.copyWith(color: p.sub)),
          Text.rich(
            TextSpan(
              text: _fmt(values.last),
              children: [
                TextSpan(
                  text: ' this week',
                  style: AppText.title.copyWith(color: p.sub),
                ),
              ],
            ),
            style: AppText.display.copyWith(fontSize: 26, color: p.text),
          ),
          const SizedBox(height: 10),
          GlassSegmented<TrendMetric>(
            options: const [(TrendMetric.distance, 'Distance'), (TrendMetric.time, 'Time'), (TrendMetric.burn, 'Burn')],
            value: _metric,
            onChanged: (v) => setState(() => _metric = v),
          ),
          const SizedBox(height: 12),
          TrendLine(
            values: values,
            color: _metric == TrendMetric.burn ? Metric.burnDot : Metric.runDot,
            labels: labels,
            marker: _fmt(values.last),
            semantics: 'Weekly ${_metric.name} for the last ${TrendCard.weeks} weeks, this week ${_fmt(values.last)}',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(ProgressRoutes.week),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('See more of your progress'),
            ),
          ),
        ],
      ),
    );
  }
}

class LogSummaryCard extends StatelessWidget {
  const LogSummaryCard({super.key, required this.all, required this.today});

  final List<ActivityItem> all;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final weeks = TrainingLog.weeks(all, today, 2, ActivityFilter.all);
    return TapGlass(
      onTap: () => context.push(ProgressRoutes.log),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('TRAINING LOG', style: AppText.eyebrow.copyWith(color: p.sub)),
              ),
              Icon(Icons.chevron_right_rounded, color: p.sub),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: 'This week ',
              style: AppText.body.copyWith(color: p.sub),
              children: [
                TextSpan(
                  text: TrainingLog.hm(weeks.first.minutes),
                  style: AppText.number.copyWith(color: p.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [for (final d in weeks.first.days) Expanded(child: LogDot(day: d, scale: 0.8))],
          ),
          Row(
            children: [
              for (final w in weekdayShort)
                Expanded(
                  child: Center(
                    child: Text(w[0], style: AppText.tab.copyWith(color: p.sub)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Last week ${TrainingLog.hm(weeks.last.minutes)}', style: AppText.small.copyWith(color: p.sub)),
        ],
      ),
    );
  }
}

class SuggestedGoalCard extends ConsumerWidget {
  const SuggestedGoalCard({super.key, required this.all, required this.today});

  final List<ActivityItem> all;
  final DateTime today;

  Future<void> _set(BuildContext context, WidgetRef ref, int minutes) async {
    final goal = Goal(
      id: ref.read(newIdProvider)(),
      kind: GoalKind.runTime,
      period: GoalPeriod.week,
      target: minutes.toDouble(),
    );
    final r = await ref.read(progressRepositoryProvider).addGoal(goal);
    if (!context.mounted) return;
    ref.invalidate(goalsProvider);
    ref.read(syncControllerProvider.notifier).nudge();
    final message = switch (r) {
      Ok() => 'Goal set: ${goal.kind.title(goal.target)} a week',
      Err(:final failure) => failure.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final goals = ref.watch(goalsProvider);
    final hasGoal = goals.value?.any((g) => g.goal.kind == GoalKind.runTime && g.goal.period == GoalPeriod.week);
    if (hasGoal != false) return const SizedBox.shrink();
    final target = TrainingLog.suggestWeeklyMinutes(all, today);
    final monday = mondayOf(today);
    final done = TrainingLog.runMinutes(all, monday, addDays(monday, 7));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SUGGESTED GOAL', style: AppText.eyebrow.copyWith(color: p.sub)),
            const SizedBox(height: 4),
            Text('${goalMinutes(target)} per week', style: AppText.cardTitle.copyWith(color: p.text)),
            Text(
              '${goalMinutes(done)} / ${goalMinutes(target)} run · about 10% more than your last 4 weeks',
              style: AppText.small.copyWith(color: p.sub),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (done / target).clamp(0, 1),
                minHeight: 6,
                color: Metric.runDot,
                backgroundColor: p.text.withValues(alpha: 0.06),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: () => _set(context, ref, target), child: const Text('Set goal')),
                OutlinedButton(
                  onPressed: () =>
                      context.push(ProgressRoutes.goalsFor(GoalKind.runTime, GoalPeriod.week, target.toDouble())),
                  child: const Text('Customize'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/line_chart.dart';
import '../../domain/entities/pace_zones.dart';
import '../../domain/entities/run_analysis.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../running_routes.dart';
import '../providers.dart';
import 'insight_parts.dart';
import 'route_map.dart';

class RunInsightCards extends StatelessWidget {
  const RunInsightCards({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Running insights', style: AppText.section.copyWith(color: p.text)),
        const SizedBox(height: 10),
        const SuggestedWorkoutCard(),
        const SizedBox(height: 12),
        const PredictionsCard(),
        const SizedBox(height: 12),
        const ZonesCard(),
        const SizedBox(height: 12),
        const BestEffortsCard(),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppText.eyebrow.copyWith(color: p.sub)),
        ),
        Icon(Icons.chevron_right_rounded, color: p.sub),
      ],
    );
  }
}

class PredictionsCard extends ConsumerWidget {
  const PredictionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final runs = ref.watch(runAnalysesProvider).value ?? const <RunAnalysis>[];
    final today = ref.watch(todayProvider);
    final now = RacePredictor.predict(runs, RaceTarget.k10, today);
    final change = RacePredictor.change(runs, RaceTarget.k10, today);
    final series = now.seconds == null
        ? const <double?>[]
        : RacePredictor.series(runs, RaceTarget.k10, addDays(today, -29), today);
    return TapGlass(
      onTap: () => context.push(RunRoutes.predictions),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader('PERFORMANCE PREDICTIONS'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('10K', style: AppText.body.copyWith(color: p.sub)),
                    Text(
                      now.seconds == null ? '--' : raceClock(now.seconds!),
                      style: AppText.display.copyWith(fontSize: 32, color: p.text),
                    ),
                    const SizedBox(height: 4),
                    if (now.seconds == null)
                      Text(
                        '${now.remaining} run${now.remaining == 1 ? '' : 's'} of 3 km+ remaining',
                        style: AppText.small.copyWith(color: p.sub),
                      )
                    else if (change != null && change.round() != 0)
                      Row(
                        children: [
                          ChangeChip(text: signedClock(change), good: change < 0, down: change < 0),
                          const SizedBox(width: 6),
                          Text('past 1 month', style: AppText.small.copyWith(color: p.sub)),
                        ],
                      )
                    else
                      Text('Steady over the past month', style: AppText.small.copyWith(color: p.sub)),
                  ],
                ),
              ),
              if (series.length > 1)
                SizedBox(
                  width: 110,
                  child: TrendLine(values: series, color: Metric.runDot, height: 56, showMarker: false),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ZonesCard extends ConsumerWidget {
  const ZonesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final runs = ref.watch(runAnalysesProvider).value ?? const <RunAnalysis>[];
    final zones = ref.watch(paceZonesProvider).value ?? const PaceZones();
    final today = ref.watch(todayProvider);
    final cur = ZoneReport.seconds(runs, zones, addDays(today, -29), today);
    final prev = ZoneReport.seconds(runs, zones, addDays(today, -59), addDays(today, -30));
    final top = ZoneReport.topZone(cur);
    final shares = ZoneReport.shares(cur), prevShares = ZoneReport.shares(prev);
    final change = top == null || ZoneReport.topZone(prev) == null
        ? null
        : ((shares[top - 1] - prevShares[top - 1]) * 100).round();
    return TapGlass(
      onTap: () => context.push(RunRoutes.zones),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader('TRAINING ZONES · PACE'),
          const SizedBox(height: 8),
          if (top == null)
            Text(
              'Record runs with GPS to see how long you spend in each pace zone.',
              style: AppText.small.copyWith(color: p.sub),
            )
          else ...[
            Text('Most time', style: AppText.body.copyWith(color: p.sub)),
            Row(
              children: [
                Text(
                  '${(shares[top - 1] * 100).round()}% in Z$top',
                  style: AppText.display.copyWith(fontSize: 28, color: p.text),
                ),
                const SizedBox(width: 8),
                if (change != null && change != 0)
                  ChangeChip(text: '${change.abs()}%', good: change > 0, down: change < 0),
              ],
            ),
            const SizedBox(height: 10),
            for (var z = 6; z >= 1; z--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('Z$z', style: AppText.tab.copyWith(color: p.sub)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: shares[z - 1],
                          minHeight: 7,
                          color: zoneColors[z - 1],
                          backgroundColor: p.text.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class BestEffortsCard extends ConsumerWidget {
  const BestEffortsCard({super.key});

  static const shown = [Effort.m400, Effort.k1, Effort.k5];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final runs = ref.watch(runAnalysesProvider).value ?? const <RunAnalysis>[];
    return TapGlass(
      onTap: () => context.push(RunRoutes.records),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader('BEST EFFORTS'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final e in shown)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final b = EffortRanks.best(runs, e);
                      return Semantics(
                        label: '${e.distance} best effort, ${b == null ? 'not set' : raceClock(b.seconds)}',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            MedalBadge(rank: b == null ? null : 1, size: 40),
                            const SizedBox(height: 6),
                            Text(e.distance, style: AppText.small.copyWith(color: p.sub)),
                            Text(
                              b == null ? '--' : raceClock(b.seconds),
                              style: AppText.number.copyWith(color: p.text),
                            ),
                            Text(b == null ? 'Not set' : 'All-time', style: AppText.tab.copyWith(color: p.sub)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SuggestedWorkoutCard extends ConsumerWidget {
  const SuggestedWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final list = ref.watch(suggestedWorkoutsProvider);
    final s = list.value?.firstOrNull;
    return TapGlass(
      onTap: () => context.push(RunRoutes.workouts),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader('SUGGESTED WORKOUT'),
          const SizedBox(height: 10),
          if (s == null)
            Text('Building workouts...', style: AppText.small.copyWith(color: p.sub))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(icon: Icons.directions_run_rounded, colors: Metric.run, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.type.label} · ${s.km.toStringAsFixed(1)} km',
                        style: AppText.cardTitle.copyWith(color: p.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.blurb,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class MedalBadge extends StatelessWidget {
  const MedalBadge({super.key, required this.rank, this.size = 44});

  final int? rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = rank;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: r == null || r > 3 ? p.text.withValues(alpha: 0.08) : medalColors[r - 1],
      ),
      child: r == null
          ? Icon(Icons.military_tech_rounded, color: p.sub, size: size * 0.55)
          : Text(
              '$r',
              style: AppText.number.copyWith(fontSize: size * 0.42, color: const Color(0xFF3A2A00)),
            ),
    );
  }
}

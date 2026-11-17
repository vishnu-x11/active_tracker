import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/gps_use_cases.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../domain/use_cases/track_math.dart';
import '../../running_routes.dart';
import '../providers.dart';
import 'insight_parts.dart';
import 'route_map.dart';
import 'run_insight_cards.dart';

class RunMapHeader extends ConsumerWidget {
  const RunMapHeader({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(runTrackProvider(run.id)).value ?? const <TrackPoint>[];
    final ranks = EffortRanks.forRun(ref.watch(runAnalysesProvider).value ?? const [], run.id);
    final medals = <MapMedal>[
      for (final r in ranks)
        if (r.end < pts.length)
          (at: pts[r.end], rank: r.rank, title: '${EffortRanks.ordinal(r.rank)} ${r.effort.distance}'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(
              child: RouteMap(points: pts, interactive: true, medals: medals),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Glass(
                kind: GlassKind.control,
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  '${run.km.toStringAsFixed(2)} km · GPS',
                  style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: context.palette.text),
                ),
              ),
            ),
            if (pts.length >= 2)
              Positioned(
                right: 12,
                bottom: 12,
                child: Tooltip(
                  message: 'Replay run',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push(RunRoutes.replay(run.id)),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF0E1018), size: 30),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EffortRankCard extends ConsumerWidget {
  const EffortRankCard({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final ranks = EffortRanks.forRun(ref.watch(runAnalysesProvider).value ?? const [], run.id);
    if (ranks.isEmpty) return const SizedBox.shrink();
    final top = ranks.first;
    final delta = top.delta;
    final rest = ranks.skip(1).take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Glass(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            MedalBadge(rank: top.rank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    top.rank == 1
                        ? 'Your fastest ${top.effort.distance}!'
                        : 'Your ${EffortRanks.ordinal(top.rank)} ${top.effort.distance}!',
                    style: AppText.cardTitle.copyWith(color: p.text),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(raceClock(top.seconds), style: AppText.body.copyWith(color: p.text)),
                      if (delta != null && delta.round() != 0)
                        top.rank == 1
                            ? ChangeChip(text: '${signedClock(delta)} faster', good: true)
                            : ChangeChip(text: '${signedClock(delta)} off your best', good: false, down: false),
                    ],
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Also ${rest.map((r) => '${EffortRanks.ordinal(r.rank).toLowerCase()} ${r.effort.distance}').join(', ')}',
                      style: AppText.small.copyWith(color: p.sub),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GpsSections extends ConsumerWidget {
  const GpsSections({super.key, required this.run, this.justRecorded = false});

  final Run run;
  final bool justRecorded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final pts = ref.watch(runTrackProvider(run.id)).value ?? const <TrackPoint>[];
    final splits = TrackMath.splits(pts);
    final records = ref.watch(personalRecordsProvider).value ?? const {};
    final fresh = GetPersonalRecords.newIn(run.id, records);
    final paces = [for (final s in splits) s.seconds / s.km];
    final slowest = paces.fold(0.0, (a, b) => a > b ? a : b);
    final fastest = paces.isEmpty ? 0 : paces.reduce((a, b) => a < b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (justRecorded && fresh.isNotEmpty) ...[
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconTile(icon: Icons.emoji_events_rounded, colors: Metric.burn, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fresh.length} new personal record${fresh.length == 1 ? '' : 's'}',
                        style: AppText.cardTitle.copyWith(color: p.text),
                      ),
                      Text(
                        fresh.map((e) => '${e.label} ${RunMetrics.clock(records[e]!.seconds.round())}').join(' · '),
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (splits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pace per km', style: AppText.cardTitle.copyWith(color: p.text)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, pace) in paces.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Semantics(
                            label: 'Km ${i + 1}, ${formatPace(pace)} per km',
                            excludeSemantics: true,
                            child: Container(
                              height: slowest == 0
                                  ? 10
                                  : (20 + 80 * (slowest - pace) / ((slowest - fastest) == 0 ? 1 : slowest - fastest)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: pace == fastest
                                    ? const LinearGradient(
                                        colors: Metric.burn,
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : const LinearGradient(
                                        colors: Metric.run,
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final (i, s) in splits.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            s.km == 1 ? 'Km ${i + 1}' : '${s.km.toStringAsFixed(2)} km',
                            style: AppText.small.copyWith(color: p.sub),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${formatPace(s.seconds / s.km)} /km',
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                          ),
                        ),
                        Text(RunMetrics.clock(s.seconds.round()), style: AppText.small.copyWith(color: p.sub)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Glass(
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push(RunRoutes.records),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const IconTile(icon: Icons.military_tech_rounded, colors: Metric.run, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Personal records', style: AppText.cardTitle.copyWith(color: p.text)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.sub),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

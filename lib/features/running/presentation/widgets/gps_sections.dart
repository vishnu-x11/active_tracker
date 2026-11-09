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
import '../../domain/use_cases/run_metrics.dart';
import '../../domain/use_cases/track_math.dart';
import '../../running_routes.dart';
import '../providers.dart';
import 'route_map.dart';

class RunMapHeader extends ConsumerWidget {
  const RunMapHeader({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(runTrackProvider(run.id)).value ?? const <TrackPoint>[];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(child: RouteMap(points: pts, interactive: true)),
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

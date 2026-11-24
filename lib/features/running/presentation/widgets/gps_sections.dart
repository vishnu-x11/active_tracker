import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../running_routes.dart';
import '../providers.dart';
import 'route_map.dart';

class RunMapHeader extends ConsumerWidget {
  const RunMapHeader({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    precacheImage(const AssetImage(mapPlaceholder), context);
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

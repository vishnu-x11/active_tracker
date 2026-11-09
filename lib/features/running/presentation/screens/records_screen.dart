import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../providers.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final records = ref.watch(personalRecordsProvider);
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Personal records', onBack: () => context.pop()),
              const SizedBox(height: 16),
              if (records.isLoading)
                const Center(
                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                ),
              if (records.value case final r?)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    for (final e in Effort.values)
                      Glass(
                        blur: false,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: r[e] == null ? null : () => context.push(RunRoutes.detail(r[e]!.runId)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: r[e] == null ? null : const LinearGradient(colors: Metric.burn),
                                    color: r[e] == null ? p.text.withValues(alpha: 0.08) : null,
                                  ),
                                  child: Text(
                                    e.label,
                                    style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: r[e] == null ? p.sub : Colors.white,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  r[e] == null ? '–' : RunMetrics.clock(r[e]!.seconds.round()),
                                  style: AppText.display.copyWith(fontSize: 24, color: p.text),
                                ),
                                Text(
                                  r[e] == null
                                      ? 'Run ${(e.meters / 1000).toStringAsFixed(e == Effort.half ? 1 : 0)} km to set it'
                                      : '${formatPace(r[e]!.seconds / (e.meters / 1000))} /km · ${shortDate(r[e]!.date)}',
                                  textAlign: TextAlign.center,
                                  style: AppText.small.copyWith(color: p.sub),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Records come from runs recorded with GPS: the fastest stretch of that distance inside any run, '
                  'not only whole runs of that length. Manual runs have no route, so they are not counted.',
                  style: AppText.small.copyWith(color: p.sub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

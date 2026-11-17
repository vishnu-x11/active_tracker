import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/pace_zones.dart';
import '../../domain/use_cases/run_insights.dart';
import '../providers.dart';
import '../widgets/insight_parts.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  static const _icons = {
    SuggestionType.recovery: (Icons.spa_rounded, Metric.protein),
    SuggestionType.easy: (Icons.directions_run_rounded, Metric.water),
    SuggestionType.intervals: (Icons.bolt_rounded, Metric.burn),
    SuggestionType.long: (Icons.route_rounded, Metric.run),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final list = ref.watch(suggestedWorkoutsProvider);
    final zones = ref.watch(paceZonesProvider).value ?? const PaceZones();
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Suggested workouts', onBack: () => context.pop()),
              const SizedBox(height: 16),
              switch (list) {
                AsyncData(:final value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, s) in value.indexed) ...[
                      Glass(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconTile(icon: _icons[s.type]!.$1, colors: _icons[s.type]!.$2, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (i == 0)
                                        Text('THIS WEEK\'S PICK', style: AppText.eyebrow.copyWith(color: p.accentText)),
                                      Text(s.type.label, style: AppText.cardTitle.copyWith(color: p.text)),
                                      Text(
                                        '${s.km.toStringAsFixed(1)} km · ${paceText(s.paceSec.toDouble())}',
                                        style: AppText.small.copyWith(color: p.sub),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(s.blurb, style: AppText.small.copyWith(color: p.sub)),
                            const SizedBox(height: 12),
                            GradientButton(
                              label: 'Start ${s.type.label.toLowerCase()}',
                              onPressed: () => startSuggestedWorkout(context, ref, s),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Glass(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Suggestions come from your GPS runs in the last 4 weeks and a threshold pace of '
                        '${formatPace(zones.thresholdSec.toDouble())} /km. Starting one sets the target pace or '
                        'intervals in the run settings, then opens the recorder.',
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                    ),
                  ],
                ),
                AsyncError(:final error) => Text(
                  error is Failure ? error.message : "Couldn't build workouts.",
                  style: AppText.small.copyWith(color: p.danger),
                ),
                _ => Column(
                  children: [
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('Building workouts...', style: AppText.small.copyWith(color: p.sub)),
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/run.dart';
import '../../domain/use_cases/run_breakdown.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../providers.dart';
import 'insight_parts.dart';
import 'profile_chart.dart';
import 'run_insight_cards.dart';

final runBreakdownProvider = Provider.autoDispose.family<RunBreakdown, String>(
  (ref, id) => RunBreakdown.of(ref.watch(runTrackProvider(id)).value ?? const []),
);

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppText.title.copyWith(color: context.palette.text)),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: p.sub)),
          ),
          Text(
            value,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: p.text),
          ),
        ],
      ),
    );
  }
}

class RunResultsSection extends ConsumerWidget {
  const RunResultsSection({super.key, required this.run, this.justRecorded = false});

  final Run run;
  final bool justRecorded;

  static String standing(int rank, {required bool fresh}) {
    final place = switch (rank) {
      1 => 'best',
      2 => '2nd best',
      _ => '3rd best',
    };
    return '${fresh ? 'New $place' : '${place[0].toUpperCase()}${place.substring(1)}'} of all time!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final results = EffortRanks.results(ref.watch(runAnalysesProvider).value ?? const [], run.id);
    if (results.isEmpty) return const SizedBox.shrink();
    final achievements = results.where((r) => r.rank <= 3).length;
    Widget count(String label, int n) => Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.small.copyWith(color: p.sub)),
          Text('$n', style: AppText.display.copyWith(fontSize: 20, color: p.text)),
        ],
      ),
    );
    return _Section(
      title: 'Results',
      action: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => context.push(RunRoutes.records),
        child: Text(
          'View all results',
          style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: Metric.burnDot),
        ),
      ),
      children: [
        Row(children: [count('Best efforts', results.length), count('Achievements', achievements)]),
        const SizedBox(height: 6),
        for (final r in results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                MedalBadge(rank: r.rank <= 3 ? r.rank : null, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.effort.label, style: AppText.cardTitle.copyWith(color: p.text)),
                      Text.rich(
                        TextSpan(
                          text: '${raceClock(r.seconds)}  ·  ${paceText(r.seconds / (r.effort.meters / 1000))}',
                          style: AppText.body.copyWith(color: p.text),
                          children: [
                            if (r.rank <= 3)
                              TextSpan(
                                text: '  ·  ${standing(r.rank, fresh: justRecorded)}',
                                style: AppText.small.copyWith(color: p.sub),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RunSplitsSection extends ConsumerWidget {
  const RunSplitsSection({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final splits = ref.watch(runBreakdownProvider(run.id)).splits;
    if (splits.isEmpty) return const SizedBox.shrink();
    final fastest = ref.read(runBreakdownProvider(run.id)).fastestSplitPace ?? 1;
    final elev = splits.any((s) => s.elevationM != null);
    final head = AppText.small.copyWith(color: p.sub);
    return _Section(
      title: 'Splits',
      children: [
        Row(
          children: [
            SizedBox(width: 44, child: Text('Km', style: head)),
            SizedBox(width: 64, child: Text('Pace', style: head)),
            const Spacer(),
            if (elev)
              SizedBox(
                width: 64,
                child: Text('Elev (m)', textAlign: TextAlign.right, softWrap: false, style: head),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Divider(height: 1, color: p.hair),
        const SizedBox(height: 4),
        for (final (i, s) in splits.indexed)
          Builder(
            builder: (context) {
              final pace = s.seconds / s.km;
              final e = s.elevationM?.round();
              return Semantics(
                label: 'Kilometre ${i + 1}, ${formatPace(pace)} per kilometre',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          softWrap: false,
                          s.km >= 0.995 ? '${i + 1}' : s.km.toStringAsFixed(1),
                          style: AppText.body.copyWith(color: p.text),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          formatPace(pace),
                          softWrap: false,
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (fastest / pace).clamp(0.08, 1.0),
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: LinearGradient(colors: pace == fastest ? Metric.burn : Metric.water),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (elev)
                        SizedBox(
                          width: 64,
                          child: Text(
                            e == null ? '–' : (e > 0 ? '+$e' : '$e'),
                            textAlign: TextAlign.right,
                            style: AppText.body.copyWith(color: p.text),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class RunPaceSection extends ConsumerWidget {
  const RunPaceSection({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(runBreakdownProvider(run.id));
    final avg = run.paceSecPerKm;
    final fastest = b.fastestSplitPace;
    return _Section(
      title: 'Pace',
      children: [
        if (b.pace.length >= 2) ...[
          ProfileChart(
            points: b.pace,
            colors: Metric.water,
            invert: true,
            average: avg > 0 ? avg : null,
            ceiling: avg > 0 ? avg * 1.6 : null,
            steps: const [15, 30, 60, 120, 300],
            label: formatPace,
            tooltip: (pt) => '${pt.value == null ? '–' : formatPace(pt.value!)} /km · ${pt.km.toStringAsFixed(2)} km',
            semantics: 'Pace through the run, average ${formatPace(avg)} per kilometre',
          ),
          const SizedBox(height: 12),
        ],
        _StatRow('Avg pace', paceText(avg)),
        _StatRow('Moving time', RunMetrics.clock(run.movingSec)),
        if (b.elapsedSec > 0 && run.km > 0) ...[
          _StatRow('Avg elapsed pace', paceText(b.elapsedSec / run.km)),
          _StatRow('Elapsed time', RunMetrics.clock(b.elapsedSec)),
        ],
        if (fastest != null) _StatRow('Fastest split', paceText(fastest)),
      ],
    );
  }
}

class RunElevationSection extends ConsumerWidget {
  const RunElevationSection({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(runBreakdownProvider(run.id));
    if (!b.hasElevation) return const SizedBox.shrink();
    return _Section(
      title: 'Elevation',
      children: [
        ProfileChart(
          points: b.elevation,
          colors: Metric.protein,
          steps: const [1, 2, 5, 10, 20, 50, 100, 200, 500],
          label: (v) => '${v.round()} m',
          tooltip: (pt) => '${pt.value?.round() ?? '–'} m · ${pt.km.toStringAsFixed(2)} km',
          height: 150,
          semantics: 'Elevation through the run',
        ),
        const SizedBox(height: 12),
        _StatRow('Elevation gain', '${run.elevationM ?? 0} m'),
        _StatRow('Max elevation', '${b.maxAltM!.round()} m'),
        _StatRow('Min elevation', '${b.minAltM!.round()} m'),
      ],
    );
  }
}

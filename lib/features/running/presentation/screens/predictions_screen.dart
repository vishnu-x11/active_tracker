import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/line_chart.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/run_analysis.dart';
import '../../domain/use_cases/run_insights.dart';
import '../providers.dart';
import '../widgets/insight_parts.dart';

enum PredictionRange {
  today('Today', 0),
  m1('1M', 30),
  m3('3M', 90),
  m6('6M', 180);

  const PredictionRange(this.label, this.days);
  final String label;
  final int days;
}

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key});

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  RaceTarget _target = RaceTarget.k10;
  PredictionRange _range = PredictionRange.m1;

  void _explain() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How predictions work'),
      content: const Text(
        'Predictions use your GPS runs from the last 60 days. The fastest stretch of each run is scaled to the race '
        'distance with the Riegel formula (time × (race distance ÷ run distance)^1.06). A prediction needs 5 runs long '
        'enough for that race: 1 km for a 5K, 3 km for a 10K and 5 km for a half or full marathon. Manual runs have no '
        'route, so they are not counted. It is an estimate of what you could run with the right training, not a promise.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final async = ref.watch(runAnalysesProvider);
    final runs = async.value ?? const <RunAnalysis>[];
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(
                title: 'Predictions',
                onBack: () => context.pop(),
                trailing: IconButton(
                  tooltip: 'How predictions work',
                  icon: Icon(Icons.info_outline_rounded, color: p.text),
                  onPressed: _explain,
                ),
              ),
              const SizedBox(height: 16),
              GlassSegmented<PredictionRange>(
                options: [for (final r in PredictionRange.values) (r, r.label)],
                value: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
              const SizedBox(height: 16),
              if (async.isLoading && async.value == null)
                const Center(
                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                )
              else if (_range == PredictionRange.today)
                for (final t in RaceTarget.values) ...[
                  _TargetRow(target: t, runs: runs, today: today),
                  const SizedBox(height: 10),
                ]
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in RaceTarget.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: t == _target,
                        onSelected: (_) => setState(() => _target = t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _Trend(target: _target, range: _range, runs: runs, today: today),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.target, required this.runs, required this.today});

  final RaceTarget target;
  final List<RunAnalysis> runs;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = RacePredictor.predict(runs, target, today);
    final change = RacePredictor.change(runs, target, today);
    final s = now.seconds;
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: s == null ? null : const LinearGradient(colors: Metric.run),
              color: s == null ? p.text.withValues(alpha: 0.08) : null,
            ),
            child: Text(
              target == RaceTarget.half
                  ? 'Half'
                  : target == RaceTarget.full
                  ? 'Full'
                  : target.label,
              style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: s == null ? p.sub : Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.label, style: AppText.small.copyWith(color: p.sub)),
                Text(s == null ? '--' : raceClock(s), style: AppText.display.copyWith(fontSize: 24, color: p.text)),
                Text(
                  s == null
                      ? '${now.remaining} run${now.remaining == 1 ? '' : 's'} remaining'
                      : paceText(s / (target.meters / 1000)),
                  style: AppText.small.copyWith(color: p.sub),
                ),
              ],
            ),
          ),
          if (change != null && change.round() != 0)
            ChangeChip(text: signedClock(change), good: change < 0, down: change < 0),
        ],
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.target, required this.range, required this.runs, required this.today});

  final RaceTarget target;
  final PredictionRange range;
  final List<RunAnalysis> runs;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = RacePredictor.predict(runs, target, today);
    final change = RacePredictor.change(runs, target, today, days: range.days);
    final from = addDays(today, -(range.days - 1));
    final series = RacePredictor.series(runs, target, from, today);
    final labels = <int, String>{
      for (var i = 0; i < series.length; i++)
        if (addDays(from, i).day == 1 || i == 0) i: monthShort[addDays(from, i).month - 1],
    };
    final s = now.seconds;
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CURRENT PREDICTION', style: AppText.eyebrow.copyWith(color: p.sub)),
          const SizedBox(height: 6),
          Text(s == null ? '--' : raceClock(s), style: AppText.hero.copyWith(fontSize: 44, color: p.text)),
          Text(
            s == null
                ? '${now.remaining} more GPS run${now.remaining == 1 ? '' : 's'} of ${target.minSourceM ~/ 1000} km or '
                      'more needed in the last ${RacePredictor.windowDays} days'
                : '${paceText(s / (target.meters / 1000))} · based on runs from ${shortDate(now.from)} to ${shortDate(now.to)}',
            style: AppText.small.copyWith(color: p.sub),
          ),
          if (change != null && change.round() != 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ChangeChip(text: signedClock(change), good: change < 0, down: change < 0),
                const SizedBox(width: 6),
                Text('past ${range.days} days', style: AppText.small.copyWith(color: p.sub)),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (series.any((v) => v != null))
            TrendLine(
              values: series,
              color: Metric.runDot,
              labels: labels,
              marker: s == null ? null : raceClock(s),
              semantics: '${target.label} prediction trend',
            )
          else
            Text('No prediction in this period yet.', style: AppText.small.copyWith(color: p.sub)),
        ],
      ),
    );
  }
}

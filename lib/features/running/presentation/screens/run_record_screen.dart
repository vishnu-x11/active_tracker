import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/data_sources/location_source.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../domain/use_cases/voice_cues.dart';
import '../../running_routes.dart';
import '../notifiers/run_recorder_notifier.dart';
import '../states/run_recorder_state.dart';
import '../widgets/route_map.dart';
import '../widgets/run_settings_sheet.dart';

class RunRecordScreen extends ConsumerWidget {
  const RunRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(runRecorderProvider.select((s) => s.draftId), (_, id) {
      if (id != null) context.pushReplacement(RunRoutes.fromRecording(id));
    });
    final status = ref.watch(runRecorderProvider.select((s) => s.status));
    final points = ref.watch(runRecorderProvider.select((s) => s.points));
    final here = ref.watch(runRecorderProvider.select((s) => s.here));
    final p = context.palette;
    return PopScope(
      canPop: status == RecorderStatus.ready,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: p.pageTop,
            title: const Text('Discard this run?'),
            content: const Text('The recording will be lost. Tap Finish to keep it.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep recording')),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text('Discard', style: TextStyle(color: p.danger)),
              ),
            ],
          ),
        );
        if ((leave ?? false) && context.mounted) context.pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: RouteMap(points: points, here: here, follow: true),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const Spacer(),
                        _StatusPill(status: status),
                        const Spacer(),
                        GlassIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Run settings',
                          onPressed: () => showRunSettings(context),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const _Panel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final RecorderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RecorderStatus.ready => ('Ready', context.palette.sub),
      RecorderStatus.recording => ('Recording', Metric.startDot),
      RecorderStatus.paused => ('Paused', Metric.burnDot),
      RecorderStatus.autoPaused => ('Auto-paused', Metric.burnDot),
    };
    return Semantics(
      liveRegion: true,
      child: Glass(
        kind: GlassKind.control,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: context.palette.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends ConsumerWidget {
  const _Panel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(runRecorderProvider);
    final n = ref.read(runRecorderProvider.notifier);
    String pace(double? v) => v == null ? '–:––' : formatPace(v);
    return Glass(
      kind: GlassKind.bar,
      radius: 32,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.problem != null) ...[
            _Problem(problem: s.problem!, onSettings: n.openSettings),
            const SizedBox(height: 12),
          ],
          if (s.coach case final c?) ...[_Coach(view: c), const SizedBox(height: 12)],
          Text(
            RunMetrics.clock(s.elapsedMs ~/ 1000),
            style: AppText.hero.copyWith(fontSize: 56, color: p.text),
            semanticsLabel: 'Time ${RunMetrics.clock(s.elapsedMs ~/ 1000)}',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Figure(value: s.km.toStringAsFixed(2), unit: 'km', label: 'Distance', colors: Metric.run),
              _Figure(value: pace(s.currentPace), unit: '/km', label: 'Current pace', colors: Metric.water),
              _Figure(value: '${s.kcal}', unit: 'kcal', label: 'Calories', colors: Metric.burn),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: p.hair),
          const SizedBox(height: 10),
          Text('Avg pace ${pace(s.avgPace)} /km', style: AppText.small.copyWith(color: p.sub)),
          if (s.error != null) ...[
            const SizedBox(height: 10),
            Text(
              s.error!,
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
            ),
          ],
          const SizedBox(height: 16),
          switch (s.status) {
            RecorderStatus.ready => GradientButton(label: 'Start', onPressed: n.start),
            RecorderStatus.recording => Row(
              children: [
                Expanded(
                  child: _Secondary(label: 'Pause', icon: Icons.pause_rounded, onTap: n.pause),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(label: 'Finish', busy: s.saving, onPressed: n.finish),
                ),
              ],
            ),
            RecorderStatus.paused || RecorderStatus.autoPaused => Row(
              children: [
                Expanded(
                  child: _Secondary(label: 'Resume', icon: Icons.play_arrow_rounded, onTap: n.resume),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(label: 'Finish', busy: s.saving, onPressed: n.finish),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _Coach extends StatelessWidget {
  const _Coach({required this.view});

  final CoachView view;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Glass(
        kind: GlassKind.control,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconTile(icon: view.done ? Icons.check_rounded : Icons.timer_outlined, colors: Metric.run, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                view.title,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
              ),
            ),
            if (view.detail case final d?) Text(d, style: AppText.number.copyWith(fontSize: 16, color: p.accentText)),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.unit, required this.label, required this.colors});

  final String value;
  final String unit;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Semantics(
        container: true,
        label: '$label $value $unit',
        excludeSemantics: true,
        child: Column(
          children: [
            Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    TextSpan(
                      text: ' $unit',
                      style: AppText.small.copyWith(color: p.sub),
                    ),
                  ],
                ),
                style: AppText.display.copyWith(fontSize: 22, color: p.text),
              ),
            ),
            Text(
              label,
              style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secondary extends StatelessWidget {
  const _Secondary({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Glass(
    kind: GlassKind.control,
    radius: 20,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.palette.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: context.palette.text),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.problem, required this.onSettings});

  final LocationProblem problem;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = switch (problem) {
      LocationProblem.serviceOff => 'Location is off. Turn it on to record a run.',
      LocationProblem.denied => 'Allow location access to record your route.',
      LocationProblem.deniedForever => 'Location access is blocked. Allow it in Settings to record runs.',
    };
    return Row(
      children: [
        Icon(Icons.location_off_rounded, color: p.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.small.copyWith(color: p.text)),
        ),
        if (problem != LocationProblem.denied) TextButton(onPressed: onSettings, child: const Text('Settings')),
      ],
    );
  }
}

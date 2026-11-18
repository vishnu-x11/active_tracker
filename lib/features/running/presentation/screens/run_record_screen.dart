import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/segmented.dart';
import '../../data/data_sources/location_source.dart';
import '../../domain/use_cases/run_metrics.dart';

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
    return PopScope(
      canPop: status == RecorderStatus.ready,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showAppDialog(
          context,
          icon: Icons.delete_outline_rounded,
          title: 'Discard this run?',
          message: 'The recording will be lost. Tap Finish to keep it.',
          cancel: 'Keep recording',
          confirm: 'Discard',
          danger: true,
        );
        if (!(leave ?? false) || !context.mounted) return;
        await ref.read(runRecorderProvider.notifier).discard();
        if (context.mounted) context.pop();
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
                        if (status != RecorderStatus.ready) _StatusPill(status: status),
                        const Spacer(),
                        GlassIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Run settings',
                          onPressed: () => showRunSettings(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _GpsChip(),
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

class _GpsChip extends ConsumerWidget {
  const _GpsChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(runRecorderProvider.select((s) => s.problem == null ? s.signal : GpsSignal.good));
    final onSteps = ref.watch(runRecorderProvider.select((s) => s.onSteps));
    if (signal == GpsSignal.good) return const SizedBox.shrink();
    final p = context.palette;
    final (icon, label, color) = switch (signal) {
      GpsSignal.searching => (Icons.gps_not_fixed_rounded, 'Finding GPS…', Metric.burnDot),
      GpsSignal.lost => (
        Icons.gps_off_rounded,
        onSteps ? 'GPS disconnected · using steps' : 'GPS disconnected',
        p.danger,
      ),
      _ => (Icons.gps_off_rounded, 'Weak GPS signal', Metric.burnDot),
    };
    return Semantics(
      liveRegion: true,
      child: Glass(
        kind: GlassKind.control,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.text),
              ),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.problem != null) ...[
            _Problem(problem: s.problem!, onSettings: n.openSettings),
            const SizedBox(height: 12),
          ],
          if (s.restored) ...[
            Text(
              'We kept your unfinished run. Tap Resume to carry on.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
            ),
            const SizedBox(height: 12),
          ],
          const _VoiceCoach(),
          const SizedBox(height: 6),
          Text(
            RunMetrics.clock(s.elapsedMs ~/ 1000),
            style: AppText.hero.copyWith(fontSize: 40, height: 1.1, color: p.text),
            semanticsLabel: 'Time ${RunMetrics.clock(s.elapsedMs ~/ 1000)}',
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Figure(value: s.km.toStringAsFixed(2), unit: 'km', label: 'Distance', colors: Metric.run),
              _Figure(value: pace(s.currentPace), unit: '/km', label: 'Current pace', colors: Metric.water),
              _Figure(value: '${s.kcal}', unit: 'kcal', label: 'Calories', colors: Metric.burn),
            ],
          ),
          const SizedBox(height: 6),
          Text('Avg pace ${pace(s.avgPace)} /km', style: AppText.small.copyWith(fontSize: 12, color: p.sub)),
          if (s.error != null) ...[
            const SizedBox(height: 10),
            Text(
              s.error!,
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
            ),
          ],
          const SizedBox(height: 10),
          switch (s.status) {
            RecorderStatus.ready => GradientButton(label: 'Start', height: 48, onPressed: n.start),
            RecorderStatus.recording => Row(
              children: [
                Expanded(
                  child: _Secondary(label: 'Pause', icon: Icons.pause_rounded, onTap: n.pause),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(label: 'Finish', height: 48, busy: s.saving, onPressed: n.finish),
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
                  child: GradientButton(label: 'Finish', height: 48, busy: s.saving, onPressed: n.finish),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _VoiceCoach extends ConsumerWidget {
  const _VoiceCoach();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(runRecorderProvider.select((s) => s.settings));
    final n = ref.read(runRecorderProvider.notifier);
    return Glass(
      kind: GlassKind.control,
      radius: 16,
      blur: false,
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Icon(Icons.record_voice_over_rounded, size: 18, color: p.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice assistant',
                    style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.text),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: s.voice,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Metric.cta.last,
                    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                    onChanged: (v) => n.updateSettings(s.copyWith(voice: v)),
                  ),
                ),
              ],
            ),
          ),
          if (s.voice)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Row(
                children: [
                  Text('Splits', style: AppText.small.copyWith(color: p.sub)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassSegmented<int>(
                      dense: true,
                      options: const [(0, 'Off'), (500, '0.5 km'), (1000, '1 km'), (2000, '2 km')],
                      value: s.splitEveryM,
                      onChanged: (v) => n.updateSettings(s.copyWith(splitEveryM: v)),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
            const SizedBox(height: 4),
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
                style: AppText.display.copyWith(fontSize: 18, color: p.text),
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
        height: 48,
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

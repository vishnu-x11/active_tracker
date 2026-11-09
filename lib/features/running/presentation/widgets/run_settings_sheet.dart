import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/run_settings.dart';
import '../notifiers/run_recorder_notifier.dart';
import '../states/run_recorder_state.dart';

Future<void> showRunSettings(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x73040610),
  builder: (_) => const RunSettingsSheet(),
);

class RunSettingsSheet extends ConsumerWidget {
  const RunSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(runRecorderProvider.select((s) => s.settings));
    final ready = ref.watch(runRecorderProvider.select((s) => s.status == RecorderStatus.ready));
    final n = ref.read(runRecorderProvider.notifier);
    final w = s.workout;
    void workout(RunWorkout next) => n.updateSettings(s.copyWith(workout: next));
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Glass(
        kind: GlassKind.bar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: p.hair, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text('Run settings', style: AppText.display.copyWith(fontSize: 24, color: p.text)),
                    ),
                    GlassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Toggle(
                  icon: Icons.pause_circle_outline_rounded,
                  title: 'Auto-pause',
                  hint: w.kind == WorkoutKind.intervals
                      ? 'Off during intervals, so rests keep counting'
                      : 'Pauses when you stop, resumes when you move',
                  value: s.autoPause,
                  onChanged: (v) => n.updateSettings(s.copyWith(autoPause: v)),
                ),
                const SizedBox(height: 10),
                _Toggle(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Voice coach',
                  hint: 'Spoken splits, pace and workout steps',
                  value: s.voice,
                  onChanged: (v) => n.updateSettings(s.copyWith(voice: v)),
                ),
                if (s.voice) ...[
                  const SizedBox(height: 14),
                  const _Label('Announce splits'),
                  GlassSegmented<int>(
                    options: const [(0, 'Off'), (500, '0.5 km'), (1000, '1 km'), (2000, '2 km')],
                    value: s.splitEveryM,
                    onChanged: (v) => n.updateSettings(s.copyWith(splitEveryM: v)),
                  ),
                ],
                const SizedBox(height: 18),
                _Label(ready ? 'Workout' : 'Workout (locked while recording)'),
                IgnorePointer(
                  ignoring: !ready,
                  child: Opacity(
                    opacity: ready ? 1 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassSegmented<WorkoutKind>(
                          options: const [
                            (WorkoutKind.free, 'Free run'),
                            (WorkoutKind.targetPace, 'Target pace'),
                            (WorkoutKind.intervals, 'Intervals'),
                          ],
                          value: w.kind,
                          onChanged: (k) => workout(w.copyWith(kind: k)),
                        ),
                        if (w.kind == WorkoutKind.targetPace) ...[
                          const SizedBox(height: 10),
                          StepperRow(
                            label: 'Target pace',
                            value: '${formatPace(w.targetPaceSec.toDouble())} /km',
                            onMinus: () => workout(w.copyWith(targetPaceSec: w.targetPaceSec - 5)),
                            onPlus: () => workout(w.copyWith(targetPaceSec: w.targetPaceSec + 5)),
                          ),
                        ],
                        if (w.kind == WorkoutKind.intervals) ...[
                          const SizedBox(height: 10),
                          StepperRow(
                            label: 'Warm-up',
                            value: w.warmupMin == 0 ? 'None' : '${w.warmupMin} min',
                            onMinus: () => workout(w.copyWith(warmupMin: w.warmupMin - 5)),
                            onPlus: () => workout(w.copyWith(warmupMin: w.warmupMin + 5)),
                          ),
                          const SizedBox(height: 8),
                          StepperRow(
                            label: 'Repeats',
                            value: '${w.reps} ×',
                            onMinus: () => workout(w.copyWith(reps: w.reps - 1)),
                            onPlus: () => workout(w.copyWith(reps: w.reps + 1)),
                          ),
                          const SizedBox(height: 8),
                          StepperRow(
                            label: 'Run',
                            value: '${w.workM} m',
                            onMinus: () => workout(w.copyWith(workM: w.workM - 100)),
                            onPlus: () => workout(w.copyWith(workM: w.workM + 100)),
                          ),
                          const SizedBox(height: 8),
                          StepperRow(
                            label: 'Rest',
                            value: '${w.restSec} s',
                            onMinus: () => workout(w.copyWith(restSec: w.restSec - 15)),
                            onPlus: () => workout(w.copyWith(restSec: w.restSec + 15)),
                          ),
                          const SizedBox(height: 8),
                          Text('Then cool down and finish when ready.', style: AppText.small.copyWith(color: p.sub)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: context.palette.sub)),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TapGlass(
      kind: GlassKind.control,
      radius: 20,
      blur: false,
      onTap: () => onChanged(!value),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          IconTile(icon: icon, colors: Metric.cta, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                ),
                Text(hint, style: AppText.small.copyWith(color: p.sub)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class StepperRow extends StatelessWidget {
  const StepperRow({super.key, required this.label, required this.value, required this.onMinus, required this.onPlus});

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      kind: GlassKind.control,
      radius: 18,
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: p.sub)),
          ),
          IconButton(
            tooltip: 'Less $label',
            onPressed: onMinus,
            icon: Icon(Icons.remove_rounded, color: p.text),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 84),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: AppText.number.copyWith(fontSize: 16, color: p.text),
            ),
          ),
          IconButton(
            tooltip: 'More $label',
            onPressed: onPlus,
            icon: Icon(Icons.add_rounded, color: p.text),
          ),
        ],
      ),
    );
  }
}

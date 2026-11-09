import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/run.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../notifiers/run_form_notifier.dart';
import '../widgets/run_stat_grid.dart';

class RunLogScreen extends ConsumerStatefulWidget {
  const RunLogScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<RunLogScreen> createState() => _RunLogScreenState();
}

class _RunLogScreenState extends ConsumerState<RunLogScreen> {
  final _title = TextEditingController();
  final _km = TextEditingController();
  final _time = TextEditingController();
  final _pace = TextEditingController();
  final _kcal = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    for (final c in [_title, _km, _time, _pace, _kcal]) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  @override
  Widget build(BuildContext context) {
    final provider = runFormProvider(widget.id);
    final notifier = ref.read(provider.notifier);
    ref.listen(provider, (prev, s) {
      if (!_filled && !s.loading) {
        _filled = true;
        _set(_title, s.title);
        _set(_kcal, s.kcalText);
      }
      _set(_km, s.kmText);
      _set(_time, s.timeText);
      _set(_pace, s.paceText);
      if (s.savedId != null && prev?.savedId == null) {
        if (prev?.isDraft ?? false) {
          context.pushReplacement(RunRoutes.justRecorded(s.savedId!));
        } else if (widget.id == null) {
          context.pushReplacement(RunRoutes.detail(s.savedId!));
        } else {
          context.pop();
        }
      }
    });
    final (loading, locked, isDraft) = ref.watch(provider.select((s) => (s.loading, s.locked, s.isDraft)));
    if (!_filled && !loading) {
      _filled = true;
      final s = ref.read(provider);
      _title.text = s.title;
      _km.text = s.kmText;
      _time.text = s.timeText;
      _pace.text = s.paceText;
      _kcal.text = s.kcalText;
    }

    return Scaffold(
      body: PageBackdrop(
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          FormHeader(
                            title: isDraft ? 'Save GPS run' : (widget.id == null ? 'Log run' : 'Edit run'),
                            onBack: () => context.pop(),
                          ),
                          const SizedBox(height: 16),
                          _SourceSwitch(id: widget.id),
                          const SizedBox(height: 16),
                          GlassField(
                            label: 'Title',
                            controller: _title,
                            onChanged: notifier.setTitle,
                            valueStyle: AppText.display.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          _TypeSwitch(id: widget.id),
                          const SizedBox(height: 16),
                          if (locked)
                            _GpsSummary(id: widget.id)
                          else ...[
                            const _RecordShortcut(),
                            const SizedBox(height: 8),
                            const FormSection('Distance, time & pace', note: 'ANY TWO'),
                            _MetricsCard(id: widget.id, km: _km, time: _time, pace: _pace),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Enter any two of distance, time and pace; the third is filled in. Time as h:mm:ss or mm:ss.',
                                style: AppText.small.copyWith(color: context.palette.sub),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DateAndStart(id: widget.id),
                          ],
                          const SizedBox(height: 16),
                          _Effort(id: widget.id),
                          const SizedBox(height: 16),
                          _Calories(id: widget.id, controller: _kcal),
                          const SizedBox(height: 8),
                          _Preview(id: widget.id),
                        ],
                      ),
              ),
            ),
            _SaveBar(id: widget.id),
          ],
        ),
      ),
    );
  }
}

class _SourceSwitch extends ConsumerWidget {
  const _SourceSwitch({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(runFormProvider(id).select((s) => s.source));
    return GlassSegmented<RunSource>(
      options: const [(RunSource.gps, 'GPS recording'), (RunSource.manual, 'Enter manually')],
      value: source,
      onChanged: (v) async {
        if (v == source) return;
        if (v == RunSource.gps) {
          unawaited(context.push(RunRoutes.record));
          return;
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: c.palette.pageTop,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Enter this run manually?', style: AppText.title.copyWith(color: c.palette.text)),
            content: Text(
              'The GPS recording (route, distance and time) will be discarded.',
              style: AppText.body.copyWith(color: c.palette.sub),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep GPS')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Enter manually')),
            ],
          ),
        );
        if (ok ?? false) await ref.read(runFormProvider(id).notifier).switchToManual();
      },
    );
  }
}

class _TypeSwitch extends ConsumerWidget {
  const _TypeSwitch({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassSegmented<RunType>(
    options: [for (final t in RunType.values) (t, t.label)],
    value: ref.watch(runFormProvider(id).select((s) => s.type)),
    onChanged: ref.read(runFormProvider(id).notifier).setType,
  );
}

class _RecordShortcut extends StatelessWidget {
  const _RecordShortcut();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 24,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(RunRoutes.record),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const IconTile(icon: Icons.my_location_rounded, colors: Metric.protein, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Going for a run now?',
                      style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                    ),
                    Text(
                      'Record with GPS and this form fills itself',
                      style: AppText.small.copyWith(fontSize: 12, color: p.sub),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsCard extends ConsumerWidget {
  const _MetricsCard({required this.id, required this.km, required this.time, required this.pace});

  final String? id;
  final TextEditingController km;
  final TextEditingController time;
  final TextEditingController pace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final n = ref.read(runFormProvider(id).notifier);
    final speed = ref.watch(runFormProvider(id).select((s) => s.speedKmh));
    final narrow = MediaQuery.sizeOf(context).width < 360;
    Widget row({
      required IconData icon,
      required List<Color> colors,
      required String label,
      required TextEditingController c,
      required ValueChanged<String> onChanged,
      required String unit,
      required String hint,
      required TextInputType keyboard,
      required List<TextInputFormatter> formatters,
      Widget? trailing,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconTile(icon: icon, colors: colors, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: c,
                        onChanged: onChanged,
                        keyboardType: keyboard,
                        inputFormatters: formatters,
                        style: AppText.display.copyWith(fontSize: 26, color: p.text),
                        decoration: InputDecoration.collapsed(
                          hintText: hint,
                          hintStyle: AppText.display.copyWith(fontSize: 26, color: p.sub.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    if (unit.isNotEmpty) Text(' $unit', style: AppText.body.copyWith(color: p.sub)),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    final clockOnly = [FilteringTextInputFormatter.allow(RegExp(r'[\d:]')), LengthLimitingTextInputFormatter(8)];
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          row(
            icon: Icons.route_rounded,
            colors: Metric.run,
            label: 'Distance',
            c: km,
            onChanged: n.setKm,
            unit: 'km',
            hint: '5.00',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')), LengthLimitingTextInputFormatter(6)],
            trailing: _Steppers(label: 'distance', onStep: n.stepKm),
          ),
          Container(height: 1, color: p.hair),
          row(
            icon: Icons.schedule_rounded,
            colors: Metric.water,
            label: 'Moving time',
            c: time,
            onChanged: n.setTime,
            unit: '',
            hint: 'h:mm:ss',
            keyboard: TextInputType.datetime,
            formatters: clockOnly,
            trailing: _Steppers(label: 'time', onStep: n.stepTime),
          ),
          Container(height: 1, color: p.hair),
          row(
            icon: Icons.speed_rounded,
            colors: Metric.burn,
            label: narrow && speed != null ? 'Avg pace · ${speed.toStringAsFixed(1)} km/h' : 'Avg pace',
            c: pace,
            onChanged: n.setPace,
            unit: '/km',
            hint: '5:30',
            keyboard: TextInputType.datetime,
            formatters: clockOnly,
            trailing: narrow
                ? null
                : Glass(
                    kind: GlassKind.control,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Avg speed',
                          style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                        ),
                        Text(
                          speed == null ? '–' : '${speed.toStringAsFixed(1)} km/h',
                          style: AppText.number.copyWith(fontSize: 16, color: p.text),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Steppers extends StatelessWidget {
  const _Steppers({required this.label, required this.onStep});

  final String label;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GlassIconButton(icon: Icons.remove_rounded, tooltip: 'Decrease $label', onPressed: () => onStep(-1)),
      const SizedBox(width: 6),
      GlassIconButton(icon: Icons.add_rounded, tooltip: 'Increase $label', onPressed: () => onStep(1)),
    ],
  );
}

class _GpsSummary extends ConsumerWidget {
  const _GpsSummary({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(runFormProvider(id));
    final end = s.seconds == null ? null : s.startedAt.add(Duration(seconds: s.seconds!));
    Widget stat(String value, String unit, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  TextSpan(
                    text: unit,
                    style: AppText.small.copyWith(color: p.sub),
                  ),
                ],
              ),
              style: AppText.display.copyWith(fontSize: 24, color: p.text),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 11, color: p.sub),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
              ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('From your GPS recording', style: AppText.section.copyWith(color: p.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: p.goodBg, borderRadius: BorderRadius.circular(12)),
              child: Text('Auto-filled', style: AppText.tab.copyWith(color: p.goodFg)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Glass(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: Column(
            children: [
              Row(
                children: [
                  stat(s.km?.toStringAsFixed(2) ?? '–', ' km', 'Distance'),
                  stat(s.timeText, '', 'Time'),
                  stat(s.paceText, ' /km', 'Pace'),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: p.hair, margin: const EdgeInsets.symmetric(horizontal: 8)),
              const SizedBox(height: 10),
              Text(
                '${shortDate(s.day)} · ${clockTime(s.startedAt)}${end == null ? '' : ' – ${clockTime(end)}'}'
                '${s.elevationM == null ? '' : ' · ${s.elevationM} m climb'}',
                style: AppText.small.copyWith(color: p.sub),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Distance, time, pace, date and start come from the phone's GPS and are locked. "
            'To type them yourself, switch to Enter manually.',
            style: AppText.small.copyWith(color: p.sub),
          ),
        ),
      ],
    );
  }
}

class _DateAndStart extends ConsumerWidget {
  const _DateAndStart({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (day, start) = ref.watch(runFormProvider(id).select((s) => (s.day, s.startMinute)));
    final n = ref.read(runFormProvider(id).notifier);
    final today = dateOnly(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: PickerField(
            label: 'Date',
            value: dayKey(day) == dayKey(today) ? 'Today' : shortDate(day),
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(today.year - 1),
                lastDate: today,
              );
              if (d != null) n.setDay(d);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PickerField(
            label: 'Start time',
            value: clockTime(day.add(Duration(minutes: start))),
            icon: Icons.schedule_rounded,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
              );
              if (t != null) n.setStart(t.hour * 60 + t.minute);
            },
          ),
        ),
      ],
    );
  }
}

class _Effort extends ConsumerWidget {
  const _Effort({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final effort = ref.watch(runFormProvider(id).select((s) => s.effort));
    final n = ref.read(runFormProvider(id).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Text('Perceived effort', style: AppText.section.copyWith(color: p.text)),
              ),
              Text(
                effortNames[effort - 1],
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (var e = 1; e <= 5; e++) ...[
              if (e > 1) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: e == effort,
                  label: '${effortNames[e - 1]}, $e of 5',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => n.setEffort(e),
                    child: e == effort
                        ? Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(colors: Metric.cta),
                              boxShadow: [
                                BoxShadow(
                                  color: Metric.cta.last.withValues(alpha: 0.38),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text('$e', style: AppText.number.copyWith(color: Colors.white)),
                          )
                        : Glass(
                            kind: GlassKind.control,
                            radius: 18,
                            blur: false,
                            child: SizedBox(
                              height: 52,
                              child: Center(
                                child: Text('$e', style: AppText.number.copyWith(color: p.text)),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Calories extends ConsumerWidget {
  const _Calories({required this.id, required this.controller});

  final String? id;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (estimate, own, km, weight) = ref.watch(
      runFormProvider(id).select((s) => (s.estimate, s.usesOwnKcal, s.km, s.weightKg)),
    );
    return Glass(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconTile(icon: Icons.local_fire_department_rounded, colors: Metric.burn, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories (edit if your watch differs)',
                  style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: controller,
                        onChanged: ref.read(runFormProvider(id).notifier).setKcal,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                        style: AppText.display.copyWith(fontSize: 26, color: p.text),
                        decoration: InputDecoration.collapsed(
                          hintText: '$estimate',
                          hintStyle: AppText.display.copyWith(fontSize: 26, color: p.text),
                        ),
                      ),
                    ),
                    Text(' kcal', style: AppText.body.copyWith(color: p.sub)),
                  ],
                ),
                Text(
                  own
                      ? 'Your value · estimate $estimate kcal'
                      : '1.04 x ${weight.toStringAsFixed(0)} kg x ${(km ?? 0).toStringAsFixed(2)} km',
                  style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runFormProvider(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection('Preview', note: s.type.label.toUpperCase()),
        RunStatGrid(
          stats: [
            RunStat(Icons.schedule_rounded, 'Duration', s.seconds == null ? '–' : RunMetrics.clock(s.seconds!), ''),
            RunStat(Icons.route_rounded, 'Distance', s.km?.toStringAsFixed(2) ?? '–', 'km'),
            RunStat(Icons.speed_rounded, 'Avg pace', s.paceText.isEmpty ? '–' : s.paceText, '/km'),
            RunStat(Icons.av_timer_rounded, 'Avg speed', s.speedKmh?.toStringAsFixed(1) ?? '–', 'km/h'),
            RunStat(Icons.local_fire_department_outlined, 'Calories', '${s.kcalShown}', 'kcal'),
            RunStat(Icons.bolt_rounded, 'Effort · ${effortNames[s.effort - 1]}', '${s.effort}', '/5'),
          ],
        ),
      ],
    );
  }
}

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (kcal, saving, error, problem) = ref.watch(
      runFormProvider(id).select((s) => (s.kcalShown, s.saving, s.error, s.problem(DateTime.now()))),
    );
    return SaveBar(
      error: error ?? problem,
      button: GradientButton(
        label: 'Save run',
        trailing: '$kcal kcal',
        busy: saving,
        onPressed: ref.read(runFormProvider(id).notifier).save,
      ),
    );
  }
}

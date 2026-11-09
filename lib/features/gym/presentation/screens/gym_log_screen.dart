import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/muscle_groups.dart';
import '../../gym_routes.dart';
import '../notifiers/gym_form_notifier.dart';
import '../states/gym_form_state.dart';
import '../widgets/exercise_section.dart';

class GymLogScreen extends ConsumerStatefulWidget {
  const GymLogScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<GymLogScreen> createState() => _GymLogScreenState();
}

class _GymLogScreenState extends ConsumerState<GymLogScreen> {
  final _hours = TextEditingController();
  final _mins = TextEditingController();
  final _newGroup = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncDuration(ref.read(gymFormProvider(widget.id)).minutes);
  }

  @override
  void dispose() {
    _hours.dispose();
    _mins.dispose();
    _newGroup.dispose();
    super.dispose();
  }

  void _syncDuration(int minutes) {
    final h = '${minutes ~/ 60}', m = (minutes % 60).toString().padLeft(2, '0');
    if (_hours.text != h) _hours.text = h;
    if (_mins.text != m) _mins.text = m;
  }

  void _typed() {
    final h = int.tryParse(_hours.text) ?? 0, m = (int.tryParse(_mins.text) ?? 0).clamp(0, 59);
    ref.read(gymFormProvider(widget.id).notifier).setMinutes(h * 60 + m);
  }

  @override
  Widget build(BuildContext context) {
    final provider = gymFormProvider(widget.id);
    ref.listen(provider.select((s) => s.minutes), (_, m) {
      final typed = (int.tryParse(_hours.text) ?? 0) * 60 + (int.tryParse(_mins.text) ?? 0);
      if (typed != m) _syncDuration(m);
    });
    ref.listen(provider.select((s) => s.savedId), (_, savedId) {
      if (savedId == null) return;
      widget.id == null ? context.pushReplacement(GymRoutes.detail(savedId)) : context.pop();
    });
    ref.listen(provider.select((s) => s.notice), (_, notice) {
      if (notice == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(notice), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
        );
      ref.read(provider.notifier).clearNotice();
    });
    final notifier = ref.read(provider.notifier);
    final loading = ref.watch(provider.select((s) => s.loading));

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
                            title: widget.id == null ? 'Log gym session' : 'Edit session',
                            onBack: () => context.pop(),
                          ),
                          const SizedBox(height: 16),
                          _BurnHero(id: widget.id),
                          const SizedBox(height: 16),
                          _DateAndStart(id: widget.id),
                          const SizedBox(height: 16),
                          _TimeCard(id: widget.id, hours: _hours, mins: _mins, onTyped: _typed),
                          const SizedBox(height: 12),
                          _Groups(id: widget.id, newGroup: _newGroup),
                          const SizedBox(height: 12),
                          ExerciseSection(id: widget.id),
                          const SizedBox(height: 12),
                          const FormSection('How hard was it?'),
                          _Intensity(id: widget.id),
                        ],
                      ),
              ),
            ),
            RestTimerBar(id: widget.id),
            _SaveBar(id: widget.id, onSave: notifier.save),
          ],
        ),
      ),
    );
  }
}

class _BurnHero extends ConsumerWidget {
  const _BurnHero({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (kcal, met, kg, minutes) = ref.watch(
      gymFormProvider(id).select((s) => (s.kcal, s.met, s.weightKg, s.minutes)),
    );
    final hours = (minutes / 60).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return Glass(
      radius: 32,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED BURN', style: AppText.eyebrow.copyWith(color: p.sub)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: '$kcal',
                    children: [
                      TextSpan(
                        text: ' kcal',
                        style: AppText.title.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                      ),
                    ],
                  ),
                  style: AppText.hero.copyWith(color: p.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'MET ${met.toStringAsFixed(2)} · ${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg · $hours h',
                  style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                ),
              ],
            ),
          ),
          const IconTile(icon: Icons.local_fire_department_rounded, colors: Metric.burn, size: 64),
        ],
      ),
    );
  }
}

class _DateAndStart extends ConsumerWidget {
  const _DateAndStart({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (day, start) = ref.watch(gymFormProvider(id).select((s) => (s.day, s.startMinute)));
    final notifier = ref.read(gymFormProvider(id).notifier);
    final today = dateOnly(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: PickerField(
            label: 'Date',
            value: dayKey(day) == dayKey(today) ? 'Today' : shortDate(day),
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(today.year - 1),
                lastDate: today,
              );
              if (picked != null) notifier.setDay(picked);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PickerField(
            label: 'Started',
            value: clockTime(day.add(Duration(minutes: start))),
            icon: Icons.schedule_rounded,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
              );
              if (picked != null) notifier.setStart(picked.hour * 60 + picked.minute);
            },
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends ConsumerWidget {
  const _TimeCard({required this.id, required this.hours, required this.mins, required this.onTyped});

  final String? id;
  final TextEditingController hours;
  final TextEditingController mins;
  final VoidCallback onTyped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final notifier = ref.read(gymFormProvider(id).notifier);
    final minutes = ref.watch(gymFormProvider(id).select((s) => s.minutes));
    Widget box(TextEditingController c, String unit, String label) => Container(
      constraints: const BoxConstraints(maxWidth: 88),
      height: 64,
      child: Glass(
        kind: GlassKind.control,
        radius: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: TextField(
                controller: c,
                onChanged: (_) => onTyped(),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                style: AppText.display.copyWith(fontSize: 30, color: p.text),
                decoration: const InputDecoration.collapsed(hintText: '0'),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.sub),
            ),
          ],
        ),
      ),
    );
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Time in gym', style: AppText.cardTitle.copyWith(color: p.text)),
          const SizedBox(height: 16),
          Row(
            children: [
              GlassIconButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease time by 15 minutes',
                onPressed: () => notifier.step(-15),
              ),
              const Spacer(),
              Flexible(child: box(hours, 'h', 'Hours')),
              const SizedBox(width: 8),
              Flexible(child: box(mins, 'm', 'Minutes')),
              const Spacer(),
              GlassIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase time by 15 minutes',
                onPressed: () => notifier.step(15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassSegmented<int>(
            options: [
              for (final m in GymFormState.presets) (m, m < 60 ? '${m}m' : '${m % 60 == 0 ? m ~/ 60 : m / 60}h'),
            ],
            value: GymFormState.presets.contains(minutes) ? minutes : -1,
            onChanged: notifier.setMinutes,
          ),
        ],
      ),
    );
  }
}

class _Groups extends ConsumerWidget {
  const _Groups({required this.id, required this.newGroup});

  final String? id;
  final TextEditingController newGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (picked, custom, groupError) = ref.watch(
      gymFormProvider(id).select((s) => (s.groups, s.customGroups, s.groupError)),
    );
    final notifier = ref.read(gymFormProvider(id).notifier);
    final keys = [...MuscleGroups.builtIn.keys, ...custom];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection('What did you train?', note: '${picked.length} selected'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            for (final k in keys)
              _GroupTile(
                label: MuscleGroups.label(k),
                selected: picked.contains(k),
                onTap: () => notifier.toggleGroup(k),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassField(
                label: 'Custom group',
                controller: newGroup,
                hint: 'e.g. Glutes, Mobility, Boxing',
                error: groupError,
                textInputAction: TextInputAction.done,
                valueStyle: AppText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                onSubmitted: (v) async {
                  if (await notifier.addCustomGroup(v)) newGroup.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 64,
              child: Glass(
                kind: GlassKind.control,
                radius: 18,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    if (await notifier.addCustomGroup(newGroup.text)) newGroup.clear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: p.accentText),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[const Icon(Icons.check_rounded, size: 14, color: Colors.white), const SizedBox(width: 4)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: selected ? Colors.white : p.text),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: Metric.burn,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Metric.burn.last.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: content,
              )
            : Glass(kind: GlassKind.control, radius: 18, blur: false, child: content),
      ),
    );
  }
}

class _Intensity extends ConsumerWidget {
  const _Intensity({required this.id});

  final String? id;

  static const _hints = {
    GymIntensity.light: ('Light', 'Long rests'),
    GymIntensity.moderate: ('Moderate', 'Steady sets'),
    GymIntensity.hard: ('Hard', 'Supersets, little rest'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final value = ref.watch(gymFormProvider(id).select((s) => s.intensity));
    final notifier = ref.read(gymFormProvider(id).notifier);
    return Glass(
      kind: GlassKind.control,
      radius: 24,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final i in GymIntensity.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == value,
                label: '${_hints[i]!.$1}, ${_hints[i]!.$2}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => notifier.setIntensity(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: i == value ? const LinearGradient(colors: Metric.burn) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _hints[i]!.$1,
                          style: AppText.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: i == value ? Colors.white : p.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _hints[i]!.$2,
                          textAlign: TextAlign.center,
                          style: AppText.tab.copyWith(
                            fontWeight: FontWeight.w500,
                            color: i == value ? Colors.white.withValues(alpha: 0.85) : p.sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.id, required this.onSave});

  final String? id;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (kcal, saving, error, problem) = ref.watch(
      gymFormProvider(id).select((s) => (s.kcal, s.saving, s.error, s.problem(DateTime.now()))),
    );
    return SaveBar(
      error: error ?? problem,
      button: GradientButton(label: 'Save session', trailing: '$kcal kcal', busy: saving, onPressed: onSave),
    );
  }
}

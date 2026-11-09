import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_groups.dart';
import '../notifiers/gym_form_notifier.dart';
import '../providers.dart';

String kgText(double kg) => kg == kg.roundToDouble() ? '${kg.round()}' : kg.toStringAsFixed(1);

String volumeText(double v) {
  final n = v.round();
  return n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}

class ExerciseSection extends ConsumerWidget {
  const ExerciseSection({super.key, required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final provider = gymFormProvider(id);
    final count = ref.watch(provider.select((s) => s.exercises.length));
    final volume = ref.watch(provider.select((s) => s.volume));
    final routines = ref.watch(provider.select((s) => s.routines));
    final n = ref.read(provider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection('Exercises', note: count == 0 ? 'Optional' : 'Volume ${volumeText(volume)} kg'),
        if (count == 0 && id == null && routines.isNotEmpty) ...[
          Text('Start from a routine', style: AppText.small.copyWith(color: p.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in routines)
                GestureDetector(
                  onLongPress: () async {
                    if (await confirmDelete(context, what: 'routine “${r.name}”')) await n.deleteRoutine(r.id);
                  },
                  child: TapGlass(
                    kind: GlassKind.control,
                    radius: 16,
                    blur: false,
                    onTap: () => n.startRoutine(r),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_play_rounded, size: 20, color: p.accentText),
                        const SizedBox(width: 6),
                        Text(
                          '${r.name} · ${r.exercises.length}',
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < count; i++) ...[_ExerciseCard(id: id, index: i), const SizedBox(height: 10)],
        Row(
          children: [
            Expanded(
              child: TapGlass(
                kind: GlassKind.control,
                radius: 18,
                blur: false,
                onTap: () => showExercisePicker(context, id),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: p.accentText),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Add exercise',
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TapGlass(
                  kind: GlassKind.control,
                  radius: 18,
                  blur: false,
                  onTap: () => _saveRoutine(context, ref),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_add_outlined, color: p.text),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Save as routine',
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                          ),
                        ),
                      ],
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

  Future<void> _saveRoutine(BuildContext context, WidgetRef ref) async {
    final n = ref.read(gymFormProvider(id).notifier);
    n.clearRoutineError();
    await showDialog<void>(
      context: context,
      builder: (_) => _RoutineDialog(id: id),
    );
  }
}

class _RoutineDialog extends ConsumerStatefulWidget {
  const _RoutineDialog({required this.id});

  final String? id;

  @override
  ConsumerState<_RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends ConsumerState<_RoutineDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (await ref.read(gymFormProvider(widget.id).notifier).saveRoutine(_name.text) && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = ref.watch(gymFormProvider(widget.id).select((s) => s.routineError));
    return AlertDialog(
      backgroundColor: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Save as routine', style: AppText.title.copyWith(color: p.text)),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: Routine.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _save(),
        style: AppText.body.copyWith(color: p.text),
        decoration: InputDecoration(hintText: 'Push day', errorText: error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: p.text)),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.id, required this.index});

  final String? id;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final provider = gymFormProvider(id);
    final e = ref.watch(provider.select((s) => s.exercises.elementAtOrNull(index)));
    if (e == null) return const SizedBox.shrink();
    final history = ref.watch(provider.select((s) => s.history[e.key]));
    final n = ref.read(provider.notifier);
    final last = history?.lastSets;
    return Glass(
      blur: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: AppText.cardTitle.copyWith(color: p.text)),
                    Text(
                      last == null || last.isEmpty
                          ? '${MuscleGroups.label(e.group)} · first time'
                          : 'Last time: ${kgText(last.first.kg)} kg × ${last.first.reps} · ${last.length} sets',
                      style: AppText.small.copyWith(color: p.sub),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${e.name}',
                onPressed: () => n.removeExercise(index),
                icon: Icon(Icons.close_rounded, color: p.sub),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text('SET', style: AppText.eyebrow.copyWith(color: p.sub)),
                ),
                Expanded(
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: AppText.eyebrow.copyWith(color: p.sub),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: AppText.eyebrow.copyWith(color: p.sub),
                  ),
                ),
                const SizedBox(width: 88),
              ],
            ),
          ),
          for (var j = 0; j < e.sets.length; j++) _SetRow(id: id, exercise: index, set: j),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => n.addSet(index),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({required this.id, required this.exercise, required this.set});

  final String? id;
  final int exercise;
  final int set;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  final _kg = TextEditingController();
  final _reps = TextEditingController();

  SetEntry get _value => ref.read(gymFormProvider(widget.id)).exercises[widget.exercise].sets[widget.set];

  @override
  void initState() {
    super.initState();
    _fill(_value);
  }

  void _fill(SetEntry s) {
    final kg = s.kg == 0 ? '' : kgText(s.kg);
    final reps = s.reps == 0 ? '' : '${s.reps}';
    if ((double.tryParse(_kg.text) ?? 0) != s.kg) _kg.text = kg;
    if ((int.tryParse(_reps.text) ?? 0) != s.reps) _reps.text = reps;
  }

  @override
  void dispose() {
    _kg.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = gymFormProvider(widget.id);
    final i = widget.exercise, j = widget.set;
    final s = ref.watch(provider.select((st) => st.exercises.elementAtOrNull(i)?.sets.elementAtOrNull(j)));
    final pr = ref.watch(provider.select((st) => s != null && st.isPr(i, j)));
    if (s == null) return const SizedBox.shrink();
    _fill(s);
    final n = ref.read(provider.notifier);
    Widget field(TextEditingController c, String label, bool decimal, ValueChanged<String> onChanged) => Expanded(
      child: SizedBox(
        height: 44,
        child: Glass(
          kind: GlassKind.control,
          radius: 14,
          blur: false,
          child: Center(
            child: TextField(
              controller: c,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.]' : r'[0-9]')),
                LengthLimitingTextInputFormatter(decimal ? 6 : 3),
              ],
              style: AppText.number.copyWith(fontSize: 17, color: p.text),
              decoration: const InputDecoration.collapsed(hintText: '0').copyWith(semanticCounterText: label),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('${j + 1}', style: AppText.number.copyWith(fontSize: 16, color: p.sub)),
          ),
          field(_kg, 'Kilograms', true, (v) => n.updateSet(i, j, kg: double.tryParse(v) ?? 0)),
          const SizedBox(width: 8),
          field(_reps, 'Reps', false, (v) => n.updateSet(i, j, reps: int.tryParse(v) ?? 0)),
          SizedBox(
            width: 40,
            child: pr
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: Metric.burn),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('PR', style: AppText.tab.copyWith(color: Colors.white)),
                    ),
                  )
                : null,
          ),
          IconButton(
            tooltip: s.done ? 'Set ${j + 1} done' : 'Mark set ${j + 1} done',
            onPressed: () {
              HapticFeedback.lightImpact();
              n.toggleDone(i, j);
            },
            onLongPress: () => n.removeSet(i, j),
            icon: Icon(
              s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: s.done ? Metric.startDot : p.sub,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showExercisePicker(BuildContext context, String? id) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x73040610),
  builder: (_) => _ExercisePicker(id: id),
);

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker({required this.id});

  final String? id;

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(String name, String group) {
    ref.read(gymFormProvider(widget.id).notifier).addExercise(name, group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = _query.text.trim();
    final history = ref.watch(gymFormProvider(widget.id).select((s) => s.history));
    final known = <(String, String)>[
      ...ExerciseLibrary.builtIn,
      for (final e in history.keys)
        if (ExerciseLibrary.groupOf(e) == null) (e[0].toUpperCase() + e.substring(1), 'full_body'),
    ];
    final matches = known.where((e) => e.$1.toLowerCase().contains(q.toLowerCase())).toList();
    final exact = known.any((e) => e.$1.toLowerCase() == q.toLowerCase());
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Glass(
          kind: GlassKind.bar,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Add exercise', style: AppText.display.copyWith(fontSize: 24, color: p.text)),
                      ),
                      GlassIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Glass(
                    kind: GlassKind.control,
                    radius: 18,
                    blur: false,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: p.sub),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _query,
                            onChanged: (_) => setState(() {}),
                            maxLength: ExerciseLibrary.maxNameLength,
                            textCapitalization: TextCapitalization.sentences,
                            style: AppText.body.copyWith(color: p.text),
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Search or type a new exercise',
                            ).copyWith(counterText: ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (q.isNotEmpty && !exact) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                      child: Text('Add “$q” to', style: AppText.small.copyWith(color: p.sub)),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final g in MuscleGroups.builtIn.entries.where((g) => g.key != 'cardio'))
                          ActionChip(label: Text(g.value), onPressed: () => _pick(q, g.key)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final (name, group) = matches[i];
                        final h = history[name.toLowerCase()];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            name,
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                          ),
                          subtitle: Text(
                            h == null
                                ? MuscleGroups.label(group)
                                : '${MuscleGroups.label(group)} · best ${kgText(h.best1rm)} kg 1RM',
                            style: AppText.small.copyWith(color: p.sub),
                          ),
                          trailing: Icon(Icons.add_circle_outline_rounded, color: p.accentText),
                          onTap: () => _pick(name, group),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key, required this.id});

  final String? id;

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = gymFormProvider(widget.id);
    final until = ref.watch(provider.select((s) => s.restUntil));
    final restSec = ref.watch(provider.select((s) => s.restSec));
    final n = ref.read(provider.notifier);
    if (until == null) {
      _timer?.cancel();
      _timer = null;
      return const SizedBox.shrink();
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = ref.read(provider).restUntil?.difference(ref.read(gymClockProvider)());
      if (left == null || left.inMilliseconds <= 0) {
        HapticFeedback.mediumImpact();
        n.skipRest();
      } else {
        setState(() {});
      }
    });
    final left = until.difference(ref.read(gymClockProvider)()).inSeconds.clamp(0, 600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Glass(
        kind: GlassKind.bar,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Metric.waterDot),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  'Rest ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                  style: AppText.number.copyWith(color: p.text),
                ),
              ),
            ),
            TextButton(onPressed: () => n.setRest(restSec - 15), child: const Text('−15')),
            TextButton(onPressed: () => n.setRest(restSec + 15), child: const Text('+15')),
            TextButton(onPressed: n.skipRest, child: const Text('Skip')),
          ],
        ),
      ),
    );
  }
}

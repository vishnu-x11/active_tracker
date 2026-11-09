import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../../../core/widgets/undo_snack.dart';
import '../../../profile/profile_api.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/protein.dart';
import '../notifiers/protein_notifier.dart';
import '../providers.dart';

String _g(double g) => g % 1 == 0 ? g.toStringAsFixed(0) : g.toStringAsFixed(1);

class ProteinScreen extends ConsumerWidget {
  const ProteinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adding = ref.watch(proteinProvider.select((s) => s.adding));
    return PopScope(
      canPop: !adding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(proteinProvider.notifier).close();
      },
      child: Scaffold(
        body: PageBackdrop(child: SafeArea(child: adding ? const _CustomEntry() : const _Today())),
      ),
    );
  }
}

Future<void> _addWithUndo(BuildContext context, WidgetRef ref, Future<ProteinEntry?> Function() add) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(proteinProvider.notifier);
  final e = await add();
  if (e == null) return;
  showUndoSnack(messenger, 'Added ${_g(e.grams)} g${e.food == null ? '' : ' · ${e.food}'}', () => notifier.remove(e));
}

class _Today extends ConsumerWidget {
  const _Today();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final day = dayKey(today);
    final total = ref.watch(dayTotalsProvider(day).select((v) => v.value?.proteinG)) ?? 0;
    final target = ref.watch(dayTargetsProvider(day).select((v) => v.value?.proteinG));
    final profile = ref.watch(profileProvider).value;
    final n = ref.read(proteinProvider.notifier);
    final f = target == null || target == 0 ? 0.0 : total / target;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        FormHeader(title: 'Protein', onBack: () => context.pop()),
        const SizedBox(height: 24),
        Center(
          child: Text(shortDate(today).toUpperCase(), style: AppText.eyebrow.copyWith(color: p.sub)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text.rich(
            TextSpan(
              text: _g(total),
              children: [
                TextSpan(
                  text: ' g',
                  style: AppText.title.copyWith(fontSize: 20, color: p.sub),
                ),
              ],
            ),
            style: AppText.hero.copyWith(fontSize: 54, color: p.text),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            target == null ? '' : (total >= target ? 'Target reached' : '${_g(target - total)} g to go'),
            style: AppText.body.copyWith(fontSize: 15, color: total >= (target ?? 1 << 30) ? p.goodFg : p.sub),
          ),
        ),
        const SizedBox(height: 20),
        Glass(
          radius: 28,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TODAY'S TARGET", style: AppText.eyebrow.copyWith(color: p.sub)),
                        Text.rich(
                          TextSpan(
                            text: '${(f * 100).round()}%',
                            children: [
                              TextSpan(
                                text: '  of ${target ?? '–'} g',
                                style: AppText.small.copyWith(color: p.sub),
                              ),
                            ],
                          ),
                          style: AppText.display.copyWith(fontSize: 26, color: p.text),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Add a custom entry',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: n.open,
                        child: const IconTile(icon: Icons.add_rounded, colors: Metric.protein, size: 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: f.clamp(0, 1)),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 14,
                    backgroundColor: p.tracks[2],
                    valueColor: AlwaysStoppedAnimation(Metric.protein.last),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Target ${target ?? '–'} g = ${profile?.proteinGPerKg ?? 1.6} g x ${profile?.weightKg.toStringAsFixed(0) ?? '–'} kg. '
                'Change the ratio in Profile.',
                style: AppText.small.copyWith(color: p.sub),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const FormSection('Quick add'),
        Row(
          children: [
            for (final (i, g) in [10, 20, 30, 40].indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Add $g grams',
                  excludeSemantics: true,
                  child: Glass(
                    kind: GlassKind.control,
                    radius: 20,
                    blur: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _addWithUndo(context, ref, () => n.quickAdd(g.toDouble())),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            const Icon(Icons.add_rounded, size: 16, color: Metric.proteinDot),
                            Text.rich(
                              TextSpan(
                                text: '$g',
                                children: [
                                  TextSpan(
                                    text: ' g',
                                    style: AppText.small.copyWith(color: p.sub),
                                  ),
                                ],
                              ),
                              style: AppText.number.copyWith(color: p.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Your foods', style: AppText.section.copyWith(color: p.text)),
            ),
            TextButton(
              onPressed: () => n.open(asNewFood: true),
              child: Text(
                '+ New food',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
              ),
            ),
          ],
        ),
        const _Foods(),
        const SizedBox(height: 20),
        _Logged(day: day),
      ],
    );
  }
}

class _Foods extends ConsumerWidget {
  const _Foods();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final foods = ref.watch(foodsProvider).value ?? Food.starters;
    final n = ref.read(proteinProvider.notifier);
    return Glass(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (i, f) in foods.indexed)
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                border: i == foods.length - 1 ? null : Border(bottom: BorderSide(color: p.hair)),
              ),
              child: Row(
                children: [
                  const IconTile(icon: Icons.restaurant_rounded, colors: Metric.protein, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                        ),
                        Text('${f.serving} · ${_g(f.grams)} g protein', style: AppText.small.copyWith(color: p.sub)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add ${f.name}',
                    icon: const Icon(Icons.add_circle_rounded, color: Metric.proteinDot),
                    onPressed: () => _addWithUndo(
                      context,
                      ref,
                      () => n.quickAdd(f.grams, food: f.serving == 'custom' ? f.name : '${f.name} ${f.serving}'),
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

class _Logged extends ConsumerWidget {
  const _Logged({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final entries = ref.watch(proteinDayProvider(day)).value ?? const <ProteinEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection('Logged today', note: '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}'),
        if (entries.isEmpty)
          Text('Nothing logged yet. Use quick add or your foods.', style: AppText.small.copyWith(color: p.sub))
        else
          Glass(
            blur: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (i, e) in entries.indexed)
                  Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      border: i == entries.length - 1 ? null : Border(bottom: BorderSide(color: p.hair)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Metric.proteinDot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.food ?? 'Quick add',
                                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                              ),
                              Text(clockTime(e.at), style: AppText.small.copyWith(fontSize: 12, color: p.sub)),
                            ],
                          ),
                        ),
                        Text('${_g(e.grams)} g', style: AppText.number.copyWith(fontSize: 15, color: p.text)),
                        IconButton(
                          tooltip: 'Remove ${e.food ?? 'entry'}',
                          icon: Icon(Icons.close_rounded, size: 18, color: p.sub),
                          onPressed: () => ref.read(proteinProvider.notifier).remove(e),
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

class _CustomEntry extends ConsumerStatefulWidget {
  const _CustomEntry();

  @override
  ConsumerState<_CustomEntry> createState() => _CustomEntryState();
}

class _CustomEntryState extends ConsumerState<_CustomEntry> {
  final _food = TextEditingController();
  final _grams = TextEditingController();

  @override
  void dispose() {
    _food.dispose();
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = ref.watch(proteinProvider);
    final n = ref.read(proteinProvider.notifier);
    final day = dayKey(ref.watch(todayProvider));
    final total = ref.watch(dayTotalsProvider(day).select((v) => v.value?.proteinG)) ?? 0;
    final target = ref.watch(dayTargetsProvider(day).select((v) => v.value?.proteinG));
    final now = TimeOfDay.now();
    final minute = s.minute ?? now.hour * 60 + now.minute;
    final g = double.tryParse(s.gramsText.replaceAll(',', '.'));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FormHeader(title: 'Custom entry', onBack: n.close),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              const Center(
                child: IconTile(icon: Icons.restaurant_rounded, colors: Metric.protein, size: 56),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('What did you eat?', style: AppText.display.copyWith(fontSize: 26, color: p.text)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${_g(total)} of ${target ?? '–'} g so far today',
                  style: AppText.body.copyWith(color: p.sub),
                ),
              ),
              const SizedBox(height: 20),
              GlassField(
                label: s.saveFood ? 'Food' : 'Food (optional)',
                controller: _food,
                onChanged: n.setFood,
                hint: 'e.g. Soya chunks 50 g',
                valueStyle: AppText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GlassField(
                      label: 'Protein',
                      controller: _grams,
                      onChanged: n.setGrams,
                      unit: 'g',
                      hint: '26',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PickerField(
                      label: 'Time',
                      value: clockTime(dateOnly(DateTime.now()).add(Duration(minutes: minute))),
                      icon: Icons.schedule_rounded,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
                        );
                        if (t != null) n.setMinute(t.hour * 60 + t.minute);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Glass(
                kind: GlassKind.control,
                radius: 20,
                child: SwitchListTile(
                  value: s.saveFood,
                  onChanged: (_) => n.toggleSaveFood(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Metric.proteinDot,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    s.saveFood ? 'Saved to my foods' : 'Save to my foods',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                  ),
                  subtitle: Text(
                    'Needs a food name. Shows up in Your foods.',
                    style: AppText.small.copyWith(color: p.sub),
                  ),
                ),
              ),
              if ((s.error ?? s.problem) != null) ...[
                const SizedBox(height: 10),
                Text(
                  s.error ?? s.problem!,
                  style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GradientButton(
            label: g == null ? 'Add protein' : 'Add ${_g(g)} g',
            busy: s.saving,
            onPressed: () => _addWithUndo(context, ref, () => n.addCustom()),
          ),
        ),
      ],
    );
  }
}

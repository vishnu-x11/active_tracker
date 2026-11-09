import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/goal.dart';
import '../../domain/use_cases/progress_rules.dart';
import '../progress_providers.dart';
import '../providers.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalPeriod _view = GoalPeriod.week;
  GoalKind _kind = GoalKind.runDistance;
  GoalPeriod _period = GoalPeriod.month;
  late final _target = TextEditingController(text: _fmt(_kind.start));

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  double? get _value => ProgressRules.parseTarget(_kind, _target.text);

  void _step(int dir) => setState(() => _target.text = _fmt(ProgressRules.stepTarget(_kind, _value ?? 0, dir)));

  Future<void> _add() async {
    final v = _value;
    if (v == null) return;
    final goal = Goal(id: ref.read(newIdProvider)(), kind: _kind, period: _period, target: v);
    final r = await ref.read(progressRepositoryProvider).addGoal(goal);
    if (!mounted) return;
    if (r case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    ref.invalidate(goalsProvider);
    setState(() => _view = _period);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final goals = (ref.watch(goalsProvider).value ?? const <GoalProgress>[])
        .where((g) => g.goal.period == _view)
        .toList();
    final today = ref.watch(todayProvider);
    final daysLeft = _view == GoalPeriod.week
        ? 7 - today.weekday
        : DateTime(today.year, today.month + 1, 0).day - today.day;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: '', onBack: () => context.pop()),
              const SizedBox(height: 8),
              Text('Goals', style: AppText.display.copyWith(fontSize: 32, color: p.text)),
              Text(
                '${_view == GoalPeriod.week ? 'THIS WEEK' : 'THIS MONTH'} · $daysLeft DAYS LEFT',
                style: AppText.eyebrow.copyWith(color: p.sub),
              ),
              const SizedBox(height: 16),
              GlassSegmented<GoalPeriod>(
                options: const [(GoalPeriod.week, 'Week'), (GoalPeriod.month, 'Month')],
                value: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
              const SizedBox(height: 16),
              if (goals.isEmpty)
                Glass(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const IconTile(icon: Icons.track_changes_rounded, colors: Metric.burn, size: 48),
                      const SizedBox(height: 10),
                      Text(
                        _view == GoalPeriod.week ? 'No weekly goals yet' : 'No monthly goals yet',
                        style: AppText.cardTitle.copyWith(color: p.text),
                      ),
                      Text('Pick a type below and set a target.', style: AppText.small.copyWith(color: p.sub)),
                    ],
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [for (final g in goals) _GoalCard(progress: g)],
                ),
              const SizedBox(height: 20),
              Glass(
                radius: 32,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('New goal', style: AppText.section.copyWith(color: p.text)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in GoalKind.values)
                          ChoiceChip(
                            label: Text(k.label),
                            selected: k == _kind,
                            onSelected: (_) => setState(() {
                              _kind = k;
                              _target.text = _fmt(k.start);
                            }),
                            selectedColor: Metric.cta.last,
                            labelStyle: AppText.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: k == _kind ? Colors.white : p.text,
                            ),
                            backgroundColor: p.glassHi.first,
                            side: BorderSide(color: p.edge),
                            shape: const StadiumBorder(),
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Glass(
                      kind: GlassKind.control,
                      radius: 24,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          GlassIconButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'Decrease target',
                            onPressed: () => _step(-1),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _target,
                                  onChanged: (_) => setState(() {}),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.numberWithOptions(decimal: _kind.decimals),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(_kind.decimals ? r'[\d.,]' : r'\d')),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  style: AppText.display.copyWith(fontSize: 32, color: p.text),
                                  decoration: const InputDecoration.collapsed(hintText: '0'),
                                ),
                                Text(
                                  '${_kind.unit} per ${_period.name}',
                                  style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                                ),
                              ],
                            ),
                          ),
                          GlassIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Increase target',
                            onPressed: () => _step(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _value == null
                          ? 'Enter a target above 0.'
                          : 'Type a number or use − / + (${_kind.step} ${_kind.unit} a step)',
                      textAlign: TextAlign.center,
                      style: AppText.small.copyWith(color: _value == null ? p.danger : p.sub),
                    ),
                    const SizedBox(height: 14),
                    GlassSegmented<GoalPeriod>(
                      options: const [(GoalPeriod.week, 'Per week'), (GoalPeriod.month, 'Per month')],
                      value: _period,
                      onChanged: (v) => setState(() => _period = v),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(label: 'Add goal', onPressed: _value == null ? null : _add),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final g = progress.goal;
    final f = g.target == 0 ? 0.0 : (progress.done / g.target).clamp(0, 1).toDouble();
    final colors = switch (g.kind) {
      GoalKind.runDistance => Metric.run,
      GoalKind.proteinDays => Metric.protein,
      GoalKind.waterDays => Metric.water,
      _ => Metric.burn,
    };
    String n(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return Glass(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 64,
                      child: CircularProgressIndicator(
                        value: f,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: p.tracks[0],
                        valueColor: AlwaysStoppedAnimation(colors.last),
                      ),
                    ),
                    Text(
                      '${(f * 100).round()}%',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: p.text),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  g.kind.title(g.target),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(color: p.text),
                ),
              ),
              Text('${n(progress.done)} of ${n(g.target)} ${g.kind.unit}', style: AppText.small.copyWith(color: p.sub)),
            ],
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              tooltip: 'Remove goal ${g.kind.title(g.target)}',
              icon: Icon(Icons.close_rounded, size: 16, color: p.sub),
              onPressed: () async {
                await ref.read(progressRepositoryProvider).removeGoal(g.id);
                ref.invalidate(goalsProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
}

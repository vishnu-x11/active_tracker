import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/undo_snack.dart';
import '../../../profile/profile_api.dart';
import '../../../progress/progress.dart';
import '../../hydration_routes.dart';
import '../notifiers/water_add_notifier.dart';
import '../providers.dart';
import '../widgets/water_tank.dart';

final _n = NumberFormat.decimalPattern('en_US');

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  static List<Orb> _orbs(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? 0.4 : 0.5;
    return [
      Orb(const Alignment(-0.7, -0.75), 240, Metric.water.last.withValues(alpha: a)),
      Orb(const Alignment(1.1, -0.2), 260, Metric.water.first.withValues(alpha: a * 0.9)),
      Orb(const Alignment(-1.1, 0.35), 240, Metric.run.first.withValues(alpha: a * 0.8)),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PageBackdrop(
        orbs: _orbs(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                FormHeader(title: 'Hydration', onBack: () => context.pop()),
                const SizedBox(height: 16),
                const _Today(),
                const SizedBox(height: 16),
                const Expanded(child: _Tank()),
                const SizedBox(height: 12),
                const _QuickLog(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Today extends ConsumerWidget {
  const _Today();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final day = dayKey(today);
    final ml = ref.watch(dayTotalsProvider(day).select((v) => v.value?.waterMl)) ?? 0;
    final target = ref.watch(dayTargetsProvider(day).select((v) => v.value?.waterMl));
    final last = ref.watch(waterDayProvider(day).select((v) => v.value?.firstOrNull?.at));
    final lastText = last == null ? '' : ' · last drink ${clockTime(last)}';
    final status = target == null
        ? ''
        : ml >= target
        ? 'Hydrated · target reached$lastText'
        : '${_n.format(target - ml)} ml to go$lastText';
    return Column(
      children: [
        Text(shortDate(today).toUpperCase(), style: AppText.eyebrow.copyWith(color: p.sub)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_rounded, size: 32, color: Metric.water.last),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  text: _n.format(ml),
                  children: [
                    TextSpan(
                      text: ' ml',
                      style: AppText.title.copyWith(fontSize: 20, color: p.sub),
                    ),
                  ],
                ),
                style: AppText.hero.copyWith(fontSize: 54, color: p.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          status,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(fontSize: 15, color: p.sub),
        ),
      ],
    );
  }
}

class _Tank extends ConsumerWidget {
  const _Tank();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final day = dayKey(ref.watch(todayProvider));
    final ml = ref.watch(dayTotalsProvider(day).select((v) => v.value?.waterMl)) ?? 0;
    final target = ref.watch(dayTargetsProvider(day).select((v) => v.value?.waterMl));
    final f = target == null || target == 0 ? 0.0 : ml / target;
    return Semantics(
      container: true,
      label: "Water ${(f * 100).round()}% of today's target",
      child: SizedBox.expand(
        child: WaterTank(
          fraction: f,
          child: Stack(
            children: [
              if (target != null)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${(f * 100).round()}% of ${_n.format(target)} ml',
                      style: AppText.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: f >= 0.9 ? Colors.white : p.sub,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundButton(
                      tooltip: 'How is my target calculated?',
                      onTap: () => _help(context, ref, target),
                      child: Text('?', style: AppText.display.copyWith(fontSize: 22, color: Colors.white)),
                    ),
                    _RoundButton(
                      tooltip: 'Hydration history',
                      onTap: () => context.push(HydrationRoutes.history),
                      child: const Icon(Icons.checklist_rounded, size: 24, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _help(BuildContext context, WidgetRef ref, int? target) {
    final p = context.palette;
    final profile = ref.read(profileProvider).value;
    final day = dayKey(ref.read(todayProvider));
    final workout = ref.read(dayTotalsProvider(day)).value?.isWorkoutDay ?? false;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Glass(
        kind: GlassKind.bar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('YOUR TARGET TODAY', style: AppText.eyebrow.copyWith(color: p.sub)),
              Text('${_n.format(target ?? 0)} ml', style: AppText.hero.copyWith(fontSize: 44, color: p.text)),
              const SizedBox(height: 12),
              _HelpLine(
                '${profile?.waterMlPerKg ?? 35} ml x ${profile?.weightKg.toStringAsFixed(0) ?? '–'} kg',
                '${_n.format(((profile?.waterMlPerKg ?? 35) * (profile?.weightKg ?? 0)).round())} ml',
              ),
              _HelpLine('Workout day (gym or run logged)', workout ? '+ 500 ml' : 'not today'),
              const SizedBox(height: 10),
              Text(
                'Change the ml per kg in Profile. Tea, coffee and other drinks can be logged as custom amounts.',
                style: AppText.small.copyWith(color: p.sub),
              ),
              const SizedBox(height: 16),
              GradientButton(label: 'Got it', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hair)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: p.sub)),
          ),
          Text(
            value,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.onTap, required this.child});

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.42))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(dimension: 56, child: Center(child: child)),
      ),
    ),
  );
}

class _QuickLog extends ConsumerStatefulWidget {
  const _QuickLog();

  @override
  ConsumerState<_QuickLog> createState() => _QuickLogState();
}

class _QuickLogState extends ConsumerState<_QuickLog> {
  late final _amount = TextEditingController(text: ref.read(waterAddProvider).amountText);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(waterAddProvider.notifier);
    FocusScope.of(context).unfocus();
    final added = await notifier.add();
    if (added == null) return;
    showUndoSnack(messenger, 'Added ${_n.format(added.ml)} ml', () => notifier.undo(added), above: 84);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = ref.read(waterAddProvider.notifier);
    ref.listen(waterAddProvider.select((s) => s.amountText), (_, v) {
      if (_amount.text != v) _amount.text = v;
    });
    final (problem, saving) = ref.watch(waterAddProvider.select((s) => (s.error ?? s.problem, s.saving)));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          kind: GlassKind.bar,
          radius: 28,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _Nudge(label: '−', tooltip: '50 ml less', onTap: () => n.nudge(-1)),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: _amount,
                        onChanged: n.setAmount,
                        onSubmitted: (_) => _add(),
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        style: AppText.display.copyWith(fontSize: 26, color: p.text),
                        decoration: const InputDecoration.collapsed(hintText: '250'),
                      ),
                    ),
                    Text(' ml', style: AppText.body.copyWith(color: p.sub)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _Nudge(label: '+', tooltip: '50 ml more', onTap: () => n.nudge(1)),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: GradientButton(label: 'Add', busy: saving, onPressed: _add),
              ),
            ],
          ),
        ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              problem,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
            ),
          ),
      ],
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({required this.label, required this.tooltip, required this.onTap});

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: TapGlass(
      kind: GlassKind.control,
      radius: 20,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 56,
        child: Center(
          child: Text(label, style: AppText.display.copyWith(fontSize: 26, color: context.palette.text)),
        ),
      ),
    ),
  );
}

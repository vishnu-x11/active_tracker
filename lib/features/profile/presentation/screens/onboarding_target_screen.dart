import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../domain/entities/body_stats_rules.dart';
import '../../profile_routes.dart';
import '../notifiers/onboarding_notifier.dart';
import '../widgets/onboarding_frame.dart';

class OnboardingTargetScreen extends ConsumerStatefulWidget {
  const OnboardingTargetScreen({super.key});

  @override
  ConsumerState<OnboardingTargetScreen> createState() => _OnboardingTargetScreenState();
}

class _OnboardingTargetScreenState extends ConsumerState<OnboardingTargetScreen> {
  late final _target = TextEditingController(text: ref.read(onboardingProvider).burnTarget);

  static const _step = 50;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _nudge(int by) {
    final now = BodyStatsRules.parseWhole(_target.text) ?? defaultBurnTargetKcal;
    final next = by > 0 ? (now ~/ _step + 1) * _step : ((now - 1) ~/ _step) * _step;
    final value = '${next < _step ? _step : next}';
    _target.text = value;
    ref.read(onboardingProvider.notifier).setBurnTarget(value);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);
    final (burnError, saving, error) = ref.watch(onboardingProvider.select((s) => (s.burnError, s.saving, s.error)));

    return OnboardingFrame(
      step: 3,
      icon: Icons.local_fire_department_rounded,
      title: 'Daily burn target',
      subtitle:
          'Calories you want to burn in workouts each day. 600 kcal is a good start; change it any time in Profile.',
      onBack: () => context.go(ProfileRoutes.onboarding),
      button: GradientButton(label: 'Start tracking', busy: saving, onPressed: notifier.finish),
      children: [
        if (error != null) ...[FormMessage(text: error), const SizedBox(height: 12)],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GlassIconButton(
                icon: Icons.remove_rounded,
                onPressed: () => _nudge(-1),
                tooltip: 'Less, by 50 kcal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassField(
                label: 'Burn target per day',
                controller: _target,
                onChanged: notifier.setBurnTarget,
                unit: 'kcal',
                error: burnError,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                valueStyle: AppText.display.copyWith(fontSize: 28),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => notifier.finish(),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GlassIconButton(icon: Icons.add_rounded, onPressed: () => _nudge(1), tooltip: 'More, by 50 kcal'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _TargetHint(),
      ],
    );
  }
}

class _TargetHint extends ConsumerWidget {
  const _TargetHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (target, gymHour) = ref.watch(
      onboardingProvider.select((s) => (BodyStatsRules.parseWhole(s.burnTarget), s.gymHourKcal)),
    );
    final text = target == null || target <= 0 || gymHour == null || gymHour == 0
        ? 'Burn from gym sessions and runs counts towards this.'
        : 'About ${_hours(target / gymHour)} of moderate gym at your weight. Gym sessions and runs both count.';
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconTile(icon: Icons.fitness_center_rounded, colors: Metric.burn),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppText.small.copyWith(height: 1.45, color: p.sub)),
          ),
        ],
      ),
    );
  }

  static String _hours(double h) {
    final mins = (h * 60).round();
    if (mins < 60) return '$mins min';
    final rest = mins % 60;
    return rest == 0 ? '${mins ~/ 60} h' : '${mins ~/ 60} h $rest min';
  }
}

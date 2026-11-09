import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../domain/entities/profile.dart';
import '../../profile_routes.dart';
import '../notifiers/onboarding_notifier.dart';
import '../widgets/daily_targets_card.dart';
import '../widgets/onboarding_frame.dart';

class OnboardingBodyScreen extends ConsumerStatefulWidget {
  const OnboardingBodyScreen({super.key, this.action});

  final Widget? action;

  @override
  ConsumerState<OnboardingBodyScreen> createState() => _OnboardingBodyScreenState();
}

class _OnboardingBodyScreenState extends ConsumerState<OnboardingBodyScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();

  static final _decimal = [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')), LengthLimitingTextInputFormatter(6)];
  static final _whole = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)];

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);
    final (weightError, heightError, ageError) = ref.watch(
      onboardingProvider.select((s) => (s.weightError, s.heightError, s.ageError)),
    );

    return OnboardingFrame(
      step: 2,
      icon: Icons.monitor_weight_outlined,
      title: 'Your body stats',
      subtitle: 'Weight and height are used to estimate calories burned in every gym session and run.',
      action: widget.action,
      button: GradientButton(
        label: 'Continue',
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (notifier.continueToTarget()) context.go(ProfileRoutes.target);
        },
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassField(
                label: 'Weight',
                controller: _weight,
                onChanged: notifier.setWeight,
                unit: 'kg',
                hint: 'e.g. 75',
                error: weightError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimal,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassField(
                label: 'Height',
                controller: _height,
                onChanged: notifier.setHeight,
                unit: 'cm',
                hint: 'e.g. 178',
                error: heightError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimal,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SectionLabel('Optional, for resting burn'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassField(
                label: 'Age',
                controller: _age,
                onChanged: notifier.setAge,
                hint: 'e.g. 29',
                error: ageError,
                keyboardType: TextInputType.number,
                inputFormatters: _whole,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(flex: 7, child: _SexPicker()),
          ],
        ),
        const SizedBox(height: 20),
        const DailyTargetsCard(),
      ],
    );
  }
}

class _SexPicker extends ConsumerWidget {
  const _SexPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final sex = ref.watch(onboardingProvider.select((s) => s.sex));
    return Glass(
      kind: GlassKind.control,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sex',
            style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<Sex?>(
              value: sex,
              isExpanded: true,
              isDense: true,
              hint: Text(
                'Choose',
                style: AppText.number.copyWith(fontWeight: FontWeight.w600, color: p.sub),
              ),
              icon: Icon(Icons.expand_more_rounded, color: p.sub),
              dropdownColor: p.pageTop,
              borderRadius: BorderRadius.circular(18),
              style: AppText.number.copyWith(fontWeight: FontWeight.w600, color: p.text),
              items: [
                for (final s in Sex.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: ref.read(onboardingProvider.notifier).setSex,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../notifiers/onboarding_notifier.dart';

class DailyTargetsCard extends ConsumerWidget {
  const DailyTargetsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (bmi, label, protein, water, gymHour) = ref.watch(
      onboardingProvider.select((s) => (s.bmiValue, s.bmiLabel, s.proteinG, s.waterMl, s.gymHourKcal)),
    );
    const dash = '–';
    return Glass(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR DAILY TARGETS', style: AppText.eyebrow.copyWith(color: p.sub)),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(value: bmi?.toStringAsFixed(1) ?? dash, unit: '', label: 'BMI${label == null ? '' : ' · $label'}'),
              _Stat(value: protein?.toString() ?? dash, unit: 'g', label: 'Protein', dot: Metric.proteinDot),
              _Stat(
                value: water == null ? dash : (water / 1000).toStringAsFixed(1),
                unit: 'L',
                label: 'Water',
                dot: Metric.waterDot,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: p.hair),
          const SizedBox(height: 14),
          Row(
            children: [
              const IconTile(icon: Icons.fitness_center_rounded, colors: Metric.burn),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'A 1 hour moderate gym session burns about ',
                    children: [
                      TextSpan(
                        text: gymHour == null ? '$dash kcal' : '$gymHour kcal',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.accentText),
                      ),
                      const TextSpan(text: ' at your weight.'),
                    ],
                  ),
                  style: AppText.small.copyWith(height: 1.45, color: p.sub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.unit, required this.label, this.dot});

  final String value;
  final String unit;
  final String label;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              children: [
                TextSpan(
                  text: unit.isEmpty ? '' : ' $unit',
                  style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                ),
              ],
            ),
            style: AppText.display.copyWith(fontSize: 24, color: p.text),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

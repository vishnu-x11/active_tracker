import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../progress/progress.dart';
import 'glow_bar.dart';

final _n = NumberFormat.decimalPattern('en_US');

class BurnedTodayCard extends StatelessWidget {
  const BurnedTodayCard({super.key, required this.day, this.onOpen});

  final String day;

  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('BURNED TODAY', style: AppText.eyebrow.copyWith(color: p.sub)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _StatusPill(day: day),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _BurnHero(day: day),
          const SizedBox(height: 18),
          _Bar(day: day, metric: _Metric.burn, onOpen: onOpen),
          const SizedBox(height: 16),
          _Bar(day: day, metric: _Metric.water, onOpen: onOpen),
          const SizedBox(height: 16),
          _Bar(day: day, metric: _Metric.protein, onOpen: onOpen),
          _ErrorLine(day: day),
        ],
      ),
    );
  }
}

class _BurnHero extends ConsumerWidget {
  const _BurnHero({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final burn = ref.watch(dayTotalsProvider(day).select((v) => v.value?.burnKcal));
    return Text.rich(
      TextSpan(
        text: burn == null ? '–' : _n.format(burn),
        children: [
          TextSpan(
            text: ' kcal',
            style: AppText.title.copyWith(fontWeight: FontWeight.w500, color: p.sub),
          ),
        ],
      ),
      style: AppText.hero.copyWith(color: p.text),
    );
  }
}

class _StatusPill extends ConsumerWidget {
  const _StatusPill({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final burn = ref.watch(dayTotalsProvider(day).select((v) => v.value?.burnKcal));
    final target = ref.watch(dayTargetsProvider(day).select((v) => v.value?.burnKcal));
    if (burn == null || target == null) return const SizedBox(height: 24);
    final over = burn >= target;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: over ? p.goodBg : p.text.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (over) ...[Icon(Icons.check_rounded, size: 13, color: p.goodFg), const SizedBox(width: 4)],
          Text(
            over ? '${_n.format(burn - target)} over target' : '${_n.format(target - burn)} kcal to go',
            style: AppText.tab.copyWith(fontSize: 12, color: over ? p.goodFg : p.sub),
          ),
        ],
      ),
    );
  }
}

enum _Metric { burn, water, protein }

class _Bar extends ConsumerWidget {
  const _Bar({required this.day, required this.metric, this.onOpen});

  final String day;
  final _Metric metric;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final (num? value, int? target) = switch (metric) {
      _Metric.burn => (
        ref.watch(dayTotalsProvider(day).select((v) => v.value?.burnKcal)),
        ref.watch(dayTargetsProvider(day).select((v) => v.value?.burnKcal)),
      ),
      _Metric.water => (
        ref.watch(dayTotalsProvider(day).select((v) => v.value?.waterMl)),
        ref.watch(dayTargetsProvider(day).select((v) => v.value?.waterMl)),
      ),
      _Metric.protein => (
        ref.watch(dayTotalsProvider(day).select((v) => v.value?.proteinG)),
        ref.watch(dayTargetsProvider(day).select((v) => v.value?.proteinG)),
      ),
    };
    final v = value ?? 0;
    final fraction = target == null || target == 0 ? null : v / target;
    return switch (metric) {
      _Metric.burn => GlowBar(
        name: 'Burn',
        value: _n.format(v),
        target: target == null ? null : '${_n.format(target)} kcal',
        fraction: fraction,
        colors: Metric.burn,
        track: p.tracks[0],
        onTap: onOpen == null ? null : () => onOpen!('burn'),
      ),
      _Metric.water => GlowBar(
        name: 'Water',
        value: (v / 1000).toStringAsFixed(2),
        target: target == null ? null : '${(target / 1000).toStringAsFixed(1)} L',
        fraction: fraction,
        colors: Metric.water,
        track: p.tracks[1],
        onTap: onOpen == null ? null : () => onOpen!('water'),
      ),
      _Metric.protein => GlowBar(
        name: 'Protein',
        value: v.round().toString(),
        target: target == null ? null : '$target g',
        fraction: fraction,
        colors: Metric.protein,
        track: p.tracks[2],
        onTap: onOpen == null ? null : () => onOpen!('protein'),
      ),
    };
  }
}

class _ErrorLine extends ConsumerWidget {
  const _ErrorLine({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(dayTotalsProvider(day).select((v) => v.hasError ? v.error : null));
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        error is Failure ? error.message : "Couldn't load today's totals.",
        style: AppText.small.copyWith(color: context.palette.danger),
      ),
    );
  }
}

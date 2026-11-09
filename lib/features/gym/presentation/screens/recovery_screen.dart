import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/muscle_groups.dart';
import '../../domain/use_cases/muscle_recovery.dart';
import '../providers.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  static Color colorFor(int percent) {
    const red = Color(0xFFFF4F5A), amber = Color(0xFFFFB547), green = Color(0xFF22C38E);
    return percent < 50
        ? Color.lerp(red, amber, percent / 50)!
        : Color.lerp(amber, green, ((percent - 50) / 50).clamp(0, 1))!;
  }

  static String statusFor(int percent) => percent >= 90 ? 'Ready' : (percent >= 60 ? 'Almost ready' : 'Recovering');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final recovery = ref.watch(muscleRecoveryProvider);
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(title: 'Muscle recovery', onBack: () => context.pop()),
              const SizedBox(height: 16),
              switch (recovery) {
                AsyncData(:final value) => _Body(recovery: value),
                AsyncError(:final error) => Text(
                  error is Failure ? error.message : "Couldn't work out your recovery.",
                  style: TextStyle(color: p.danger),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.recovery});

  final Map<String, int> recovery;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ready = [
      for (final g in MuscleRecovery.mapped)
        if (recovery[g]! >= 90) MuscleGroups.label(g),
    ];
    final avg = recovery.values.fold(0, (a, b) => a + b) ~/ recovery.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: avg / 100,
                      strokeWidth: 7,
                      backgroundColor: p.hair,
                      color: RecoveryScreen.colorFor(avg),
                    ),
                    Center(
                      child: Text('$avg%', style: AppText.number.copyWith(fontSize: 16, color: p.text)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OVERALL', style: AppText.eyebrow.copyWith(color: p.sub)),
                    Text(
                      ready.length == MuscleRecovery.mapped.length
                          ? 'Fully recovered'
                          : (ready.isEmpty ? 'Take it easy today' : 'Ready: ${ready.join(', ')}'),
                      style: AppText.cardTitle.copyWith(color: p.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < MuscleRecovery.mapped.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Tile(group: MuscleRecovery.mapped[i], percent: recovery[MuscleRecovery.mapped[i]]!),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < MuscleRecovery.mapped.length
                    ? _Tile(group: MuscleRecovery.mapped[i + 1], percent: recovery[MuscleRecovery.mapped[i + 1]]!)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        Text(
          'Worked out from your gym sessions of the last 3 days: each muscle group you trained '
          'recovers over 36 h (light), 48 h (moderate) or 72 h (hard). Full body counts for every group. '
          'An estimate; listen to your body.',
          style: AppText.small.copyWith(color: p.sub),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.group, required this.percent});

  final String group;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = RecoveryScreen.colorFor(percent);
    return Semantics(
      container: true,
      label: '${MuscleGroups.label(group)} $percent percent recovered',
      excludeSemantics: true,
      child: Glass(
        blur: false,
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MuscleGroups.label(group),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
            ),
            const SizedBox(height: 4),
            Text('$percent%', style: AppText.number.copyWith(fontSize: 22, color: c)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: percent / 100, minHeight: 8, backgroundColor: p.hair, color: c),
            ),
            const SizedBox(height: 6),
            Text(
              RecoveryScreen.statusFor(percent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(color: p.sub),
            ),
          ],
        ),
      ),
    );
  }
}

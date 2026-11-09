import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../providers.dart';

final _n = NumberFormat.decimalPattern('en_US');

Future<void> showDayGoals(BuildContext context, DateTime day) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close',
  barrierColor: Theme.of(context).brightness == Brightness.dark ? const Color(0x8C040610) : const Color(0x471E243C),
  transitionDuration: const Duration(milliseconds: 180),
  pageBuilder: (context, _, _) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _DayGoals(day: day),
    ),
  ),
  transitionBuilder: (context, a, _, child) => FadeTransition(
    opacity: a,
    child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child),
  ),
);

class _DayGoals extends ConsumerWidget {
  const _DayGoals({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final key = dayKey(day);
    final isToday = key == dayKey(ref.watch(todayProvider));
    final t = ref.watch(dayTotalsProvider(key)).value;
    final target = ref.watch(dayTargetsProvider(key)).value;
    final rows = [
      ('Burn', t?.burnKcal ?? 0, target?.burnKcal, 'kcal', Metric.burn, p.tracks[0]),
      ('Water', t?.waterMl ?? 0, target?.waterMl, 'ml', Metric.water, p.tracks[1]),
      ('Protein', (t?.proteinG ?? 0).round(), target?.proteinG, 'g', Metric.protein, p.tracks[2]),
    ];
    final met = rows.where((r) => r.$3 != null && r.$2 >= r.$3!).length;
    final kind = t == null
        ? 'Rest day'
        : t.runCount > 0 && t.gymCount > 0
        ? 'Run and gym'
        : t.runCount > 0
        ? 'Run day'
        : t.gymCount > 0
        ? 'Gym day'
        : 'Rest day';
    final (chipBg, chipFg, chip) = met == 3
        ? (p.goodBg, p.goodFg, 'All 3 goals met')
        : isToday
        ? (p.text.withValues(alpha: 0.06), p.sub, '$met of 3 met so far')
        : (Metric.alert.withValues(alpha: 0.16), p.danger, '$met of 3 goals met');
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Goals for ${shortDate(day)}',
      child: Glass(
        kind: GlassKind.bar,
        radius: 32,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isToday ? 'Today' : weekdayShort[day.weekday - 1]}, ${day.day} ${monthLong[day.month - 1]}',
                        style: AppText.title.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: p.text),
                      ),
                      Text(kind, style: AppText.small.copyWith(color: p.sub)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: p.sub),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(14)),
                child: Text(chip, style: AppText.tab.copyWith(fontSize: 12, color: chipFg)),
              ),
            ),
            const SizedBox(height: 16),
            for (final (name, value, goal, unit, colors, track) in rows) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: _n.format(value),
                      children: [
                        TextSpan(
                          text: ' / ${goal == null ? '–' : _n.format(goal)} $unit',
                          style: TextStyle(color: p.sub),
                        ),
                      ],
                    ),
                    style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: p.text),
                  ),
                  const SizedBox(width: 8),
                  _Badge(met: goal != null && value >= goal, today: isToday),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: goal == null || goal == 0 ? 0 : (value / goal).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: track,
                  valueColor: AlwaysStoppedAnimation(colors.last),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.met, required this.today});

  final bool met;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = met
        ? (Metric.proteinDot, Icons.check_rounded, 'met')
        : today
        ? (context.palette.tabIdle, Icons.schedule_rounded, 'in progress')
        : (Metric.alert, Icons.priority_high_rounded, 'missed');
    return Semantics(
      label: label,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}

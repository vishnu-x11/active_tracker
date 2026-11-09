import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../progress/progress.dart';

class ThisWeekCard extends ConsumerWidget {
  const ThisWeekCard({super.key, required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final week = ref.watch(weekBurnProvider(dayKey(mondayOf(today)))).value;
    final days = week?.days ?? List.filled(7, 0);
    final top = days.fold(0, (a, b) => a > b ? a : b);
    final change = week?.changePct;
    final todayIndex = today.weekday - 1;
    return Semantics(
      container: true,
      label:
          'This week ${week?.total ?? 0} kcal${change == null ? '' : ', ${change >= 0 ? 'up' : 'down'} ${change.abs()}% on last week'}',
      excludeSemantics: true,
      child: Glass(
        radius: 28,
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIS WEEK', style: AppText.eyebrow.copyWith(color: p.sub)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: NumberFormat.decimalPattern('en_US').format(week?.total ?? 0),
                        children: [
                          TextSpan(
                            text: ' kcal',
                            style: AppText.small.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                      style: AppText.display.copyWith(fontSize: 26, color: p.text),
                    ),
                  ),
                  if (change != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${change >= 0 ? '+' : ''}$change% vs last week',
                      style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: change >= 0 ? p.goodFg : p.sub),
                    ),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: 12,
                    height: top == 0 ? 8 : (days[i] / top * 64).clamp(8, 64).toDouble(),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: i == todayIndex
                          ? const LinearGradient(
                              colors: Metric.burn,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: i == todayIndex ? null : p.text.withValues(alpha: days[i] > 0 ? 0.14 : 0.06),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekdayShort[i][0],
                    style: AppText.tab.copyWith(
                      fontWeight: i == todayIndex ? FontWeight.w700 : FontWeight.w500,
                      color: i == todayIndex ? p.text : p.sub,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

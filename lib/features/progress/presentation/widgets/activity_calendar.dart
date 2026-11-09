import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/use_cases/progress_rules.dart';
import '../progress_providers.dart';
import 'day_goals_dialog.dart';

class ActivityCalendar extends ConsumerStatefulWidget {
  const ActivityCalendar({super.key, required this.today});

  final DateTime today;

  @override
  ConsumerState<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends ConsumerState<ActivityCalendar> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  static const monthsBack = 12;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = DateTime(widget.today.year, widget.today.month - monthsBack);
    final canBack = _month.isAfter(first);
    final canForward = _month.isBefore(DateTime(widget.today.year, widget.today.month));
    final days = ref.watch(calendarMonthProvider(_month)).value;
    final missedDays = days?.where((d) => d.missed.isNotEmpty).toList() ?? const [];
    final counts = <DailyGoal, int>{};
    for (final d in missedDays) {
      for (final g in d.missed) {
        counts.update(g, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final top = counts.entries.isEmpty ? null : (counts.entries.toList()..sort((a, b) => b.value - a.value)).first.key;
    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Activity calendar', style: AppText.section.copyWith(color: p.text)),
              ),
              IconButton(
                tooltip: 'Previous month',
                onPressed: canBack ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
                icon: Icon(Icons.chevron_left_rounded, color: canBack ? p.text : p.hair),
              ),
              Text(
                '${monthShort[_month.month - 1]} ${_month.year}',
                style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.sub),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: canForward ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null,
                icon: Icon(Icons.chevron_right_rounded, color: canForward ? p.text : p.hair),
              ),
            ],
          ),
          Container(height: 1, color: p.hair),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final w in weekdayShort)
                Expanded(
                  child: Center(
                    child: Text(w, style: AppText.tab.copyWith(color: p.sub)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (days == null) const SizedBox(height: 240) else _Grid(days: days),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: [
              const _Legend(color: Metric.runDot, label: 'Run'),
              _Legend(color: Metric.burn.first, label: 'Gym only'),
              _Legend(ring: p.accentText, label: 'Today'),
              const _Legend(badge: true, label: 'Goal missed'),
            ],
          ),
          if (missedDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Metric.alert.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const _MissBadge(size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${missedDays.length} day${missedDays.length == 1 ? '' : 's'} in ${monthLong[_month.month - 1]} '
                      'missed a daily goal. Most often: ${top!.name}. Tap a day for its goals.',
                      style: AppText.small.copyWith(color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.days});

  final List<CalendarDay> days;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lead = days.first.date.weekday - 1;
    final cells = <Widget>[for (var i = 0; i < lead; i++) const SizedBox()];
    for (final d in days) {
      final label = [
        '${d.date.day} ${monthLong[d.date.month - 1]}',
        if (d.run && d.gym) 'run and gym' else if (d.run) 'run' else if (d.gym) 'gym',
        if (d.today) 'today',
        if (d.missed.isNotEmpty) 'missed ${d.missed.map((g) => g.name).join(', ')}',
      ].join(', ');
      cells.add(
        Semantics(
          button: !d.future,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: d.future ? null : () => showDayGoals(context, d.date),
            child: Opacity(
              opacity: d.future ? 0.45 : 1,
              child: Center(
                child: SizedBox.square(
                  dimension: 38,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: d.run ? const LinearGradient(colors: Metric.run) : null,
                          color: d.run
                              ? null
                              : (d.gym ? Metric.burn.first.withValues(alpha: 0.28) : p.text.withValues(alpha: 0.06)),
                          border: d.today ? Border.all(color: p.accentText, width: 2) : null,
                        ),
                        child: Text(
                          '${d.date.day}',
                          style: AppText.tab.copyWith(
                            fontSize: 12,
                            fontWeight: d.today ? FontWeight.w700 : FontWeight.w600,
                            color: d.run ? Colors.white : (d.gym ? p.accentText : p.sub),
                          ),
                        ),
                      ),
                      if (d.missed.isNotEmpty) const Positioned(top: -1, right: -1, child: _MissBadge(size: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      children: cells,
    );
  }
}

class _MissBadge extends StatelessWidget {
  const _MissBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Metric.alert,
      shape: BoxShape.circle,
      border: Border.all(color: context.palette.pageTop, width: 1.4),
      boxShadow: [BoxShadow(color: Metric.alert.withValues(alpha: 0.45), blurRadius: 3, offset: const Offset(0, 2))],
    ),
    child: Icon(Icons.priority_high_rounded, size: size * 0.7, color: Colors.white),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, this.color, this.ring, this.badge = false});

  final String label;
  final Color? color;
  final Color? ring;
  final bool badge;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (badge)
        const _MissBadge(size: 12)
      else
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: ring == null ? null : Border.all(color: ring!, width: 2),
          ),
        ),
      const SizedBox(width: 6),
      Text(label, style: AppText.tab.copyWith(fontSize: 12, color: context.palette.sub)),
    ],
  );
}

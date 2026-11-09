import 'package:flutter/material.dart';

import '../dates.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

class DateStrip extends StatefulWidget {
  const DateStrip({
    super.key,
    required this.first,
    required this.last,
    required this.today,
    required this.selected,
    required this.active,
    required this.onPick,
    this.initial,
  });

  final DateTime first;
  final DateTime last;
  final DateTime today;

  final DateTime? selected;

  final Set<String> active;
  final ValueChanged<DateTime> onPick;

  final DateTime? initial;

  static const itemWidth = 52.0, gap = 8.0;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  late final ScrollController _scroll;

  int get _count => widget.last.difference(widget.first).inDays + 1;

  @override
  void initState() {
    super.initState();
    final target = widget.initial ?? widget.selected ?? widget.today;
    final index = target.difference(widget.first).inDays.clamp(0, _count - 1);
    _scroll = ScrollController(
      initialScrollOffset: ((index - 5) * (DateStrip.itemWidth + DateStrip.gap)).clamp(0, double.infinity),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemExtent: DateStrip.itemWidth + DateStrip.gap,
        itemCount: _count,
        itemBuilder: (context, i) {
          final day = addDays(widget.first, i);
          final key = dayKey(day);
          final isSelected = widget.selected != null && dayKey(widget.selected!) == key;
          final isToday = dayKey(widget.today) == key;
          final future = day.isAfter(widget.today);
          final hasDot = widget.active.contains(key);
          return Padding(
            padding: const EdgeInsets.only(right: DateStrip.gap),
            child: Semantics(
              button: true,
              selected: isSelected,
              label:
                  '${weekdayShort[day.weekday - 1]} ${day.day} ${monthLong[day.month - 1]}'
                  '${isToday ? ', today' : ''}${hasDot ? ', workout logged' : ''}',
              excludeSemantics: true,
              child: Opacity(
                opacity: future ? 0.5 : 1,
                child: GestureDetector(
                  onTap: () => widget.onPick(day),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: Metric.cta,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(colors: p.glassHi, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(
                        color: isToday && !isSelected
                            ? p.accentText
                            : (isSelected ? Colors.white.withValues(alpha: 0.28) : p.edge),
                        width: isToday && !isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Metric.cta.last.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayShort[day.weekday - 1],
                          style: AppText.tab.copyWith(color: isSelected ? Colors.white.withValues(alpha: 0.9) : p.sub),
                        ),
                        const SizedBox(height: 2),
                        Text('${day.day}', style: AppText.number.copyWith(color: isSelected ? Colors.white : p.text)),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasDot ? (isSelected ? Colors.white : Metric.burnDot) : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

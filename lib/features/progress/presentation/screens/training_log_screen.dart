import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/use_cases/training_log.dart';
import '../providers.dart';
import '../widgets/log_dot.dart';

class TrainingLogScreen extends ConsumerStatefulWidget {
  const TrainingLogScreen({super.key, required this.dayRoute});

  final String dayRoute;

  static const weeks = 52;

  @override
  ConsumerState<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends ConsumerState<TrainingLogScreen> {
  ActivityFilter _filter = ActivityFilter.all;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _rowHeight => MediaQuery.textScalerOf(context).scale(20) + 56;

  void _jump(DateTime month, DateTime today) {
    final weeksBack = mondayOf(today).difference(mondayOf(DateTime(month.year, month.month + 1, 0))).inDays ~/ 7;
    final target = (weeksBack.clamp(0, TrainingLogScreen.weeks - 1) * _rowHeight).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  void _open(DateTime day) {
    ref.read(selectedDayProvider.notifier).select(day);
    context.go(widget.dayRoute);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final from = addDays(mondayOf(today), -7 * (TrainingLogScreen.weeks - 1));
    final items = ref.watch(activitiesProvider((dayKey(from), dayKey(today)))).value ?? const <ActivityItem>[];
    final weeks = TrainingLog.weeks(items, today, TrainingLogScreen.weeks, _filter);
    final months = [for (var i = 0; i < 12; i++) DateTime(today.year, today.month - i)];
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    FormHeader(
                      title: 'Training log',
                      onBack: () => context.pop(),
                      trailing: PopupMenuButton<DateTime>(
                        tooltip: 'Jump to month',
                        color: p.pageTop,
                        icon: Icon(Icons.calendar_month_rounded, color: p.text),
                        onSelected: (m) => _jump(m, today),
                        itemBuilder: (_) => [
                          for (final m in months)
                            PopupMenuItem(
                              value: m,
                              child: Text('${monthLong[m.month - 1]} ${m.year}', style: TextStyle(color: p.text)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassSegmented<ActivityFilter>(
                      options: const [
                        (ActivityFilter.all, 'All'),
                        (ActivityFilter.gym, 'Gym'),
                        (ActivityFilter.run, 'Runs'),
                      ],
                      value: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 84),
                        for (final w in weekdayShort)
                          Expanded(
                            child: Center(
                              child: Text(w[0], style: AppText.tab.copyWith(color: p.sub)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemExtent: _rowHeight,
                  itemCount: weeks.length,
                  itemBuilder: (context, i) {
                    final w = weeks[i];
                    final sunday = addDays(w.monday, 6);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: p.hair)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.monday.month == sunday.month
                                      ? '${w.monday.day}–${sunday.day} ${monthShort[sunday.month - 1]}'
                                      : '${w.monday.day} ${monthShort[w.monday.month - 1]}–${sunday.day} ${monthShort[sunday.month - 1]}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.tab.copyWith(color: p.sub),
                                ),
                                Text(
                                  TrainingLog.hm(w.minutes),
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: p.text),
                                ),
                              ],
                            ),
                          ),
                          for (final d in w.days)
                            Expanded(
                              child: LogDot(day: d, onTap: () => _open(d.date)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Glass(
                  kind: GlassKind.control,
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4,
                    children: [
                      for (final (label, color) in [('Run', Metric.runDot), ('Gym', Metric.burnDot)]) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(label, style: AppText.tab.copyWith(color: p.sub)),
                        const SizedBox(width: 16),
                      ],
                      Text('Bigger dot = longer workout', style: AppText.tab.copyWith(color: p.sub)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

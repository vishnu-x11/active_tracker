import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/date_strip.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/segmented.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../gym/gym_routes.dart';
import '../../../running/running_routes.dart';
import '../../../progress/progress.dart';
import '../notifiers/activity_notifier.dart';
import '../states/activity_view.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(activityViewProvider);
    final groups = view.value?.groups ?? const <ActivityGroup>[];
    final rows = <Object>[
      for (final g in groups) ...[g, ...g.items],
    ];
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _Header(),
                SizedBox(height: 16),
                _StripCard(),
                SizedBox(height: 14),
                _Filter(),
                SizedBox(height: 14),
                _Tiles(),
                SizedBox(height: 8),
              ]),
            ),
          ),
          if (view.hasError)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  view.error is Failure ? (view.error! as Failure).message : "Couldn't load your workouts.",
                  style: AppText.small.copyWith(color: context.palette.danger),
                ),
              ),
            )
          else if (view.hasValue && groups.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _Empty(title: view.value!.emptyTitle, hint: view.value!.emptyHint),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  final ActivityGroup g => _GroupHeader(key: ValueKey('h${g.day}'), group: g),
                  final ActivityItem a => Padding(
                    key: ValueKey(a.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ActivityTile(
                      item: a,
                      detailed: true,
                      onTap: () =>
                          context.push(a.type == ActivityType.gym ? GymRoutes.detail(a.id) : RunRoutes.detail(a.id)),
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${shortDate(today)} · this week',
                style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
              ),
              Text('Activity', style: AppText.display.copyWith(color: p.text)),
            ],
          ),
        ),
        GlassIconButton(icon: Icons.add_rounded, tooltip: 'Log an activity', onPressed: () => context.push('/log')),
      ],
    );
  }
}

class _StripCard extends ConsumerWidget {
  const _StripCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final selected = ref.watch(selectedDayProvider);
    final allDays = ref.watch(activityProvider.select((s) => s.allDays));
    final active = ref.watch(stripActiveDaysProvider);
    final notifier = ref.read(activityProvider.notifier);
    final shownMonth = allDays ? today : selected;
    final isToday = dayKey(selected) == dayKey(today);
    final hint = allDays
        ? 'Showing all days · pick a day'
        : 'Showing ${isToday ? 'today' : shortDate(selected)} · tap again for all';
    Widget chip(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Glass(
        kind: GlassKind.control,
        radius: 16,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.text),
            ),
          ),
        ),
      ),
    );
    return Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${monthLong[shownMonth.month - 1]} ${shownMonth.year}',
                      style: AppText.cardTitle.copyWith(color: p.text),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                    ),
                  ],
                ),
              ),
              if (!allDays) chip('All days', notifier.showAll),
              if (allDays || !isToday) chip('Today', notifier.goToday),
            ],
          ),
          const SizedBox(height: 12),
          DateStrip(
            first: ActivityView.rangeStart(today),
            last: ActivityView.rangeEnd(today),
            today: today,
            selected: allDays ? null : selected,
            active: active,
            onPick: notifier.pickDay,
          ),
        ],
      ),
    );
  }
}

class _Filter extends ConsumerWidget {
  const _Filter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassSegmented<ActivityFilter>(
      options: const [(ActivityFilter.all, 'All'), (ActivityFilter.gym, 'Gym'), (ActivityFilter.run, 'Runs')],
      value: ref.watch(activityProvider.select((s) => s.filter)),
      onChanged: ref.read(activityProvider.notifier).setFilter,
    );
  }
}

class _Tiles extends ConsumerWidget {
  const _Tiles();

  static (IconData, List<Color>) _look(TileKind k) => switch (k) {
    TileKind.gym => (Icons.fitness_center_rounded, Metric.burn),
    TileKind.run => (Icons.directions_run_rounded, Metric.run),
    TileKind.distance => (Icons.route_rounded, Metric.run),
    TileKind.time => (Icons.schedule_rounded, Metric.water),
    TileKind.burn => (Icons.local_fire_department_rounded, Metric.burn),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(activityViewProvider.select((v) => v.value?.tiles));
    if (tiles == null) return const SizedBox(height: 108);
    return Row(
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              icon: _look(t.kind).$1,
              colors: _look(t.kind).$2,
              value: t.value,
              unit: t.unit,
              label: t.label,
            ),
          ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({super.key, required this.group});

  final ActivityGroup group;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(group.label, style: AppText.section.copyWith(fontSize: 15, color: p.text)),
          ),
          Text(
            '${group.totalKcal} kcal',
            style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.sub),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const IconTile(icon: Icons.event_available_rounded, colors: Metric.run, size: 48),
          const SizedBox(height: 12),
          Text(title, style: AppText.cardTitle.copyWith(color: p.text)),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: p.sub),
          ),
        ],
      ),
    );
  }
}

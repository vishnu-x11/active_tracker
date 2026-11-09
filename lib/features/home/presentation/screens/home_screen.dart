import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/layout.dart';
import '../../../progress/progress.dart';
import '../../../gym/gym_routes.dart';
import '../../../profile/profile_api.dart';
import '../../../hydration/hydration_routes.dart';
import '../../../protein/protein_routes.dart';
import '../../../reminders/reminders_routes.dart';
import '../../../running/running_routes.dart';
import '../widgets/burned_today_card.dart';
import '../widgets/quick_log_row.dart';
import '../widgets/this_week_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final day = dayKey(today);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => invalidateDayFromWidget(ref, day),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, tabBarInset),
          children: [
            _Header(today: today),
            const SizedBox(height: 20),
            BurnedTodayCard(
              day: day,
              onOpen: (m) => switch (m) {
                'water' => context.push(HydrationRoutes.water),
                'protein' => context.push(ProteinRoutes.protein),
                _ => context.go('/progress'),
              },
            ),
            const SizedBox(height: 16),
            QuickLogRow(
              onLog: (kind) => context.push(switch (kind) {
                'gym' => GymRoutes.newSession,
                'run' => RunRoutes.newRun,
                'water' => HydrationRoutes.water,
                _ => ProteinRoutes.protein,
              }),
            ),
            const SizedBox(height: 24),
            _WorkoutsTitle(day: day),
            const SizedBox(height: 10),
            _TodayWorkouts(day: day),
            const SizedBox(height: 16),
            ThisWeekCard(today: today),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.today});

  final DateTime today;

  static String greeting(int hour) => hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final name = ref.watch(displayNameProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
    return Row(
      children: [
        Glass(
          kind: GlassKind.control,
          radius: 22,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: initials(name).isEmpty
                  ? Icon(Icons.person_rounded, size: 20, color: p.text)
                  : Text(
                      initials(name),
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: p.text),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greeting(DateTime.now().hour)} · ${shortDate(today)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
              ),
              Text(
                first.isEmpty ? 'Today' : first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display.copyWith(fontSize: 24, color: p.text),
              ),
            ],
          ),
        ),
        GlassIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Reminders',
          onPressed: () => context.push(ReminderRoutes.reminders),
        ),
        const SizedBox(width: 8),
        GlassIconButton(
          icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: dark ? 'Switch to light theme' : 'Switch to dark theme',
          onPressed: () => ref
              .read(profileProvider.notifier)
              .change((p) => p.copyWith(theme: dark ? ThemePreference.light : ThemePreference.dark)),
        ),
      ],
    );
  }
}

class _WorkoutsTitle extends ConsumerWidget {
  const _WorkoutsTitle({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final count = ref.watch(dayActivitiesProvider(day).select((v) => v.value?.length));
    return Row(
      children: [
        Flexible(
          child: Text(
            'Workouts',
            overflow: TextOverflow.ellipsis,
            style: AppText.section.copyWith(color: p.text),
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppText.section.copyWith(fontWeight: FontWeight.w500, color: p.sub),
          ),
        ],
        const Spacer(),
        TextButton(
          onPressed: () => context.go('/activity'),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: Text(
            'See all',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
          ),
        ),
      ],
    );
  }
}

class _TodayWorkouts extends ConsumerWidget {
  const _TodayWorkouts({required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(dayActivitiesProvider(day)).value;
    if (items == null) return const SizedBox(height: 80);
    if (items.isEmpty) return const _NoWorkouts();
    return Column(
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          ActivityTile(key: ValueKey(item.id), item: item, onTap: () => openActivity(context, item)),
        ],
      ],
    );
  }
}

class _NoWorkouts extends StatelessWidget {
  const _NoWorkouts();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const IconTile(icon: Icons.bolt_rounded, colors: Metric.burn, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No workouts yet today', style: AppText.cardTitle.copyWith(color: p.text)),
                const SizedBox(height: 2),
                Text('Tap + to log a gym session or a run.', style: AppText.small.copyWith(color: p.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openActivity(BuildContext context, ActivityItem item) {
  context.push(item.type == ActivityType.gym ? GymRoutes.detail(item.id) : RunRoutes.detail(item.id));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/result.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/gym_session.dart';
import '../../domain/entities/muscle_groups.dart';
import '../../gym_routes.dart';
import '../providers.dart';
import '../widgets/exercise_section.dart';
import '../widgets/gym_share_card.dart';

class GymDetailScreen extends ConsumerWidget {
  const GymDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final session = ref.watch(gymSessionProvider(id));
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: switch (session) {
            AsyncData(value: final s?) => _Body(session: s),
            AsyncData() => _Missing(onBack: () => context.pop()),
            AsyncError(:final error) => Center(
              child: Text(
                error is Failure ? error.message : "Couldn't open this session.",
                style: TextStyle(color: p.danger),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.session});

  final GymSession session;

  static String hm(int minutes) => '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context, what: 'this session')) return;
    final result = await ref.read(deleteGymSessionProvider)(session.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        invalidateDayFromWidget(ref, session.day);
        context.pop();
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = session;
    final hours = s.durationMin / 60;
    final perGroup = s.muscleGroups.isEmpty ? 0 : s.durationMin ~/ s.muscleGroups.length;
    final week = ref.watch(weekBurnProvider(dayKey(mondayOf(s.startedAt)))).value;
    final n = NumberFormat.decimalPattern('en_US');
    final stats = [
      ('Duration', hm(s.durationMin), Icons.schedule_rounded),
      ('Intensity', _cap(s.intensity.name), Icons.speed_rounded),
      ('Groups', '${s.muscleGroups.length}', Icons.grid_view_rounded),
      ('MET', s.met.toStringAsFixed(2), Icons.bolt_rounded),
      ('Per hour', '${hours == 0 ? 0 : (s.kcal / hours).round()} kcal', Icons.local_fire_department_outlined),
      ('Weight', '${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)} kg', Icons.monitor_weight_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        FormHeader(
          title: '',
          onBack: () => context.pop(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Share session',
                icon: Icon(Icons.ios_share_rounded, color: p.text),
                onPressed: () => showSharePreview(
                  context,
                  name: 'gym-${s.id}',
                  text: '${s.title}: ${s.kcal} kcal',
                  card: GymShareCard(session: s),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                color: p.pageTop,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                icon: Icon(Icons.more_horiz_rounded, color: p.text),
                onSelected: (v) => v == 'edit' ? context.push(GymRoutes.edit(s.id)) : _delete(context, ref),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit session', style: TextStyle(color: p.text)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete session', style: TextStyle(color: p.danger)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('GYM SESSION', style: AppText.eyebrow.copyWith(color: p.sub)),
        const SizedBox(height: 4),
        Text(s.title, style: AppText.display.copyWith(color: p.text)),
        const SizedBox(height: 4),
        Text(
          '${weekdayLong(s.startedAt)}, ${s.startedAt.day} ${monthLong[s.startedAt.month - 1]} · ${clockTime(s.startedAt)}',
          style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
        ),
        const SizedBox(height: 16),
        Glass(
          radius: 32,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BURNED', style: AppText.eyebrow.copyWith(color: p.sub)),
                        Text.rich(
                          TextSpan(
                            text: n.format(s.kcal),
                            children: [
                              TextSpan(
                                text: ' kcal',
                                style: AppText.title.copyWith(color: p.sub),
                              ),
                            ],
                          ),
                          style: AppText.hero.copyWith(color: p.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estimated from ${hm(s.durationMin)} of ${s.intensity.name} training',
                          style: AppText.small.copyWith(color: p.sub),
                        ),
                      ],
                    ),
                  ),
                  const IconTile(icon: Icons.fitness_center_rounded, colors: Metric.burn, size: 64),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: p.hair),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  for (final (label, value, icon) in stats)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 13, color: p.accentText),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value, style: AppText.number.copyWith(color: p.text)),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Muscle split', style: AppText.cardTitle.copyWith(color: p.text)),
              const SizedBox(height: 12),
              for (final g in s.muscleGroups) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(MuscleGroups.label(g), style: AppText.body.copyWith(color: p.text)),
                    ),
                    Text(
                      hm(perGroup),
                      style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.sub),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1 / s.muscleGroups.length,
                    minHeight: 8,
                    backgroundColor: p.tracks[0],
                    valueColor: AlwaysStoppedAnimation(Metric.burn.last),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Time is split evenly across the groups you picked.', style: AppText.small.copyWith(color: p.sub)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How this was estimated', style: AppText.cardTitle.copyWith(color: p.text)),
              const SizedBox(height: 10),
              _Line('${_cap(s.intensity.name)} intensity', 'MET ${s.intensity.baseMet.toStringAsFixed(1)}'),
              _Line('Muscle group factor', 'x ${(s.met / s.intensity.baseMet).toStringAsFixed(2)}'),
              _Line(
                'Body weight x time',
                '${s.weightKg.toStringAsFixed(0)} kg x ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 2)} h',
              ),
              Container(height: 1, color: p.hair, margin: const EdgeInsets.symmetric(vertical: 6)),
              _Line(
                'MET ${s.met.toStringAsFixed(2)} x ${s.weightKg.toStringAsFixed(0)} x ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 2)}',
                '${s.kcal} kcal',
                bold: true,
              ),
              const SizedBox(height: 6),
              Text(
                'An estimate; actual burn varies with rest times and effort.',
                style: AppText.small.copyWith(color: p.sub),
              ),
            ],
          ),
        ),
        if (s.exercises.isNotEmpty) ...[
          const SizedBox(height: 16),
          FormSection('Exercises', note: 'Volume ${volumeText(s.volume)} kg'),
          for (final e in s.exercises) ...[
            Glass(
              blur: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.name, style: AppText.cardTitle.copyWith(color: p.text)),
                      ),
                      Text(
                        '${MuscleGroups.label(e.group)} · ${volumeText(e.volume)} kg',
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final (j, set) in e.sets.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text('${j + 1}', style: AppText.body.copyWith(color: p.sub)),
                          ),
                          Expanded(
                            child: Text(
                              '${kgText(set.kg)} kg × ${set.reps}',
                              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                            ),
                          ),
                          Text('1RM ~${kgText(set.oneRepMax)} kg', style: AppText.small.copyWith(color: p.sub)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 6),
        TapGlass(
          blur: false,
          onTap: () => context.push(GymRoutes.recovery),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconTile(icon: Icons.accessibility_new_rounded, colors: Metric.protein),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Muscle recovery', style: AppText.cardTitle.copyWith(color: p.text)),
                    Text('See which muscles are ready to train', style: AppText.small.copyWith(color: p.sub)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.sub),
            ],
          ),
        ),
        if (week != null && week.total > 0) ...[
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconTile(icon: Icons.pie_chart_rounded, colors: Metric.burn),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${(s.kcal * 100 / week.total).round()}% of this week's burn",
                        style: AppText.cardTitle.copyWith(color: p.text),
                      ),
                      Text(
                        '${n.format(s.kcal)} of ${n.format(week.total)} kcal burned this week',
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = bold ? FontWeight.w700 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(fontWeight: w, color: bold ? p.text : p.sub),
            ),
          ),
          Text(
            value,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
          ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FormHeader(title: '', onBack: onBack),
          const Spacer(),
          Text('This session was deleted.', style: AppText.body.copyWith(color: p.sub)),
          const Spacer(),
        ],
      ),
    );
  }
}

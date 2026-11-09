import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/run.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../providers.dart';
import '../widgets/gps_sections.dart';
import '../widgets/run_share_card.dart';
import '../widgets/run_stat_grid.dart';

class RunDetailScreen extends ConsumerWidget {
  const RunDetailScreen({super.key, required this.id, this.justRecorded = false});

  final String id;

  final bool justRecorded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: switch (ref.watch(runProvider(id))) {
            AsyncData(value: final r?) => _Body(run: r, justRecorded: justRecorded),
            AsyncData() => Center(
              child: Text('This run was deleted.', style: TextStyle(color: p.sub)),
            ),
            AsyncError(:final error) => Center(
              child: Text(
                error is Failure ? error.message : "Couldn't open this run.",
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

class _Menu extends StatelessWidget {
  const _Menu({required this.run, required this.onDelete});

  final Run run;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      color: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Icon(Icons.more_horiz_rounded, color: p.text),
      onSelected: (v) => v == 'edit' ? context.push(RunRoutes.edit(run.id)) : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit run', style: TextStyle(color: p.text)),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete run', style: TextStyle(color: p.danger)),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.run, required this.justRecorded});

  final Run run;
  final bool justRecorded;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context, what: 'this run')) return;
    final result = await ref.read(deleteRunProvider)(run.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        invalidateDayFromWidget(ref, run.day);
        context.pop();
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = run;
    final gps = r.source == RunSource.gps;
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
                tooltip: 'Share run',
                icon: Icon(Icons.ios_share_rounded, color: p.text),
                onPressed: () => showSharePreview(
                  context,
                  name: 'run-${r.id}',
                  text: '${r.title}: ${r.km.toStringAsFixed(2)} km',
                  card: RunShareCard(
                    run: r,
                    points: gps ? ref.read(runTrackProvider(r.id)).value ?? const [] : const [],
                  ),
                ),
              ),
              _Menu(run: r, onDelete: () => _delete(context, ref)),
            ],
          ),
        ),
        if (gps) ...[const SizedBox(height: 12), RunMapHeader(run: r)],
        const SizedBox(height: 12),
        Text(r.title, style: AppText.display.copyWith(color: p.text)),
        const SizedBox(height: 4),
        Text(
          '${shortDate(r.startedAt)} ${r.startedAt.year} · ${clockTime(r.startedAt)} · '
          '${gps ? 'Recorded with GPS' : 'Logged manually'} · ${r.type.label}',
          style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: r.km.toStringAsFixed(2),
            children: [
              TextSpan(
                text: ' km',
                style: AppText.title.copyWith(fontWeight: FontWeight.w500, color: p.sub),
              ),
            ],
          ),
          style: AppText.hero.copyWith(color: p.text),
        ),
        const SizedBox(height: 16),
        RunStatGrid(
          stats: [
            RunStat(Icons.schedule_rounded, 'Duration', RunMetrics.clock(r.movingSec), ''),
            RunStat(Icons.speed_rounded, 'Avg pace', formatPace(r.paceSecPerKm), '/km'),
            RunStat(
              Icons.local_fire_department_outlined,
              r.kcalOverride == null ? 'Calories' : 'Calories (yours)',
              '${r.kcalShown}',
              'kcal',
            ),
            RunStat(Icons.av_timer_rounded, 'Avg speed', r.speedKmh.toStringAsFixed(1), 'km/h'),
            if (r.elevationM != null)
              RunStat(Icons.terrain_rounded, 'Elevation gain', '${r.elevationM}', 'm')
            else
              RunStat(Icons.landscape_rounded, 'Type', r.type.label, ''),
            RunStat(
              Icons.bolt_rounded,
              r.effort == null ? 'Effort' : 'Effort · ${effortNames[r.effort! - 1]}',
              '${r.effort ?? '–'}',
              '/5',
            ),
          ],
        ),
        if (gps) GpsSections(run: r, justRecorded: justRecorded),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(16),
          child: Text(
            r.kcalOverride == null
                ? 'Calories: 1.04 x ${r.weightKg.toStringAsFixed(0)} kg x ${r.km.toStringAsFixed(2)} km = ${r.kcal} kcal (rounded down).'
                : 'Calories are your own value. The estimate would be ${r.kcal} kcal.',
            style: AppText.small.copyWith(color: p.sub),
          ),
        ),
      ],
    );
  }
}

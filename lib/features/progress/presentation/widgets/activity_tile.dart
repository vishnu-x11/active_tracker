import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/activity_item.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item, this.detailed = false, this.onTap});

  final ActivityItem item;
  final bool detailed;

  final VoidCallback? onTap;

  static String duration(int minutes) => '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  static String clock(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    final mmss = '${h > 0 ? m.toString().padLeft(2, '0') : m}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$mmss' : mmss;
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String get _source => switch (item.type) {
    ActivityType.gym => 'Gym',
    ActivityType.run => item.fromGps ? 'GPS' : 'Manual',
  };

  String get _stats {
    switch (item.type) {
      case ActivityType.gym:
        return '${duration(item.durationMin ?? 0)} · ${_cap(item.intensity ?? '')}';
      case ActivityType.run:
        final pace = paceSecPerKm(
          km: item.km,
          time: Duration(seconds: item.movingSec ?? 0),
        );
        return [
          '${item.km.toStringAsFixed(2)} km',
          if (pace != null) '${formatPace(pace)} /km',
          if (detailed) clock(item.movingSec ?? 0),
        ].join(' · ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = clockTime(item.startedAt);
    final isGym = item.type == ActivityType.gym;
    final label = '${item.title}, $time, $_stats, ${item.kcal} kcal';
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Glass(
        radius: 26,
        blur: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconTile(
                    icon: isGym ? Icons.fitness_center_rounded : Icons.directions_run_rounded,
                    colors: isGym ? Metric.burn : Metric.run,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardTitle.copyWith(color: p.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detailed ? '$time · $_source' : '$time · $_stats',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(color: p.sub),
                        ),
                        if (detailed) ...[
                          const SizedBox(height: 2),
                          Text(
                            _stats,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.text),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.kcal}', style: AppText.number.copyWith(fontSize: 20, color: p.text)),
                      Text('kcal', style: AppText.small.copyWith(fontSize: 12, color: p.sub)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

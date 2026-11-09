import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/gym_session.dart';
import 'exercise_section.dart';

class GymShareCard extends StatelessWidget {
  const GymShareCard({super.key, required this.session});

  final GymSession session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final top = s.exercises.take(5).toList();
    return ShareCardFrame(
      colors: Metric.burn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${shortDate(s.startedAt)} ${s.startedAt.year} · ${clockTime(s.startedAt)}'.toUpperCase(),
            style: AppText.eyebrow.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            s.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.display.copyWith(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: top.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: '${s.kcal}',
                        children: [
                          TextSpan(
                            text: ' kcal',
                            style: AppText.title.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                      style: AppText.hero.copyWith(fontSize: 72, color: Colors.white),
                    ),
                  )
                : Column(
                    children: [
                      for (final e in top)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Metric.burnDot, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              Text(
                                '${e.sets.length} × ${e.sets.isEmpty ? '' : '${kgText(e.sets.first.kg)} kg'}',
                                style: AppText.small.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      if (s.exercises.length > top.length)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+ ${s.exercises.length - top.length} more',
                            style: AppText.small.copyWith(color: Colors.white60),
                          ),
                        ),
                    ],
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: ShareStat(
                  value: '${s.durationMin ~/ 60}h ${(s.durationMin % 60).toString().padLeft(2, '0')}m',
                  label: 'Duration',
                ),
              ),
              Expanded(
                child: ShareStat(value: '${s.kcal}', unit: 'kcal', label: 'Burned'),
              ),
              if (s.volume > 0)
                Expanded(
                  child: ShareStat(value: volumeText(s.volume), unit: 'kg', label: 'Volume'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

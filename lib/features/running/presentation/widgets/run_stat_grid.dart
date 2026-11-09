import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';

class RunStat {
  const RunStat(this.icon, this.label, this.value, this.unit);

  final IconData icon;
  final String label;
  final String value;
  final String unit;
}

class RunStatGrid extends StatelessWidget {
  const RunStatGrid({super.key, required this.stats});

  final List<RunStat> stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _Cell(stat: stats[i])),
              Container(width: 1, color: p.hair, margin: const EdgeInsets.symmetric(horizontal: 14)),
              Expanded(child: i + 1 < stats.length ? _Cell(stat: stats[i + 1]) : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(children: rows),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.stat});

  final RunStat stat;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: '${stat.label} ${stat.value} ${stat.unit}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 13, color: Metric.runDot),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  stat.label,
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
            child: Text.rich(
              TextSpan(
                text: stat.value,
                children: [
                  TextSpan(
                    text: stat.unit.isEmpty ? '' : ' ${stat.unit}',
                    style: AppText.small.copyWith(color: p.sub),
                  ),
                ],
              ),
              style: AppText.number.copyWith(fontSize: 20, color: p.text),
            ),
          ),
        ],
      ),
    );
  }
}

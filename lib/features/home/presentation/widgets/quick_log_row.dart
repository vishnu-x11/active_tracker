import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';

class QuickLogRow extends StatelessWidget {
  const QuickLogRow({super.key, required this.onLog});

  final ValueChanged<String> onLog;

  static const _items = [
    ('gym', 'Gym', Icons.fitness_center_rounded, Metric.burn),
    ('run', 'Run', Icons.directions_run_rounded, Metric.run),
    ('water', 'Water', Icons.water_drop_rounded, Metric.water),
    ('protein', 'Protein', Icons.egg_alt_rounded, Metric.protein),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final (i, (key, name, icon, colors)) in _items.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Log $name',
              excludeSemantics: true,
              child: TapGlass(
                kind: GlassKind.control,
                radius: 24,
                onTap: () => onLog(key),
                child: SizedBox(
                  height: 84,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTile(icon: icon, colors: colors),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(name, style: AppText.tab.copyWith(fontSize: 12, color: p.text)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

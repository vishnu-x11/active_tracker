import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';
import 'glass.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.colors,
    required this.value,
    required this.label,
    this.unit = '',
  });

  final IconData icon;
  final List<Color> colors;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: '$value $unit $label',
      excludeSemantics: true,
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: icon, colors: colors, size: 30),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                  ],
                ),
                style: AppText.display.copyWith(fontSize: 22, color: p.text),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
            ),
          ],
        ),
      ),
    );
  }
}

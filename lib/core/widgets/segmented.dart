import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      kind: GlassKind.control,
      radius: 999,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == value,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: v == value ? const LinearGradient(colors: Metric.cta) : null,
                      boxShadow: v == value
                          ? [
                              BoxShadow(
                                color: Metric.cta.last.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: v == value ? Colors.white : p.sub,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

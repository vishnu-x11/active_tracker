import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';

class GlowBar extends StatelessWidget {
  const GlowBar({
    super.key,
    required this.name,
    required this.value,
    required this.target,
    required this.fraction,
    required this.colors,
    required this.track,
    this.onTap,
  });

  final VoidCallback? onTap;

  final String name;

  final String value;

  final String? target;

  final double? fraction;
  final List<Color> colors;
  final Color track;

  static const span = 1.5;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = fraction ?? 0;
    final pct = (f * 100).round();
    final hit = f >= 1;
    final note = fraction == null ? '' : (hit ? 'Target hit · +${pct - 100}%' : '${100 - pct}% to go');
    final bar = Semantics(
      container: true,
      button: onTap != null,
      label: '$name $value${target == null ? '' : ' of $target'}, $pct% of target',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: colors.last, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  name,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text.rich(
                    TextSpan(
                      text: value,
                      children: [
                        if (target != null)
                          TextSpan(
                            text: ' / $target',
                            style: AppText.small.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                          ),
                      ],
                    ),
                    style: AppText.number.copyWith(fontSize: 15, color: p.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (f.clamp(0, span)) / span),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(7)),
                          ),
                        ),
                        if (t > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: (w * t).clamp(14, w),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(colors: colors),
                                boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.45), blurRadius: 16)],
                              ),
                            ),
                          ),
                        if (t > 0)
                          Positioned(
                            left: ((w * t) - 12).clamp(2, w - 12),
                            top: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.25), spreadRadius: 3)],
                              ),
                            ),
                          ),
                        Positioned(
                          left: w / span - 1,
                          top: -5,
                          bottom: -5,
                          width: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.text.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  fraction == null ? '' : '$pct% of target',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tab.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  note,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.tab.copyWith(color: hit ? p.goodFg : p.sub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return bar;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: bar);
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';

class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.label,
    required this.pct,
    required this.colors,
    required this.track,
    this.size = 48,
  });

  final String label;
  final int pct;
  final List<Color> colors;
  final Color track;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label $pct%',
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _Ring(pct / 100, colors, track),
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '$pct%',
                style: AppText.tab.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: context.palette.text),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Ring extends CustomPainter {
  _Ring(this.f, this.colors, this.track);

  final double f;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.5;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (f <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * f.clamp(0, 1),
      false,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.f != f || old.track != track;
}

class DayKindLabel extends StatelessWidget {
  const DayKindLabel({super.key, required this.workouts});

  final int workouts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = workouts.clamp(0, 2);
    final color = n == 0 ? Metric.water.first : Metric.burnDot;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i <= n; i++) Icon(Icons.bolt_rounded, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            ['Rest day', 'Workout day', 'Hard day'][n],
            overflow: TextOverflow.ellipsis,
            style: AppText.tab.copyWith(fontSize: 12, color: p.sub),
          ),
        ),
      ],
    );
  }
}

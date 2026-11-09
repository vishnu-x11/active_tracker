import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

class WaterTank extends StatelessWidget {
  const WaterTank({super.key, required this.fraction, required this.child});

  final double fraction;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(colors: p.glass, begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: p.edge),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraction.clamp(0, 1)),
                duration: const Duration(milliseconds: 700),
                curve: const Cubic(0.2, 0.8, 0.2, 1),
                builder: (context, f, _) => CustomPaint(painter: _WaterPainter(f)),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter(this.f);

  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    if (f <= 0) return;
    final top = size.height * (1 - f);
    final rect = Rect.fromLTRB(0, top, size.width, size.height);
    final water = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7FD6FF), Color(0xFF4C9BFF), Color(0xFF2F6BFF)],
        stops: [0, 0.45, 1],
      ).createShader(rect);
    final path = Path()..moveTo(0, top);
    if (f < 1) {
      for (var x = 0.0; x <= size.width; x += 4) {
        path.lineTo(x, top + 5 * math.sin(x / size.width * 2 * math.pi * 1.5));
      }
    } else {
      path.lineTo(size.width, top);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, water);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(18, top + 18, 12, (size.height - top) * 0.55), const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(_WaterPainter old) => old.f != f;
}

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.values,
    required this.color,
    this.labels = const {},
    this.height = 140,
    this.marker,
    this.showMarker = true,
    this.semantics,
  });

  final List<double?> values;
  final Color color;
  final Map<int, String> labels;
  final double height;
  final String? marker;
  final bool showMarker;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semantics,
      excludeSemantics: semantics != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _TrendPainter(
                values: values,
                color: color,
                grid: p.hair,
                marker: showMarker ? marker : null,
                markerStyle: AppText.tab.copyWith(color: p.text),
                markerBg: p.pageTop,
                showDot: showMarker,
              ),
            ),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 16,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final e in labels.entries)
                      Positioned(
                        left: values.length < 2
                            ? 0
                            : (c.maxWidth * e.key / (values.length - 1) - 14).clamp(0, c.maxWidth - 28),
                        width: 28,
                        child: Text(
                          e.value,
                          textAlign: TextAlign.center,
                          style: AppText.tab.copyWith(color: p.sub),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.marker,
    required this.markerStyle,
    required this.markerBg,
    required this.showDot,
  });

  final List<double?> values;
  final Color color;
  final Color grid;
  final String? marker;
  final TextStyle markerStyle;
  final Color markerBg;
  final bool showDot;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.15 + 0.35 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final known = [for (final v in values) ?v];
    if (known.isEmpty) return;
    var lo = known.reduce((a, b) => a < b ? a : b), hi = known.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final top = 24.0, bottom = size.height - 6;
    Offset at(int i, double v) => Offset(
      values.length < 2 ? size.width / 2 : size.width * i / (values.length - 1),
      bottom - (v - lo) / (hi - lo) * (bottom - top),
    );
    final path = Path(), fill = Path();
    Offset? first, last;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final o = at(i, v);
      if (first == null) {
        path.moveTo(o.dx, o.dy);
        fill.moveTo(o.dx, bottom);
        fill.lineTo(o.dx, o.dy);
        first = o;
      } else {
        path.lineTo(o.dx, o.dy);
        fill.lineTo(o.dx, o.dy);
      }
      last = o;
    }
    fill
      ..lineTo(last!.dx, bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (!showDot) return;
    canvas
      ..drawCircle(last, 6, Paint()..color = markerBg)
      ..drawCircle(last, 4.5, Paint()..color = color);
    if (marker case final text?) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: markerStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (last.dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      final y = (last.dy - tp.height - 10).clamp(0.0, size.height - tp.height);
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.color != color || old.marker != marker || old.grid != grid;
}

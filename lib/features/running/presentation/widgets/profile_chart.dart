import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/use_cases/run_breakdown.dart';

class ProfileChart extends StatefulWidget {
  const ProfileChart({
    super.key,
    required this.points,
    required this.colors,
    required this.label,
    required this.tooltip,
    required this.steps,
    this.invert = false,
    this.average,
    this.ceiling,
    this.height = 190,
    this.semantics,
  });

  final List<ProfilePoint> points;
  final List<Color> colors;
  final String Function(double value) label;
  final String Function(ProfilePoint point) tooltip;
  final List<double> steps;
  final bool invert;
  final double? average;
  final double? ceiling;
  final double height;
  final String? semantics;

  @override
  State<ProfileChart> createState() => _ProfileChartState();
}

class _ProfileChartState extends State<ProfileChart> {
  int? _selected;

  void _select(Offset at, double width) {
    final n = widget.points.length;
    if (n < 2) return;
    final x = ((at.dx - _ProfilePainter.left) / (width - _ProfilePainter.left)).clamp(0.0, 1.0);
    final i = (x * (n - 1)).round();
    if (i != _selected) setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: widget.semantics,
      excludeSemantics: widget.semantics != null,
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _select(d.localPosition, c.maxWidth),
          onHorizontalDragStart: (d) => _select(d.localPosition, c.maxWidth),
          onHorizontalDragUpdate: (d) => _select(d.localPosition, c.maxWidth),
          child: SizedBox(
            height: widget.height,
            width: c.maxWidth,
            child: CustomPaint(
              painter: _ProfilePainter(
                points: widget.points,
                colors: widget.colors,
                invert: widget.invert,
                average: widget.average,
                ceiling: widget.ceiling,
                steps: widget.steps,
                label: widget.label,
                tooltip: widget.tooltip,
                selected: _selected,
                grid: p.hair,
                text: p.text,
                sub: p.sub,
                tipBg: p.pageTop,
                base: DefaultTextStyle.of(context).style,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.points,
    required this.colors,
    required this.invert,
    required this.average,
    required this.ceiling,
    required this.steps,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.grid,
    required this.text,
    required this.sub,
    required this.tipBg,
    required this.base,
  });

  static const left = 44.0;
  static const bottomGutter = 20.0;
  static const topGutter = 8.0;

  final List<ProfilePoint> points;
  final List<Color> colors;
  final bool invert;
  final double? average;
  final double? ceiling;
  final List<double> steps;
  final String Function(double value) label;
  final String Function(ProfilePoint point) tooltip;
  final int? selected;
  final Color grid;
  final Color text;
  final Color sub;
  final Color tipBg;
  final TextStyle base;

  TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  double _step(double range) {
    for (final s in steps) {
      if (range / s <= 4) return s;
    }
    return steps.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final known = [for (final p in points) ?p.value];
    if (known.length < 2) return;
    var lo = known.reduce(math.min), hi = known.reduce(math.max);
    if (ceiling case final c?) hi = math.min(hi, c);
    if (hi - lo < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    final step = _step(hi - lo);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;
    final plot = Rect.fromLTRB(left, topGutter, size.width, size.height - bottomGutter);
    double y(double v) {
      final f = ((v.clamp(lo, hi) - lo) / (hi - lo));
      return invert ? plot.top + f * plot.height : plot.bottom - f * plot.height;
    }

    final maxKm = points.last.km <= 0 ? 1.0 : points.last.km;
    double x(double km) => plot.left + km / maxKm * plot.width;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final small = base.merge(AppText.tab.copyWith(color: sub, fontWeight: FontWeight.w500));
    for (var v = lo; v <= hi + 1e-6; v += step) {
      final yy = y(v);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), gridPaint);
      final tp = _text(label(v), small);
      tp.paint(canvas, Offset(left - tp.width - 6, yy - tp.height / 2));
    }
    final kmStep = maxKm <= 2 ? 0.5 : (maxKm <= 6 ? 1.0 : (maxKm <= 15 ? 2.0 : 5.0));
    for (var km = kmStep; km < maxKm - kmStep * 0.3; km += kmStep) {
      final xx = x(km);
      canvas.drawLine(Offset(xx, plot.top), Offset(xx, plot.bottom), gridPaint);
      final tp = _text('${km % 1 == 0 ? km.toInt() : km} km', small);
      tp.paint(canvas, Offset(xx - tp.width / 2, plot.bottom + 4));
    }

    final line = Path(), fill = Path();
    var open = false;
    double? lastX;
    void close() {
      if (!open || lastX == null) return;
      fill
        ..lineTo(lastX, plot.bottom)
        ..close();
      open = false;
    }

    for (final p in points) {
      final v = p.value;
      if (v == null) {
        close();
        continue;
      }
      final o = Offset(x(p.km), y(v));
      if (!open) {
        line.moveTo(o.dx, o.dy);
        fill
          ..moveTo(o.dx, plot.bottom)
          ..lineTo(o.dx, o.dy);
        open = true;
      } else {
        line.lineTo(o.dx, o.dy);
        fill.lineTo(o.dx, o.dy);
      }
      lastX = o.dx;
    }
    close();
    canvas
      ..save()
      ..clipRect(plot)
      ..drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(plot.topCenter, plot.bottomCenter, [
            colors.first.withValues(alpha: 0.55),
            colors.last.withValues(alpha: 0.08),
          ]),
      )
      ..drawPath(
        line,
        Paint()
          ..color = colors.first
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();

    if (average case final a?) {
      final yy = y(a);
      final dash = Paint()
        ..color = text.withValues(alpha: 0.8)
        ..strokeWidth = 1.2;
      for (var xx = plot.left; xx < plot.right; xx += 8) {
        canvas.drawLine(Offset(xx, yy), Offset(math.min(xx + 4, plot.right), yy), dash);
      }
    }

    final i = selected;
    if (i == null || i >= points.length) return;
    final p = points[i];
    final xx = x(p.km);
    canvas.drawLine(
      Offset(xx, plot.top),
      Offset(xx, plot.bottom),
      Paint()
        ..color = text
        ..strokeWidth = 1.5,
    );
    if (p.value case final v?) {
      final dot = Offset(xx, y(v));
      canvas
        ..drawCircle(dot, 6, Paint()..color = tipBg)
        ..drawCircle(dot, 4, Paint()..color = colors.first);
    }
    final tp = _text(
      tooltip(p),
      base.merge(AppText.small.copyWith(color: text, fontWeight: FontWeight.w600, fontSize: 12)),
    );
    final w = tp.width + 16, h = tp.height + 10;
    final bx = (xx - w / 2).clamp(plot.left, plot.right - w);
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(bx, plot.top, w, h), const Radius.circular(10));
    canvas
      ..drawRRect(box, Paint()..color = tipBg.withValues(alpha: 0.94))
      ..drawRRect(
        box,
        Paint()
          ..color = colors.first
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    tp.paint(canvas, Offset(bx + 8, plot.top + 5));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.average != average ||
      old.text != text ||
      old.grid != grid ||
      old.colors != colors;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/run_metrics.dart';

class RunShareCard extends StatelessWidget {
  const RunShareCard({super.key, required this.run, this.points = const []});

  final Run run;
  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) => ShareCardFrame(
    colors: Metric.run,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${shortDate(run.startedAt)} ${run.startedAt.year} · ${clockTime(run.startedAt)}'.toUpperCase(),
          style: AppText.eyebrow.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(run.title, style: AppText.display.copyWith(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 10),
        Expanded(
          child: points.length >= 2
              ? CustomPaint(painter: RoutePainter(points), size: Size.infinite)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: run.km.toStringAsFixed(2),
                      children: [
                        TextSpan(
                          text: ' km',
                          style: AppText.title.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                    style: AppText.hero.copyWith(fontSize: 72, color: Colors.white),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShareStat(value: run.km.toStringAsFixed(2), unit: 'km', label: 'Distance'),
            ),
            Expanded(
              child: ShareStat(value: RunMetrics.clock(run.movingSec), label: 'Time'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ShareStat(
                value: run.distanceM == 0 ? '–' : formatPace(run.paceSecPerKm),
                unit: '/km',
                label: 'Pace',
              ),
            ),
            Expanded(
              child: ShareStat(value: '${run.kcalShown}', unit: 'kcal', label: 'Burned'),
            ),
          ],
        ),
      ],
    ),
  );
}

class RoutePainter extends CustomPainter {
  RoutePainter(this.points);

  final List<TrackPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = double.infinity, maxLat = -double.infinity, minLng = double.infinity, maxLng = -double.infinity;
    for (final p in points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final midLat = (minLat + maxLat) / 2;
    final xScale = math.cos(midLat * math.pi / 180);
    final w = math.max((maxLng - minLng) * xScale, 1e-9), h = math.max(maxLat - minLat, 1e-9);
    final scale = math.min((size.width - 24) / w, (size.height - 24) / h);
    final dx = (size.width - w * scale) / 2, dy = (size.height - h * scale) / 2;
    Offset at(TrackPoint p) => Offset(dx + (p.lng - minLng) * xScale * scale, dy + (maxLat - p.lat) * scale);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i]);
      i == 0 || points[i].segment != points[i - 1].segment ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Metric.run.last.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(colors: Metric.run).createShader(Offset.zero & size),
    );
    canvas.drawCircle(at(points.first), 6, Paint()..color = Metric.startDot);
    canvas.drawCircle(at(points.last), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(RoutePainter old) => !identical(old.points, points);
}

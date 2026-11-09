import 'package:flutter/material.dart';

abstract final class BrandColors {
  static const flame = [Color(0xFFFF9F43), Color(0xFFFF6A2B), Color(0xFFEE3B1E)];
  static const glow = Color(0xCCFFE27A);
  static const hot = [Color(0xFFFFF3B0), Color(0xFFFFFFFF), Color(0xFFFFFFFF)];
  static const core = [Color(0xFFE3201B), Color(0xFFFFB224)];
}

class FlameMarkPainter extends CustomPainter {
  const FlameMarkPainter({this.heightFraction = 0.70, this.burning = true});

  final double heightFraction;
  final bool burning;

  static const _box = Rect.fromLTRB(272, 160, 752, 876);
  static const _coreBox = Rect.fromLTRB(414, 566, 610, 818);

  static final Path _outer = Path()
    ..moveTo(540, 160)
    ..cubicTo(604, 276, 752, 380, 752, 594)
    ..cubicTo(752, 764, 644, 876, 512, 876)
    ..cubicTo(380, 876, 272, 770, 272, 620)
    ..cubicTo(272, 520, 316, 450, 374, 400)
    ..cubicTo(380, 466, 404, 510, 446, 536)
    ..cubicTo(438, 404, 476, 274, 540, 160)
    ..close();

  static final Path _core = Path()
    ..moveTo(512, 566)
    ..cubicTo(546, 622, 610, 660, 610, 734)
    ..cubicTo(610, 788, 566, 818, 512, 818)
    ..cubicTo(458, 818, 414, 788, 414, 734)
    ..cubicTo(414, 660, 478, 622, 512, 566)
    ..close();

  static final Path _flame = Path.combine(PathOperation.difference, _outer, _core);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height * heightFraction / _box.height;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-_box.center.dx, -_box.center.dy);
    if (burning) {
      canvas
        ..drawPath(
          _outer,
          Paint()
            ..color = BrandColors.glow
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 28 * scale),
        )
        ..drawPath(
          _flame,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: BrandColors.hot,
              stops: [0, 0.6, 1],
            ).createShader(_box),
        )
        ..drawPath(
          _core,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: BrandColors.core,
            ).createShader(_coreBox),
        );
    } else {
      canvas.drawPath(_flame, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FlameMarkPainter old) => old.heightFraction != heightFraction || old.burning != burning;
}

class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.rounded = true});

  final bool rounded;

  static const cornerFraction = 230 / 1024;

  static const background = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: BrandColors.flame,
    stops: [0, 0.55, 1],
  );

  static const highlight = RadialGradient(
    center: Alignment(-0.56, -0.76),
    radius: 0.75,
    colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(rounded ? size.width * cornerFraction : 0));
    canvas
      ..drawRRect(shape, Paint()..shader = background.createShader(rect))
      ..drawRRect(shape, Paint()..shader = highlight.createShader(rect));
    const FlameMarkPainter().paint(canvas, size);
  }

  @override
  bool shouldRepaint(AppIconPainter old) => old.rounded != rounded;
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Active Tracker',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: const AppIconPainter()),
  );
}

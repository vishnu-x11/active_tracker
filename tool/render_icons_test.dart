import 'dart:io';
import 'dart:ui' as ui;

import 'package:active_tracker/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> render(String path, int px, CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

class _Layer extends CustomPainter {
  const _Layer({this.background = false, this.mark});

  final bool background;
  final CustomPainter? mark;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width / 6;
    final visible = Rect.fromLTWH(inset, inset, size.width - 2 * inset, size.height - 2 * inset);
    if (background) {
      final all = Offset.zero & size;
      canvas
        ..drawRect(all, Paint()..shader = AppIconPainter.background.createShader(visible))
        ..drawRect(all, Paint()..shader = AppIconPainter.highlight.createShader(visible));
    }
    if (mark case final m?) {
      canvas
        ..save()
        ..translate(visible.left, visible.top);
      m.paint(canvas, visible.size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Layer old) => false;
}

void main() {
  test('render app icons', () async {
    const res = 'android/app/src/main/res';
    const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in legacy.entries) {
      final layer = e.value * 9 ~/ 4;
      await render('$res/mipmap-${e.key}/ic_launcher.png', e.value, const AppIconPainter());
      await render('$res/mipmap-${e.key}/ic_launcher_background.png', layer, const _Layer(background: true));
      await render('$res/mipmap-${e.key}/ic_launcher_foreground.png', layer, const _Layer(mark: FlameMarkPainter()));
      await render(
        '$res/mipmap-${e.key}/ic_launcher_monochrome.png',
        layer,
        const _Layer(mark: FlameMarkPainter(burning: false)),
      );
    }
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    const sizes = {
      '20x20@1x': 20,
      '20x20@2x': 40,
      '20x20@3x': 60,
      '29x29@1x': 29,
      '29x29@2x': 58,
      '29x29@3x': 87,
      '40x40@1x': 40,
      '40x40@2x': 80,
      '40x40@3x': 120,
      '60x60@2x': 120,
      '60x60@3x': 180,
      '76x76@1x': 76,
      '76x76@2x': 152,
      '83.5x83.5@2x': 167,
      '1024x1024@1x': 1024,
    };
    for (final e in sizes.entries) {
      await render('$ios/Icon-App-${e.key}.png', e.value, const AppIconPainter(rounded: false));
    }
    await render('assets/branding/app_icon_1024.png', 1024, const AppIconPainter());
    await render('assets/branding/play_store_512.png', 512, const AppIconPainter(rounded: false));
  });
}

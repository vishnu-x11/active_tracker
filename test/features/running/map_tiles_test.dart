import 'dart:math';
import 'dart:typed_data';

import 'package:active_tracker/features/running/presentation/widgets/route_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List png(int w, int h, {required bool detailed}) {
  final r = Random(1);
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    if (detailed && (p.x % 7 == 0 || p.y % 11 == 0 || r.nextInt(6) == 0)) {
      p.setRgb(r.nextInt(256), r.nextInt(256), r.nextInt(256));
    } else {
      p.setRgb(240, 237, 229);
    }
  }
  return img.encodePng(image);
}

void main() {
  test('a blank map snapshot is not ready, a drawn one is', () {
    expect(mapHasTiles(png(540, 1200, detailed: false)), isFalse);
    expect(mapHasTiles(png(540, 1200, detailed: true)), isTrue);
    expect(mapHasTiles(Uint8List(10)), isFalse);
  });
}

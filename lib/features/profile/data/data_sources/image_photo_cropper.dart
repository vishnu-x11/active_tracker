import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../../core/result.dart';
import '../../domain/use_cases/profile_photo.dart';

class ImagePhotoCropper implements PhotoCropper {
  const ImagePhotoCropper({this.side = 512, this.quality = 85});

  final int side;
  final int quality;

  @override
  Future<Result<Uint8List>> crop(Uint8List source, CropBox box) async {
    try {
      final (side, quality) = (this.side, this.quality);
      return Ok(await Isolate.run(() => _crop(source, box, side, quality)));
    } catch (e) {
      return Err(DeviceFailure("Couldn't read that photo. Please pick another one.", e));
    }
  }

  static Uint8List _crop(Uint8List source, CropBox box, int side, int quality) {
    final decoded = img.decodeImage(source);
    if (decoded == null) throw const FormatException('Unsupported image');
    final image = img.bakeOrientation(decoded);
    final size = box.size.round().clamp(1, math.min(image.width, image.height)).toInt();
    final x = box.left.round().clamp(0, image.width - size).toInt();
    final y = box.top.round().clamp(0, image.height - size).toInt();
    var square = img.copyCrop(image, x: x, y: y, width: size, height: size);
    if (size > side) square = img.copyResize(square, width: side, height: side, interpolation: img.Interpolation.cubic);
    return img.encodeJpg(square, quality: quality);
  }
}

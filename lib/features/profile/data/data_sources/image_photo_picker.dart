import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../../core/result.dart';
import '../../domain/use_cases/profile_photo.dart';

class ImagePhotoPicker implements PhotoPicker {
  ImagePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Result<Uint8List?>> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      return Ok(file == null ? null : await file.readAsBytes());
    } catch (e) {
      return Err(
        DeviceFailure(
          source == PhotoSource.camera
              ? "Couldn't open the camera. Allow camera access in Settings."
              : "Couldn't open your photos. Allow photo access in Settings.",
          e,
        ),
      );
    }
  }
}

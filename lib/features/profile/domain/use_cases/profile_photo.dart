import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/result.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

enum PhotoSource { camera, gallery }

abstract interface class PhotoPicker {
  Future<Result<Uint8List?>> pick(PhotoSource source);
}

class SetProfilePhoto {
  const SetProfilePhoto(this._repository);

  final ProfileRepository _repository;

  static const maxBytes = 400 * 1024;

  Future<Result<Profile>> call(String uid, Profile current, Uint8List? jpeg) async {
    if (jpeg != null && jpeg.isEmpty) return const Err(ValidationFailure("That photo couldn't be read."));
    if (jpeg != null && jpeg.length > maxBytes) {
      return const Err(ValidationFailure('That photo is too large. Please pick another one.'));
    }
    final next = current.copyWith(photo: () => jpeg == null ? null : base64Encode(jpeg));
    return switch (await _repository.save(uid, next)) {
      Ok() => Ok(next),
      Err(:final failure) => Err(failure),
    };
  }
}

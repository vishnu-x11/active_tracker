import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../../core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/edit_profile.dart';
import '../../domain/use_cases/profile_photo.dart';
import '../providers.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    ref.watch(dataRevisionProvider);
    final uid = await ref.watch(currentUidProvider.future);
    if (uid == null) return null;
    var result = await ref.read(getProfileProvider)(uid);
    if (result case Ok(value: null)) {
      if (await ref.read(syncControllerProvider.notifier).restoreProfile(uid)) {
        result = await ref.read(getProfileProvider)(uid);
      }
    }
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  void saved(Profile profile) => state = AsyncData(profile);

  Future<String?> edit(ProfileField field, String text) async {
    final current = state.value;
    final uid = await ref.read(currentUidProvider.future);
    if (current == null || uid == null) return 'You are signed out.';
    final result = await ref.read(editProfileProvider)(uid, current, field, text);
    if (!ref.mounted) return null;
    return switch (result) {
      Ok(:final value) => () {
        state = AsyncData(value);
        return null;
      }(),
      Err(:final failure) => failure.message,
    };
  }

  Future<void> change(Profile Function(Profile) apply) async {
    final current = state.value;
    final uid = await ref.read(currentUidProvider.future);
    if (current == null || uid == null) return;
    final next = apply(current);
    state = AsyncData(next);
    final result = await ref.read(editProfileProvider).save(uid, next);
    if (result is Err<Profile> && ref.mounted) state = AsyncData(current);
  }

  Future<String?> pickPhoto(PhotoSource source) async {
    final picked = await ref.read(photoPickerProvider).pick(source);
    if (!ref.mounted) return null;
    return switch (picked) {
      Ok(value: final bytes?) => _setPhoto(bytes),
      Ok() => null,
      Err(:final failure) => failure.message,
    };
  }

  Future<String?> removePhoto() => _setPhoto(null);

  Future<String?> _setPhoto(Uint8List? bytes) async {
    final current = state.value;
    final uid = await ref.read(currentUidProvider.future);
    if (current == null || uid == null) return 'You are signed out.';
    final result = await ref.read(setProfilePhotoProvider)(uid, current, bytes);
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }
}

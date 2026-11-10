import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/data_sources/image_photo_cropper.dart';
import '../data/data_sources/image_photo_picker.dart';
import '../data/data_sources/profile_local_data_source.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/use_cases/edit_profile.dart';
import '../domain/use_cases/get_profile.dart';
import '../domain/use_cases/profile_photo.dart';
import '../domain/use_cases/save_body_stats.dart';

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>(
  (ref) => ProfileLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileLocalDataSourceProvider)),
);

final getProfileProvider = Provider((ref) => GetProfile(ref.watch(profileRepositoryProvider)));
final saveBodyStatsProvider = Provider((ref) => SaveBodyStats(ref.watch(profileRepositoryProvider)));
final editProfileProvider = Provider((ref) => EditProfile(ref.watch(profileRepositoryProvider)));

final photoPickerProvider = Provider<PhotoPicker>((ref) => ImagePhotoPicker());
final photoCropperProvider = Provider<PhotoCropper>((ref) => const ImagePhotoCropper());
final setProfilePhotoProvider = Provider((ref) => SetProfilePhoto(ref.watch(profileRepositoryProvider)));
